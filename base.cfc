component {
  public component function init( fw1Config ) {
    variables.basePath = getDirectoryFromPath( getBaseTemplatePath( ) );
    variables.root = getRoot( );
    variables.name = hash( variables.basePath );
    variables.framework = fw1Config;

    return this;
  }

  public struct function readConfig( string site = cgi.server_name ) {
    if ( !structKeyExists( url, "reload" ) ) {
      var cachedConfig = cacheGet( "config_#variables.name#" );

      if ( !isNull( cachedConfig ) ) {
        param cachedConfig.appIsLive=true;

        if ( cachedConfig.appIsLive ) {
          return cachedConfig;
        }
      }
    }

    var defaultSettings = {
      "webroot" = ( cgi.https == 'on' ? 'https' : 'http' ) & "://" & cgi.server_name
    };

    var mustangSharedRoot = getDirectoryFromPath( getCurrentTemplatePath( ) );

    var globalConfig = deserializeJSON( fileRead( mustangSharedRoot & "/config/global.json", "utf-8" ) );
    mergeStructs( globalConfig, defaultSettings );

    if ( fileExists( variables.root & "/config/default.json" ) ) {
      var defaultConfig = deserializeJSON( fileRead( variables.root & "/config/default.json", "utf-8" ) );
      mergeStructs( defaultConfig, defaultSettings );
    }

    if ( fileExists( variables.root & "/config/" & site & ".json" ) ) {
      var siteConfig = deserializeJSON( fileRead( variables.root & "/config/" & site & ".json", "utf-8" ) );
      mergeStructs( siteConfig, defaultSettings );
    }

    cachePut( "config_#variables.name#", defaultSettings );

    return defaultSettings;
  }

  public void function mergeStructs( required struct from, struct to = { } ) {
    for ( var key in from ) {
      if ( isStruct( from[ key ] ) ) {
        if ( !structKeyExists( to, key ) ) {
          to[ key ] = from[ key ];
        } else if ( isStruct( to[ key ] ) ) {
          mergeStructs( from[ key ], to[ key ] );
        }
      } else {
        to[ key ] = from[ key ];
      }
    }
    structAppend( from, to, false );
  }

  public void function addToConstants( required struct websiteSpecificConstants ) {
    mergeStructs( websiteSpecificConstants, variables.framework.diConfig.constants );
  }

  public string function getRoot( string basePath = variables.basePath ) {
    var tmp = fixPath( basePath );
    return listDeleteAt( tmp, listLen( tmp, "/" ), "/" ) & "/";
  }

  public void function cleanXHTMLQueryString( ) {
    for ( var kv in url ) {
      if ( kv contains ";" ) {
        url[ listRest( kv, ";" ) ] = url[ kv ];
        structDelete( url, kv );
      }
    };
  }

  public string function fixPath( string originalPath ) {
    var output = listChangeDelims( originalPath, '/', '\/' );

    if ( !server.os.name contains "Windows" && left( originalPath, 1 ) == "/" ) {
      output = "/" & output;
    }

    return output;
  }

  public string function getDbCreate( required struct config ) {
    if ( !structKeyExists( url, "reload" ) || !structKeyExists( url, "nuke" ) ) {
      return "none";
    }

    if ( compare( url.reload, config.reloadpw ) != 0 ) {
      return "none";
    }

    return "update";
  }

  public void function loadListener( bf ) {
    // ACF / Lucee compatibility services:
    if ( !structKeyExists( server, "lucee" ) ) {
      bf.declareBean( "threadfix", "mustang.compatibility.acf.threadfix" );
    }
  }

  public void function handleExceptions( required struct config, any exception, string event ) {
    exception = duplicate( exception );

    if ( structKeyExists( exception, "Cause" ) ) {
      exception = duplicate( exception.cause );
    }

    param exception.message="Uncaught Error";
    param exception.detail="";

    var pc = getPageContext( );

    if ( structKeyExists( server, "lucee" ) ) {
      cfcontent( reset = true );
      cfheader( statusCode = 500, statusText = exception.message );
    } else {
      pc.getCfoutput( ).clearAll( );
      pc.getResponse( )
        .getResponse( )
        .setStatus( 500, exception.message );
    }

    var showDebugError = listFind( config.debugIP, cgi.remote_addr );

    if ( !showDebugError && !isNull( config.rollbar ) ) {
      try {
        var rollbar = new mustang.lib.rollbar.Rollbar( config.rollbar );
        rollbar.reportMessage( exception.message, "critical", exception );
      } catch ( any e ) { }
    }

    if ( cgi.path_info contains "/api/" || cgi.path_info contains "/adminapi/" || showDebugError ) {
      if ( structKeyExists( server, "lucee" ) ) {
        cfcontent( type = "text/plain" );
      } else {
        pc.getResponse( )
          .setContentType( "text/plain" );
      }

      writeOutput( "Error: " & exception.message );

      if ( showDebugError ) {
        writeOutput( chr( 13 ) & chr( 13 ) & "Detail: " & exception.detail );
        writeOutput( chr( 13 ) & chr( 13 ) & "Stacktrace: " & exception.stackTrace );
      }

      abort;
    }

    if ( fileExists( variables.root & "/webroot/error.html" ) ) {
      include "/root/webroot/error.html";
      writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
      abort;
    }

    if ( fileExists( variables.root & "/www/error.html" ) ) {
      include "/root/www/error.html";
      writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
      abort;
    }
  }
}