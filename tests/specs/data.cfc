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

    describe( "reMatchGroups Tests", function ( ) {
      it( "Expects reMatchGroups( '105B', '(\d+)(\D*)' ) to return a 2 dimensional array with 2 array items inside the first", function() {
        var result = dataService.reMatchGroups( '105B', '(\d+)(\D*)' );
        expect( result ).toBeTypeOf( "array" ).toHaveLength( 1 );
        expect( result[ 1 ] ).toBeTypeOf( "array" ).toHaveLength( 3 );
        expect( result[ 1 ][ 1 ] ).toBeTypeOf( "string" ).toBe( "105B" );
        expect( result[ 1 ][ 2 ] ).toBeTypeOf( "string" ).toBe( "105" );
        expect( result[ 1 ][ 3 ] ).toBeTypeOf( "string" ).toBe( "B" );
      } );
    } );
  }
}