component extends=framework.one {
  setupMustang( );

  // public functions:

  public void function setupApplication( ) {
    var bf = getBeanFactory( );
    var logService = bf.getBean( "logService" );

    if ( structKeyExists( url, "nuke" ) ) {
      // empty caches:
      structDelete( application, "threads" );
      try { ORMEvictQueries( ); } catch ( any e ) { }
      cacheRemove( arrayToList( cacheGetAllIds( ) ) );
      logService.writeLogLevel( "NUKE: Caches purged", request.appName );

      // rebuild ORM:
      if ( variables.cfg.useOrm ) {
        var hbmxmlFiles = directoryList( this.ormSettings.CFCLocation, true, "path", "*.hbmxml" );
        for ( var filepath in hbmxmlFiles ) {
          fileDelete( filepath );
        }
        logService.writeLogLevel( "NUKE: HBMXML files deleted", request.appName );

        ORMReload( );
        logService.writeLogLevel( "NUKE: ORM reloaded", request.appName );
      }
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

    request.context.util = util;
    request.context.i18n = i18n;

    util.setCFSetting( "showdebugoutput", request.context.debug );

    // rate limiter:
    util.limiter( );

    // security:
    controller( ":security.authorize" );

    // internationalization:
    controller( ":i18n.load" );

    // content:
    if ( getSubsystem( ) == getDefaultSubsystem( ) || listFindNoCase( variables.cfg.contentSubsystems, getSubsystem( ) ) ) {
      controller( ":admin-ui.load" );
    }

    // try to queue up crud (admin) actions:
    if ( getSubsystem( ) == getDefaultSubsystem( ) && !util.fileExistsUsingCache( variables.root & "/controllers/#getSection( )#.cfc" ) ) {
      controller( ":crud.#getItem( )#" );
    }

    // try to queue up api actions:
    if ( getSubsystem( ) == "api" && !util.fileExistsUsingCache( variables.root & "/subsystems/api/controllers/#getSection( )#.cfc" ) ) {
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
    if ( util.fileExistsUsingCache( variables.root & "/views/" & getSection( ) & "/" & getItem( ) & ".cfm" ) ) {
      return view( getSection( ) & "/" & getItem( ) );
    }

    if ( util.fileExistsUsingCache( variables.root & "/subsystems/" & getSubsystem( ) & "/views/" & getSection( ) & "/" & getItem( ) & ".cfm" ) ) {
      return view( getSubsystem( ) & ":" & getSection( ) & "/" & getItem( ) );
    }

    if ( structKeyExists( request.context, "fallbackView" ) ) {
      return view( request.context.fallbackView );
    }

    return view( ":app/notfound" );
  }

  public string function getEnvironment( ) {
    return variables.live ? "live" : "dev";
  }

  public array function getRoutes( ) {
    var resources = cacheGet( "resources-#this.name#" );

    if ( isNull( resources ) || request.reset || !variables.cfg.appIsLive ) {
      var listOfResources = "";
      var modelFiles = directoryList( this.mappings[ "/#request.context.config.root#" ] & "/model", true, "name", "*.cfc", "name asc" );

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

  // private functions:

  private void function setupMustang( ) {
    request.context.startTime = getTickCount( );

    // Overwrite these in the app's own Application.cfc
    param request.version="?";
    param request.appName="?";

    if ( isNull( request.appSimpleName ) ) {
      request.appSimpleName = listFirst( request.appName, " ,-" );
    }

    // CF application setup:
    this.mappings[ "/root" ] = variables.root = request.root = getRoot();
    this.sessionManagement = true;
    this.sessionTimeout = createTimeSpan( 0, 2, 0, 0 );
    this.routes = [];

    // Private variables:
    variables.cfg = request.context.config = readConfig( );

    param variables.cfg.appIsLive=true;
    param variables.cfg.contentSubsystems="";
    param variables.cfg.datasource="";
    param variables.cfg.debugEmail="beta-errors@e-line.nl";
    param variables.cfg.debugIP="127.0.0.1";
    param variables.cfg.defaultLanguage="en_US";
    param variables.cfg.disableSecurity=false;
    param variables.cfg.dontSecureFQA="";
    param variables.cfg.encryptKey="Xeexnvtvtz7wbxu4v892gHjs9ecwL778C2h8MhM4DumnhDDYnqEycmc2erytpNXR";
    param variables.cfg.log=true;
    param variables.cfg.logNotes=false;
    param variables.cfg.nukeScript="";
    param variables.cfg.ownerEmail="administrator@e-line.nl";
    param variables.cfg.paths={};
    param variables.cfg.reloadpw="1";
    param variables.cfg.root="root";
    param variables.cfg.secureDefaultSubsystem=true;
    param variables.cfg.securedSubsystems="";
    param variables.cfg.showDebug=false;
    param variables.cfg.webroot="";
    param variables.cfg.useOrm=true;

    variables.live = variables.cfg.appIsLive;
    variables.i18n = 0;
    variables.util = 0;

    if ( structKeyExists( variables.cfg.paths, "basecfc" ) ) {
      this.mappings[ "/basecfc" ] = variables.cfg.paths.basecfc;
    }

    cleanXHTMLQueryString( );

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
        CFCLocation = variables.root & "model",
        DBCreate = ( variables.live ? ( request.reset ? "update" : "none" ) : ( request.reset ? "dropcreate" : "update" ) ),
        SQLScript = variables.cfg.nukescript,
        secondaryCacheEnabled = variables.live ? true : false,
        cacheProvider = "ehcache",
        cacheConfig = "ehcache-config_ORM_#request.appSimpleName#.xml"
      };
    }

    // framework settings:
    variables.framework = {
      generateSES = true,
      SESOmitIndex = true,
      base = "/#variables.cfg.root#",
      baseURL = variables.cfg.webroot,
      error = "app.error",
      unhandledPaths = "/inc,/tests,/browser,/cfimage,/diagram",
      diLocations = [
        "/mustang/services",
        "/#variables.cfg.root#/services",
        "/#variables.cfg.root#/model/services",
        "/#variables.cfg.root#/subsystems/api/services"
      ],
      diConfig = {
        constants = {
          root = variables.root,
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

    // ACF / Lucee compatibility services:
    if ( !structKeyExists( server, "lucee" ) ) {
      // bf.declareBean( "threadfix", "mustang.compatibility.acf.threadfix" );
      arrayAppend( variables.framework.diLocations, "/mustang/compatibility/acf" );
    }
  }

  private struct function readConfig( string site = cgi.server_name ) {
    // cached:
    if ( !structKeyExists( url, "reload" ) ) {
      var cachedConfig = cacheGet( "config-#this.name#" );

      // found cached settings, only use it in live apps:
      if ( !isNull( cachedConfig ) &&
          structKeyExists( cachedConfig, "appIsLive" ) &&
          isBoolean( cachedConfig.appIsLive ) &&
          cachedConfig.appIsLive ) {
        return cachedConfig;
      }
    }

    // not cached:
    var defaultSettings = { "webroot" = ( cgi.https == 'on' ? 'https' : 'http' ) & "://" & cgi.server_name };

    if ( fileExists( variables.root & "/config/default.json" ) ) {
      var defaultConfig = deserializeJSON( fileRead( variables.root & "/config/default.json", "utf-8" ) );
      defaultSettings = mergeStructs( defaultConfig, defaultSettings );
    }

    if ( fileExists( variables.root & "/config/" & site & ".json" ) ) {
      var siteConfig = deserializeJSON( fileRead( variables.root & "/config/" & site & ".json", "utf-8" ) );
      defaultSettings = mergeStructs( siteConfig, defaultSettings );
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

  private void function addToConstants( required struct websiteSpecificConstants ) {
    variables.framework.diConfig.constants = mergeStructs( websiteSpecificConstants, variables.framework.diConfig.constants );
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
}