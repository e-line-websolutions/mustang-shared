component accessors=true {
  property localeService;

  public void function load( required struct rc ) {
    var defaultLanguage = rc.config.defaultLanguage;
    var localeID = createUUID();
    var reload = false;

    lock scope="session" timeout=5 {
      if( !structKeyExists( cookie, "localeID" ) ||
          !structKeyExists( session, "localeID" ) ||
          !structKeyExists( session, "locale" ) ||
          structKeyExists( url, "localeID" ) ||
          request.reset ) {
        reload = true;
      }
    }

    if( reload ) {
      if( structKeyExists( rc, "localeID" ) && len( trim( rc.localeID ))) {
        localeID = rc.localeID;
      }

      if( !len( trim( localeID )) && structKeyExists( cookie, "localeID" ) && len( trim( cookie.localeID ))) {
        localeID = cookie.localeID;
      }

      if( !len( trim( localeID ))) {
        lock scope="session" timeout=5 {
          if( structKeyExists( session, "localeID" ) && len( trim( session.localeID ))) {
            localeID = session.localeID;
          }
        }
      }

      var locale = localeService.get( localeID ); // entityLoadByPK( "locale", localeID );

      if( isNull( locale ) && len( trim( defaultLanguage ))) {
        var defaultLanguageCode = listGetAt( defaultLanguage, 1, "_" );
        var defaultCountryCode = listGetAt( defaultLanguage, 2, "_" );
        var language = entityLoad( "language", { "iso2" = defaultLanguageCode }, true );
        var country = entityLoad( "country", { "iso2" = defaultCountryCode }, true );

        if( !isNull( language ) && !isNull(country) ) {
          var locale = entityLoad( "locale" , { country = country, language = language }, true );
        }

        if( isNull( locale )) {
          var locale = entityNew( "locale" );

          if( isNull( language )) {
            var language = entityNew( "language" );
            language.setISO2( defaultLanguageCode );
          }

          if( isNull( country )) {
            var country = entityNew( "country" );
            country.setISO2( defaultCountryCode );
          }

          locale.setID( localeID );
          locale.setLanguage( language );
          locale.setCountry( country );
        }
      }

      localeID = locale.getID();

      var localeCode = locale.getCode();

      if( !isNull( localeCode ) &&
          len( trim( localeCode ))) {
        setLocale( localeCode );
      }

      lock scope="session" timeout=5 type="exclusive" {
        cookie.localeID = localeID;
        session.localeID = localeID;
        session.locale = locale;
        rc.currentlocaleID = localeID;
        rc.currentlocale = locale;
      }
    }

    lock scope="session" timeout=5 {
      rc.currentlocaleID = session.localeID;
      rc.currentlocale = session.locale;
    }
  }
}