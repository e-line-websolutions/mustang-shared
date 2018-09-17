component accessors=true {
  property config;
  property ds;
  property dataService;
  property logService;

  property string dbvendor;
  property string dialect;

  public component function init( utilityService, config, ds ) {
    if ( isNull( ds ) && !isNull( config.datasource ) ) {
      ds = config.datasource;
    }

    if ( !isNull( ds ) ) {
      setupVendor( utilityService, ds );
    }

    structAppend( variables, arguments );

    variables.queryServiceLogId = 0;

    return this;
  }

  public array function toArray( required query inputQuery ) {
    return variables.dataService.queryToArrayOfStructs( inputQuery );
  }

  /** Backports CF11's queryExecute() to CF9 & CF10
    *
    * @sqlStatement  The SQL statement to execute
    * @queryParams    Array, or struct of query parameters
    * @queryOptions   Struct with query options (like datasource)
    *
    * @author   Henry Ho (henryho167@gmail.com), Mingo Hagen (email@mingo.nl)
    * @version  1, September 22, 2014
    * @version  2, December 29, 2015
    */
  public any function execute( required string sqlStatement, any queryParams = { }, struct queryOptions = { } ) {
    addDatasource( queryOptions );

    variables.queryServiceLogId++;

    var sqlToLog = left( reReplace( sqlStatement, "\s+", " ", "all" ), 1000 );
    var localQueryOptions = duplicate( queryOptions );

    if ( structKeyExists( localQueryOptions, "cachedWithin" ) &&
         isNumeric( localQueryOptions.cachedWithin ) &&
         val( localQueryOptions.cachedWithin ) > 0 ) {
      var cacheId = buildCacheId( sqlStatement, queryParams );
      var cacheFor = localQueryOptions.cachedWithin;
      structDelete( localQueryOptions, "cachedWithin" );
      var cachedQuery = cacheGet( cacheId );
      if ( !isNull( cachedQuery ) ) {
        return cachedQuery;
      }
    }

    try {
      if( isModernCFML( ) ) {
        structAppend( local, localQueryOptions );
        var result = queryExecute( sqlStatement, queryParams, localQueryOptions );
      } else {
        // run and return query using query.cfc:
        localQueryOptions.sql = sqlStatement;
        if ( !isNull( cacheFor ) ) {
          localQueryOptions.name = cacheId;
        }
        localQueryOptions.parameters = normalizeParameters( queryParams );
        var result = new query( argumentCollection = localQueryOptions ).execute( ).getResult( );
      }
    } catch ( any e ) {
      if ( !isNull( sqlToLog ) ) {
        e.message &= " (SQL: #sqlToLog#)";
      }
      variables.logService.writeLogLevel( "#request.appName#: " & e.message, "queryService", "error" );
      variables.logService.dumpToFile( [ sqlStatement, e ] );
      rethrow;
    }

    if ( isNull( result ) ) {
      return;
    }

    if ( !isNull( cacheFor ) ) {
      cachePut( cacheId, result, cacheFor, createTimeSpan( 0, 1, 0, 0 ) );
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

  private string function buildCacheId( required string sqlStatement, required any queryParams ) {
    var params = [ ];
    var sortedKeys = structKeyArray( queryParams );
    arraySort( sortedKeys, "textnocase" );
    for ( var key in sortedKeys ) {
      var value = queryParams[ key ];
      if ( isStruct( value ) ) {
        value = value.value;
      }
      if ( isSimpleValue( value ) ) {
        arrayAppend( params, "#key#=#value#" );
      }
    }
    return "query_" & hash( lcase( reReplace( sqlStatement, '\s+', ' ', 'all' ) ) & serializeJson( params ) );
  }

  private void function addDatasource( queryOptions ) {
    if ( ( structKeyExists( queryOptions, "dbtype" ) && queryOptions.dbtype == "query" ) || structKeyExists(
      queryOptions,
      "datasource"
    ) ) {
      return;
    }

    if ( !isNull( variables.ds ) ) {
      queryOptions.datasource = variables.ds;
    }
  }

  private boolean function isModernCFML( ) {
    return ( structKeyExists( server, "railo" ) ||
             structKeyExists( server, "lucee" ) || (
             structKeyExists( server, "coldfusion" ) &&
               int( listFirst( server.coldfusion.productVersion ) ) >= 11
             ) );
  }

  private array function normalizeParameters( required any queryParams ) {
    var result = [ ];

    if( isArray( queryParams ) ) {
      for( var param in queryParams ) {
        if( isNull( param ) ) {
          arrayAppend( result, { "null" = true } );
        } else if( isSimpleValue( param ) ) {
          arrayAppend( result, { "value" = param } );
        } else {
          arrayAppend( result, param );
        }
      }
    } else if( isStruct( queryParams ) ) {
      for( var key in queryParams ) {
        if( isSimpleValue( queryParams[ key ] ) ) {
          arrayAppend( result, { "name" = key, "value" = queryParams[ key ] } );
        } else {
          var parameter = { "name" = key };
          structAppend( parameter, queryParams[ key ] );
          arrayAppend( result, parameter );
        }
      }
    } else {
      throw "unexpected type for queryParams";
    }

    return result;
  }
}