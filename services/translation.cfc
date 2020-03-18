component accessors=true {
  property config;
  property fw;
  property root;

  property logService;
  property utilityService;

  property struct languageStruct;
  property struct translations;

  // CONSTRUCTOR

  public any function init( root, config, fw, logService, utilityService ) {
    structAppend( variables, arguments );
    populateLanguageStruct( );
    param config.defaultLanguage="en_US";
    changeLanguage( config.defaultLanguage );
    return this;
  }

  // PUBLIC

  public string function translate(
    string label,
    string localeID = getLocaleId( ),
    string alternative,
    struct stringVariables = { },
    boolean capFirst = true
  ) {
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

    setLocale( newLanguage );

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

    try {
      param session.currentLanguage=config.defaultLanguage;
      return session.currentLanguage;
    } catch ( any e ) {
      return config.defaultLanguage;
    }
  }

  public void function setLocaleId( required string locale ) {
    param config.useOrm=true;

    if ( config.useOrm ) {
      var defaultLanguageCode = listGetAt( locale, 1, "_" );
      var defaultCountryCode = listGetAt( locale, 2, "_" );
      var language = entityLoad( "language", { "iso2" = defaultLanguageCode }, true );
      var country = entityLoad( "country", { "iso2" = defaultCountryCode }, true );

      if ( !isNull( language ) && !isNull( country ) ) {
        var localeObj = entityLoad( "locale", { country = country, language = language }, true );
      }

      if ( !isNull( localeObj ) ) {
        session.localeID = localeObj.getID( );
      }
    } else {
      session.localeID = locale;
    }
  }

  public string function getLocaleId( ) {
    if ( isNull( session.localeID ) ) {
      setLocaleId( config.defaultLanguage );
    }
    return session.localeID;
  }

  // PRIVATE

  private void function populateLanguageStruct() {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( '<b>i18n</b>: populateLanguageStruct() called.' );
    }

    variables.languageStruct = { 'default' = {} };

    var translationFilesRoot = utilityService.cleanPath( root & '/i18n/' );

    directoryList( translationFilesRoot, true, 'path', '*.json' ).each( function( path ) {
      var justSubDir = replace( utilityService.cleanPath( path, false ), translationFilesRoot, '' ).listToArray( '/' );
      var translationData = deserializeJSON( fileRead( path, 'utf-8' ) );
      var grouping = justSubDir.len() > 1 ? justSubDir[ 1 ] : 'default';
      var locale = listFirst( justSubDir[ justSubDir.len() ], '.' );
      if ( grouping != 'default' && structKeyExists( variables.languageStruct.default, locale ) ) {
        structAppend( translationData, variables.languageStruct.default[ locale ], false );
      }
      variables.languageStruct[ grouping ][ locale ] = translationData;
    } );
  }

  private string function cacheRead(
    required string translation,
    string localeID = getLocaleId( ),
    boolean reload = false,
    string grouping = 'default'
  ) {
    if ( !isNull( fw ) ) {
      fw.frameworkTrace( "<b>i18n</b>: cacheRead() called." );
    }

    try {
      return variables.translations[ localeID ][ translation ];
    } catch ( any e ) {
      var currentLanguage = getCurrentLanguage( );
      if ( structKeyExists( variables.languageStruct[ grouping ], currentLanguage ) &&
           structKeyExists( variables.languageStruct[ grouping ][ currentLanguage ], translation ) ) {
        var translated = variables.languageStruct[ grouping ][ currentLanguage ][ translation ];
        variables.translations[ localeID ][ translation ] = translated;
        return translated;
      }
    }

    return "";
  }
}