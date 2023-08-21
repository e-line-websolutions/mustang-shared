component extends="framework.one" {
  if ( !structKeyExists( variables, 'framework' ) ) {
    variables.framework = {};
  }
  variables.mstng = createObject( 'base' ).init( variables.framework );
  variables.cfg = variables.mstng.readConfig();
  variables.root = variables.mstng.getRoot();

  param request.domainName=cgi.server_name;
  param request.appName="Nameless-Mustang-App-#createUUID()#";
  param request.version="?";
  param request.context.startTime=getTickCount();
  param request.context.config=variables.cfg;
  param request.webroot=variables.cfg.webroot;
  param request.appSimpleName=request.appName.listFirst( " ,-_" );
  param request.context.debug=mstng.canDebug( variables.cfg );

  param this.javaSettings={};

  param variables.framework.subsystemDelimiter=':';

  variables.framework.reloadApplicationOnEveryRequest = !variables.cfg.appIsLive;

  variables.mstng.cleanXHTMLQueryString();
  variables.live = variables.cfg.appIsLive;
  variables.routes = [];
  variables.mstng.mergeStructs(
    {
      'routesCaseSensitive' = false,
      'generateSES' = true,
      'SESOmitIndex' = true,
      'base' = '/#variables.cfg.root#',
      'baseURL' = variables.cfg.webroot,
      'error' = 'app.error',
      'unhandledPaths' = '/inc,/tests,/browser,/cfimage,/diagram,/orm',
      'diLocations' = [
        '/mustang/services',
        '/#variables.cfg.root#/services',
        '/#variables.cfg.root#/model/services',
        '/#variables.cfg.root#/subsystems/api/services'
      ],
      'diConfig' = { 'constants' = { 'root' = variables.root, 'config' = variables.cfg }, 'loadListener' = variables.mstng.loadListener },
      'environments' = {
        'live' = {
          'cacheFileExists' = true,
          'password' = variables.cfg.reloadpw,
          'trace' = variables.cfg.showDebug
        },
        'dev' = { 'trace' = variables.cfg.showDebug }
      },
      'subsystems' = { 'api' = { 'error' = 'api#variables.framework.subsystemDelimiter#main.error' } }
    },
    variables.framework
  );

  this.mappings[ '/#variables.cfg.root#' ] = request.root = variables.root;
  this.sessionManagement = true;
  this.sessionTimeout = createTimespan( 0, 2, 0, 0 );

  if ( len( variables.cfg.datasource ) ) {
    this.datasource = variables.cfg.datasource;

    orm_cfcLocation = directoryExists( variables.root & 'orm' )
      ? variables.root & 'orm'
      : variables.root & 'model';

    if ( variables.cfg.useOrm ) {
      this.ormEnabled = true;
      this.ormSettings = {
        'cfcLocation' = orm_cfcLocation,
        'dbCreate' = variables.mstng.getDbCreate( variables.cfg ),
        'secondaryCacheEnabled' = variables.live ? true : false,
        'cacheProvider' = 'ehcache',
        'cacheConfig' = 'ehcache-config_ORM_#request.appSimpleName#.xml'
      };
    }
  }

  if ( structKeyExists( variables.cfg.paths, 'basecfc' ) ) {
    this.mappings[ '/basecfc' ] = variables.cfg.paths.basecfc;
  }

  if ( structKeyExists( variables.cfg.paths, 'mustang' ) ) {
    this.mappings[ '/mustang' ] = variables.cfg.paths.mustang;
  }

  if ( !structKeyExists( variables.cfg.paths, variables.cfg.root ) ) {
    variables.cfg.paths[ variables.cfg.root ] = variables.root;
  }

  if ( !isNull( variables.cfg.paths.fileUploads ) && len( variables.cfg.paths.fileUploads ) ) {
    request.fileUploads = variables.cfg.paths.fileUploads;
  }

  variables.mustangRoot = variables.mstng.getMustangRoot();
  variables.mstng.addToJavapaths( this.javaSettings, variables.mustangRoot & '/lib' );

  // fw1 flow control

  public void function setupApplication() {
    frameworkTrace( '<b>mustang</b>: setupApplication() called.' );

    var bf = getBeanFactory();
    var logService = bf.getBean( 'logService' );

    if ( structKeyExists( url, 'nuke' ) ) {
      // empty caches:
      var t = getTickCount();
      structDelete( application, 'cache' );
      structDelete( application, 'threads' );
      cacheRemove( arrayToList( cacheGetAllIds() ) );

      logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): Caches purged', request.appName );

      // rebuild ORM:
      if ( variables.cfg.useOrm ) {
        var t = getTickCount();

        try {
          ormEvictQueries();
        } catch ( any e ) {}

        logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): ORM Caches purged', request.appName );

        var t = getTickCount();

        var modelPath = this.ormSettings.CFCLocation;

        if ( left( modelPath, 1 ) == '/' ) {
          modelPath = expandPath( modelPath );
        }

        var hbmxmlFiles = directoryList( modelPath, true, 'path', '*.hbmxml|*.cfc.hbm.xml' );

        for ( var filepath in hbmxmlFiles ) {
          fileDelete( filepath );
        }

        logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): HBMXML files deleted', request.appName );

        var t = getTickCount();

        ormReload();

        if ( structKeyExists( url, 'nuke' ) &&
             structKeyExists( variables.cfg, 'nukescript' ) &&
             fileExists( expandPath( variables.cfg.nukescript ) ) &&
             (
               structKeyExists( this.ormSettings, 'dbCreate' ) &&
               this.ormSettings.dbCreate == 'dropcreate'
             ) ) {
          transaction {
            try {
              queryExecute( fileRead( expandPath( variables.cfg.nukescript ), 'utf-8' ) );
              transactionCommit();
            } catch ( any e ) {
              transactionRollback();
              rethrow;
            }
          }
        }

        logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): ORM reloaded', request.appName );

        var hbmxmlFiles = directoryList( modelPath, true, 'path', '*.hbmxml|*.cfc.hbm.xml' );

        if ( !arrayIsEmpty( hbmxmlFiles ) ) {
          var t = getTickCount();

          if ( !directoryExists( variables.root & 'documentation' ) ) {
            directoryCreate( variables.root & 'documentation' );
          }

          if ( !directoryExists( variables.root & 'documentation/hbmxml' ) ) {
            directoryCreate( variables.root & 'documentation/hbmxml' );
          }

          logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): moving HBMXML files to documentation location (if present)', request.appName );

          var t = getTickCount();

          for ( var filepath in hbmxmlFiles ) {
            var fileName = getFileFromPath( filepath ).listFirst('.');
            var destination = variables.root & 'documentation/hbmxml/' & fileName & '.hbmxml';
            fileMove( filepath, destination );
          }

          logService.writeLogLevel( 'NUKE (#getTickCount()-t#ms): HBMXML files moved.', request.appName );
        }
      }
    }

    logService.writeLogLevel( 'Application initialized', request.appName, 'information' );
  }

  public void function setupSession() {
    frameworkTrace( '<b>mustang</b>: setupSession() called.' );
    if ( variables.cfg.sessionManagement )
    structDelete( session, 'progress' );
    session.connectionStorage = {};
  }

  public void function setupSubsystem( string subsystem = '' ) {
    frameworkTrace( '<b>mustang</b>: setupSubsystem() called.' );

    if ( structKeyExists( variables.framework.subsystems, subsystem ) ) {
      var subsystemConfig = getSubsystemConfig( subsystem );
      variables.mstng.mergeStructs( subsystemConfig, variables.framework );
      structDelete( variables.framework.subsystems, subsystem );
    }
  }

  public void function setupRequest() {
    frameworkTrace( '<b>mustang</b>: setupRequest() called.' );

    if ( structKeyExists( url, 'clear' ) ) {
      variables.mstng.clearCache();
      frameworkTrace( '<b>mustang</b>: cache reset' );
    }

    request.reset = isFrameworkReloadRequest();

    if ( request.reset ) {
      setupSession();
    }

    if ( variables.cfg.useOrm ) {
      request.allOrmEntities = variables.mstng.listAllOrmEntities( this.ormSettings.cfcLocation );
    }

    var bf = getBeanFactory();
    var i18n = bf.getBean( 'translationService' );
    var sec = bf.getBean( 'securityService' );
    var util = bf.getBean( 'utilityService' );

    setLocale( i18n.getCurrentLanguage() );

    request.context.i18n = variables.i18n = i18n;
    request.context.sec = variables.sec = sec;
    request.context.util = variables.util = util;

    util.setCFSetting( 'showdebugoutput', request.context.debug );
    util.limiter();
    // security:
    controller( '#framework.subsystemDelimiter#security.authorize' );

    // internationalization:
    controller( '#framework.subsystemDelimiter#i18n.load' );

    // content:
    if ( getSubsystem() == getDefaultSubsystem() ||
         listFindNoCase( variables.cfg.contentSubsystems, getSubsystem() ) ) {
      controller( '#framework.subsystemDelimiter#admin-ui.load' );
    }

    // try to queue up crud (admin) actions:
    if ( getSubsystem() == getDefaultSubsystem() && !util.fileExistsUsingCache( variables.root & '/controllers/#getSection()#.cfc' ) ) {
      controller( '#framework.subsystemDelimiter#crud.#getItem()#' );
    }

    // try to queue up api actions:
    if ( getSubsystem() == 'api' && !util.fileExistsUsingCache( variables.root & '/subsystems/api/controllers/#getSection()#.cfc' ) ) {
      controller( 'api#framework.subsystemDelimiter#main.#getItem()#' );
    }
  }


  // fw1 helper functions

  public array function getRoutes() {
    var resources = cacheGet( 'resources_#this.name#' );

    if ( isNull( resources ) || !variables.cfg.appIsLive ) {
      var listOfResources = '';
      var modelFiles = directoryList( this.mappings[ '/#request.context.config.root#' ] & '/model', true, 'name', '*.cfc', 'name asc' );

      for ( var fileName in modelFiles ) {
        listOfResources = listAppend( listOfResources, reverse( listRest( reverse( fileName ), '.' ) ) );
      }

      var resources = variables.routes;

      resources.addAll( [
        { '^/api/auth/:item' = '/api#framework.subsystemDelimiter#auth/:item/' },
        { '^/api/$' = '/api#framework.subsystemDelimiter#main/notfound' },
        { '$RESOURCES' = { resources = listOfResources, subsystem = 'api' } }
      ] );

      cachePut( 'resources_#this.name#', resources );
    }

    return resources;
  }

  public string function getEnvironment() {
    return variables.live ? 'live' : 'dev';
  }


  // cf flow control

  public void function onError( any exception, string event ) {
    var args = arguments;
    args.config = variables.cfg;
    variables.mstng.handleExceptions( argumentCollection = args );
  }

  public string function onMissingView( struct rc ) {
    var cfmlFileInsideDefaultSubsystem = root & '/views/' & getSection() & '/' & getItem() & '.cfm';
    var cfmlFileInsideSubsystem = root & '/subsystems/' & getSubsystem() & '/views/' & getSection() & '/' & getItem() & '.cfm';

    cfmlFileInsideDefaultSubsystem = reReplace( cfmlFileInsideDefaultSubsystem, '/+', '/', 'all' );
    cfmlFileInsideSubsystem = reReplace( cfmlFileInsideSubsystem, '/+', '/', 'all' );

    if ( util.fileExistsUsingCache( cfmlFileInsideDefaultSubsystem ) ) {
      return view( framework.subsystemDelimiter & getSection() & '/' & getItem() );
    }

    if ( util.fileExistsUsingCache( cfmlFileInsideSubsystem ) ) {
      return view( getSubsystem() & framework.subsystemDelimiter & getSection() & '/' & getItem() );
    }

    if ( structKeyExists( rc, 'fallbackView' ) ) {
      return view( rc.fallbackView );
    }

    return view( framework.subsystemDelimiter & 'app/notfound' );
  }
}