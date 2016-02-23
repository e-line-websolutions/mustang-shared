component accessors=true {
  property framework;
  property securityService;
  property contactService;
  property contentService;
  property mailService;
  property optionService;
  property dataService;

  public void function login( required struct rc ) {
    framework.setLayout( "security" );

    param rc.username="";
    param rc.password="";
  }

  public void function doLogin( required struct rc ) {
    param rc.username="";
    param rc.password="";
    param rc.authhash="";
    param rc.dontRedirect=false;

    var updateUserWith = {
      lastLoginDate = now()
    };

    // Check credentials:
    if( structKeyExists( rc, "authhash" ) && len( trim( rc.authhash ))) {
      writeLog( text="trying authhash", type="information", file=request.appName );

      var contactID = decrypt( rc.util.base64urlDecode( rc.authhash ), rc.config.encryptKey );
      var user = contactService.get( contactID );

      if( isNull( user )) {
        rc.alert={
          "class"="danger",
          "text"="user-not-found"
        };
        writeLog( text="authhash failed", type="warning", file=request.appName );
        doLogout( rc );
      }

      rc.dontRedirect=true;
      writeLog( text="authhash success", type="information", file=request.appName );
    } else {
      // CHECK USERNAME:
      var user=contactService.getByUsername( rc.username );

      if( isNull( user )) {
        rc.alert={
          "class"="danger",
          "text"="user-not-found"
        };
        writeLog( text="login failed: wrong username (#rc.username#)", type="warning", file=request.appName );
        doLogout( rc );
      }

      // CHECK PASSWORD:
      var decryptSpeed = getTickCount();
      var passwordIsCorrect = securityService.comparePassword( password=rc.password, storedPW=user.getPassword());
      decryptSpeed=getTickCount() - decryptSpeed;

      if( !passwordIsCorrect ) {
        rc.alert={
          "class"="danger",
          "text"="password-incorrect"
        };
        writeLog( text="user #user.getUsername()# login failed: wrong password ", type="warning", file=request.appName );
        doLogout( rc );
      }

      if( passwordIsCorrect && ( decryptSpeed < 250 || decryptSpeed > 1000 )) {
        // re-encrypt if decryption is too slow, or too fast:
        updateUserWith.password = securityService.hashPassword( rc.password );
      }
    }


    // Set auth struct:
    securityService.refreshSession( user );

    updateUserWith.contactID = user.getID();

    if( rc.config.log ) {
      structAppend( updateUserWith, {
        add_logEntry = {
          relatedEntity = user,
          by = user,
          dd = now(),
          ip = cgi.remote_addr,
          logaction = optionService.getOptionByName( "logaction", "security" ),
          note = "Logged in"
        }
      });
    }

    var originalLogSetting = rc.config.log;
    request.context.config.log = false;

    user.save( updateUserWith );

    request.context.config.log=originalLogSetting;

    writeLog( text="user #user.getUsername()# logged in.", type="information", file=request.appName );

    if( !rc.dontRedirect ) {
      var loginscript = securityService.getAuth().role.loginscript;

      if( structKeyExists( rc , 'returnpage') ) {
      	loginscript = rc.returnpage;
      } else if( isNull( loginscript ) || !len( trim( loginscript ))) {
        loginscript = ":";
      }

      framework.redirect( loginscript );
    } else {
      rc.auth = securityService.getAuth();
    }
  }

  public void function doLogout( required struct rc ) {
    // reset session
    securityService.createSession();

    if( isDefined( "rc.auth.isLoggedIn" ) && isBoolean( rc.auth.isLoggedIn ) && rc.auth.isLoggedIn && !structKeyExists( rc, "alert" )) {
      rc.alert={
        "class"="success",
        "text"="logout-success"
      };
    }

    var logMessage="user logged out.";

    if( rc.config.log && isDefined( "rc.auth.userid" ) && dataService.isGUID( rc.auth.userid )) {
      var user=contactService.get( rc.auth.userid );

      if( !isNull( user )) {
        logMessage=user.getUsername() & " logged out.";
      }

      var updateUserLog = {
        contactID = user.getID(),
        add_logEntry = {
          relatedEntity = user,
          logaction = optionService.getOptionByName( "logaction", "security" ),
          note = logMessage,
          by = user,
          dd = now(),
          ip = cgi.remote_addr
        }
      };

      var originalLogSetting = rc.config.log;
      request.context.config.log = false;

      user.save( updateUserLog );

      request.context.config.log = originalLogSetting;
    }

    writeLog( text=logMessage, type="information", file=request.appName );

    if( framework.getSubsystem() == "api" || listFirst( cgi.PATH_INFO, "/" ) == "api" ) {
      var isLucee = listFindNoCase( "lucee,railo", server.ColdFusion.ProductName );
      var pageContext=getPageContext();
      var response = isLucee ? pageContext.getResponse() : pageContext.getFusionContext().getResponse();

      response.setHeader( "WWW-Authenticate", "Basic realm=""#request.appName#-API""" );

      framework.renderData( "rawjson", '{"status":"error","detail":"Unauthorized"}', 401 );
      framework.abortController();
    }

    framework.redirect( ":security.login", "alert" );
  }

  public void function authorize( required struct rc ) {
    rc.auth = { isLoggedIn = false };

    if( rc.config.disableSecurity ) {
      rc.auth.isLoggedIn = true;
      rc.auth.user = new root.lib.fakeUser();
      rc.auth.role = new root.lib.fakeRole();
      return;
    }

    // Always allow access to security && api:css
    var isDefaultSubsystem = framework.getSubsystem() == framework.getDefaultSubsystem() ? true : false;
    var dontSecureDefaultSubsystem = isDefaultSubsystem && !rc.config.secureDefaultSubsystem ? true : false;
    var dontSecureCurrentSubsystem = len( trim( framework.getSubsystem())) ? listFindNoCase( rc.config.securedSubsystems, framework.getSubsystem()) eq 0 : false;
    var isAPISecurity = framework.getSubsystem() == "api" && framework.getSection() == "auth" ? true : false;

    var dontSecureThisSubsystem = dontSecureDefaultSubsystem || dontSecureCurrentSubsystem ? true : false;
    var isLoginPageOrAction = ( isDefaultSubsystem && framework.getSection() == "security" ) || isAPISecurity ? true : false;
    var isCSS = framework.getSubsystem() == "adminapi" && framework.getSection() == "css" ? true : false;

    if( dontSecureThisSubsystem || isLoginPageOrAction || isCSS ) {
      return;
    }

    // Use auth struct that's stored in session
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
      if( structKeyExists( session, "auth" )) {
        structAppend( rc.auth, session.auth );
      }
    }

    // check validity of auth struct
    if( !structKeyExists( rc, "auth" )) {
      rc.alert = { "class"="danger", "text"="no-auth-in-session" };
      rc.auth.isLoggedIn = false;
    } else if( !structKeyExists( rc.auth, "isLoggedIn" ) || !isBoolean( rc.auth.isLoggedIn ) || !securityService.authIsValid( rc.auth )) {
      rc.alert = { "class"="danger", "text"="invalid-auth-struct" };
      rc.auth.isLoggedIn = false;
    }

    // we're not logged in, try a few options:
    if( !rc.auth.isLoggedIn ) {
      if( framework.getSubsystem() == "api" || listFirst( cgi.PATH_INFO, "/" ) == "api" ) {
        // API basic auth login:
        var HTTPRequestData = GetHTTPRequestData();

        if( isDefined( "HTTPRequestData.headers.authorization" )) {
          writeLog( text="trying API basic auth", type="information", file=request.appName );
          var basicAuth = toString( toBinary( listLast( HTTPRequestData.headers.authorization, " " )));
          rc.username=listFirst( basicAuth, ":" );
          rc.password=listRest( basicAuth, ":" );
          rc.dontRedirect=true;
        } else {
          var isLucee = listFindNoCase( "lucee,railo", server.ColdFusion.ProductName );
          var pageContext=getPageContext();
          var response = isLucee ? pageContext.getResponse() : pageContext.getFusionContext().getResponse();
              response.setHeader( "WWW-Authenticate", "Basic realm=""#request.appName#-API""" );

          framework.renderData( "rawjson", '{"status":"error","detail":"Unauthorized"}', 401 );
          framework.abortController();
        }
      }

      // Try authhash, or regular username/password if available (via basic auth for instance)
      if( structKeyExists( rc, "authhash" ) || ( structKeyExists( rc, "username" ) && structKeyExists( rc, "password" ))) {
        doLogin( rc );

      } else {
        // nope, still not logged in: reset session via logout method.
        rc.alert = { "class"="danger", "text"="user-not-logged-in" };
        doLogout( rc );
      }
    }
  }

  public void function doRetrieve( required struct rc ) {
    if( structKeyExists( rc, 'email' ) && len( trim( rc.email ))) {
      var user=contactService.getByEmail( rc.email );

      if( !isNull( user )) {
        var authhash=toBase64( encrypt( user.getID(), rc.config.encryptKey ));
        var activationEmails=contentService.getByFQA( "mail.activation" );

        if( arrayLen( activationEmails ) gt 0 ) {
          var emailText=activationEmails[1];
        }

        if( isNull( emailText )) {
          var logMessage="missing activation email text, add text with fqa: 'mail.activation'";
          writeLog( text=logMessage, type="warning", file=request.appName );
          throw( logMessage );
        }

        mailService.send(
          rc.config.ownerEmail,
          user,
          emailText.getTitle(),
          rc.util.parseStringVariables(
            emailText.getBody(),
            {
              link=framework.buildURL( action='profile.password', queryString={ "authhash"=authhash })
            }
          )
        );

        rc.alert = {
          "class"="success",
          "text"="email-sent"
        };
        writeLog( text="retrieve password email sent", type="information", file=request.appName );
        framework.redirect( ":security.login", "alert" );
      } else {
        rc.alert = {
          "class"="danger",
          "text"="email-not-found"
        };
        writeLog( text="retrieve password email not found", type="warning", file=request.appName );
        framework.redirect( ":security.retrieve", "alert" );
      }
    }
  }
}