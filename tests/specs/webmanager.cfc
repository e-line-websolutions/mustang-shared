component extends="testbox.system.BaseSpec" {
  variables.webmanagerService = new services.webmanagerService( );

  function run( ) {
    describe( "Webmanager Unit Tests", function( ) {
      it( "Expects webmanager to initialize", function( ) {
writeDump(webmanagerService);
      } );
    } );
  }
}