component accessors=true {
  property config;
  property logService;
  property utilityService;

  public void function send(
    required  string  from,
    required  any     to,
    required  string  subject,
    required  string  body,
              string  type = "html",
              string  bcc
  ) {
    try {
      var toEmail = isSimpleValue( to ) ? to : to.getEmail( );
      var sendTo = config.appIsLive ? toEmail : config.debugEmail;

      if( !utilityService.isValidEmail( from ) ) {
        throw( "Invalid from address", "emailService.send.invalidEmailError", from );
      }

      if( !utilityService.isValidEmail( sendTo ) ) {
        throw( "Invalid to address", "emailService.send.invalidEmailError", sendTo );
      }

      var message = new mail( );

      message.setType( type );
      message.setFrom( from );
      message.setTo( sendTo );
      message.setSubject( subject );
      message.setBody( body );

      if ( !isNull( bcc ) ) {
        message.setBcc( bcc );
      }

      message.send( );

      logService.writeLogLevel( text = "email sent: '#subject#' to #sendTo#.", type = "information", file = request.appName );
    } catch ( any e ) {
      logService.writeLogLevel( text = "Error sending email. (#e.message#)", type = "fatal", file = request.appName );
      rethrow;
    }
  }
}
