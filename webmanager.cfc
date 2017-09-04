component extends=framework.one {
  setupWebmanager( );

  // public functions

  public void function setupApplication( ) {
    frameworkTrace( "<b>webmanager</b>: setupApplication() called." );
    structDelete( application, "cache" );
  }

  public void function setupRequest( ) {
    frameworkTrace( "<b>webmanager</b>: setupRequest() called." );
    request.reset = isFrameworkReloadRequest( );

    var bf = getBeanFactory( );

    variables.wm = bf.getBean( "webmanagerService" );
    variables.util = bf.getBean( "utilityService" );
    variables.i18n = bf.getBean( "translationService" );

    util.limiter( );
    wm.relocateOnce( request.domainName );

    if ( structKeyExists( url, "nuke" ) ) {
      wm.clearCache();
      frameworkTrace( "<b>webmanager</b>: cache reset" );
    }

    if ( getSection( ) == "main" ) {
      var seoPathArray = wm.seoPathAsArray( );
      i18n.changeLanguage( wm.getLanguageFromPath( seoPathArray ) );
      controller( "main.setupLevel#arrayLen( seoPathArray )#" );
      request.action = request.context.action = wm.getActionFromPath( seoPathArray );
      setView( request.action );
    }
  }

  public void function onError( any exception, string event ) {
    if ( arrayFind( this.debugIps, cgi.remote_addr ) ) {
      writeDump( arguments );
      abort;
    }

    getpagecontext().getcfoutput().clearall();
    include "/error.html";
    abort;
  }

  public string function onMissingView( struct rc ) {
    if ( getSection( ) == "main" ) {
      return view( "main/default" );
    }

    return "Missing view for: #rc.action#";
  }

  // private functions

  private void function setupWebmanager( ) {
    cleanXHTMLQueryString( );

    param request.appName="Nameless-Webmanager-Site-#createUuid( )#";
    param request.domainName=cgi.server_name;

    this.debugIps = listToArray( "95.97.10.147,127.0.0.1" );
    this.sessionManagement = true;

    variables.root = this.mappings[ "/root" ] = getRoot( );
    variables.framework = {
      routesCaseSensitive = false,
      generateSES = true,
      SESOmitIndex = true,
      diLocations = [ "/root/model/services", "/mustang/services" ],
      diConfig = {
        constants = {
          root = variables.root,
          ds = "e-line_cm",
          navigationType = "per-level",
          config = {
            mediaRoot = fixPath( "D:\Accounts\E\E-Line Websolutions CM\files" ),
            cacheFileExists = true,
            defaultLanguage = "nl_NL",
            useOrm = false,
            logLevel = "error",
            templates = [ ]
          }
        }
      },
      base = "/root",
      routes = [
        { "/media/:file" = "/media/load/file/:file" },
        { "/forms/:action" = "/forms/:action" },
        { "/api/:action" = "/api/:action" },
        { "*" = "/main/default" }
      ]
    };
  }

  private struct function readConfig( string site = cgi.server_name ) {
    // cached:
    if ( !structKeyExists( url, "reload" ) ) {
      var config = cacheGet( "config-#this.name#" );

      // found cached settings, only use it in live apps:
      if ( !isNull( config ) &&
          structKeyExists( config, "appIsLive" ) &&
          isBoolean( config.appIsLive ) &&
          config.appIsLive ) {
        return config;
      }
    }

    // not cached:
    var defaultSettings = { "webroot" = ( cgi.https == 'on' ? 'https' : 'http' ) & "://" & cgi.server_name };

    if ( fileExists( root & "/config/default.json" ) ) {
      var defaultConfig = deserializeJSON( fileRead( root & "/config/default.json", "utf-8" ) );
      mergeStructs( defaultConfig, defaultSettings );
    }

    if ( fileExists( root & "/config/" & site & ".json" ) ) {
      var siteConfig = deserializeJSON( fileRead( root & "/config/" & site & ".json", "utf-8" ) );
      mergeStructs( siteConfig, defaultSettings );
    }

    cachePut( "config-#this.name#", defaultSettings );

    return defaultSettings;
  }

  private void function mergeStructs( required struct from, struct to = { } ) {
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

  private void function addToConstants( required struct websiteSpecificConstants ) {
    mergeStructs( websiteSpecificConstants, variables.framework.diConfig.constants );
  }

  private void function addMapping( required string name, required string absolutePath ) {
    if ( left( name, 1 ) != "/" ) {
      name = "/#name#";
    }

    this.mappings[ name ] = absolutePath;
  }

  private string function getRoot( string basePath = getDirectoryFromPath( getBaseTemplatePath( ) ) ) {
    var tmp = replace( basePath, "\", "/", "all" );
    return listDeleteAt( tmp, listLen( tmp, "/" ), "/" ) & "/";
  }

  private void function cleanXHTMLQueryString( ) {
    for ( var kv in url ) {
      if ( kv contains ";" ) {
        url[ listRest( kv, ";" ) ] = url[ kv ];
        structDelete( url, kv );
      }
    };
  }

  private string function fixPath( string originalPath ) {
    return listChangeDelims( originalPath, '/', '\/' );
  }
}
