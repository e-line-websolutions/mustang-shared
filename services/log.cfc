component accessors=true {
  property emailService;
  property contactService;
  property utilityService;
  property dataService;
  property debugService;
  property config;

  this.logLevels = [ "debug", "information", "warning", "error", "fatal" ];

  public string function reportError( message, file = request.appName, sendMail = true ) {
    writeLogLevel( message, file, "error" );

    if ( sendMail && variables.config.appIsLive ) {
      var sendTo = variables.contactService.getByUsername( "admin" );
      if ( !isNull( sendTo ) ) {
        variables.emailService.send( variables.config.debugEmail, sendTo, "Error in #request.appName#", message );
      }
    }

    return message;
  }

  public boolean function writeLogLevel(
    required string text,
    string file = request.appName,
    string level = "debug",
    string type
  ) {
    param variables.config.logLevel = "fatal";

    if ( isNull( type ) ) {
      type = level;
    } else {
      // makes this function compatible with CF's BIF:
      if ( arrayFindNoCase( this.logLevels, type ) ) {
        level = type;
      }
    }

    var requestedLevel = arrayFindNoCase( this.logLevels, level );

    if ( !requestedLevel ) {
      return false;
    }

    var levelThreshold = arrayFindNoCase( this.logLevels, variables.config.logLevel );

    if ( requestedLevel >= levelThreshold ) {
      writeLog( text = text, type = mapLevelToCfType( level ), file = file );
      systemOutput( text, true, requestedLevel > 3 );
      return true;
    }

    return false;
  }

  public void function dumpToFile( any data, boolean force = false, boolean saveStacktrace = false, string level = "error", string title = "" ) {
    param arguments.title = "";

    param variables.config.showDebug=false;

    if ( !variables.config.showDebug && !force ) {
      return;
    }

    try {
      var asStruct = { dump = duplicate( data ) };

      if ( saveStacktrace ) {
        asStruct.stackTrace = variables.debugService.getStackTrace( );
      }

      if ( !variables.utilityService.amInCFThread( ) ) {
        var threadData = { data = asStruct, args = arguments };
        thread name="debugWritingThread_#createUUID( )#" threadData = threadData {
          writeToFile( data = threadData.data, fileNamePrefix = threadData.args.level, title = threadData.args.title );
        }
        return;
      }

      writeToFile( data = asStruct, fileNamePrefix = level, title = title );
    } catch ( any e ) {
      writeLogLevel( "Error writing data to file", "logService", "error" );
      try {
        writeToFile( data = duplicate( e ), title = title );
      } catch ( any e ) {
        writeLogLevel( e.message, "logService", "fatal" );
      }
    }
  }

  public void function writeToRollbar(
    required exception
  ){
    if( config.keyExists( 'rollbar' ) ) {
      runAsync( function() {
        try {
          request.rollbarUserInfo = !isNull( request.context.auth.user ) && isStruct( request.context.auth.user ) && structKeyExists( request.context.auth.user, 'id') ?  {
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
    }
  }

  private void function writeToFile( any data, string fileNamePrefix = "error", string title = "" ) {
    param variables.config.paths.errors="C:/TEMP";

    variables.utilityService.setCFSetting( "requestTimeout", 600 );

    var debug = "";

    savecontent variable="debug" {
      writeDump( data );
    }

    if ( len( title ) ) {
      debug = '<h1>' & title & '</h1>' & debug;
    }

    var fileName = "#fileNamePrefix#-#dateTimeFormat(now(), 'yyyymmdd-HHnnss')#-#createUUID( )#.html";

    fileWrite( "#variables.config.paths.errors#/#fileName#", debug );
    fileSetAccessMode( "#variables.config.paths.errors#/#fileName#", 755 );
  }

  private string function mapLevelToCfType( level ) {
    var logTypes = [ "information", "warning", "warning", "error", "fatal" ];
    var levelIndex = arrayFindNoCase( this.logLevels, level );

    return logTypes[ levelIndex ];
  }
}
