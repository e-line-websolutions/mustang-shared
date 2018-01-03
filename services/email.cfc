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
              string  bcc,
              struct  attachement
  ) {
    try {
      var toEmail = isSimpleValue( to ) ? to : to.getEmail( );
      var sendTo = variables.config.appIsLive ? toEmail : variables.config.debugEmail;

      var emailsFrom = listToArray( from );
      for( emailFrom in emailsFrom ){
        if( !variables.utilityService.isValidEmail( emailFrom ) ) {
          throw( "Invalid to address", "emailService.send.invalidEmailError", emailFrom );
        }
      }

      var emailsTo = listToArray( sendTo );
      for( emailTo in emailsTo ){
        if( !variables.utilityService.isValidEmail( emailTo ) ) {
          throw( "Invalid to address", "emailService.send.invalidEmailError", emailTo );
        }
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

      if ( !isNull( attachement ) && structKeyExists( attachement, 'file' ) && structKeyExists( attachement, 'type' ) && structKeyExists( attachement, 'remove' ) ) {
        message.addParam( file  = attachement.file, type = attachement.type, remove = attachement.remove );
      }

      message.send( );

      variables.logService.writeLogLevel( "email sent: '#subject#' to #sendTo#." );
    } catch ( any e ) {
      variables.logService.writeLogLevel( text = "Error sending email. (#e.message#)", type = "fatal" );
      rethrow;
    }
  }
}
