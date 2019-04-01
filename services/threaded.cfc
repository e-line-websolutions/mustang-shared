component accessors=true extends="mustang.services.asyncQueue" {
  private void function initThreads( ) {
    application.threads = { };
  }

  private string function getThreadName( ) {
    var threadName = createUUID( );
    application.threads[ threadName ] = 1;
    return threadName;
  }

  private void function cleanUpThread( required string threadName ) {
    structDelete( application.threads, threadName );
    createObject( 'java', 'java.lang.System' ).gc();
  }

  private numeric function getNumberOfRunningThreads( ) {
    return !structIsEmpty( application.threads );
  }
}