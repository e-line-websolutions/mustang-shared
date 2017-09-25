component {
  public component function init( framework ) {
    variables.basePath = getDirectoryFromPath( getBaseTemplatePath( ) );
    variables.root = getRoot( variables.basePath );
    variables.name = hash( variables.basePath );
    variables.framework = framework;

    return this;
  }

  public struct function readConfig( string site = cgi.server_name ) {
    if ( !structKeyExists( url, "reload" ) ) {
      var cachedConfig = cacheGet( "config_#variables.name#" );

      // found cached settings, only use it in live apps:
      if ( !isNull( cachedConfig ) &&
          structKeyExists( cachedConfig, "appIsLive" ) &&
          isBoolean( cachedConfig.appIsLive ) &&
          cachedConfig.appIsLive ) {
        return cachedConfig;
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

  public string function getRoot( string basePath ) {
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
    return listChangeDelims( originalPath, '/', '\/' );
  }

  public string function getDbCreate( required struct config ) {
    if ( !structKeyExists( url, "reload" ) || !structKeyExists( url, "nuke" ) ) {
      return "none";
    }

    if ( compare( url.reload, config.reloadpw ) != 0 ) {
      return "none";
    }

    if ( config.appIsLive ) {
      return "update";
    } else {
      return "dropcreate";
    }
  }

  public void function loadListener( bf ) {
    // ACF / Lucee compatibility services:
    if ( !structKeyExists( server, "lucee" ) ) {
      bf.declareBean( "threadfix", "mustang.compatibility.acf.threadfix" );
    }
  }
}