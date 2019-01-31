component accessors=true {
  property config;
  property dataService;
  property logService;
  property utilityService;

  property any bcrypt;

  public component function init( root, config ) {
    var bCryptPath = replace( getDirectoryFromPath( getCurrentTemplatePath( ) ), "\", "/", "all" ) & "../lib/bcrypt";

    if ( structKeyExists( config, "paths" ) && structKeyExists( config.paths, "bcrypt" ) && len( trim( config.paths.bcrypt ) ) ) {
      bCryptPath = config.paths.bcrypt;
    }

    variables.bcrypt = getBCrypt( bCryptPath );

    return this;
  }

  public struct function getAuth( ) {
    var result = getEmptyAuth( );

    if ( !isNull( session.auth ) ) {
      var result = session.auth;
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
    logService.writeLogLevel( "createSession() called", "securityService", "debug" );

    var tmpSession = {
      "can" = { },
      "auth" = getEmptyAuth( )
    };

    structClear( session );

    structAppend( session, tmpSession );
  }

  public void function refreshFakeSession( ) {
    createSession( );

    var tempAuth = {
      "canAccessAdmin" = true,
      "isLoggedIn" = true,
      "role" = getFakeRole( ),
      "user" = dataService.processEntity( getFakeUser( ) ),
      "userid" = createUUID( )
    };

    structAppend( session.auth, tempAuth, true );
  }

  public void function refreshSession( component user ) {
    if ( isNull( user ) ) {
      var currentAuth = getAuth( );

      if ( utilityService.isGuid( currentAuth.userId ) ) {
        user = entityLoadByPK( "contact", currentAuth.userId );
      }
    } else {
      entityReload( user );
    }

    createSession( );

    var userAsStruct = dataService.processEntity( user, 0, 1, false );
    var securityRole = dataService.processEntity( user.getSecurityRole( ), 0, 1, false );

    if ( isNull( securityRole ) || structIsEmpty( securityRole ) || !structKeyExists( securityRole, "name" ) ) {
      throw( "No security role for this user, or no security role name set.", "securityService.refreshSession" );
    }

    var tempAuth = {
      "isLoggedIn" = true,
      "user" = userAsStruct,
      "userid" = user.getID( ),
      "role" = securityRole
    };

    if ( isAdmin( securityRole.name ) ) {
      tempAuth.role.can = yesWeCan;
      tempAuth.canAccessAdmin = true;
    } else {
      cachePermissions( securityRole.permissions );
      tempAuth.role.can = can;
      tempAuth.canAccessAdmin = false;
    }

    structAppend( session.auth, tempAuth, true );
  }

  public string function hashPassword( required string password ) {
    var minSpeed = 100;
    var cost = 4;
    do {
      var salt = variables.bcrypt.gensalt( cost );
      var hashedPW = variables.bcrypt.hashpw( password, salt );
      var start = getTickCount( );
      variables.bcrypt.checkpw( password, hashedPW );
      var hashSpeed = getTickCount( ) - start;
      logService.writeLogLevel( "Password hash speed #hashSpeed#ms at #cost#.", "securityService", "debug" );
      cost++;
    } while ( hashSpeed < minSpeed && cost <= 30 );
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
    param session.can={};
    var cachedCan = session.can;
    var tempAuth = session.auth;

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

    if ( !inDefaultSubsystem && !listFindNoCase( variables.config.securedSubsystems, subsystem ) ) {
      return true;
    }

    return false;
  }

  /*
   * From https://github.com/misterdai/cfbackport/blob/master/cf10.cfm
   * Altered a bit to follow project coding style
   **/
  public void function invalidateSession( ) {
    if ( val( server.coldfusion.productversion ) >= 10 ) {
      sessionInvalidate( );
      return;
    }

    if ( structKeyExists( session, "cfid" ) && structKeyExists( session, "cftoken" ) ) {
      var sessionId = session.cfid & '_' & session.cftoken;
    }

    // Fire onSessionEnd
    var appEvents = application.getEventInvoker( );
    appEvents.onSessionEnd( [ application, session ] );

    // Make sure that session is empty
    for ( var key in session ) {
      if ( !listFindNoCase( "cfid,cftoken,sessionid,urltoken", key ) ) {
        structDelete( session, key );
      }
    }
    // structClear( session );

    // Clean up the session
    if ( !isNull( sessionId ) ) {
      var sessionTracker = createObject( "java", "coldfusion.runtime.SessionTracker" );
      sessionTracker.cleanUp( application.applicationName, sessionId );
    }
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

    session.can = cachedPermissions;
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
      "role" = { "name" = "none" },
      "userid" = '',
      "canAccessAdmin" = false
    };
  }
}
