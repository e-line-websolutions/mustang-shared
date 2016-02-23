component accessors=true {
  property jsonService;
  property utilityService;

  property struct languageStruct;
  property string localeID;

  public any function init( root, config, jsonService ) {
    var jsonFile = root & "/i18n/" & config.defaultLanguage & ".json";
    var jsonFileContents = fileRead( jsonFile, "utf-8" );
    var lanStruct = jsonService.deserialize( jsonFileContents );

    setLanguageStruct( lanStruct );

    var defaultLanguageCode = listGetAt( config.defaultLanguage, 1, "_" );
    var defaultCountryCode = listGetAt( config.defaultLanguage, 2, "_" );
    var language = entityLoad( "language", { "iso2" = defaultLanguageCode }, true );
    var country = entityLoad( "country", { "iso2" = defaultCountryCode }, true );

    if( !isNull( language ) && !isNull(country) ) {
      var locale = entityLoad( "locale" , { country = country, language = language }, true );
    }

    if( !isNull( locale )) {
      setLocaleID( locale.getID());
    }

    return this;
  }

  public string function translate( label, localeID=getLocaleID(), alternative, stringVariables={}, capFirst=true ) {
    if( isNull( alternative )) {
      arguments.alternative = label;
    }

    var translation = "";

    if( label == "" && alternative == "" ) {
      translation = "Please provide a label to translate.";
    } else {
      translation = cacheRead( label, localeID, request.reset );
    }

    if( !len( trim( translation ))) {
      translation = capFirst ? utilityService.capFirst( alternative ) : alternative;

      // Try some default translation options on FQAs
      if( listLen( "padding" & label, ":" ) == 2 && listLen( "padding" & label, "." ) == 2 ) {
        var subsystem  = replace( listFirst( "padding" & label, ":" ), "padding", "", "one" );
        var section    = replace( listFirst( listRest( "padding" & label, ":" ), "." ), "padding", "", "one" );
        var item       = replace( listRest( listRest( "padding" & label, ":" ), "." ), "padding", "", "one" );

        if( label == "#subsystem#:#section#.default" ) {
          translation = "{#subsystem#:#section#}";
        }

        if( label == "#subsystem#:#section#.view" ) {
          translation = "{#section#}";
        }

        if( label == "#subsystem#:#section#.edit" ) {
          translation = "{btn-edit} {#section#}";
        }

        if( label == "#subsystem#:#section#.new" ) {
          translation = "{btn-new} {#section#}";
        }

        if( listFirst( label, "-" ) == "btn" ) {
          translation = "{btn-#item#} {#section#}";
        }
      } else if( listLen( "padding" & label, ":" ) == 2 ) {
        translation = "{#listLast( label, ':' )#s}";
      } else if( listLen( label, "-" ) gte 2 && listFirst( label, "-" ) == "placeholder" ) {
        translation = "{placeholder} {#listRest( label, '-' )#}";
      }
    }

    var result = parseStringVariables( translation, stringVariables );

    // replace {label} with whatever comes out of translate( 'label' )
    for( var _label_ in REMatchNoCase( '{[^}]+}', result )) {
      result = replaceNoCase( result, _label_, translate( mid( _label_, 2, len( _label_ ) - 2 )));
    }

    return result;
  }

  public string function cacheRead( required string translation, string localeID = getLocaleID(), boolean reload = false ) {
    var result = "";

    // SEARCH CACHE FOR LABEL:
    lock name="fw1_#application.applicationName#_translations_#localeID#" type="exclusive" timeout="30" {
      if( reload ) {
        structDelete( application, "translations" );
      }

      if( structKeyExists( application, "translations" ) &&
          structKeyExists( application.translations, localeID ) &&
          structKeyExists( application.translations[localeID], translation )) {
        result = application.translations[localeID][translation];
      } else {
        if( !structKeyExists( application, "translations" )) {
          application.translations = {};
        }

        if( !structKeyExists( application.translations, localeID )) {
          application.translations[localeID] = {};
        }

        if( !structKeyExists( application.translations[localeID], translation )) {
          var lanStruct = getLanguageStruct();
          if( structKeyExists( lanStruct, translation )) {
            application.translations[localeID][translation] = lanStruct[translation];
          }
        }

        if( structKeyExists( application.translations[localeID], translation )) {
          result = application.translations[localeID][translation];
        }
      }
    }

    return result;
  }

  public string function parseStringVariables( required string stringToParse, struct stringVariables = {} ) {
    if( isNull( stringVariables ) || !structCount( stringVariables )) {
      return stringToParse;
    }

    for( var key in stringVariables ) {
      stringToParse = replaceNoCase( stringToParse, '###key###', stringVariables[key] );
    }

    return stringToParse;
  }
}