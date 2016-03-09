component accessors=true {
  property dataService;

  property type="struct" name="auth";
  property type="struct" name="instance";

  public any function init( config ) {
    var bCryptPath = "#request.root#/lib/java";

    if( structKeyExists( config, "paths" ) && structKeyExists( config.paths, "bcrypt" ) && len( trim( config.paths.bcrypt ))) {
      bCryptPath = config.paths.bcrypt;
    }

    variables.instance.bcrypt = getBCrypt( bCryptPath );
  }

  public struct function getAuth() {
    var result = {};

    if( structKeyExists( variables, "auth" ) && isStruct( variables.auth )) {
      result = variables.auth;
    }

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
      if( structKeyExists( session, "auth" )) {
        result = session.auth;
      }
    }

    if( !isStruct( result )) {
      result = {};
    }

    return result;
  }

  public boolean function authIsValid( required struct auth ) {
    var requiredKeys = [ 'isLoggedIn', 'user', 'userid', 'role' ];

    for( var key in requiredKeys ) {
      if( !structKeyExists( auth, key )) {
        return false;
      }
    }

    if( !len( trim( auth.userid ))) { return false; }
    if( !isStruct( auth.user )) { return false; }
    if( !isStruct( auth.role )) { return false; }
    if( !isBoolean( auth.isLoggedIn )) { return false; }

    return true;
  }

  public void function createSession() {
    var tmpSession = {
      "can" = {},
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

  public void function refreshSession( required root.model.contact user ) {
    createSession();

    var securityRole = user.getSecurityrole();
    var tempAuth = {
      isLoggedIn = true,
      user = dataService.processEntity( user ),
      userid = user.getID(),
      role = dataService.processEntity( securityRole )
    };

    if( isAdmin( securityRole.getName())) {
      tempAuth.role.can = yesWeCan;
      tempAuth.canAccessAdmin = true;
    } else {
      cachePermissions( securityRole );
      tempAuth.role.can = can;
      tempAuth.canAccessAdmin = false;
    }

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      structAppend( session.auth, tempAuth, true );
    }

    setAuth( tempAuth );
  }

  public string function hashPassword( required string password ) {
    var t = 0;
    var cost = 4;

    while( t < 500 && cost <= 30 ) {
      var salt = variables.instance.bcrypt.gensalt( cost );
      var hashedPW = variables.instance.bcrypt.hashpw( password, salt );

      // test speed of decryption:
      var start = getTickCount();
      variables.instance.bcrypt.checkpw( password, hashedPW );
      t = getTickCount() - start;
      cost++;
    }

    return hashedPW;
  }

  public boolean function comparePassword( required string password, required string storedPW ) {
    try {
      // FIRST TRY BCRYPT:
      return variables.instance.bcrypt.checkpw( password, storedPW );
    } catch( Any e ) {
      try {
        // THEN TRY THE OLD SHA-512 WAY:
        var storedsalt = right( storedPW, 16 );

        return 0 == compare( storedPW, hash( password & storedsalt, 'SHA-512' ) & storedsalt );
      } catch( Any e ) {
        return false;
      }
    }
  }

  private any function getBCrypt( required string pathToBcrypt ) {
    var system = createObject( "java", "java.lang.System" );
    var javaVersion = listGetAt( system.getProperty( "java.version" ), 2, "." );
    var bCryptLocation = directoryList( pathToBcrypt & "/" & javaVersion, false, "path", "*.jar" );
    var jl = new javaloader.javaloader( bCryptLocation );

    return jl.create( "org.mindrot.jbcrypt.BCrypt" );
  }

  public boolean function isAdmin( required string roleName ) {
    return ( roleName == "Administrator" || roleName == "Admin" );
  }

  public boolean function yesWeCan() {
    return true;
  }

  public boolean function can( string action="", string section="" ) {
    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="readonly" timeout="5" {
      allPermissions = session.can;
    }

    return structKeyExists( allPermissions, "#action#-#section#" );
  }

  public void function cachePermissions( required component securityRole ) {
    var cachedPermissions = {};
    var allPermissions = dataService.processEntity( securityRole.getPermissions(), 0, 2 );

    for( var permission in allPermissions ) {
      if( !structKeyExists( permission, "section" ) || !len( trim( permission.section ))) {
        continue;
      }

      for( var action in [ "view", "change", "delete", "approve", "create" ]) {
        if( structKeyExists( permission, action ) && isBoolean( permission[action] ) && permission[action] ) {
          cachedPermissions["#action#-#permission.section#"] = true;
        }
      }
    }

    lock name="lock_#request.appName#_#cfid#_#cftoken#" type="exclusive" timeout="5" {
      session.can = cachedPermissions;
    }
  }
}