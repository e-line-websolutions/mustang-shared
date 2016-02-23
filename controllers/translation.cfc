component {
  public void function default( required struct rc ) {
    rc.allLanguages = directoryList( request.root & '/i18n', false, "name" );
  }
}