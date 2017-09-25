component extends=framework.one {
  variables.framework = { };
  variables.mstng = new base( variables.framework );

  variables.cfg = {
    "mediaRoot" = "D:/Accounts/E/E-Line Websolutions CM/files"
  };

  variables.mstng.mergeStructs( variables.mstng.readConfig( ), variables.cfg );
  variables.cfg.useOrm = false;

  variables.root = variables.mstng.getRoot( );

  param request.domainName=cgi.server_name;
  param request.appName="Nameless-Webmanager-Site-#createUuid( )#";
  param request.version="?";
  param request.context.startTime=getTickCount( );
  param request.context.config=variables.cfg;
  param request.webroot=variables.cfg.webroot;
  param request.appSimpleName=listFirst( request.appName, " ,-_" );
  param request.context.debug=variables.cfg.showDebug && listFind( variables.cfg.debugIP, cgi.remote_addr );

  variables.mstng.cleanXHTMLQueryString( );
  variables.live = variables.cfg.appIsLive;
  variables.routes = [ ];
  variables.mstng.mergeStructs( {
    "routesCaseSensitive" = false,
    "generateSES" = true,
    "SESOmitIndex" = true,
    "base" = "/root",
    "diLocations" = [
      "/mustang/services",
      "/root/model/services"
    ],
    "diConfig" = {
      "constants" = {
        "root" = variables.root,
        "config" = variables.cfg,
        "ds" = "e-line_cm",
        "navigationType" = "per-level"
      }
    },
    "environments" = {
      "live" = {
        "cacheFileExists" = true,
        "password" = variables.cfg.reloadpw,
        "trace" = variables.cfg.showDebug
      },
      "dev" = {
        "trace" = variables.cfg.showDebug
      }
    },
    "routes" = [
      { "/media/:file" = "/media/load/file/:file" },
      { "/forms/:action" = "/forms/:action" },
      { "/api/:action" = "/api/:action" },
      { "*" = "/main/default" }
    ]
  }, variables.framework );

  this.mappings[ "/root" ] = request.root = variables.root;
  this.sessionManagement = true;
  this.sessionTimeout = createTimeSpan( 0, 2, 0, 0 );

  if ( isNull( request.appSimpleName ) ) {
    request.appSimpleName = listFirst( request.appName, " ,-_" );
  }

  public string function getEnvironment( ) {
    return variables.live ? "live" : "dev";
  }

  public void function setupApplication( ) {
    frameworkTrace( "<b>webmanager</b>: setupApplication() called." );
    structDelete( application, "cache" );
  }

  public void function setupRequest( ) {
    frameworkTrace( "<b>webmanager</b>: setupRequest() called." );

    var reset = isFrameworkReloadRequest( );

    if ( reset ) {
      setupSession( );
    }

    var bf = getBeanFactory( );
    var i18n = bf.getBean( "translationService" );
    var util = bf.getBean( "utilityService" );
    var wm = bf.getBean( "webmanagerService" );

    request.reset = reset;
    request.context.util = variables.util = util;
    request.context.i18n = variables.i18n = i18n;

    util.setCFSetting( "showdebugoutput", request.context.debug );
    util.limiter( );

    wm.relocateOnce( request.domainName );

    if ( structKeyExists( url, "clear" ) ) {
      wm.clearCache( );
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
    if ( listFind( variables.cfg.debugIP, cgi.remote_addr ) ) {
      writeDump( arguments );
      abort;
    }

    var pc = getpagecontext( );
    pc.getcfoutput( ).clearall( );
    pc.getresponse( )
      .getresponse( )
      .setstatus( 500, exception.message );

    if ( fileExists( variables.root & "/www/error.html" ) ) {
      include "/root/www/error.html";
      writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
    }
  }

  public string function onMissingView( struct rc ) {
    if ( getSection( ) == "main" ) {
      return view( "main/default" );
    }

    return "Missing view for: #rc.action#";
  }
}