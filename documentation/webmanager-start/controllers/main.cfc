component accessors=true {
  property framework;
  property webmanagerService;
  property websiteService;

  public void function before( required struct rc ) {
    param rc.pageTemplate='';
    param rc.homepage='main.default';

    webmanagerService.appendPageDataToRequestContext( rc ); // <-- required

    if ( !webmanagerService.actionHasView( rc.action ) ) {
      framework.setView( rc.pageTemplate );
    }

    websiteService.addMediaQueriesToRequestScope( rc );

    rc[ 'stylesheets' ] = [];
    rc[ 'scripts' ] = [];
  }

  public void function home( required struct rc ) {
  }
}
