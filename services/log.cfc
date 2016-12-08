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
}