component extends="testbox.system.BaseSpec" {
  function run( ) {
    describe( "Complex JSON deserialization", function( ) {
      it( "Expects deserialize to do as it's told", function( ) {
        var jsonFile = fileRead( expandPath( "./testdata/json-file-001.json" ) );

        expect( jsonFile ).toBeTypeOf( "string" );

        var jsonService = new services.json( );

        expect( function( ){
          jsonService.deserialize( jsonFile );
        } ).notToThrow( "jsonService.deserializeFromJSON.parsingError" );

        var jsonJavaService = new services.jsonJava( );

        expect( function( ){
          jsonJavaService.deserialize( jsonFile );
        } ).notToThrow( );
      } );
    } );
  }
}