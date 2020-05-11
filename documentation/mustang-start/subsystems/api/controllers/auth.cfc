component accessors=true {
  property framework;
  property securityService;
  property jsonJavaService;

  public void function logout( required struct rc ) {
    variables.securityService.endSession();
    variables.framework.renderData( "rawjson", variables.jsonJavaService.serialize( { "status" = "logged-out" } ) );
    variables.framework.abortController( );
  }
}