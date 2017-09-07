component accessors=true {
  property config;
  property ds;
  property utilityService;
  property dataService;
  property logService;

  property string dbvendor;
  property string dialect;

  public component function init( utilityService, config, ds ) {
    if ( isNull( ds ) && !isNull( config.datasource ) ) {
      ds = config.datasource;
    }
    setupVendor( utilityService, ds );
    return this;
  }

  public array function toArray( required query inputQuery ) {
    return dataService.queryToArrayOfStructs( inputQuery );
  }

  /** Backports CF11's queryExecute() to CF9 & CF10
    *
    * @sql_statement  The SQL statement to execute
    * @queryParams    Array, or struct of query parameters
    * @queryOptions   Struct with query options (like datasource)
    *
    * @author   Henry Ho (henryho167@gmail.com), Mingo Hagen (email@mingo.nl)
    * @version  1, September 22, 2014
    * @version  2, December 29, 2015
    */
  public any function execute( required string sql_statement, any queryParams = { }, struct queryOptions = { } ) {
    var localQueryOptions = duplicate( queryOptions );
    var cacheId = buildCacheId( sql_statement, queryParams );

    if ( structKeyExists( localQueryOptions, "cachedWithin" ) && isNumeric( localQueryOptions.cachedWithin ) && val( localQueryOptions.cachedWithin ) > 0 ) {
      var cacheFor = localQueryOptions.cachedWithin;
      structDelete( localQueryOptions, "cachedWithin" );
      var cachedQuery = cacheGet( cacheId );
      if ( !isNull( cachedQuery ) ) {
        logService.writeLogLevel( "#request.appName#: (cached) #sql_statement#", "queryService" );
        return cachedQuery;
      }
    }

    var timer = getTickCount( );
    if( structKeyExists( server, "railo" ) ||
        structKeyExists( server, "lucee" ) || (
          structKeyExists( server, "coldfusion" ) &&
          int( listFirst( server.coldfusion.productVersion ) ) >= 11
        ) ) {
      try {
        var result = queryExecute( sql_statement, queryParams, localQueryOptions );
      } catch ( any e ) {
        writeDump( sql_statement );
        writeDump( e );
      }
      var sqlToLog = left( reReplace( sql_statement, "\s+", " ", "all" ), 1000 );
      logService.writeLogLevel( "#request.appName#: #getTickCount( ) - timer#ms. #sqlToLog#", "queryService" );
      if ( !isNull( cacheFor ) ) {
        cachePut( cacheId, result, cacheFor );
      }
      return result;
    }

    // normalize query params:
    var parameters = [ ];
    if( isArray( queryParams ) ) {
      for( var param in queryParams ) {
        if( isNull( param ) ) {
          arrayAppend( parameters, { "null" = true } );
        } else if( isSimpleValue( param ) ) {
          arrayAppend( parameters, { "value" = param } );
        } else {
          arrayAppend( parameters, param );
        }
      }
    } else if( isStruct( queryParams ) ) {
      for( var key in queryParams ) {
        if( isSimpleValue( queryParams[ key ] ) ) {
          arrayAppend( parameters, { "name" = key, "value" = queryParams[ key ] } );
        } else {
          var parameter = { "name" = key };
          structAppend( parameter, queryParams[ key ] );
          arrayAppend( parameters, parameter );
        }
      }
    } else {
      throw "unexpected type for queryParams";
    }

    // run and return query using query.cfc:
    localQueryOptions.sql = sql_statement;
    localQueryOptions.name = cacheId;
    localQueryOptions.parameters = parameters;

    var result = new query( argumentCollection = localQueryOptions ).execute( ).getResult( );
    var sqlToLog = left( reReplace( sql_statement, "\s+", " ", "all" ), 1000 );
    logService.writeLogLevel( "#request.appName#: #getTickCount( ) - timer#ms. #sqlToLog#", "queryService" );
    if ( !isNull( cacheFor ) ) {
      cachePut( cacheId, result, cacheFor );
    }
    return result;
  }

  /** Courtesy of user 'Tomalak' from http://stackoverflow.com/questions/2653804/how-to-sort-an-array-of-structs-in-coldfusion#answer-2653972
    */
  public array function arrayOfStructSort(
    required array base,
    string sortType = "text",
    string sortOrder = "ASC",
    string pathToSubElement = ""
  ) {
    var tmpStruct = { };
    var returnVal = [ ];

    for( var i = 1; i <= arrayLen( base ); i++ ) {
      tmpStruct[ i ] = base[ i ];
    }

    var keys = structSort( tmpStruct, sortType, sortOrder, pathToSubElement );

    for( var i = 1; i <= arrayLen( keys ); i++ ) {
      returnVal[ i ] = tmpStruct[ keys[ i ] ];
    }

    return returnVal;
  }

  public any function ormNativeQuery(
    string sql,
    struct where = { },
    struct options = { },
    array entities = [ ],
    unique = false
  ) {
    var ormSession = ormGetSession( );
    var sqlQuery = ormSession.createSQLQuery( sql );
    var paramMetadata = sqlQuery.getParameterMetadata( );

    for( var key in where ) {
      var value = where[ key ];

      if( isArray( value ) ) {
        sqlQuery = sqlQuery.setParameterList( key, value );
      } else if( isDate( value ) && !isNumeric( value ) ) {
        var asJavaDate = createObject( "java", "java.util.Date" ).init( value.getTime( ) );
        sqlQuery = sqlQuery.setDate( key, asJavaDate );
      } else if( isNull( value ) ) {
        sqlQuery = sqlQuery.setParameter( key, javaCast( "null", 0 ) );
      } else if( isSimpleValue( value ) ) {
        if ( !compareNoCase( "true", value ) || !compareNoCase( "false", value ) ) {
          sqlQuery = sqlQuery.setBoolean( key, value );
        } else {
          sqlQuery = sqlQuery.setString( key, value );
        }
      }
    }

    for( var key in options ) {
      if( key == "maxResults" ) {
        sqlQuery = sqlQuery.setMaxResults( options[ key ] );
        sqlQuery = sqlQuery.setFetchSize( options[ key ] );
      } else if( key == "offset" ) {
        sqlQuery = sqlQuery.setFirstResult( options[ key ] );
      } else if( key == "cacheable" && !arrayIsEmpty( entities ) ) {
        sqlQuery = sqlQuery.setCacheable( true );
      }
    }

    for( var entity in entities ) {
      if( isStruct( entity ) ) {
        var key = structKeyArray( entity )[ 1 ];
        var value = entity[ key ];
        sqlQuery = sqlQuery.addEntity( key, value );
      } else {
        sqlQuery = sqlQuery.addEntity( entity );
      }
    }

    if( unique ) {
      return sqlQuery.uniqueResult( );
    }

    try {
      return sqlQuery.list( );
    } catch ( any e ) {
      writeDump( sql );
      writeDump( sqlQuery );
      writeDump( e );
      abort;
    }
  }

  public string function buildQueryForEntity( entityName ) {
    var entity = entityNew( entityName );
    var tableName = entity.getTableName( );
    var sqlEntities = [ entityName ];
    var metaDataTable = "mainEntity";
    var SQLSelect = " SELECT DISTINCT mainEntity.* ";
    var SQLFrom = " FROM #tableName# mainEntity ";
    if( isInstanceOf( entity, "#config.root#.model.logged" ) ) {
      var loggedObj = createObject( "#config.root#.model.logged" ).init( );
      metaDataTable = loggedObj.getTableName( );
      SQLFrom &= " INNER JOIN #metaDataTable# ON mainEntity.id = #metaDataTable#.id ";
      SQLSelect &= ", #metaDataTable#.* ";
    }
    var SQLWhere = " WHERE #metaDataTable#.deleted IS NULL OR #metaDataTable#.deleted != #config.booleans.true# ";
    var SQLOrder = " ORDER BY #metaDataTable#.sortorder, #metaDataTable#.name ";
    return SQLSelect & SQLFrom & SQLWhere & SQLOrder;
  }

  public string function escapeField( required string input ) {
    var result = "";
    var inputAsArray = listToArray( input, "." );
    var escapeChars = {
      "PostgreSQL" = [
        '"',
        '"'
      ],
      "SQLServer" = [
        '[',
        ']'
      ]
    };

    for ( var field in inputAsArray ) {
      var escapedWord = "#escapeChars[ variables.dialect ][ 1 ]##field##escapeChars[ variables.dialect ][ 2 ]#";
      result = listAppend( result, escapedWord, "." );
    }

    return result;
  }

  private string function setupVendor( utilityService, ds ) {
    variables.dbvendor = "unknown";

    if ( isNull( ds ) ) {
      if( val( server.coldfusion.productversion ) < 10 ) {
        var appMetadata = application.getApplicationSettings( );
        ds = appMetadata.datasource;
      } else {
        var appMetadata = getApplicationMetaData( );
        if( structKeyExists( appMetadata, "ormsettings" ) && structKeyExists( appMetadata.ormsettings, "datasource" ) ) {
          ds = appMetadata.ormsettings.datasource;
        } else if ( structKeyExists( appMetadata, "datasource" ) ) {
          ds = appMetadata.datasource;
        }
      }
    }

    if ( !isNull( ds ) ) {
      var dbinfo = utilityService.getDbInfo( ds );

      variables.dbvendor = dbinfo.DATABASE_PRODUCTNAME;
      variables.dialect = listFirst( dbinfo.DRIVER_NAME, " " );
    }
  }

  private string function buildCacheId( required string sql_statement, required struct queryParams ) {
    var params = [];
    var sortedKeys = structKeyArray( queryParams );
    arraySort( sortedKeys, "textnocase" );
    for ( var key in sortedKeys ) {
      var value = queryParams[ key ];
      if ( isStruct( value ) ) { value = value.value; }
      if ( isSimpleValue( value ) ) { arrayAppend( params, "#key#=#value#" ); }
    }
    return hash( lcase( reReplace( sql_statement, '\s+', ' ', 'all' ) ) & serializeJson( params ) );
  }
}