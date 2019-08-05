component {
  public component function init( fw1Config ) {
    variables.basePath = getDirectoryFromPath( getBaseTemplatePath( ) );
    variables.root = getRoot( );
    variables.name = hash( variables.basePath & cgi.server_name );
    variables.framework = fw1Config;

    return this;
  }

  public struct function readConfig( string site = cgi.server_name ) {
    if ( !structKeyExists( url, 'reload' ) ) {
      lock name="lock_mustang_#variables.name#_config_read" timeout="3" type="readonly" {
        var cachedConfig = cacheGet( 'config_#variables.name#' );

        if ( !isNull( cachedConfig ) ) {
          param cachedConfig.appIsLive=true;

          if ( cachedConfig.appIsLive ) {
            return cachedConfig;
          }
        }
      }
    }

    var result = { 'webroot' = ( cgi.https == 'on' ? 'https' : 'http' ) & '://' & cgi.server_name };

    var mustangSharedRoot = getMustangRoot();

    var globalConfig = deserializeJSON( fileRead( mustangSharedRoot & '/config/global.json', 'utf-8' ) );
    mergeStructs( globalConfig, result );

    if ( fileExists( variables.root & '/config/default.json' ) ) {
      var defaultConfig = deserializeJSON( fileRead( variables.root & '/config/default.json', 'utf-8' ) );
      mergeStructs( defaultConfig, result );
    }

    if ( fileExists( variables.root & '/config/' & site & '.json' ) ) {
      var siteConfig = deserializeJSON( fileRead( variables.root & '/config/' & site & '.json', 'utf-8' ) );

      if ( structKeyExists( siteConfig, 'include' ) ) {
        var includeConfig = deserializeJSON( fileRead( variables.root & '/config/#siteConfig.include#', 'utf-8' ) );
        mergeStructs( includeConfig, result );
      }

      mergeStructs( siteConfig, result );
    }

    lock name="lock_mustang_#variables.name#_config_write" timeout="3" type="exclusive" {
      cachePut( 'config_#variables.name#', result );
    }

    return result;
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

  public string function getMustangRoot( ) {
    return getDirectoryFromPath( getCurrentTemplatePath( ) );
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
    param exception.errorCode=500;
    param exception.detail="";

    exception.errorCode = val( exception.errorCode );

    if ( exception.errorCode == 0 ) {
      exception.errorCode = 500;
    }

    var pc = getPageContext( );

    if ( structKeyExists( server, "lucee" ) ) {
      cfcontent( reset = true );
      cfheader( statusCode = exception.errorCode, statusText = exception.message );
    } else {
      pc.getCfoutput( ).clearAll( );
      pc.getResponse( )
        .getResponse( )
        .setStatus( val( exception.errorCode ) == 0 ? 500 : exception.errorCode, exception.message );
    }

    var showDebugError = listFind( config.debugIP, cgi.remote_addr );

    if ( !showDebugError && !isNull( config.rollbar ) ) {
      try {
        var rollbar = new mustang.lib.rollbar.Rollbar( config.rollbar );
        rollbar.reportMessage( exception.message, "critical", exception );
      } catch ( any e ) { }
    }

    if ( cgi.path_info contains "/api/" || cgi.path_info contains "/adminapi/" || showDebugError || config.showDebug ) {
      if ( structKeyExists( server, "lucee" ) ) {
        cfcontent( type = "text/plain" );
      } else {
        pc.getResponse( )
          .setContentType( "text/plain" );
      }

      writeOutput( "Error: " & exception.message );
      writeOutput( chr( 13 ) & chr( 10 ) & "Detail: " & exception.detail );

      if ( showDebugError ) {
        writeOutput( chr( 13 ) & chr( 10 ) & "Stacktrace: " & exception.stackTrace );
      }

      abort;
    }

    var errorDump = "";

    savecontent variable="errorDump" {
      writeOutput( "Error: " & exception.message );
      writeOutput( "<br />Detail: " & exception.detail );
      writeOutput( "<br />Stacktrace: <pre>" & exception.stackTrace & "</pre>" );

      writeDump( cgi );
    }

    fileWrite( config.paths.errors & "/uncaught-error-#createUUID()#.html", errorDump, "utf-8" );

    var webroots = [ 'webroot', 'www' ];
    var fallbackErrorFile = 'error.html';

    for ( webroot in webroots ) {
      if ( fileExists( variables.root & "/#webroot#/error-#exception.errorCode#.html" ) ) {
        include "/#config.root#/#webroot#/error-#exception.errorCode#.html";
        writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
        abort;
      } else if ( fileExists( variables.root & "/#webroot#/error.html" ) ) {
        include "/#config.root#/#webroot#/error.html";
        writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
        abort;
      }
    }
  }

  public void function clearCache() {
    // clear query cache:
    createObject( 'java', 'coldfusion.server.ServiceFactory' ).getDataSourceService().purgeQueryCache();

    // clear ehcache:
    var allCacheIds = cacheGetAllIds();
    if ( !arrayIsEmpty( allCacheIds ) ) {
      cacheRemove( arrayToList( allCacheIds ) );
    }
  }
}