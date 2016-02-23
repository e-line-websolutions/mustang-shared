component {
  public void function send(  required  string              from,
                              required  root.model.contact  to,
                              required  string              subject,
                              required  string              body,
                                        string              type = "html" ) {
    try {
      var sendTo = request.context.debug ? request.context.config.ownerEmail : to.getEmail();

      var message = new mail();
      message.setType( type );

      message.setFrom( from );
      message.setTo( sendTo );
      message.setSubject( subject );
      message.setBody( body );

      message.send();

      writeLog( text = "email sent: '#subject#' to #sendTo#.", type = "information", file = request.appName );
    } catch( any e ) {
      writeLog( text = "error sending email.", type = "fatal", file = request.appName );
      rethrow;
    }
  }
}