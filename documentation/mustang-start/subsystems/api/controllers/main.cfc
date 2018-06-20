component accessors=true {
  property framework;
  property config;
  property jsonJavaService;
  property dataService;
  property utilityService;
  property queryService;
  property apiService;

  // CONSTRUCTOR:
  public component function init( ) {
    variables.ormEntities = structKeyArray( ormGetSessionFactory( ).getAllClassMetadata( ) );

    arrayAppend( variables.ormEntities, "main" );

    variables.supportedVerbs = "GET,POST,PUT,DELETE";

    return this;
  }

  // setup and security
  public void function before( required struct rc ) {
    var item = variables.framework.getItem( );

    if( item == "error" ) {
      return;
    }

    var section = variables.framework.getSection( );

    variables.entityName = listLast( section, '.-/\' );
    variables.timer = getTickCount( );

    if ( !arrayFindNoCase( ormEntities, entityName ) ) {
      variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "not-found" } ), 404 );
      variables.framework.abortController( );
    }

    variables.entity = entityNew( entityName );
    variables.props = entity.getInheritedProperties( );
    variables.where = { "deleted" = false };

    if ( structKeyExists( rc, "id" ) ) {
      variables.where[ "id" ] = rc.id;
    }

    if ( item == "info" ) {
      return;
    }

    var privilegeMapping = {
      "default" = "view",
      "filter" = "view",
      "bycoating" = "view",
      "search" = "view",
      "show" = "view",
      "create" = "create",
      "update" = "change",
      "destroy" = "delete"
    };

    writeLog( file = "#request.appName#_API", text = "#privilegeMapping[ item ]# #item# by #cgi.remote_addr#" );

    if ( !rc.auth.role.can( privilegeMapping[ item ], entityName ) ) {
      variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "not-allowed" } ), 405 );
      variables.framework.abortController( );
    }

    if ( !structKeyExists( rc, "maxLevel" ) ) {
      var md = getMetaData( entity );
      if ( structKeyExists( md, "defaultLevel" ) ) {
        rc.maxLevel = md.defaultLevel;
      }
    }

    __setupDefaults( rc );
  }

  // GET (list, search)
  public void function default( required struct rc ) {
    param string rc.filterType="";

    var filterType = rc.filterType;
    var querySettings = {
      "cacheable" = variables.config.appIsLive,
      "maxResults" = min( 10000, maxResults ),
      "offset" = offset
    };
    var debugInfo = {
      "timers" = { },
      "querySettings" = querySettings
    };

    var timer = t = getTickCount( );

    structDelete( url, "basicsOnly" );
    structDelete( url, "cacheable" );
    structDelete( url, "filterType" );
    structDelete( url, "maxResults" );
    structDelete( url, "offset" );

    for ( var key in url ) {
      if ( entity.propertyExists( key ) ) {
        variables.where[ key ] = url[ key ];
      }
    }

    var useAF = false;
    var afCounter = 0;
    var afAlias = "";
    var afWhere = "";
    var tableName = entity.getTableName( );
    var sqlEntities = [ entityName ];
    var metaDataTable = "mainEntity";
    var SQLSelect = " SELECT mainEntity. * ";
    var SQLFrom = " FROM #tableName# mainEntity ";
    var SQLWhere = " WHERE 0 = 0 ";
    var SQLOrder = "";

    if ( isInstanceOf( entity, "#variables.config.root#.model.logged" ) ) {
      var loggedObj = createObject( "#variables.config.root#.model.logged" ).init();
      metaDataTable = loggedObj.getTableName();
      SQLFrom &= " INNER JOIN #metaDataTable# ON mainEntity.id = #metaDataTable#.id ";
      SQLSelect &= ", #metaDataTable#.* ";
    }

    if ( structKeyExists( props, "sortorder" ) || structKeyExists( props, "name" ) ) {
      SQLOrder = " ORDER BY ";
      if ( structKeyExists( props, "sortorder" ) ) {
        SQLOrder &= " #metaDataTable#.sortorder, ";
      }
      if ( structKeyExists( props, "name" ) ) {
        SQLOrder &= " #metaDataTable#.name, ";
      }
      SQLOrder = " " & listChangeDelims( trim( SQLOrder ), "," );
    }

    for ( var key in where ) {
      var searchInTable = "mainEntity";

      if ( listFindNoCase( "id,name,deleted,archived,sortorder", key ) ) {
        searchInTable = metaDataTable;
      }

      if ( isSimpleValue( where[ key ] ) ) {
        // NULL:
        if ( where[ key ] == "NULL" ) {
          SQLWhere &= " AND #searchInTable#.#key# IS NULL";
          structDelete( where, key );
          continue;
        }

        // OBJECT IDs:
        if ( structKeyExists( props[ key ], "cfc" ) ) {
          if ( props[ key ].fieldType contains "to-many" ) {
            SQLFrom &= " JOIN #searchInTable#.#props[ key ].name# _#key# ";
            SQLWhere &= " AND _#key#.id IN ( :#key# ) ";
            variables.where[ key ] = listToArray( where[ key ] );
            continue;
          } else {
            SQLFrom &= " JOIN #searchInTable#.#props[ key ].name# _#key# ";
            SQLWhere &= " AND _#key#.id = :#key# ";
            continue;
          }
        }

        // WILDCARD:
        if ( structKeyExists( props[ key ], "searchable" ) ) {
          afAlias = "";
          afWhere = "";
          useAF = false;

          if ( structKeyExists( props[ key ], "alsoFilter" ) && len( trim( props[ key ].alsoFilter ) ) ) {
            useAF = true;
            afCounter++;

            var afTable = listFirst( props[ key ].alsoFilter, "." );
            var afField = listLast( props[ key ].alsoFilter, "." );
            afAlias = "_af_#afTable#_#afCounter#";
            afWhere = "#afAlias#.#afField#";

            SQLFrom &= " LEFT JOIN #searchInTable#.#afTable# #afAlias# ";
          }

          if ( isDefined( "filterType" ) && len( trim( filterType ) ) ) {
            if ( filterType == "contains" ) {
              variables.where[ key ] = "%#where[ key ]#";
            }
            variables.where[ key ] = "#where[ key ]#%";

            if ( useAF && len( trim( afWhere ) ) ) {
              SQLWhere &= " AND ( #searchInTable#.#key# LIKE :#key# OR #afWhere# LIKE :#key# )";
              continue;
            }

            SQLWhere &= " AND #searchInTable#.#key# LIKE :#key# ";
          }
        }
      }

      // DEFAULT:
      if ( useAF && len( trim( afWhere ) ) ) {
        SQLWhere &= " AND ( #searchInTable#.#key# = :#key# OR #afWhere# = :#key# )";
        continue;
      }

      SQLWhere &= " AND #searchInTable#.#key# = :#key# ";
    }

    var SQL = SQLSelect & SQLFrom & SQLWhere & SQLOrder;
    debugInfo.timers[ "buildQuery" ] = getTickCount( ) - t;

    debugInfo[ "sql" ] = SQL;
    debugInfo[ "where" ] = where;

    var t = getTickCount( );
    var data = variables.queryService.ORMNativeQuery( SQL, where, querySettings, sqlEntities );
    var SQLForRecordCount = "SELECT COUNT( mainEntity.id ) " & SQLFrom & SQLWhere;
    var recordCount = variables.queryService.ORMNativeQuery( SQLForRecordCount, where, querySettings, [ ], true );
    debugInfo.timers[ "runQuery" ] = getTickCount( ) - t;

    var t = getTickCount( );
    var result = [ ];
    for ( var record in data ) {
      var processedForJSON = variables.dataService.processEntity( data = record, maxLevel = maxLevel, basicsOnly = basicsOnly );
      arrayAppend( result, processedForJSON );
    }
    debugInfo.timers[ "processObjectTree" ] = getTickCount( ) - t;

    var t = getTickCount( );
    var output = variables.jsonJavaService.serialize(
      {
        "status" = "ok",
        "recordCount" = recordCount,
        "data" = result,
        "_debug" = "debugplaceholder"
      }
    );
    debugInfo.timers[ "serializeJson" ] = getTickCount( ) - t;

    debugInfo.timers[ "global" ] = getTickCount( ) - timer;

    output = replace( output, '"debugplaceholder"', variables.jsonJavaService.serialize( debugInfo ) );

    variables.framework.renderData( "rawjson", output );
  }

  // GET (detail)
  public void function show( required struct rc ) {
    variables.maxResults = max( maxResults, 2 );

    var record = entityLoad( entityName, where, true );

    if ( isNull( record ) ) {
      variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "not-found" } ) );
      return;
    }

    var result = variables.dataService.processEntity( data = record, maxLevel = maxLevel, basicsOnly = basicsOnly );

    variables.framework.renderData(
      "rawjson",
      variables.jsonJavaService.serialize(
        {
          "status" = "ok",
          "data" = result,
          "_debug" = {
        "where" = where,
        "timer" = ( getTickCount( ) - timer )
      }
        }
      )
    );
  }

  // POST (new)
  public void function create( required struct rc ) {
    var result = {
      "status" = "created",
      "data" = [ ]
    };

    var batchData = variables.apiService.parsePayload( );

    transaction {
      try {
        for ( var objProperties in batchData ) {
          structDelete( objProperties, "fieldnames" );
          structDelete( objProperties, "batch" );

          var newObject = entityNew( entityName );
          entitySave( newObject );
          newObject.save( objProperties );

          arrayAppend( result.data, newObject );
        }
      } catch ( any e ) {
        transactionRollback( );
        rethrow;
      }
    }

    variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( result ), 201 );
  }

  // PUT (change)
  public void function update( required struct rc ) {
    var result = {
      "status" = "ok",
      "data" = [ ]
    };

    var batchData = variables.apiService.parsePayload( );

    transaction {
      try {
        for ( var objProperties in form.batch ) {
          structDelete( objProperties, "fieldnames" );
          structDelete( objProperties, "batch" );

          var updateObject = entityLoad( entityName, where, true );

          if ( isNull( updateObject ) ) {
            throw( "not-found", "mainApiService.update.recordNotFoundError", "", 404 );
          }

          updateObject.init( );
          objProperties[ "#entityName#ID" ] = updateObject.getID( );
          updateObject.save( objProperties );
          arrayAppend( result.data, updateObject );
        }
      } catch ( any e ) {
        transactionRollback( );
        rethrow;
      }
    }

    variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( result ), 200 );
  }

  // DELETE
  public void function destroy( required struct rc ) {
    var data = entityLoad( entityName, where, true );

    if ( isNull( data ) ) {
      variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "not-found" } ), 404 );
      return;
    }

    data.init( );
    data.save(
      {
        "#entityName#ID" = data.getID( ),
        "deleted" = true
      }
    );

    variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "no-content" } ), 204 );
  }

  // INFO
  public void function info( required struct rc ) {
    variables.framework.renderData(
      "rawjson",
      variables.jsonJavaService.serialize(
        {
          "status" = "ok",
          "data" = getComponentMetadata( "#variables.config.root#.model.#entityName#" )
        }
      )
    );
  }

  // CATCH ALL HANDLER:
  public void function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
    if ( listFindNoCase( "after", missingMethodName ) ) {
      return; // skip framework functions
    }

    var rc = missingMethodArguments.rc;
    var customArgs = { };
    structAppend( customArgs, url, true );
    structAppend( customArgs, form, true );

    if ( arrayFindNoCase( ormEntities, entityName ) > 0 ) {
      var entityService = variables.framework.getBeanFactory( ).getBean( '#entityName#Service' );
      var basicsOnlyDefault = missingMethodName == "search" ? true : false;

      param string rc.filterType="";
      param string rc.keywords="";
      param boolean rc.basicsOnly=basicsOnlyDefault;

      __setupDefaults( rc );

      structAppend(
        customArgs,
        {
          maxResults = min( 10000, maxResults ),
          offset = offset,
          filterType = rc.filterType,
          keywords = rc.keywords,
          cacheable = variables.config.appIsLive
        },
        true
      );

      var executedMethod = variables.utilityService.cfinvoke( entityService, missingMethodName, customArgs );
      var debugInfo = entityService.getDebugInfo( );

      var t = getTickCount( );
      var result = [ ];
      for ( var object in executedMethod ) {
        var processed = variables.dataService.processEntity( data = object, maxLevel = maxLevel, basicsOnly = basicsOnly );
        arrayAppend( result, processed );
      }
      debugInfo.timers[ "processObjectTree" ] = getTickCount( ) - t;

      var t = getTickCount( );
      var output = variables.jsonJavaService.serialize(
        {
          "status" = "ok",
          "recordCount" = entityService.getRecordCount( ),
          "data" = result,
          "_debug" = "debugplaceholder"
        }
      );
      debugInfo.timers[ "serializeJson" ] = getTickCount( ) - t;

      debugInfo.timers[ "global" ] = getTickCount( ) - timer;

      output = replace( output, '"debugplaceholder"', variables.jsonJavaService.serialize( debugInfo ) );

      variables.framework.renderData( "rawjson", output );
    } else {
      var entityService = variables.framework.getBeanFactory( ).getBean( '#entityName#Service' );
      var executedMethod = variables.utilityService.cfinvoke( entityService, missingMethodName, customArgs );
      if ( !isNull( executedMethod ) ) {
        variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( executedMethod ) );
      }
    }
  }

  // ERROR HANDLER:
  public void function error() {
    param request.exception={};

    if( structKeyExists( request.exception, "RootCause" ) ) {
      request.exception = request.exception.RootCause;
    }

    param request.exception.message="Unexpected Error";
    param request.exception.detail="";

    variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( {
      "status" = "Error",
      "errorMessage" = request.exception.message,
      "errorDetail" = request.exception.detail
    } ), 500 );
  }

  public void function __setupDefaults( required struct rc ) {
    variables.basicsOnly = false;
    variables.maxLevel = 1;
    variables.maxResults = 25;
    variables.offset = 0;

    if ( !isNull( rc.basicsOnly ) ) {
      variables.basicsOnly = rc.basicsOnly;
    }
    if ( !isNull( rc.maxLevel ) ) {
      variables.maxLevel = rc.maxLevel;
    }
    if ( !isNull( rc.maxResults ) ) {
      variables.maxResults = rc.maxResults;
    }
    if ( !isNull( rc.offset ) ) {
      variables.offset = rc.offset;
    }
  }
}