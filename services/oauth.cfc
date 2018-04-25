component {
  variables.tokenName = "access_token";

  public boolean function hasValidOauthAccessToken( ) {
    var storedOauth = getOauth( );

    if ( structIsEmpty( storedOauth ) ) {
      return false;
    }

    if ( !len( getOauthKey( variables.tokenName ) ) ) {
      return false;
    }

    if ( dateDiff( "s", storedOauth.store_date, now( ) ) > getOauthKey( "store_date" ) ) {
      return false;
    }

    return true;
  }

  public void function storeOauth( oauth ) {
    oauth.store_date = now( );
    application.oauth = oauth;
  }

  public struct function getOauth( ) {
    if ( !structKeyExists( application, "oauth" ) ) {
      return { };
    }
    return application.oauth;
  }

  public any function getOauthKey( key ) {
    var tmp = getOauth( );

    if ( !structKeyExists( tmp, key ) ) {
      return "";
    }

    return tmp[ key ];
  }
}