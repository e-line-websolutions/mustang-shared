component extends=framework.one {
  this.sessionManagement = true;

  param request.appName="Nameless-Webmanager-Site-#createUuid( )#";
  param request.domainName=cgi.server_name;

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
    routes = [ { "/media/:file" = "/media/load/file/:file" }, { "*" = "/main/default" } ]
  };

  private void function setupRequest( ) {
    frameworkTrace( "<b>webmanager</b>: setupRequest() called." );
    request.reset = isFrameworkReloadRequest( );

    var bf = getBeanFactory( );

    variables.wm = bf.getBean( "webmanagerService" );
    variables.util = bf.getBean( "utilityService" );
    variables.i18n = bf.getBean( "translationService" );

    util.limiter( );
    wm.relocateOnce( request.domainName );

    if ( request.reset ) {
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

  private void function setupApplication( ) {
    frameworkTrace( "<b>webmanager</b>: setupApplication() called." );
    structDelete( application, "cache" );
  }

  private string function onMissingView( rc ) {
    if ( getSection( ) == "main" ) {
      return view( "main/default" );
    }

    return "Missing view for: #rc.action#";
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

  private string function fixPath( string originalPath ) {
    return listChangeDelims( originalPath, '/', '\/' );
  }

  private string function getRoot( ) {
    var basePath = getDirectoryFromPath( getBaseTemplatePath( ) );
    var tmp = replace( basePath, "\", "/", "all" );
    return listDeleteAt( tmp, listLen( tmp, "/" ), "/" ) & "/";
  }
}