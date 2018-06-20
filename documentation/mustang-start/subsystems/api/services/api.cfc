component accessors=true {
  property utilityService;
  property queryService;
  property jsonJavaService;
  property config;
  property numeric recordCount;
  property string query;
  property struct debugInfo;
  property struct params;
  property struct querySettings;
  property struct entities;

  public component function init() {
    variables.debugInfo = {
      "timers" = {}
    };
    return this;
  }

  public array function onMissingMethod( string missingMethodName, struct missingMethodArguments ) {
    // defaults
    var customArgs = {
      basicsOnly = false,
      cacheable = false,
      maxLevel = 1,
      maxResults = 25,
      offset = 0
    };

    structDelete( customArgs, "this" );
    structDelete( customArgs, "arguments" );

    structAppend( customArgs, missingMethodArguments, true );

    variables.querySettings = {
      "cacheable" = customArgs.cacheable,
      "maxResults" = customArgs.maxResults,
      "offset" = customArgs.offset
    };

    var t = getTickCount();
    var fn = "__#missingMethodName#";
    if( structKeyExists( this, fn )) {
      utilityService.cfinvoke( this, fn, customArgs );
    } else {
      throw( message="Missing method", detail="Method #fn#() does not exist.", type="api.onMissingMethod.missingMethodError" );
    }
    variables.debugInfo.timers[ "buildQuery" ] = getTickCount() - t;

    var t = getTickCount();
    var result = queryService.ormNativeQuery( query, params, querySettings, entities, false );
    variables.debugInfo.timers[ "runQuery" ] = getTickCount() - t;

    return result;
  }

  public struct function getDebugInfo() {
    structAppend( variables.debugInfo, {
      "sql" = query,
      "settings" = querySettings,
      "where" = params
    });

    return debugInfo;
  }

  public array function parsePayload() {
    var payload = toString( GetHttpRequestData( ).content );

    if ( structKeyExists( form, "batch" ) ) {
      if ( isJSON( form.batch ) ) {
        form.batch = jsonJavaService.deserialize( form.batch );
      } else {
        throw( "batch should be a JSON formatted array" );
      }
    } else if ( isJson( payload ) ) {
      form.batch = [ jsonJavaService.deserialize( payload ) ];
    } else {
      form.batch = [ ];
      for ( keyVal in listToArray( payload, "&" ) ) {
        var key = urlDecode( listFirst( keyVal, "=" ) );
        var val = urlDecode( listRest( keyVal, "=" ) );
        form.batch[ 1 ][ key ] = val;
      }
    }

    return form.batch;
  }
}