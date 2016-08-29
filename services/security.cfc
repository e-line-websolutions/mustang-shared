component accessors=true {
  property dataService;
  property struct auth;
  property struct instance;

  public component function init( root, config ) {
    var bCryptPath = "#root#/lib/java";
    if ( structKeyExists( config, "paths" ) && structKeyExists( config.paths, "bcrypt" ) && len( trim( config.paths.bcrypt ) ) ) {
      bCryptPath = config.paths.bcrypt;
    }
    variables.instance.bcrypt = getBCrypt( bCryptPath );
    return this;
  }

  public struct function getAuth( ) {
    var result = { };
    if ( structKeyExists( variables, "auth" ) && isStruct( variables.auth ) ) {
      result = auth;
    }
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
      if ( structKeyExists( session, "auth" ) ) {
        result = session.auth;
      }
    }
    if ( !isStruct( result ) ) {
      result = { };
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
    if ( !len( trim( checkAuth.userid ) ) ) {
      return false;
    }
    if ( !isStruct( checkAuth.user ) ) {
      return false;
    }
    if ( !isStruct( checkAuth.role ) ) {
      return false;
    }
    if ( !isBoolean( checkAuth.isLoggedIn ) ) {
      return false;
    }
    return true;
  }

  public void function createSession( ) {
    var tmpSession = {
      "can" = { },
      "auth" = {
        "isLoggedIn" = false,
        "user" = 0,
        "role" = 0,
        "userid" = '',
        "canAccessAdmin" = false
      }
    };
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structClear( session );
      structAppend( session, tmpSession );
    }
  }

  public void function refreshFakeSession( ) {
    createSession( );
    var tempAuth = {
      isLoggedIn = true,
      user = dataService.processEntity( getFakeUser( ) ),
      userid = createUUID( ),
      role = getFakeRole( )
    };
    tempAuth.role.can = yesWeCan;
    tempAuth.canAccessAdmin = true;
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structAppend( session.auth, tempAuth, true );
    }
    variables.auth = tempAuth;
  }

  public void function refreshSession( root.model.contact user ) {
    if( isNull( user ) ) {
      lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
        if( structKeyExists( session, "auth" ) ) {
          var currentAuth = session.auth;
          if( structKeyExists( currentAuth, "userid" ) ) {
            user = entityLoadByPK( "contact", currentAuth.userid );
          }
        }
      }
    }

    createSession( );
    // var securityRole = user.getSecurityrole( );
    var userAsStruct = dataService.processEntity( user, 0, 2 );
    var securityRole = userAsStruct.securityrole;
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
      cachePermissions( user.getSecurityRole() );
      tempAuth.role.can = can;
      tempAuth.canAccessAdmin = false;
    }
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structAppend( session.auth, tempAuth, true );
    }
    variables.auth = tempAuth;
  }

  public string function hashPassword( required string password ) {
    var t = 0;
    var cost = 4;
    while ( t < 500 && cost <= 30 ) {
      var salt = instance.bcrypt.gensalt( cost );
      var hashedPW = instance.bcrypt.hashpw( password, salt );
      // test speed of decryption:
      var start = getTickCount( );
      instance.bcrypt.checkpw( password, hashedPW );
      t = getTickCount( ) - start;
      cost++;
    }
    return hashedPW;
  }

  public boolean function comparePassword( required string password, required string storedPW ) {
    try {
      // FIRST TRY BCRYPT:
      return instance.bcrypt.checkpw( password, storedPW );
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
    if( isNull( roleName ) ) {
      var auth = getAuth( );
      roleName=auth.role.name;
    }

    return roleName == "Administrator" || roleName == "Admin";
  }

  public boolean function yesWeCan( ) {
    return true;
  }

  public boolean function can( string action = "", string section = "" ) {
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      var auth = session.auth;
      param session.can={ };
      var cachedCan = session.can;
    }

    return structKeyExists( cachedCan, "#action#-#section#" );
  }

  public void function cachePermissions( required component securityRole ) {
    var cachedPermissions = { };
    var allPermissions = dataService.processEntity( securityRole.getPermissions( ), 0, 2 );
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

  public struct function getFakeUser( ) {
    return {
      "name" = "Administrator",
      "firstname" = "John",
      "lastname" = "Doe"
    };
  }

  public struct function getFakeRole( ) {
    return {
      "name" = "Administrator",
      "menuList" = ""
    };
  }

  private any function getBCrypt( required string pathToBcrypt ) {
    var system = createObject( "java", "java.lang.System" );
    var javaVersion = listGetAt( system.getProperty( "java.version" ), 2, "." );
    var bCryptLocation = directoryList( pathToBcrypt & "/" & javaVersion, false, "path", "*.jar" );
    var jl = new javaloader.javaloader( bCryptLocation );

    return jl.create( "org.mindrot.jbcrypt.BCrypt" );
  }
}