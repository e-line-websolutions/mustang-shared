component accessors=true {
  property config;
  property dataService;
  property utilityService;
  property bcrypt;

  public component function init( root, config ) {
    var bCryptPath = "#root#/lib/java";

    if ( structKeyExists( config, "paths" ) && structKeyExists( config.paths, "bcrypt" ) && len( trim( config.paths.bcrypt ) ) ) {
      bCryptPath = config.paths.bcrypt;
    }

    variables.bcrypt = getBCrypt( bCryptPath );

    return this;
  }

  public struct function getAuth( ) {
    var result = getEmptyAuth( );

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
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

  public void function createSession( ) {
    var tmpSession = {
      "can" = { },
      "auth" = getEmptyAuth( )
    };

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structClear( session );
      structAppend( session, tmpSession );
    }
  }

  public void function refreshFakeSession( ) {
    createSession( );

    var tempAuth = {
      canAccessAdmin = true,
      isLoggedIn = true,
      role = getFakeRole( ),
      user = dataService.processEntity( getFakeUser( ) ),
      userid = createUUID( )
    };

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structAppend( session.auth, tempAuth, true );
    }
  }

  public void function refreshSession( root.model.contact user ) {
    if ( isNull( user ) ) {
      var currentAuth = getAuth( );

      if ( utilityService.isGuid( currentAuth.userId ) ) {
        user = entityLoadByPK( "contact", currentAuth.userId );
      }
    }

    createSession( );

    var userAsStruct = dataService.processEntity( user, 0, 1, false );
    var securityRole = dataService.processEntity( user.getSecurityRole( ), 0, 1, false );

    if ( isNull( securityRole ) || structIsEmpty( securityRole ) || !structKeyExists( securityRole, "name" ) ) {
      throw( "No security role for this user, or no security role name set.", "securityService.refreshSession" );
    }

    var tempAuth = {
      isLoggedIn = true,
      user = userAsStruct,
      userid = user.getID( ),
      role = securityRole
    };

    if ( isAdmin( securityRole.name ) ) {
      tempAuth.role.can = yesWeCan;
      tempAuth.canAccessAdmin = true;
    } else {
      cachePermissions( securityRole.permissions );
      tempAuth.role.can = can;
      tempAuth.canAccessAdmin = false;
    }

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structAppend( session.auth, tempAuth, true );
    }
  }

  public string function hashPassword( required string password ) {
    var t = 0;
    var cost = 4;
    while ( t < 500 && cost <= 30 ) {
      var salt = variables.bcrypt.gensalt( cost );
      var hashedPW = variables.bcrypt.hashpw( password, salt );
      // test speed of decryption:
      var start = getTickCount( );
      variables.bcrypt.checkpw( password, hashedPW );
      t = getTickCount( ) - start;
      cost++;
    }
    return hashedPW;
  }

  public boolean function comparePassword( required string password, required string storedPW ) {
    try {
      // FIRST TRY BCRYPT:
      return variables.bcrypt.checkpw( password, storedPW );
    } catch ( any e ) {
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
      var tempAuth = getAuth( );
      roleName = tempAuth.role.name;
    }

    return roleName == "Administrator" || roleName == "Admin";
  }

  public boolean function yesWeCan( ) {
    return true;
  }

  public boolean function can( string action = "", string section = "" ) {
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      param session.can={
      };
      var cachedCan = session.can;
      var tempAuth = session.auth;
    }

    return structKeyExists( cachedCan, "#action#-#section#" ) || tempAuth.canAccessAdmin;
  }

  public boolean function canIgnoreSecurity( string subsystem="",
                                             string section="",
                                             string fqa="",
                                             string defaultSubsystem="" ) {
    if ( listFindNoCase( variables.config.dontSecureFQA, fqa ) ) {
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

    if ( listFindNoCase( variables.config.securedSubsystems, subsystem ) ) {
      return true;
    }

    return false;




    // REPLACES THIS:

    // var isDefaultSubsystem = framework.getSubsystem() == framework.getDefaultSubsystem();
    // var dontSecureDefaultSubsystem = isDefaultSubsystem && !config.secureDefaultSubsystem;
    // var dontSecureCurrentSubsystem = len( trim( framework.getSubsystem())) ? listFindNoCase( config.securedSubsystems, framework.getSubsystem()) eq 0 : false;
    // var isAPISecurity = framework.getSubsystem() == "api" && framework.getSection() == "auth";
    // var dontSecureThisFQA = structKeyExists( config, "dontSecureFQA" ) && len( config.dontSecureFQA ) && listFindNoCase( config.dontSecureFQA, rc.action );
    // var dontSecureThisSubsystem = dontSecureDefaultSubsystem || dontSecureCurrentSubsystem;
    // var isLoginPageOrAction = ( isDefaultSubsystem && framework.getSection() == "security" ) || isAPISecurity;
    // var isCSS = framework.getSubsystem() == "adminapi" && framework.getSection() == "css";

    // if( dontSecureThisFQA || dontSecureThisSubsystem || isLoginPageOrAction || isCSS ) {
    //   return;
    // }

  }

  // private

  private void function cachePermissions( required array allPermissions ) {
    var cachedPermissions = { };

    for ( var permission in allPermissions ) {
      if ( !structKeyExists( permission, "section" ) || !len( trim( permission.section ) ) ) {
        continue;
      }
      for ( var action in [ "view", "change", "delete", "execute", "create" ] ) {
        if ( structKeyExists( permission, action ) && isBoolean( permission[ action ] ) && permission[ action ] ) {
          cachedPermissions[ "#action#-#permission.section#" ] = true;
        }
      }
    }

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      session.can = cachedPermissions;
    }
  }

  private struct function getFakeUser( ) {
    return {
      "name" = "Administrator",
      "firstname" = "John",
      "lastname" = "Doe"
    };
  }

  private struct function getFakeRole( ) {
    return {
      "name" = "Administrator",
      "menuList" = "",
      "can" = yesWeCan
    };
  }

  private any function getBCrypt( required string pathToBcrypt ) {
    var system = createObject( "java", "java.lang.System" );
    var javaVersion = listGetAt( system.getProperty( "java.version" ), 2, "." );
    var bCryptLocation = directoryList( pathToBcrypt & "/" & javaVersion, false, "path", "*.jar" );
    var jl = new javaloader.javaloader( bCryptLocation );

    return jl.create( "org.mindrot.jbcrypt.BCrypt" );
  }

  private struct function getEmptyAuth( ) {
    return {
      "isLoggedIn" = false,
      "user" = { },
      "role" = { },
      "userid" = '',
      "canAccessAdmin" = false
    };
  }
}