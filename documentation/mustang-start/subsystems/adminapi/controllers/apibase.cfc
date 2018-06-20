component accessors=true {
  property utilityService;

  public void function after( rc ) {
    utilityService.setCFSetting( "showdebugoutput", false );
    request.layout = false;
  }

  private String function returnAsJSON( Any variable ) {
    var statusCode = 200; // default
    var statusCodes = {
      "error" = 500,
      "not-allowed" = 405,
      "not-found" = 404,
      "created" = 201,
      "no-content" = 204
    };

    if ( isStruct( variable ) and
        structKeyExists( variable, "status" ) and
        structKeyExists( statusCodes, variable.status ) ) {
      statusCode = statusCodes[ variable.status ];
    }

    var pageContext = getPageContext( );

    if ( listFindNoCase( "lucee,railo", server.ColdFusion.ProductName ) ) {
      pageContext.clear( );
    } else {
      pageContext.getcfoutput( ).clearall( );
    }

    var response = pageContext.getResponse( );

    response.setHeader( "Access-Control-Allow-Origin", "*" );
    response.setStatus( statusCode );
    response.setContentType( 'application/json; charset=utf-8' );

    writeOutput( serializeJSON( variable ) );

    abort;
  }
}