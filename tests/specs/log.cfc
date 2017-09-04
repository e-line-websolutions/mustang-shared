component extends="testbox.system.BaseSpec" {
  function run( ) {
    describe( "Test writing to log at different levels", function( ) {
      it( "Expects writing at a level LOWER than the log threshold to NOT show up in logs", function( ) {
        request.appName = "mustangSharedTests";
        var logService = new services.log( {
          debugEmail = "bugs@mstng.info",
          logLevel = "information",
          showDebug = false
        } );

        expect( logService.writeLogLevel( text = "test", level = "debug" ) ).toBeFalse( );
      } );

      it( "Expects writing at a level HIGHER than the log threshold to show up in logs", function( ) {
        request.appName = "mustangSharedTests";
        var logService = new services.log( {
          debugEmail = "bugs@mstng.info",
          logLevel = "debug",
          showDebug = false
        } );

        expect( logService.writeLogLevel( text = "test", level = "information" ) ).toBeTrue( );
      } );

      it( "Expects writing at a the same level as the log threshold to show up in logs", function( ) {
        request.appName = "mustangSharedTests";
        var logService = new services.log( {
          debugEmail = "bugs@mstng.info",
          logLevel = "information",
          showDebug = false
        } );

        expect( logService.writeLogLevel( text = "test", level = "information" ) ).toBeTrue( );
      } );
    } );
  }
}