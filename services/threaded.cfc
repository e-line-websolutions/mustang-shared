component accessors=true extends="mustang.services.asyncQueue" {
  public component function init( ) {
    param variables.runSingleThreaded=false;
    return super.init( argumentCollection = arguments );
  }

  private void function initThreads( ) {
    if ( variables.runSingleThreaded ) {
      return;
    }

    application.threads = { };
  }

  private string function getThreadName( ) {
    if ( variables.runSingleThreaded ) {
      return "";
    }

    var threadName = createUUID( );

    application.threads[ threadName ] = 1;

    return threadName;
  }

  private void function cleanUpThread( required string threadName ) {
    if ( variables.runSingleThreaded ) {
      return;
    }

    structDelete( application.threads, threadName );
  }

  private numeric function getNumberOfRunningThreads( ) {
    if ( variables.runSingleThreaded ) {
      return 0;
    }

    return !structIsEmpty( application.threads );
  }
}