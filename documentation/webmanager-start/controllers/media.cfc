component accessors=true {
  property webmanagerService;
  property framework;

  public void function load( required struct rc ) {
    try {
      variables.webmanagerService.serveMedia( rc );
    } catch ( webmanagerService.serveMedia.fileNotFoundError e ) {
      variables.framework.renderData( "text", e.message, 404 );
    }
  }
}