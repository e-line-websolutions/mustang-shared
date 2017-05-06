component extends="testbox.system.BaseSpec" {
  function run( ) {
    xdescribe( "Complex JSON deserialization", function( ) {
      it( "Expects deserialize to do as it's told", function( ) {
        var jsonFile = fileRead( expandPath( "./testdata/json-file-001.json" ) );

        expect( jsonFile )
          .toBeTypeOf( "string" );

        var jsonService = new services.json();

        expect( jsonService.deserialize( jsonFile ) )
          .notToThrow( "jsonService.deserializeFromJSON.parsingError" );
      } );
    } );
  }
}