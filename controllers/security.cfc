component accessors=true {
  property framework;
  property config;

  property contactService;
  property contentService;
  property dataService;
  property emailService;
  property optionService;
  property securityService;
  property logService;
  property utilityService;

  public void function before( required struct rc ) {
  }

  public void function login( required struct rc ) {
    framework.setLayout( 'security' );

    sessionInvalidate();

    param rc.username="";
    param rc.password="";
  }

  public void function doLogin( required struct rc ) {
    param rc.username="";
    param rc.password="";
    param rc.authhash="";

    var updateUserWith = { 'lastLoginDate' = now() };

    // Check credentials:
    if ( rc.keyExists( 'authhash' ) && rc.authhash.trim().len() ) {
      logService.writeLogLevel( 'trying authhash', request.appName );

      var decryptedHash = utilityService.decryptForUrl( rc.authhash );
      if ( isJSON( decryptedHash ) ) {
        var hashStruct = deserializeJSON( decryptedHash );
        if ( isStruct( hashStruct ) && structKeyExists( hashStruct, 'path' ) ) {
          var cgi_path = cgi.path_info;
          if ( right( cgi.path_info, 1 ) eq '/' ) {
            cgi_path = left( cgi_path, len( cgi_path ) - 1 );
          }

          if ( !findNoCase( cgi_path, hashStruct.path ) ) {
            rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
            logService.writeLogLevel( text = 'authhash path failure', type = 'warning', file = request.appName );
            doLogout( rc );
          }
          var contactID = hashStruct.userId;
        }
      } else {
        var contactID = utilityService.decryptForUrl( rc.authhash );
      }
      var user = contactService.get( contactID );

      if ( isNull( user ) ) {
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
        logService.writeLogLevel( text = 'authhash failed', type = 'warning', file = request.appName );
        doLogout( rc );
      }

      param rc.dontRedirect = true;

      logService.writeLogLevel( text = 'authhash success', type = 'information', file = request.appName );
    }
    else if( !isNull( request._fw1.headers.authorization )
              && request._fw1.headers.authorization contains "Bearer"){

      var token = trim( replace( request._fw1.headers.authorization, 'Bearer', '', 'ALL' ));

      if( isNull( config.jwt.secret )){
        logService.writeLogLevel(
          text = 'No-JWT-secret-setup',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      if( isNull( config.jwt.algorithm )){
        logService.writeLogLevel(
          text = 'No-JWT-algorithm-setup',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      var jwt     = new mustang.lib.jwtcfml.models.jwt();
      var payload = jwt.decode(token, config.jwt.secret, config.jwt.algorithm );

      if( isNull( payload.contact.id )){
        logService.writeLogLevel(
          text = 'No-valid-contact-id',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      var user = contactService.getById( payload.contact.id );
    } else {
      // CHECK USERNAME:
      var user = contactService.getByUsername( rc.username );

      if ( isNull( user ) ) {
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
        logService.writeLogLevel(
          text = 'login failed: wrong username (#rc.username#)',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      // CHECK PASSWORD:
      var decryptSpeed = getTickCount();
      var passwordIsCorrect = securityService.comparePassword( password = rc.password, storedPW = user.getPassword() );
      decryptSpeed = getTickCount() - decryptSpeed;

      if ( !passwordIsCorrect ) {
        rc.alert = { 'class' = 'danger', 'text' = 'password-incorrect' };
        logService.writeLogLevel(
          text = 'user #user.getUsername()# login failed: wrong password ',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      if ( decryptSpeed < 250 || decryptSpeed > 1000 ) {
        // re-encrypt if decryption is too slow, or too fast:
        updateUserWith[ 'password' ] = securityService.hashPassword( rc.password );
      }
    }

    updateUserWith[ 'contactID' ] = user.getID();

    if ( config.log ) {
      var securityLogaction = optionService.getOptionByName( 'logaction', 'security' );
      updateUserWith[ 'add_logEntry' ] = {
        'relatedEntity' = user.getId(),
        'by' = user.getId(),
        'dd' = now(),
        'ip' = cgi.remote_addr,
        'logaction' = securityLogaction.getId(),
        'note' = 'Logged in'
      };
    }

    // user.enableDebug();
    user.dontLog();

    transaction {
      user.save( updateUserWith );
    }

    logService.writeLogLevel( text = 'user #user.getUsername()# logged in.', type = 'information', file = request.appName );

    // Set auth struct:
    securityService.refreshSession( user );
    rc.auth = securityService.getAuth();

    param rc.dontRedirect=false;
    param rc.auth.role.loginscript=":";

    if ( !rc.dontRedirect ) {
      var redirectTo = rc.keyExists( 'returnpage' )
        ? rc.returnpage
        : rc.auth.role.loginscript;

      redirectTo.left( 1 ) == '/'
        ? framework.redirectCustomURL( redirectTo )
        : framework.redirect( redirectTo.trim().len() ? redirectTo : ':' );
    }
  }

  public void function doLogout( required struct rc, boolean failedAuthorization = false ) {
    // reset session
    securityService.endSession();

    var logMessage = 'user logged out.';

    if ( config.log && isDefined( 'rc.auth.userid' ) && dataService.isGUID( rc.auth.userid ) ) {
      var user = contactService.get( rc.auth.userid );

      if ( !isNull( user ) ) {
        logMessage = user.getUsername() & ' logged out.';

        var updateUserLog = {
          'contactID' = user.getID(),
          'add_logEntry' = {
            'relatedEntity' = user.getId(),
            'by' = user.getId(),
            'dd' = now(),
            'ip' = cgi.remote_addr,
            'logaction' = optionService.getOptionByName( 'logaction', 'security' ),
            'note' = logMessage
          }
        };

        var originalLogSetting = config.log;
        request.context.config.log = false;

        entityReload(user);

        transaction {
          user.save( updateUserLog );
        }

        request.context.config.log = originalLogSetting;
      }
    }

    logService.writeLogLevel( logMessage );

    if ( framework.getSubsystem() == 'api' || listFirst( cgi.PATH_INFO, '/' ) == 'api' ) {
      cfcontent( reset = true );
      var statusCode = rc.alert.class == 'danger' ? 401 : 200;
      framework.renderData()
        .type( 'json' )
        .data( rc.alert )
        .statusCode( statusCode );
      framework.abortController();
    }

    if ( isDefined( 'rc.auth.isLoggedIn' ) && isBoolean( rc.auth.isLoggedIn ) && rc.auth.isLoggedIn && !structKeyExists( rc, 'alert' ) ) {
      rc.alert = { 'class' = 'success', 'text' = 'logout-success' };
    }

    if( !failedAuthorization ){
      framework.redirect( ':security.login', 'alert' );
      framework.abortController();
    }

    // if we come from a failed authorization we try to create a returnpage to use after a successful login

    rc.returnpage = "";

    if( !isNull( url ) && isStruct( url ) ){
      var urlString = "";
      for( var key in url ){
        if( !len(trim( urlString ))) urlString &="?";
        else urlString &="&";

        urlString&= "#key#=#url[key]#";
      }

      rc.returnpage = cgi.path_info & urlString;
    }


    framework.redirect( ':security.login', 'alert,returnpage' );
    framework.abortController();
  }

  // THIS FUNCTION WILL ALWAYS SET RC.AUTH
  public void function authorize( required struct rc ) {

    if( rc.keyExists( 'authhash' ) ) doLogin( rc );

    // Use auth struct that's stored in session
    rc.auth = securityService.getAuth();

    if ( config.disableSecurity ) {
      securityService.refreshFakeSession();
      return;
    }

    // Always allow access to security && api:css
    var args = {
      'subsystem' = framework.getSubsystem(),
      'section' = framework.getSection(),
      'fqa' = framework.getFullyQualifiedAction(),
      'defaultSubsystem' = framework.getDefaultSubsystem()
    };

    if ( securityService.canIgnoreSecurity( argumentCollection = args ) ) {
      return; // EARLY EXIT
    }

    // check validity of auth struct
    if ( !structKeyExists( rc, 'auth' ) ) {
      rc.alert = { 'class' = 'danger', 'text' = 'no-auth-in-session' };
      rc.auth.isLoggedIn = false;
    } else if ( structKeyExists( rc, 'authhash' ) || !structKeyExists( rc.auth, 'isLoggedIn' ) || !isBoolean( rc.auth.isLoggedIn ) ) {
      rc.auth.isLoggedIn = false;
    }

    // we're not logged in, try a few options:
    if ( !rc.auth.isLoggedIn ) {
      if ( ( framework.getSubsystem() == 'api' || listFirst( cgi.PATH_INFO, '/' ) == 'api' ) && !structKeyExists(
        rc,
        'authhash'
      ) ) {
        // API basic auth login:
        var HTTPRequestData = getHTTPRequestData();




        if ( isDefined( 'HTTPRequestData.headers.authorization' ) ) {
          logService.writeLogLevel( text = 'trying API basic auth', type = 'information', file = request.appName );
          var basicAuth = toString( toBinary( listLast( HTTPRequestData.headers.authorization, ' ' ) ) );

          rc.username = listFirst( basicAuth, ':' );
          rc.password = listRest( basicAuth, ':' );
          rc.dontRedirect = true;
        } else {
          var isLucee = listFindNoCase( 'lucee,railo', server.ColdFusion.ProductName );
          var pageContext = getPageContext();
          var response = isLucee ? pageContext.getResponse() : pageContext.getFusionContext().getResponse();
          response.setHeader( 'WWW-Authenticate', 'Basic realm="#request.appName#-API"' );

          framework.renderData( 'rawjson', '{"status":"error","detail":"Unauthorized","action":"#rc.action#"}', 401 );
          framework.abortController();
        }
      }

      // Try authhash, or regular username/password if available (via basic auth for instance)
      if ( structKeyExists( rc, 'authhash' ) || ( structKeyExists( rc, 'username' ) && structKeyExists( rc, 'password' ) ) ) {
        doLogin( rc );
      } else {
        // nope, still not logged in: reset session via logout method.
        logService.writeLogLevel( text = 'User not logged in, reset session', type = 'information', file = request.appName );
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-logged-in' };
        doLogout( rc, true );
      }
    }
  }

  public void function doRetrieve( required struct rc ) {
    param rc.returnToSection='security';
    param rc.passwordResetFQA=':#rc.returnToSection#.password';
    param rc.emailTemplate='';

    if ( structKeyExists( rc, 'email' ) && len( trim( rc.email ) ) ) {
      var contact = contactService.getByEmail( rc.email );

      if ( !isNull( contact ) ) {
        var authhash = utilityService.encryptForUrl( contact.getID() );
        var activationEmails = contentService.getByFQA( 'mail.activation' );

        if ( isObject( activationEmails ) ) {
          var emailText = activationEmails;
        } else if ( ( isArray( activationEmails ) && !arrayIsEmpty( activationEmails ) ) ) {
          var emailText = activationEmails[ 1 ];
        }

        if ( isNull( emailText ) || isNull( emailText.getFullyqualifiedaction() ) ) {
          var logMessage = 'missing activation email text, add text with fqa: ''mail.activation''';
          logService.writeLogLevel( text = logMessage, type = 'warning', file = request.appName );
          throw( logMessage );
        }

        var emailBody = utilityService.parseStringVariables(
          emailText.getBody(),
          {
            'link' = framework.buildURL( action = rc.passwordResetFQA, queryString = { 'authhash' = authhash } ),
            'firstname' = contact.getFirstname(),
            'fullname' = contact.getFullname()
          }
        );

        if ( len( trim( rc.emailTemplate ) ) ) {
          var emailBody = utilityService.parseStringVariables(
            framework.layout( 'mail', framework.view( rc.emailTemplate ) ),
            { 'firstname' = contact.getFirstname(), 'body' = emailBody }
          );
        }

        emailService.send( from = config.ownerEmail, to = contact, subject = emailText.getTitle(), body = emailBody );

        rc.alert = { 'class' = 'success', 'text' = 'email-sent' };
        logService.writeLogLevel( text = 'retrieve password email sent', type = 'information', file = request.appName );
        framework.redirect( ':#rc.returnToSection#.login', 'alert' );
      } else {
        rc.alert = { 'class' = 'danger', 'text' = 'email-not-found' };
        logService.writeLogLevel( text = 'retrieve password email not found', type = 'warning', file = request.appName );
        framework.redirect( ':#rc.returnToSection#.retrieve', 'alert' );
      }
    }
  }
}
