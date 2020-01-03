component accessors=true {
  property framework;
  property contactService;
  property securityService;
  property utilityService;

  public void function before( required struct rc ) {
    rc.subnav = "profile";
    rc.subsubnav = "password";
  }

  public void function default( required struct rc ) {
    rc.data = contactService.get( rc.auth.userID );
  }

  public void function save( required struct rc ) {
    var currentUser = contactService.get( rc.auth.userID );

    param rc.firstname="";
    param rc.infix="";
    param rc.lastname="";
    param rc.email="";
    param rc.phone="";
    param rc.photo="";

    formFields = {
      "firstname"     = rc.firstname,
      "infix"         = rc.infix,
      "lastname"      = rc.lastname,
      "email"         = rc.email,
      "phone"         = rc.phone,
      "contactID"     = currentUser.getID()
	  };

		if( len( trim( rc.photo ))) {
      formFields["photo"] = rc.photo;
		}

    transaction {
      currentUser.save( formFields );
    }

    securityService.refreshSession( currentUser );

    rc.alert = {
      class = "success",
      text  = "saved-text"
	  };

    framework.redirect( ".default", "alert" );
  }

  public void function newpassword( required struct rc ) {
    param rc.newPassword = utilityService.generatePassword( 8 );
    param rc.returnToSection = "profile";
    param rc.returnTo = ":#rc.returnToSection#";

    if ( len( trim( rc.newPassword ) ) lt 8 ) {
      rc.alert = { 'class' = 'danger', 'text' = 'password-change-fail-tooshort' };
      framework.redirect( ':#rc.returnToSection#.password', 'alert' );
      framework.abortController();
    }

    var currentUser = contactService.get( rc.auth.userID );

    if ( !isNull( currentUser ) ) {
      transaction {
        try {
          currentUser.save( { password = securityService.hashPassword( rc.newPassword ) } );
        } catch ( any e ) {
          rc.alert = { 'class' = 'danger', 'text' = 'password-change-failed' };
          logService.writeLogLevel( text = 'Error saving password (userid = #rc.auth.userID#)', level = 'fatal' );
        }
      }
      rc.alert = {
        'class' = 'success',
        'text' = 'password-changed',
        'stringVariables' = { 'newPassword' = rc.newPassword }
      };
    } else {
      rc.alert = { 'class' = 'danger', 'text' = 'user-not-found-error' };
    }

    framework.redirect( rc.returnTo, 'alert' );
  }
}