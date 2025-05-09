component {
  public component function init( fw1Config ) {
    variables.basePath = fixPath( mid(getBaseTemplatePath(), 1, getBaseTemplatePath().findNoCase('index.cfm')-1) );
    variables.root = getRoot();
    variables.name = hash( variables.basePath & cgi.server_name );
    variables.framework = fw1Config;

    return this;
  }

  public struct function readConfig( string site = cgi.server_name, string configRoot = variables.root ) {
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

    var result = { 'webroot' = getDefaultWebroot(), 'paths' = {} };
    var mustangSharedRoot = getMustangRoot();

    systemOutput( 'reading file: #mustangSharedRoot#/config/global.json' );
    
    var globalConfig = deserializeJSON( fileRead( mustangSharedRoot & '/config/global.json', 'utf-8' ) );
    mergeStructs( globalConfig, result );
    if ( fileExists( configRoot & '/config/default.json' ) ) {
      systemOutput( 'reading file: #configRoot#/config/default.json' );
      
      var defaultConfig = deserializeJSON( fileRead( configRoot & '/config/default.json', 'utf-8' ) );
      mergeStructs( defaultConfig, result );
    }

    site = site.replaceNoCase( 'www.', '' );

    if ( fileExists( configRoot & '/config/' & site & '.json' ) ) {
      systemOutput( 'reading file: #configRoot#/config/#site#.json' );
      
      var siteConfig = deserializeJSON( fileRead( configRoot & '/config/' & site & '.json', 'utf-8' ) );

      if ( siteConfig.keyExists( 'include' ) ) {
        systemOutput( 'reading file: #configRoot#/config/#siteConfig.include#' );
        
        var includeConfig = deserializeJSON( fileRead( configRoot & '/config/#siteConfig.include#', 'utf-8' ) );
        mergeStructs( includeConfig, result );
      }

      mergeStructs( siteConfig, result );
    }

    var domain = site.listLast('.');
    if( site.listLen('.') gt 1 ){
      domain = site.listGetAt( site.listLen('.') - 1, '.' ) & '.' & domain;
    }

    if ( fileExists( configRoot & '/config/' & domain & '.json' ) ) {
      systemOutput( 'reading file: #configRoot#/config/#domain#.json' );
      
      var domainConfig = deserializeJSON( fileRead( configRoot & '/config/' & domain & '.json', 'utf-8' ) );

      if ( domainConfig.keyExists( 'include' ) ) {
        systemOutput( 'reading file: #configRoot#/config/#domainConfig.include#' );
        
        var includeDomainConfig = deserializeJSON( fileRead( configRoot & '/config/#domainConfig.include#', 'utf-8' ) );
        mergeStructs( includeDomainConfig, result );
      }

      mergeStructs( domainConfig, result );
    }

    var machineName = getMachineName();

    if ( fileExists( configRoot & '/config/#machineName.lCase()#.json' ) ) {
      systemOutput( 'reading file: #configRoot#/config/#machineName#.json' );
      
      var machineConfig = deserializeJSON( fileRead( configRoot & '/config/#machineName#.json', 'utf-8' ) );
      mergeStructs( machineConfig, result );
    }

    var useCommandbox = false;

    if ( fileExists( configRoot & '/config/commandbox.json' ) ) {
      if ( server.keyExists( 'system' ) ) {
        param server.system.properties={};
        if ( server.system.properties.keyExists( 'sun.java.command' ) &&
             server.system.properties[ 'sun.java.command' ] contains '.CommandBox' ) {
          useCommandbox = true;
        }
      }

      if ( !useCommandbox ) {
        try {
          createObject("java", "runwar.options.ServerOptions");
          useCommandbox = true;
        } catch ( any e ) {}
      }

      if ( useCommandbox ) {
        systemOutput( 'reading file: #configRoot#/config/commandbox.json' );
        
        var commandboxConfig = deserializeJSON( fileRead( configRoot & '/config/commandbox.json', 'utf-8' ) );
        mergeStructs( commandboxConfig, result );
      }
    }

    if ( fileExists( configRoot & '/config/docker.json' ) && server.system.environment?.IN_DOCKER == 'true' ) {
      systemOutput( 'reading file: #configRoot#/config/docker.json' );
      
      var dockerConfig = deserializeJSON( fileRead( configRoot & '/config/docker.json', 'utf-8' ) );
      mergeStructs( dockerConfig, result );
    }

    // expand relative paths:
    result.paths = result.paths.map(function( key, path ) {
      return ( left( path, 2 ) == './' || left( path, 3 ) == '../' ? expandPath( path ) : path );
    });

    lock name="lock_mustang_#variables.name#_config_write" timeout="3" type="exclusive" {
      cachePut( 'config_#variables.name#', result );
    }

    return result;
  }

  public void function mergeStructs( required struct from, struct to = { } ) {
    from.each(function(key, value){
      if ( isStruct( value ) && to.keyExists( key ) && isStruct( to[ key ] ) ) {
        mergeStructs( value, to[ key ] );
      } else {
        to[ key ] = value;
      }
    });
  }

  public void function addToConstants( required struct websiteSpecificConstants ) {
    mergeStructs( websiteSpecificConstants, variables.framework.diConfig.constants );
  }

  public string function getRoot( string basePath = variables.basePath ) {
    var tmp = fixPath( basePath );
    return tmp.listDeleteAt( tmp.listLen( "/" ), "/" ) & "/";
  }

  public string function getMustangRoot( ) {
    return getDirectoryFromPath( getCurrentTemplatePath( ) );
  }

  public void function cleanXHTMLQueryString( ) {
    for ( var kv in url ) {
      if ( kv contains ";" ) {
        url[ kv.listRest( ";" ) ] = url[ kv ];
        url.delete( kv );
      }
    };
  }

  public string function fixPath( string originalPath ) {
    var output = originalPath.listChangeDelims( '/', '\/' );

    if ( !server.os.name contains "Windows" && originalPath.left( 1 ) == "/" ) {
      output = "/" & output;
    }

    return output;
  }

  public string function getDbCreate( required struct config ) {
    if ( !url.keyExists( "reload" ) || !url.keyExists( "nuke" ) ) {
      return "none";
    }

    if ( compare( url.reload, config.reloadpw ) != 0 ) {
      return "none";
    }

    return "update";
  }

  public void function loadListener( bf ) {
    // ACF / Lucee compatibility services:
    if ( !server.keyExists( "lucee" ) ) {
      bf.declareBean( "threadfix", "mustang.compatibility.acf.threadfix" );
    }
  }

  public void function handleExceptions( required struct config, any exception, string event ) {
    try {
      exception = duplicate( exception );

      if ( exception.keyExists( "Cause" ) ) {
        exception = duplicate( exception.cause );
      }

      param exception.message="Uncaught Error";
      param exception.errorCode=500;
      param exception.detail="";

      if ( !isNumeric( exception.errorCode ) || val( exception.errorCode ) == 0 ) {
        exception.message &= ' (code: #exception.errorCode#)';
        exception.errorCode = 500;
      }

      var pc = getPageContext( );

      if ( server.keyExists( "lucee" ) ) {
        try {
          cfcontent( reset = true );
          cfheader( statusCode = exception.errorCode, statusText = exception.type & 'Error' );
        } catch ( any e ) {
          writeDump(exception);
          writeDump(e);abort;
        }
      } else {
        pc.getCfoutput( ).clearAll( );
        pc.getResponse( )
          .getResponse( )
          .setStatus( exception.errorCode, exception.message );
      }

      var showDebugError = config.debugIP.listFind( cgi.remote_addr ) || config.showDebug || (server.system.environment?.IN_DOCKER == 'true');
      var inApi = cgi.path_info contains "/api/" || cgi.path_info contains "/adminapi/";

      if ( inApi || showDebugError ) {
        if ( inApi ) {
          if ( server.keyExists( "lucee" ) ) {
            try {
              cfcontent( type = "application/json" );
            } catch ( any e ) {}
          } else {
            pc.getResponse( )
              .setContentType( "application/json" );
          }

          writeOutput( serializeJSON( {
            'status': 'error',
            'message': exception.message,
            'detail': exception.detail,
            'error_description': '#exception.message#, #exception.detail#',
            'stackTrace': exception.stackTrace
          } ) );
        } else {
          writeOutput( '<h1>#exception?.message#</h1>' );
          writeOutput( '<h3>#exception?.detail#</h3>' );
          writeOutput( '#exception.stackTrace.reReplace( '\sat\s', '<br> at ', 'all' )#' );
          writeOutput( '<hr />' );
        }
        abort;
      }

      if ( !showDebugError && config.keyExists( 'rollbar' ) ) {
        runAsync( function() {
          try {
            request.rollbarUserInfo = userExistsInRequestScope() ? {
                'id' = request.context.auth.user.id
              , 'username' = request.context.auth.user.username
              , 'email' = request.context.auth.user.email
              , 'extra' = 'test'
            } : {};
            config.rollbar.environment = cgi.SERVER_NAME;
            var rollbar = new mustang.lib.rollbar.Rollbar( config.rollbar );
            rollbar.reportMessage( exception.message, "critical", exception, request.rollbarUserInfo );
          } catch ( any e ) {
            writeLog( 'Failed to send error to Rollbar: #e.message# (#e.detail#).', 'fatal' );
          }
        } );
      } else {
        var errorDump = "";
        savecontent variable="errorDump" {
          writeOutput( "Error: " & exception.message );
          writeOutput( "<br />Detail: " & exception.detail );
          writeOutput( "<br />Stacktrace: <pre>" & exception.stackTrace & "</pre>" );
          writeDump( cgi );
        }

        param config.paths.errors = expandPath( '../../ProjectsTemporaryFiles/errors' );

        fileWrite( config.paths.errors & "/uncaught-error-#createUUID()#.html", errorDump, "utf-8" );
      }

      var webroots = [ 'webroot', 'www' ];

      param request.fallbackErrorFile = 'error.html';

      for ( webroot in webroots ) {
        if ( fileExists( variables.root & "/#webroot#/error-#exception.errorCode#.html" ) ) {
          include "/#config.root#/#webroot#/error-#exception.errorCode#.html";
          writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
          abort;
        } else if ( fileExists( variables.root & "/#webroot#/#request.fallbackErrorFile#" ) ) {
          include "/#config.root#/#webroot#/#request.fallbackErrorFile#";
          writeOutput( '<!-- Message: #exception.message# | Detail: #exception.detail# -->' );
          abort;
        }
      }
    } catch ( any e ) {
      writeDump( exception );
      writeDump( e );
      abort;
    }
  }


  private boolean function userExistsInRequestScope(){
    if( isNull( request.context.auth.user )) return false;
    if( isNull( request.context.auth.user.id )) return false;
    if( isNull( request.context.auth.user.username )) return false;
    if( isNull( request.context.auth.user.email )) return false;

    return true;
  }

  public void function clearCache() {
    // clear query cache:
    createObject( 'java', 'coldfusion.server.ServiceFactory' ).getDataSourceService().purgeQueryCache();

    // clear ehcache:
    var allCacheIds = cacheGetAllIds();
    if ( !allCacheIds.isEmpty() ) {
      cacheRemove( allCacheIds.toList() );
    }
  }

  public void function addToJavapaths( javaSettings, absolutePath ) {
    param javaSettings.loadPaths = [];

    var existingFileNames = javaSettings.loadPaths.map( function( path ) {
      return getFileFromPath( path );
    } );

    if ( fileExists( absolutePath ) ) {
      javaSettings.loadPaths.add( absolutePath );
    } else if ( directoryExists( absolutePath ) ) {
      javaSettings.loadPaths.addAll(
        directoryList( absolutePath, true, 'path', '*.jar' ).filter( function( path ) {
          return !existingFileNames.find( getFileFromPath( path ) );
        } )
      );
    }
  }

  private string function getDefaultWebroot() {
    var httpRequestData = getHttpRequestData();
    var httpsIsOn = cgi.https == 'on' || (httpRequestData.headers.keyExists('X-Forwarded-Proto') && httpRequestData.headers['X-Forwarded-Proto'] == 'https')
    return ( httpsIsOn ? 'https' : 'http' ) & '://' & cgi.http_host;
  }

  public string function getMachineName() {
    if ( server.keyExists( 'lucee' ) ) return cgi.local_host;
    return createObject( 'java', 'java.net.InetAddress' ).getLocalHost().getHostName();
  }

  public struct function listAllOrmEntities( cfcLocation ) {
    var cacheKey = 'orm-entities-#getApplicationMetadata().name#';
    var allOrmEntities = cacheGet( cacheKey );

    if ( !isNull( allOrmEntities ) ) return allOrmEntities;

    if ( server.keyExists( 'lucee' ) ) {
      /* LUCEE */
      var allOrmEntities = entityNameArray().reduce( ( r, entityName ) => {
        var entity = entityNew( entityName );
        r[ entityName ] = {
          name: entityName,
          table: entity.table?:entityName,
          isOption: isInstanceOf( entity, 'option' )
        };
        return r;
      }, {} );
    } else {
      /* COLDFUSION */
      var allOrmEntities = {};
      var allEntities = ormGetSessionFactory().getStatistics().getEntityNames();

      for ( var entityName in allEntities ) {
        var entity = entityNew( entityName );
        var md = getMetadata( entity );
        allOrmEntities[ entityName ] = {
          'name' = entityName,
          'table' = isNull( md.table ) ? entityName : md.table,
          'isOption' = isInstanceOf( entity, 'option' )
        };
      }
    }

    cachePut( cacheKey, allOrmEntities );

    return allOrmEntities;
  }

  public boolean function canDebug( cfg ) {
    if ( !cfg.showDebug ) return false;

    if ( cgi.remote_addr.listFirst( '.' ) == 127 ) return true;

    if ( cfg.debugIP.listFind( cgi.remote_addr ) ) return true;

    return false;
  }
}
