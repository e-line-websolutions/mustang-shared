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

        expect( logService.writeLogLevel( text = "test 1", level = "debug" ) ).toBeFalse( );
      } );

      it( "Expects writing at a level HIGHER than the log threshold to show up in logs", function( ) {
        request.appName = "mustangSharedTests";
        var logService = new services.log( {
          debugEmail = "bugs@mstng.info",
          logLevel = "debug",
          showDebug = false
        } );

        expect( logService.writeLogLevel( text = "test 2", level = "information" ) ).toBeTrue( );
      } );

      it( "Expects writing at a the same level as the log threshold to show up in logs", function( ) {
        request.appName = "mustangSharedTests";
        var logService = new services.log( {
          debugEmail = "bugs@mstng.info",
          logLevel = "information",
          showDebug = false
        } );

        expect( logService.writeLogLevel( text = "test 3", level = "information" ) ).toBeTrue( );
      } );
    } );

    describe( "Test dumpToFile() in nested thread", function( ) {
      beforeEach( function( ) {
        request.appName = "mustangSharedTests";
        logService = new services.log( config = {
          debugEmail = "bugs@mstng.info",
          logLevel = "debug",
          showDebug = true
        }, utilityService = new services.utility( ) );
      } );

      it( "Expects dumpToFile() to choose direct writing when nested inside another thread", function( ) {
        expect( function ( ) {
          thread name="t1" logService=logService {
            logService.dumpToFile( { "testData" = true } );
          }
        } ).notToThrow( );

        thread action="join" name="t1";
      } );

      it( "Expects dumpToFile() to choose threaded writing when on the main thread", function( ) {
        expect( function ( ) {
          logService.dumpToFile( { "testData" = true } );
        } ).notToThrow( );
      } );
    } );
  }
}