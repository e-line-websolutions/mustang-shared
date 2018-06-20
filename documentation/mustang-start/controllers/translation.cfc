component accessors=true {
  property root;
  property config;

  public void function default( required struct rc ) {
    rc.allLanguages = directoryList( root & '/i18n', false, "name" );
  }
}