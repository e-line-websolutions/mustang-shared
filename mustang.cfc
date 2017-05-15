component extends="framework.one" {
  variables.downForMaintenance = false; // set this to true during updates

  setupMustang( );

  // public functions:

  public void function setupApplication( ) {
    var bf = getBeanFactory( );
    var logService = bf.getBean( "logService" );

    if ( structKeyExists( url, "nuke" ) ) {
      // rebuild ORM:
      ORMReload( );
      logService.writeLogLevel( "ORM reloaded", request.appName );

      // empty caches:
      structDelete( application, "threads" );
      try { ORMEvictQueries( ); } catch ( any e ) { }
      cacheRemove( arrayToList( cacheGetAllIds( ) ) );
      logService.writeLogLevel( "Caches purged", request.appName );
    }

    logService.writeLogLevel( "Application initialized", request.appName );
  }

  public void function setupSession( ) {
    structDelete( session, "progress" );
    session.connectionStorage = { };
  }

  public void function setupRequest( ) {
    if ( request.reset ) {
      setupSession( );
    }

    // globally available utility libraries:
    var bf = getBeanFactory( );
    variables.i18n = bf.getBean( "translationService" );
    variables.util = bf.getBean( "utilityService" );

    util.setCFSetting( "showdebugoutput", request.context.debug );

    // rate limiter:
    util.limiter( );

    // down for maintenance message to non dev users:
    if ( variables.downForMaintenance && !listFind( variables.cfg.debugIP, cgi.remote_addr ) ) {
      writeOutput(
        'Geachte gebruiker,
        <br /><br />
        Momenteel is deze applicatie niet beschikbaar in verband met onderhoud.<br />
        Onze excuses voor het ongemak.
        <!-- IP adres: #cgi.remote_addr# -->
      '
      );
      abort;
    }

    // security:
    controller( ":security.authorize" );

    // internationalization:
    controller( ":i18n.load" );

    // content:
    if ( getSubsystem( ) == getDefaultSubsystem( ) || listFindNoCase( variables.cfg.contentSubsystems, getSubsystem( ) ) ) {
      controller( ":admin-ui.load" );
    }

    // try to queue up crud (admin) actions:
    if ( getSubsystem( ) == getDefaultSubsystem( ) && !util.fileExistsUsingCache( request.root & "/controllers/#getSection( )#.cfc" ) ) {
      controller( ":crud.#getItem( )#" );
    }

    // try to queue up api actions:
    if ( getSubsystem( ) == "api" && !util.fileExistsUsingCache( request.root & "/subsystems/api/controllers/#getSection( )#.cfc" ) ) {
      controller( "api:main.#getItem( )#" );
    }
  }

  public void function setupSubsystem( string subsystem = "" ) {
    if ( structKeyExists( variables.framework.subsystems, subsystem ) ) {
      var subsystemConfig = getSubsystemConfig( subsystem );
      variables.framework = mergeStructs( subsystemConfig, variables.framework );
      structDelete( variables.framework.subsystems, subsystem );
    }
  }

  public void function onError( any exception, string event ) {
    param request.action="main.default";

    if ( listFindNoCase( "adminapi,api", listFirst( cgi.PATH_INFO, "/" ) ) ) {
      if ( structKeyExists( exception, "cause" ) ) {
        return onError( exception.cause, event );
      }

      if ( structKeyExists( exception, "message" ) && structKeyExists( exception, "detail" ) ) {
        var jsonJavaService = getBeanFactory( ).getBean( "jsonJavaService" );
        var pageContext = getPageContext( );
        var response = pageContext.getResponse( );

        response.setContentType( "application/json" );
        response.setStatus( 500 );

        writeOutput(
          jsonJavaService.serialize(
            {
              "status" = "error",
              "error" = "uncaught error: " & exception.message,
              "detail" = exception.detail
            }
          )
        );
        abort;
      }
    }

    super.onError( argumentCollection = arguments );
  }

  public string function onMissingView( struct rc ) {
    if ( util.fileExistsUsingCache( request.root & "/views/" & getSection( ) & "/" & getItem( ) & ".cfm" ) ) {
      return view( getSection( ) & "/" & getItem( ) );
    }

    if ( util.fileExistsUsingCache( request.root & "/subsystems/" & getSubsystem( ) & "/views/" & getSection( ) & "/" & getItem( ) & ".cfm" ) ) {
      return view( getSubsystem( ) & ":" & getSection( ) & "/" & getItem( ) );
    }

    if ( structKeyExists( request.context, "fallbackView" ) ) {
      return view( request.context.fallbackView );
    }

    return view( ":app/notfound" );
  }

  // private functions:

  private void function setupMustang( ) {
    request.context.startTime = getTickCount( );

    cleanXHTMLQueryString( );

    request.root = getRoot();

    // Overwrite these in the app's own Application.cfc
    param request.version="?";
    param request.appName="?";
    param this.routes=[];

    // CF application setup:
    this.mappings[ "/root" ] = request.root;
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan( 0, 2, 0, 0 );

    // Private variables:
    variables.cfg = request.context.config = readConfig( );
    variables.live = variables.cfg.appIsLive;
    variables.i18n = 0;
    variables.util = 0;

    if ( structKeyExists( variables.cfg.paths, "basecfc" ) ) {
      this.mappings[ "/basecfc" ] = variables.cfg.paths.basecfc;
    }

    // Reload:
    if ( structKeyExists( url, "reload" ) && url.reload != variables.cfg.reloadpw ) {
      structDelete( url, "reload" );
    }

    request.reset = structKeyExists( url, "reload" );

    // Config based global variables:
    request.context.debug = variables.cfg.showDebug && ( listFind( variables.cfg.debugIP, cgi.remote_addr ) || !len( trim( variables.cfg.debugIP ) ) );
    request.webroot = variables.cfg.webroot;

    if ( len( variables.cfg.paths.fileUploads ) ) {
      request.fileUploads = variables.cfg.paths.fileUploads;
    }

    // Datasource settings:
    if ( len( variables.cfg.datasource ) ) {
      this.datasource = variables.cfg.datasource;
      this.ormEnabled = true;
      this.ormSettings = {
        CFCLocation = request.root & "model",
        DBCreate = ( variables.live ? ( request.reset ? "update" : "none" ) : ( request.reset ? "dropcreate" : "update" ) ),
        SQLScript = variables.cfg.nukescript,
        secondaryCacheEnabled = variables.live ? true : false,
        cacheProvider = "ehcache"
      };
    }

    // framework settings:
    variables.framework = {
      generateSES = true,
      SESOmitIndex = true,
      base = "/root",
      baseURL = variables.cfg.webroot,
      error = "app.error",
      unhandledPaths = "/inc,/tests,/browser,/cfimage,/diagram",
      diLocations = [
        "/mustang/services",
        "/root/services",
        "/root/model/services",
        "/root/subsystems/api/services"
      ],
      diConfig = {
        constants = {
          root = request.root,
          config = cfg
        }
      },
      routesCaseSensitive = false,
      environments = {
        live = {
          cacheFileExists = true,
          password = variables.cfg.reloadpw,
          trace = variables.cfg.showDebug
        },
        dev = {
          trace = variables.cfg.showDebug
        }
      },
      subsystems = { api = { error = "api:main.error" } }
    };
  }

  private void function cleanXHTMLQueryString( ) {
    for ( var kv in url ) {
      if ( kv contains ";" ) {
        url[ listRest( kv, ";" ) ] = url[ kv ];
        structDelete( url, kv );
      }
    };
  }

  private string function getEnvironment( ) {
    return variables.live ? "live" : "dev";
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
    var computedSettings = { "webroot" = ( cgi.https == 'on' ? 'https' : 'http' ) & "://" & cgi.server_name };
    var defaultSettings = { };

    if ( fileExists( request.root & "/config/default.json" ) ) {
      var defaultConfig = deserializeJSON( fileRead( request.root & "/config/default.json", "utf-8" ) );
      defaultSettings = mergeStructs( defaultConfig, computedSettings );
    }

    if ( fileExists( request.root & "/config/" & site & ".json" ) ) {
      var siteConfig = deserializeJSON( fileRead( request.root & "/config/" & site & ".json", "utf-8" ) );
      var defaultSettings = mergeStructs( siteConfig, defaultSettings );
    }

    cachePut( "config-#this.name#", defaultSettings );

    return defaultSettings;
  }

  private struct function mergeStructs( required struct from, struct to = { } ) {
    // also append nested struct keys:
    for ( var key in to ) {
      if ( isStruct( to[ key ] ) && structKeyExists( from, key ) ) {
        structAppend( to[ key ], from[ key ] );
      }
    }

    // copy the other keys:
    structAppend( to, from );

    return to;
  }

  private array function getRoutes( ) {
    var resources = cacheGet( "resources-#this.name#" );

    if ( isNull( resources ) || request.reset || !variables.cfg.appIsLive ) {
      var listOfResources = "";
      var modelFiles = directoryList( this.mappings[ "/root" ] & "/model", true, "name", "*.cfc", "name asc" );

      for ( var fileName in modelFiles ) {
        listOfResources = listAppend( listOfResources, reverse( listRest( reverse( fileName ), "." ) ) );
      }

      var resources = this.routes;

      resources.addAll( [
        { "^/api/auth/:item" = "/api:auth/:item/" },
        { "^/api/$" = "/api:main/notfound" },
        { "$RESOURCES" = { resources = listOfResources, subsystem = "api" } }
      ] );

      cachePut( "resources-#this.name#", resources );
    }

    return resources;
  }

  private string function getRoot( ) {
    var basePath = getDirectoryFromPath( getBaseTemplatePath( ) );
    var tmp = replace( basePath, "\", "/", "all" );
    return listDeleteAt( tmp, listLen( tmp, "/" ), "/" ) & "/";
  }
}