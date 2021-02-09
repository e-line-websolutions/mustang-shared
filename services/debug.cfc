component accessors = true {
  property logService;

  public array function getStackTrace( ) {
    try {
      var oException = createObject( "java", "java.lang.Exception" ).init( );
      return oException.TagContext;
    } catch ( any e ) {
      logService.dumpToFile( oException, true, false );
      return [];
    }
  }
}