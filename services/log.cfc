component accessors=true {
  property emailService;
  property contactService;
  property utilityService;
  property dataService;
  property debugService;
  property config;

  this.logLevels = [ "debug", "information", "warning", "error", "fatal" ];

  public component function init( config ) {
    if ( structKeyExists( config, "rollbar" ) && structKeyExists( config.rollbar, "access_token" ) ) {
      variables.rollbar = new mustang.lib.rollbar.Rollbar( config.rollbar );
    }
    return this;
  }

  public string function reportError( message, file = request.appName, sendMail = true ) {
    writeLogLevel( message, file, "error" );

    if ( sendMail ) {
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
      if ( structKeyExists( variables, "rollbar" ) && level != "debug" ) {
        var rollbarData = {
          "api_endpoint" = variables.rollbar.getAPIEndpoint( ),
          "payload" = variables.rollbar.getPreparedMessagePayload( text, level )
        };
        sendGatewayMessage( "Rollbar", rollbarData );
        return true;
      }

      writeLog( text = text, type = mapLevelToCfType( level ), file = file );
      return true;
    }

    return false;
  }

  public void function dumpToFile( any data, boolean force = false, boolean saveStacktrace = false, string level = "error" ) {
    if ( !variables.config.showDebug && !force ) {
      return;
    }

    try {
      var asStruct = { dump = duplicate( data ) };

      if ( saveStacktrace ) {
        asStruct.stackTrace = variables.debugService.getStackTrace( );
      }

      if ( structKeyExists( variables, "rollbar" ) && level != "debug" ) {
        var rollbarData = {
          "api_endpoint" = variables.rollbar.getAPIEndpoint( ),
          "payload" = variables.rollbar.getPreparedMessagePayload( "debug data", level, { meta = data } )
        };
        sendGatewayMessage( "Rollbar", rollbarData );
        return;
      }

      if ( !variables.utilityService.amInCFThread( ) ) {
        var threadData = { data = asStruct, args = arguments };
        thread name="debugWritingThread_#createUUID( )#" threadData = threadData {
          writeToFile( threadData.data, threadData.args.level );
        }
        return;
      }

      writeToFile( asStruct, level );
    } catch ( any e ) {
      writeLogLevel( "Error writing data to file", "logService", "error" );
      try {
        writeToFile( duplicate( e ) );
      } catch ( any e ) {
        writeLogLevel( e.message, "logService", "fatal" );
      }
    }
  }

  private void function writeToFile( any data, fileNamePrefix = "error" ) {
    param variables.config.paths.errors="C:/TEMP";

    variables.utilityService.setCFSetting( "requestTimeout", 600 );

    savecontent variable="local.debug" {
      writeDump( data );
    }

    fileWrite( "#variables.config.paths.errors#/#fileNamePrefix#-#createUUID( )#.html", debug );
  }

  private string function mapLevelToCfType( level ) {
    var logTypes = [ "information", "warning", "warning", "error", "fatal" ];
    var levelIndex = arrayFindNoCase( this.logLevels, level );

    return logTypes[ levelIndex ];
  }
}