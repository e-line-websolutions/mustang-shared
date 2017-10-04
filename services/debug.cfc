component accessors = true {
  public array function getStackTrace( ) {
    var oException = createObject( "java", "java.lang.Exception" ).init( );
    return oException.TagContext;
  }
}