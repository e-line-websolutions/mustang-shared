component extends="com.adobe.coldfusion.base" {
  public function cacheScriptObjects( ) {
    var tags = [
      "CFFTP",
      "CFHTTP",
      "CFMAIL",
      "CFPDF",
      "CFQUERY",
      "CFPOP",
      "CFIMAP",
      "CFFEED",
      "CFLDAP"
    ];

    for( var tag in tags ) {
      getSupportedTagAttributes( tag );
    }
  }
}