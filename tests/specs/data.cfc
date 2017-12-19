component extends="testbox.system.BaseSpec" {
  variables.dataService = new services.data( );

  function run( ) {
    describe( "GUID Tests", function( ) {
      it( "Expects isGuid to work", function( ) {
        expect( dataService.isGuid( 'C56A4180-65AA-42EC-A945-5FD21DEC0538' ) ).toBeTrue( );
        expect( dataService.isGuid( 'C56A4180-65AA-42EC-A945-5FD21DEC0538', true ) ).toBeTrue( );
        expect( dataService.isGuid( createUUID( ) ) ).toBeTrue( );
        expect( dataService.isGuid( createUUID( ), true ) ).toBeFalse( );
      } );
    } );
  }
}