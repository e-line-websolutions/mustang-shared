component extends=framework.one {
  this.sessionManagement = true;

  param request.appName="Nameless-Webmanager-Site-#createUuid()#";
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
      { "*" = "/main/default" }
    ]
  };

  private void function setupRequest( ) {
    request.reset = isFrameworkReloadRequest();

    if ( request.reset ) {
      createObject( "java", "coldfusion.server.ServiceFactory" ).getDataSourceService( ).purgeQueryCache( );

      var allCacheIds = cacheGetAllIds( );
      if ( !arrayIsEmpty( allCacheIds ) ) {
        cacheRemove( arrayToList( allCacheIds ) );
      }
    }

    var bf = getBeanFactory( );

    variables.util = bf.getBean( "utilityService" );
    util.limiter( );

    variables.wm = bf.getBean( "webmanagerService" );
    wm.relocateOnce( request.domainName );

    variables.i18n = bf.getBean( "translationService" );

    if ( getSection( ) == "main" ) {
      request.action = "main.home";

      var language = "";
      var pathInfo = variables.util.fixPathInfo( );
      var pathLength = listLen( pathInfo, "/" );

      if ( pathLength ) {
        var item = reReplace( listFirst( listFirst( pathInfo, "/" ) ), "^[-_]", "", "one" );

        if ( listFindNoCase( variables.wm.getAllLanguages( ), item ) ) {
          language = variables.wm.asLocale( item );
          item = "home";
        }

        request.action
          = rc.action
          = request.context.action
          = "main.#item#";

        controller( "main.setupLevel#pathLength#" );
      }

      variables.i18n.changeLanguage( language );

      setView( request.action );
    }
  }

  private void function setupApplication( ) {
    structDelete( application, "cache" );
  }

  private string function onMissingView( rc ) {
    if ( getSection( ) == "main" ) {
      return view( "main/default" );
    }

    return "Missing view for: #rc.action#";
  }

  private void function mergeStructs( required struct from, struct to = { } ) {
    // also append nested struct keys:
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

    // copy the other keys:
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