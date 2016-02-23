component accessors=true {
  property framework;
  property contactService;
  property securityService;

  public void function before( required struct rc ) {
    rc.subnav = "profile";
    rc.subsubnav = "password";
  }

  public void function default( required struct rc ) {
    rc.data = contactService.get( rc.auth.userID );
  }

  public void function save( required struct rc ) {
    transaction {
      var currentUser = contactService.get( rc.auth.userID );

      param rc.firstname ="";
      param rc.infix ="";
      param rc.lastname ="";
      param rc.email ="";
      param rc.phone ="";
      param rc.photo ="";

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

      currentUser.save( formFields );


    }

    session.auth.user = contactService.get( rc.auth.userID );

    rc.alert = {
      class = "success",
      text  = "saved-text"
	  };

    framework.redirect( ".default", "alert" );
  }

  public void function newpassword( required struct rc ) {
    param rc.newPassword = rc.util.generatePassword( 8 );

    if( len( trim( rc.newPassword )) lt 8 ) {
      lock scope="session" timeout="5" {
        session.alert = {
          "class" = "danger",
          "text"  = "password-change-fail-tooshort"
        };
      }
      framework.redirect( '.password' );
    }

    lock scope="session" timeout="5" {
      session.alert = {
        "class"           = "danger",
        "text"            = "password-change-failed"
      };
    }

    transaction {
      var currentUser = contactService.get( rc.auth.userID );

      if( isDefined( "currentUser" )) {
        currentUser.save({
          password = securityService.hashPassword( rc.newPassword )
        });
        lock scope="session" timeout="5" {
          session.alert = {
            "class"           = "success",
            "text"            = "password-changed",
            "stringVariables" = { "newPassword" = rc.newPassword }
          };
        }
      }


    }

    framework.redirect( ':' );
  }
}