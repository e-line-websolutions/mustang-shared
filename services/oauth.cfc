component {
  variables.tokenName = "access_token";

  public boolean function hasValidOauthAccessToken( string app = "default" ) {
    var storedOauth = getOauth( app );

    if ( structIsEmpty( storedOauth ) ) {
      return false;
    }

    if ( !len( getOauthKey( variables.tokenName ) ) ) {
      return false;
    }

    if ( dateDiff( "s", storedOauth.store_date, now( ) ) > getOauthKey( "store_date", app ) ) {
      return false;
    }

    return true;
  }

  public void function storeOauth( oauth, string app = "default" ) {
    oauth.store_date = now( );
    application[app] = {
      oauth = oauth
    };
  }

  public struct function getOauth( string app = "default" ) {
    if ( !structKeyExists( application, app ) || !structKeyExists( application[app], "oauth" ) ) {
      return { };
    }
    return application[app].oauth;
  }

  public any function getOauthKey( key, string app = "default" ) {
    var tmp = getOauth( app );

    if ( !structKeyExists( tmp, key ) ) {
      return "";
    }

    return tmp[ key ];
  }
}
