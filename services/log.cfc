component accessors=true {
  property emailService;
  property contactService;
  property utilityService;
  property config;

  this.logLevels = [ "debug", "information", "warning", "error", "fatal" ];

  public component function init( config, emailService, contactService, utilityService ) {
    structAppend( variables, arguments );
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

  public boolean function writeLogLevel( required string text, string file = request.appName, string level = "debug", string type = "" ) {
    param variables.config.logLevel="fatal";

    // makes this function compatible with CF's BIF:
    if ( arrayFindNoCase( this.logLevels, type ) ) {
      level = type;
    }

    var requestedLevel = arrayFindNoCase( this.logLevels, level );

    if ( !requestedLevel ) {
      return false;
    }

    var levelThreshold = arrayFindNoCase( this.logLevels, variables.config.logLevel );

    if ( requestedLevel >= levelThreshold ) {
      writeLog( text = text, type = level, file = file );
      return true;
    }

    return false;
  }

  public void function dumpToFile( any data, boolean force = false ) {
    if ( !variables.config.showDebug && !force ) {
      return;
    }

    if ( !utilityService.amInCFThread( ) ) {
      thread name="debugWritingThread_#createUUID( )#" data = data {
        writeToFile( data );
      }
      return;
    }

    try {
      writeToFile( data );
    } catch ( any e ) {
      writeLogLevel( "Error writing data to file", "logService", "error" );
      try {
        writeToFile( e );
      } catch ( any e ) {
        writeLogLevel( e.message, "logService", "fatal" );
      }
    }
  }

  private void function writeToFile( any data ) {
    param variables.config.paths.errors="C:/TEMP";

    variables.utilityService.setCFSetting( "requestTimeout", 600 );

    savecontent variable="local.debug" {
      writeDump( data );
    }

    fileWrite( "#variables.config.paths.errors#/error-#createUUID( )#.html", debug );
  }
}