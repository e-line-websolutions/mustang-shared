component accessors=true {
  property fw;
  property root;
  property config;

  function translations() {
    fw.renderData( "rawjson", fileRead( "#root#/i18n/#config.defaultLanguage#.json", "utf-8" ) );
  }
}