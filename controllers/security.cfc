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
    variables.framework.setLayout( 'security' );

    param rc.username = "";
    param rc.password = "";
  }

  public void function doLogin( required struct rc ) {
    param rc.username = "";
    param rc.password = "";
    param rc.authhash = "";

    var updateUserWith = { 'lastLoginDate' = now() };
    // Check credentials:
    if ( structKeyExists( rc, 'authhash' ) && len( trim( rc.authhash ) ) ) {
      variables.logService.writeLogLevel( 'trying authhash', request.appName );

      var decryptedHash = decrypt( variables.utilityService.base64urlDecode( rc.authhash ), variables.config.encryptKey );
      if ( isJSON( decryptedHash ) ) {
        var hashStruct = deserializeJSON( decryptedHash );
        if ( isStruct( hashStruct ) && structKeyExists( hashStruct, 'path' ) ) {
          var cgi_path = cgi.path_info;
          if ( right( cgi.path_info, 1 ) eq '/' ) {
            cgi_path = left( cgi_path, len( cgi_path ) - 1 );
          }

          if ( !findNoCase( cgi_path, hashStruct.path ) ) {
            rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
            variables.logService.writeLogLevel( text = 'authhash path failure', type = 'warning', file = request.appName );
            doLogout( rc );
          }
          var contactID = hashStruct.userId;
        }
      } else {
        var contactID = decrypt( variables.utilityService.base64urlDecode( rc.authhash ), variables.config.encryptKey );
      }
      var user = variables.contactService.get( contactID );

      if ( isNull( user ) ) {
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
        variables.logService.writeLogLevel( text = 'authhash failed', type = 'warning', file = request.appName );
        doLogout( rc );
      }

      param rc.dontRedirect = true;

      variables.logService.writeLogLevel( text = 'authhash success', type = 'information', file = request.appName );
    } else {
      // CHECK USERNAME:
      var user = variables.contactService.getByUsername( rc.username );

      if ( isNull( user ) ) {
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-found' };
        variables.logService.writeLogLevel(
          text = 'login failed: wrong username (#rc.username#)',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      // CHECK PASSWORD:
      var decryptSpeed = getTickCount();
      var passwordIsCorrect = variables.securityService.comparePassword( password = rc.password, storedPW = user.getPassword() );
      decryptSpeed = getTickCount() - decryptSpeed;

      if ( !passwordIsCorrect ) {
        rc.alert = { 'class' = 'danger', 'text' = 'password-incorrect' };
        variables.logService.writeLogLevel(
          text = 'user #user.getUsername()# login failed: wrong password ',
          type = 'warning',
          file = request.appName
        );
        doLogout( rc );
      }

      if ( decryptSpeed < 250 || decryptSpeed > 1000 ) {
        // re-encrypt if decryption is too slow, or too fast:
        updateUserWith.password = variables.securityService.hashPassword( rc.password );
      }
    }

    // Set auth struct:
    variables.securityService.refreshSession( user );

    updateUserWith[ 'contactID' ] = user.getID();

    if ( variables.config.log ) {
      var securityLogaction = variables.optionService.getOptionByName( 'logaction', 'security' );
      updateUserWith[ 'add_logEntry' ] = {
        'relatedEntity' = user.getId(),
        'by' = user.getId(),
        'dd' = now(),
        'ip' = cgi.remote_addr,
        'logaction' = securityLogaction.getId(),
        'note' = 'Logged in'
      };
    }

    var originalLogSetting = variables.config.log;

    request.context.config.log = false;

    transaction {
      user.save( updateUserWith );
    }

    request.context.config.log = originalLogSetting;

    variables.logService.writeLogLevel( text = 'user #user.getUsername()# logged in.', type = 'information', file = request.appName );

    rc.auth = variables.securityService.getAuth();

    param rc.dontRedirect = false;

    if ( !rc.dontRedirect ) {
      var loginscript = '';

      if ( !isNull( rc.auth.role.loginscript ) ) {
        loginscript = rc.auth.role.loginscript;
      }

      if ( structKeyExists( rc, 'returnpage' ) ) {
        loginscript = rc.returnpage;
      } else if ( isNull( loginscript ) || !len( trim( loginscript ) ) ) {
        loginscript = ':';
      }

      variables.framework.redirect( loginscript );
    }
  }

  public void function doLogout( required struct rc ) {
    // reset session
    variables.securityService.invalidateSession();

    var logMessage = 'user logged out.';

    if ( variables.config.log && isDefined( 'rc.auth.userid' ) && variables.dataService.isGUID( rc.auth.userid ) ) {
      var user = variables.contactService.get( rc.auth.userid );

      if ( !isNull( user ) ) {
        logMessage = user.getUsername() & ' logged out.';

        var updateUserLog = {
          'contactID' = user.getID(),
          'add_logEntry' = {
            'relatedEntity' = user.getId(),
            'by' = user.getId(),
            'dd' = now(),
            'ip' = cgi.remote_addr,
            'logaction' = variables.optionService.getOptionByName( 'logaction', 'security' ),
            'note' = logMessage
          }
        };

        var originalLogSetting = variables.config.log;
        request.context.config.log = false;

        user.save( updateUserLog );

        request.context.config.log = originalLogSetting;
      }
    }

    variables.logService.writeLogLevel( logMessage );

    if ( variables.framework.getSubsystem() == 'api' || listFirst( cgi.PATH_INFO, '/' ) == 'api' ) {
      cfcontent( reset = true );
      var statusCode = rc.alert.class == 'danger' ? 401 : 200;
      variables.framework.renderData()
        .type( 'json' )
        .data( rc.alert )
        .statusCode( statusCode );
      variables.framework.abortController();
    }

    if ( isDefined( 'rc.auth.isLoggedIn' ) && isBoolean( rc.auth.isLoggedIn ) && rc.auth.isLoggedIn && !structKeyExists( rc, 'alert' ) ) {
      rc.alert = { 'class' = 'success', 'text' = 'logout-success' };
    }

    variables.framework.redirect( ':security.login', 'alert' );
    variables.framework.abortController();
  }

  public void function authorize( required struct rc ) {
    if( structKeyExists( rc, 'authhash' ) ) doLogin( rc );

    // Use auth struct that's stored in session
    rc.auth = variables.securityService.getAuth();

    if ( variables.config.disableSecurity ) {
      variables.securityService.refreshFakeSession();
      rc.auth = variables.securityService.getAuth();
      return;
    }

    // Always allow access to security && api:css
    var args = {
      'subsystem' = variables.framework.getSubsystem(),
      'section' = variables.framework.getSection(),
      'fqa' = variables.framework.getFullyQualifiedAction(),
      'defaultSubsystem' = variables.framework.getDefaultSubsystem()
    };

    if ( variables.securityService.canIgnoreSecurity( argumentCollection = args ) ) {
      return;
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
      if ( ( variables.framework.getSubsystem() == 'api' || listFirst( cgi.PATH_INFO, '/' ) == 'api' ) && !structKeyExists(
        rc,
        'authhash'
      ) ) {
        // API basic auth login:
        var HTTPRequestData = getHTTPRequestData();

        if ( isDefined( 'HTTPRequestData.headers.authorization' ) ) {
          variables.logService.writeLogLevel( text = 'trying API basic auth', type = 'information', file = request.appName );
          var basicAuth = toString( toBinary( listLast( HTTPRequestData.headers.authorization, ' ' ) ) );

          rc.username = listFirst( basicAuth, ':' );
          rc.password = listRest( basicAuth, ':' );
          rc.dontRedirect = true;
        } else {
          var isLucee = listFindNoCase( 'lucee,railo', server.ColdFusion.ProductName );
          var pageContext = getPageContext();
          var response = isLucee ? pageContext.getResponse() : pageContext.getFusionContext().getResponse();
          response.setHeader( 'WWW-Authenticate', 'Basic realm="#request.appName#-API"' );

          variables.framework.renderData( 'rawjson', '{"status":"error","detail":"Unauthorized"}', 401 );
          variables.framework.abortController();
        }
      }

      // Try authhash, or regular username/password if available (via basic auth for instance)
      if ( structKeyExists( rc, 'authhash' ) || ( structKeyExists( rc, 'username' ) && structKeyExists( rc, 'password' ) ) ) {
        doLogin( rc );
      } else {
        // nope, still not logged in: reset session via logout method.
        rc.alert = { 'class' = 'danger', 'text' = 'user-not-logged-in' };
        doLogout( rc );
      }
    }
  }

  public void function doRetrieve( required struct rc ) {
    if ( structKeyExists( rc, 'email' ) && len( trim( rc.email ) ) ) {
      var user = variables.contactService.getByEmail( rc.email );

      if ( !isNull( user ) ) {
        var authhash = toBase64( encrypt( user.getID(), variables.config.encryptKey ) );
        var activationEmails = variables.contentService.getByFQA( 'mail.activation' );

        if ( ( isArray( activationEmails ) && arrayLen( activationEmails ) ) ) {
          var emailText = activationEmails[ 1 ];
        }

        if ( !isNull( activationEmails ) && !isArray( activationEmails ) ) {
          var emailText = activationEmails;
        }

        if ( isNull( emailText ) ) {
          var logMessage = 'missing activation email text, add text with fqa: ''mail.activation''';
          variables.logService.writeLogLevel( text = logMessage, type = 'warning', file = request.appName );
          throw( logMessage );
        }

        variables.emailService.send(
          from = variables.config.ownerEmail,
          to = user,
          subject = emailText.getTitle(),
          body = variables.utilityService.parseStringVariables(
            emailText.getBody(),
            {
              link = variables.framework.buildURL( action = 'profile.password', queryString = { 'authhash' = authhash } ),
              fullname = user.getFullname()
            }
          )
        );

        rc.alert = { 'class' = 'success', 'text' = 'email-sent' };
        variables.logService.writeLogLevel( text = 'retrieve password email sent', type = 'information', file = request.appName );
        variables.framework.redirect( ':security.login', 'alert' );
      } else {
        rc.alert = { 'class' = 'danger', 'text' = 'email-not-found' };
        variables.logService.writeLogLevel( text = 'retrieve password email not found', type = 'warning', file = request.appName );
        variables.framework.redirect( ':security.retrieve', 'alert' );
      }
    }
  }
}