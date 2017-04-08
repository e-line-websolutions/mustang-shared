component accessors=true {
  property emailService;
  property contactService;
  property config;

  this.logLevels = [ "information", "warning", "error", "fatal" ];

  public string function reportError( message, file = request.appName, sendMail = true ) {
    writeLogLevel( message, file, "error" );

    if ( sendMail ) {
      var sendTo = contactService.getByUsername( "admin" );
      if ( !isNull( sendTo ) ) {
        emailService.send( config.debugEmail, sendTo, "Error in #request.appName#", message );
      }
    }

    return message;
  }

  public void function writeLogLevel( required string text, string file = request.appName, string level = "information", string type = "" ) {
    param config.logLevel="fatal";

    if ( arrayFindNoCase( this.logLevels, type ) ) {
      level = type;
    } // <-- makes this function compatible with CF's BIF

    var requestedLevel = arrayFindNoCase( this.logLevels, level );

    if ( !requestedLevel ) {
      return;
    }

    var levelThreshold = arrayFindNoCase( this.logLevels, config.logLevel );

    if ( requestedLevel >= levelThreshold ) {
      writeLog( text = text, type = level, file = file );
    }
  }

  public void function dumpToFile( any data ) {
    if ( !config.showDebug ) {
      return;
    }

    param config.paths.errors="C:/TEMP/";

    savecontent variable="local.debug" {
      writeDump( data );
    }

    fileWrite( "#config.paths.errors#/error-#createUUID( )#.html", debug );
  }
}