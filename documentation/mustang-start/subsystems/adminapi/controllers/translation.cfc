component extends="apibase"{
  request.layout = false;

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  public void function list( struct rc ){
    param string rc.label = "";

    var result = {
      "status" = "ok",
      "data" = []
    };

    var languageStructs = {};
    var allLabels = [];
    var allLanguages = getTranslationFiles();

    for( var language in allLanguages ){
      var lanCode = listFirst( language, "." );

      languageStructs[lanCode] = readTranslationFile( lanCode );

      if( len( trim( rc.label ))){
        allLabels = [ rc.label ];
      }
      else{
        for( var key in languageStructs[lanCode] ){
          if( not arrayFindNoCase( allLabels, key )){
            arrayAppend( allLabels, key );
          }
        }
      }
    }

    arraySort( allLabels, "textNoCase" );

    for( var label in allLabels ){
      var row = {
        "id" = label,
        "label" = label
      };

      for( var language in allLanguages ){
        var lanCode = listFirst( language, "." );

        if( structKeyExists( languageStructs[lanCode], label )){
          row[lanCode] = languageStructs[lanCode][label];
        }
      }

      arrayAppend( result.data, row );
    }

    returnAsJSON( result );
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  public void function remove( struct rc ){
    try{
      var allLanguages = getTranslationFiles();

      for( language in allLanguages )
      {
        var lanCode = listFirst( language, "." );
        lock timeout=5 scope="application"{
          var translations = readTranslationFile( lanCode );
          for( var label in listToArray( rc.labels ))
          {
            structDelete( translations, label );
          }
          writeTranslationFile( lanCode, translations );
        }
      }
      returnAsJSON({ "status" = "ok" });
    }
    catch( any e ){
      returnAsJSON({ "status" = "error", "message" = e.message, "detail" = e.detail });
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  public void function save( struct rc ){
    try{
      lock timeout=5 scope="application"{
        var translations = readTranslationFile( language );
        translations[rc.name] = rc.value;
        writeTranslationFile( language, translations );
      }
      returnAsJSON({ "status" = "ok", "data" = {
        "label" = rc.name,
        "#rc.language#" = rc.value
      }});
    }
    catch( any e ){
      returnAsJSON({ "status" = "error", "message" = e.message });
    }
  }





  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  private array function getTranslationFiles(){
    try{
      return directoryList( request.root & '/i18n', false, "name" );
    }
    catch( any e ){
      return [];
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  private struct function readTranslationFile( required string language ){
    try{
      return deserializeJSON( fileRead( "#request.root#/i18n/#language#.json", "utf-8" ));
    }
    catch( any e ){
      return {};
    }
  }

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  private void function writeTranslationFile( required string language, required any data ){
    try{
      fileWrite( "#request.root#/i18n/#language#.json", serializeJSON( data ), "utf-8" );
    }
    catch( any e ){}
  }
}