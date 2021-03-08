component extends="testbox.system.BaseSpec" {
  variables.dataService = new services.data( );

  function run( ) {
    describe( "isGUID function", function( ) {
      it( "knows C56A4180-65AA-42EC-A945-5FD21DEC0538 to be a valid GUID", function( ) { expect( dataService.isGUID( 'C56A4180-65AA-42EC-A945-5FD21DEC0538' ) ).toBeTrue( ); } );
      it( "knows C56A4180-65AA-42EC-A945-5FD21DEC0538 to be a valid GUID using strict method", function( ) { expect( dataService.isGUID( 'C56A4180-65AA-42EC-A945-5FD21DEC0538', true ) ).toBeTrue( ); } );
      it( "accepts CF's createUUID() to be valid", function( ) { expect( dataService.isGUID( createUUID( ) ) ).toBeTrue( ); } );
      it( "knows CF's createUUID() to be invalid using strict", function( ) { expect( dataService.isGUID( createUUID( ), true ) ).toBeFalse( ); } );
      it( "doesn't error when no value is given", function( ) { expect( dataService.isGUID() ).toBeFalse( ); } );
      it( "doesn't error on a null value", function( ) { expect( dataService.isGUID( javaCast( 'null', 0 ) ) ).toBeFalse( ); } );
      it( "knows a non GUID is not valid", function( ) { expect( dataService.isGUID( 'this is not a GUID' ) ).toBeFalse( ); } );
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