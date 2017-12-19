component extends="testbox.system.BaseSpec" {
  variables.utilityService = new services.utility();

  function run( ) {
    describe( "Encryption Tests", function( ) {
      it( "Expects string to be encrypted to a URL compatible format", function( ) {
        var input = createUUID();
        var encryptKey = "zacFKf3y28vYrA72en2hm3qnNugeN2ye"; //utilityService.generatePassword( 16 );
        var encryptedString = utilityService.encryptForUrl( input, encryptKey );
        var decryptedString = utilityService.decryptForUrl( encryptedString, encryptKey );

        expect( decryptedString ).toBe( input );
      } );
    } );
  }
}