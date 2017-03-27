component accessors=true {
  property emailService;
  property contactService;
  property config;

  public string function reportError( message, file = request.appName, sendMail = true ) {
    writeLog( text = message, file = file );

    if ( sendMail ) {
      var sendTo = contactService.getByUsername( "admin" );
      if ( !isNull( sendTo ) ) {
        emailService.send( config.debugEmail, sendTo, "Error in #request.appName#", message );
      }
    }

    return message;
  }

  public void function writeLogLevel( required string text, string file = request.appName, string level = "information" ) {
    param config.logLevel="fatal";

    var logLevels = [ "information", "warning", "error", "fatal" ];
    var requestedLevel = arrayFindNoCase( logLevels, level );

    if ( !requestedLevel ) {
      return;
    }

    var levelThreshold = arrayFindNoCase( logLevels, config.logLevel );

    if ( requestedLevel >= levelThreshold ) {
      writeLog( text = text, type = level, file = file );
    }
  }
}


