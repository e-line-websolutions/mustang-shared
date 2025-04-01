component accessors=true {
  property config;
  property contactService;
  property dataService;
  property logService;
  property optionService;
  property utilityService;

  public struct function getAuth() {
    var result = getEmptyAuth();

    lock name="_lock_session_for_#cfid#-#cftoken#" timeout="3" throwontimeout="true" type="readonly" {
      if ( !isNull( session.auth ) ) {
        var result = session.auth;
      }
    }

    return result;
  }

  public boolean function authIsValid( required struct checkAuth ) {
    var requiredKeys = [ 'isLoggedIn', 'user', 'userid', 'role' ];

    for ( var key in requiredKeys ) {
      if ( !structKeyExists( checkAuth, key ) ) {
        return false;
      }
    }

    if ( !len( trim( checkAuth.userid ) ) ||
         !isStruct( checkAuth.user ) ||
         !isStruct( checkAuth.role ) ||
         !isBoolean( checkAuth.isLoggedIn ) ) {
      return false;
    }

    return true;
  }

  public void function createSession() {
    logService.writeLogLevel( "createSession() called", "securityService", "debug" );

    var tmpSession = {
      "can" = { },
      "auth" = getEmptyAuth()
    };

    session.clear();
    session.append( tmpSession );
  }

  public void function endSession() {
    structDelete( session, 'auth' );
    structDelete( session, 'can' );
    sessionRotate();
  }

  public void function refreshFakeSession() {
    lock name="_lock_session_for_#cfid#-#cftoken#" timeout="3" throwontimeout="true" type="exclusive" {
      createSession();

      var tempAuth = {
        "isLoggedIn" = true,
        "role" = getFakeRole(),
        "user" = dataService.processEntity( getFakeUser() ),
        "userid" = createUUID()
      };

      session.auth.append( tempAuth, true );
    }
  }

  public void function refreshSession( component user ) {
    lock name="_lock_session_for_#cfid#-#cftoken#" timeout="3" throwontimeout="true" type="exclusive" {
      if ( isNull( user ) ) {
        var currentAuth = getAuth();

        if ( dataService.isGuid( currentAuth.userId ) ) {
          user = entityLoadByPK( "contact", currentAuth.userId );
        }
      } else {
        entityReload( user );
      }

      createSession();

      var tempAuth = {
        "isLoggedIn" = true,
        "user" = dataService.processEntity( user, 0, 1, false ),
        "userid" = user.getID()
      };

      if ( structKeyExists( user, 'getSecurityRole' ) ) {
        var securityRole = user.getSecurityRole();

        if ( isNull( securityRole ) ) {
          throw( "No security role for this user, or no security role name set.", "securityService.refreshSession" );
        }

        tempAuth[ "role" ] = dataService.processEntity( securityRole, 0, 1, false )
          .append( { permissions: securityRole.getPermissions().filter((p) => !p.getDeleted()).map((p) => dataService.processEntity( p, 0, 1, false ) ) }, true );

        tempAuth.role.delete( 'contacts' );

        if ( isAdmin( tempAuth.role.name ) ) {
          tempAuth.role.can = yesWeCan;
        } else {
          cachePermissions( tempAuth.role.permissions );
          tempAuth.role.can = this.can;
        }
      }

      session.auth.append( tempAuth, true );

      sessionRotate();
    }
  }

  public string function hashPassword( required string password ) {
    var minSpeed = 250;
    var cost = 4;
    var bcrypt = getBCrypt();
    do {
      // var salt = bcrypt.gensalt( cost );
      // var hashedPW = bcrypt.hashpw( password, salt );
      var hashedPW = bcrypt.withDefaults().hashToString(cost, passwordAsCharArray( password ));
      var start = getTickCount();
      bcrypt.verifyer().verify( passwordAsCharArray( password ), hashedPW );
      var hashSpeed = getTickCount() - start;
      logService.writeLogLevel( "Password hash speed #hashSpeed#ms at #cost#.", "securityService", "debug" );
      cost++;
    } while ( hashSpeed < minSpeed && cost <= 30 );
    return hashedPW;
  }

  public boolean function comparePassword( required string password, required string storedPW ) {
    try {
      // FIRST TRY BCRYPT:
      var bcrypt = getBCrypt();
      return bcrypt.verifyer().verify( passwordAsCharArray( password ), storedPW ).verified;
    } catch ( any e ) {
      writeDump( e );abort;
      try {
        // THEN TRY THE OLD SHA-512 WAY:
        var storedsalt = right( storedPW, 16 );
        return 0 == compare( storedPW, hash( password & storedsalt, 'SHA-512' ) & storedsalt );
      } catch ( any e ) {
        return false;
      }
    }
  }

  public boolean function isAdmin( string roleName ) {
    if ( isNull( roleName ) ) {
      var currentAuth = getAuth();
      roleName = currentAuth.role.name;
    }

    return roleName == "Administrator" || roleName == "Admin";
  }

  public boolean function yesWeCan() {
    return true;
  }

  public boolean function ahAhAhYouDidntSayTheMagicWord() {
    return false;
  }

  public boolean function can( string action = '', string section = '' ) {
    lock name="_lock_session_for_#cfid#-#cftoken#" timeout="3" throwontimeout="true" type="readonly" {
      // not logged in:
      if ( !session.keyExists( 'auth' ) ) return false;

      var authInSession = session.auth;
      var sessionCanCache = session.can;
    }

    param sessionCanCache = {};
    param authInSession.role.name = 'none';
    param authInSession.role.isAdmin = false;

    // admin can do anything (cached):
    if ( authInSession.role.name.left( 5 ) == 'Admin' ) return true;

    // check permissions:
    return sessionCanCache.keyExists( '#action#-#section#' );
  }

  public boolean function canIgnoreSecurity( string subsystem="",
                                             string section="",
                                             string fqa="",
                                             string defaultSubsystem="" ) {
    if ( isArray( variables.config.dontSecureFQA ) && variables.config.dontSecureFQA.findNoCase( fqa ) ) {
      return true;
    }

    if ( isSimpleValue( variables.config.dontSecureFQA ) && variables.config.dontSecureFQA.listfindNoCase( fqa ) ) {
      return true;
    }

    if ( subsystem == "adminapi" && section == "css" ) {
      return true;
    }

    if ( subsystem == "api" && section == "auth" ) {
      return true;
    }

    var inDefaultSubsystem = subsystem == defaultSubsystem;

    if ( inDefaultSubsystem && section == "security" ) {
      return true;
    }

    if ( inDefaultSubsystem && !variables.config.secureDefaultSubsystem ) {
      return true;
    }


  writedUmp( variables.config.securedSubsystems );
  writedUmp( subsystem );abort;

    if ( !inDefaultSubsystem && !listFindNoCase( variables.config.securedSubsystems, subsystem ) ) {
      return true;
    }

    return false;
  }

  public void function doLogin( required string username, required string password ) {
    var contact = contactService.getByUsername( username );

    if ( comparePassword( password, contact.getPassword() ) ) {
      logUserLogin( contact );
      refreshSession( contact );
    }
  }

  public void function doLogout() {
    logUserLogout();
    endSession();
  }

  public string function createJWTForContact(
    required component contact,
    struct additionalData
  ){
    if( isNull( additionalData )) additionalData = {};
    if( isNull( config.jwt.secret )){
      logService.writeLogLevel(
        text = 'No-JWT-secret-setup',
        type = 'warning',
        file = request.appName
      );
      throw('No-JWT-secret-setup');
    }


    if( isNull( config.jwt.algorithm )){
      logService.writeLogLevel(
        text = 'No-JWT-algorithm-setup',
        type = 'warning',
        file = request.appName
      );
      throw('No-JWT-algorithm-setup');
    }

    var jwt     = new mustang.lib.jwtcfml.models.jwt();
    var payload = { 'id' = contact.getId(), 'username' = contact.getUsername(), 'securityroleid' = contact.getSecurityRole().getId() };

    try{
      var company = contact.getCompany();
      if( !isNull( company )){
        payload['companyid'] = company.getId();
      }
    }catch(e){}

    var token   = jwt.encode( additionalData.append({ 'contact' = payload, 'exp' = dateAdd( 'd', 1, now() ) }), config.jwt.secret, config.jwt.algorithm );
    return token;
  }

  public any function decodeJwt(
    required string token
  ){
    if( isNull( config.jwt.secret )){
      logService.writeLogLevel(
        text = 'No-JWT-secret-setup',
        type = 'warning',
        file = request.appName
      );
      throw('No-JWT-secret-setup');
    }


    if( isNull( config.jwt.algorithm )){
      logService.writeLogLevel(
        text = 'No-JWT-algorithm-setup',
        type = 'warning',
        file = request.appName
      );
      throw('No-JWT-algorithm-setup');
    }


    var jwt     = new mustang.lib.jwtcfml.models.jwt();
    return jwt.decode( token, config.jwt.secret, config.jwt.algorithm );
  }


  private void function cachePermissions( required array allPermissions ) {
    var cachedPermissions = { };

    for ( var permission in allPermissions ) {
      if ( !structKeyExists( permission, "section" ) || !len( trim( permission.section ) ) ) {
        continue;
      }
      for ( var action in [ "view", "change", "delete", "execute", "create" ] ) {
        if ( structKeyExists( permission, action ) &&
                   isBoolean( permission[ action ] ) &&
                              permission[ action ] ) {
          cachedPermissions[ "#action#-#permission.section#" ] = '';
        }
      }
    }

    lock name="_lock_session_for_#cfid#-#cftoken#" timeout="3" throwontimeout="true" type="exclusive" {
      session.can = cachedPermissions;
    }
  }

  private struct function getFakeUser() {
    return {
      "name" = "Administrator",
      "firstname" = "John",
      "lastname" = "Doe"
    };
  }

  private struct function getFakeRole() {
    return {
      "name" = "Administrator",
      "menuList" = "",
      "can" = yesWeCan
    };
  }

  private any function getBCrypt() {
    return createObject( 'java', 'at.favre.lib.crypto.bcrypt.BCrypt', expandPath( '/mustang/lib/java/' ) );
  }

  private any function passwordAsCharArray(password) {
    // var StandardCharsets = createObject( 'java', 'java.nio.charset.StandardCharsets' );
    return password.toCharArray();
  }

  private struct function getEmptyAuth() {
    return {
      'isLoggedIn' = false,
      'user' = {
        'company' = {
          'id' = createUUID()
        }
      },
      'role' = { 'name' = 'none', 'isAdmin' = false, can = ahAhAhYouDidntSayTheMagicWord },
      'userid' = ''
    };
  }

  private void function logUserLogin( contact ) {
    if ( !config.log ) return;

    contact.dontLog();
    contact.save( {
        'lastLoginDate' = now()
      , 'add_logEntry' = {
            'relatedEntity' = contact.getId()
          , 'by' = contact.getId()
          , 'dd' = now()
          , 'ip' = cgi.remote_addr
          , 'logaction' = optionService.getOptionByName( 'logaction', 'security' )
          , 'note' = '#contact.getUsername()# logged in'
        }
    } );
  }

  private void function logUserLogout() {
    if ( !config.log ) return;

    var auth = getAuth();

    if ( dataService.isGUID( auth?.userid ) ) {
      var contact = contactService.get( auth.userid );
      contact.dontLog().save( {
        'add_logEntry' = {
            'relatedEntity' = contact.getId()
          , 'by' = contact.getId()
          , 'dd' = now()
          , 'ip' = cgi.remote_addr
          , 'logaction' = optionService.getOptionByName( 'logaction', 'security' )
          , 'note' = '#contact.getUsername()# logged out'
        }
      } );
    }
  }
}
