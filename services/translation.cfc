component accessors=true {
  property config;
  property fw;
  property root;

  property logService;
  property utilityService;

  property struct languageStruct;
  property struct translations;

  // CONSTRUCTOR

  public any function init( root, config, fw, logService ) {
    structAppend( variables, arguments );
    populateLanguageStruct( );
    param config.defaultLanguage="en_US";
    changeLanguage( config.defaultLanguage );
    return this;
  }

  // PUBLIC

  public string function translate( label, localeID = getLocaleId( ), alternative, stringVariables = { }, capFirst = true ) {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: translate() called." );
    }

    if ( isNull( alternative ) ) {
      arguments.alternative = label;
    }

    var translation = "";

    if ( label == "" && alternative == "" ) {
      translation = "Please provide a label to translate.";
    } else {
      translation = cacheRead( label, localeID, request.reset );
    }

    if ( !len( trim( translation ) ) ) {
      translation = capFirst
        ? replace( utilityService.capFirst( alternative ), "-", " ", "all" )
        : alternative;

      // Try some default translation options on FQAs
      if ( listLen( "padding" & label, ":" ) == 2 && listLen( "padding" & label, "." ) == 2 ) {
        var subsystem = replace( listFirst( "padding" & label, ":" ), "padding", "", "one" );
        var section = replace( listFirst( listRest( "padding" & label, ":" ), "." ), "padding", "", "one" );
        var item = replace( listRest( listRest( "padding" & label, ":" ), "." ), "padding", "", "one" );

        if ( label == "#subsystem#:#section#.default" ) {
          translation = "{#subsystem#:#section#}";
        }

        if ( label == "#subsystem#:#section#.view" ) {
          translation = "{#section#}";
        }

        if ( label == "#subsystem#:#section#.edit" ) {
          translation = "{btn-edit} {#section#}";
        }

        if ( label == "#subsystem#:#section#.new" ) {
          translation = "{btn-new} {#section#}";
        }

        if ( listFirst( label, "-" ) == "btn" ) {
          translation = "{btn-#item#} {#section#}";
        }
      } else if ( listLen( "padding" & label, ":" ) == 2 ) {
        translation = "{#listLast( label, ':' )#s}";
      } else if ( listLen( label, "-" ) gte 2 && listFirst( label, "-" ) == "placeholder" ) {
        translation = "{placeholder} {#listRest( label, '-' )#}";
      }
    }

    var result = utilityService.parseStringVariables( translation, stringVariables );

    // replace {label} with whatever comes out of translate( 'label' )
    for ( var _label_ in REMatchNoCase( '{[^}]+}', result ) ) {
      result = replaceNoCase( result, _label_, translate( mid( _label_, 2, len( _label_ ) - 2 ) ) );
    }

    return result;
  }

  public void function changeLanguage( string newLanguage ) {
    if ( isNull( newLanguage ) || !len( newLanguage ) ) {
      newLanguage = config.defaultLanguage;
    }

    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: changeLanguage( #newLanguage# ) called." );
    }

    var currentLanguage = getCurrentLanguage( );

    if ( newLanguage == currentLanguage ) {
      return;
    }

    session.currentLanguage = newLanguage;

    setLocaleId( newLanguage );

    logService.writeLogLevel( "Changed language from #currentLanguage# to #newLanguage#." );
  }

  public string function getCurrentLanguage( ) {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: getCurrentLanguage() called." );
    }

    param session.currentLanguage=config.defaultLanguage;
    return session.currentLanguage;
  }

  public void function setLocaleId( required string locale ) {
    param config.useOrm=true;
    if ( config.useOrm ) {
      var defaultLanguageCode = listGetAt( locale, 1, "_" );
      var defaultCountryCode = listGetAt( locale, 2, "_" );
      var language = entityLoad( "language", { "iso2" = defaultLanguageCode }, true );
      var country = entityLoad( "country", { "iso2" = defaultCountryCode }, true );

      if ( !isNull( language ) && !isNull( country ) ) {
        var localeObj = entityLoad( "locale",
                                 {
                                   country = country,
                                   language = language
                                 },
                                 true );
      }

      if ( !isNull( localeObj ) ) {
        session.localeID = localeObj.getID( );
      }
    } else {
      session.localeID = locale;
    }
  }

  public function getLocaleId( ) {
    if ( isNull( session.localeID ) ) {
      setLocaleId( config.defaultLanguage );
    }
    return session.localeID;
  }

  // PRIVATE

  private void function populateLanguageStruct( ) {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: populateLanguageStruct() called." );
    }

    variables.languageStruct = { };

    var translationFiles = directoryList( root & "/i18n/", false, "path", "*.json" );

    for ( var jsonFile in translationFiles ) {
      var jsonFileContents = fileRead( jsonFile, "utf-8" );
      var locale = listFirst( listLast( jsonFile, "/\" ), "." );
      variables.languageStruct[ locale ] = deserializeJson( jsonFileContents );
    }
  }

  private string function cacheRead( required string translation, string localeID = getLocaleId( ), boolean reload = false ) {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: cacheRead() called." );
    }

    if ( reload ) {
      variables.translations = { };
    }

    try {
      return variables.translations[ localeID ][ translation ];
    } catch ( any e ) {
      var currentLanguage = getCurrentLanguage( );
      if ( structKeyExists( variables.languageStruct, currentLanguage ) &&
           structKeyExists( variables.languageStruct[ currentLanguage ], translation ) ) {
        var translated = variables.languageStruct[ currentLanguage ][ translation ];
        variables.translations[ localeID ][ translation ] = translated;
        return translated;
      }
    }

    return "";
  }
}