component accessors=true {
  property config;

  public void function send(
    required  string  from,
    required  any     to,
    required  string  subject,
    required  string  body,
              string  type = "html"
  ) {
    try {
      var toEmail = isSimpleValue( to ) ? to : to.getEmail( );
      var sendTo = config.appIsLive ? toEmail : config.debugEmail;
      var message = new mail( );

      message.setType( type );
      message.setFrom( from );
      message.setTo( sendTo );
      message.setSubject( subject );
      message.setBody( body );
      message.send( );

      writeLog( text = "email sent: '#subject#' to #sendTo#.", type = "information", file = request.appName );
    } catch ( any e ) {
      writeLog( text = "error sending email.", type = "fatal", file = request.appName );
      rethrow;
    }
  }
}