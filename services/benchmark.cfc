component {
  resetTimers( );

  function init( ) {
    variables.system = createObject( "java", "java.lang.System" );

    return this;
  }

  function start( timer = createUUID() ) {
    stop( );
    currentTimer = {
      name = timer,
      time = system.nanoTime( )
    };
  }

  function stop( ) {
    var timeNow = system.nanoTime( );

    if ( !structKeyExists( variables, "currentTimer" ) ) {
      return;
    }

    var timerName = currentTimer.name;

    if ( !structKeyExists( timers, timerName ) ) {
      timers[ timerName ] = [ ];
    }

    arrayAppend( timers[ timerName ], timeNow - currentTimer.time );

    structDelete( variables, "currentTimer" );
  }

  function output( unit = 'ms' ) {
    var divider = 1;

    switch ( unit ) {
      case 'milli':
      case 'ms':
        divider = 1000000;
        break;
      case 'micro':
        divider = 1000;
        break;
      case 'nano':
        divider = 1;
        break;
    }

    writeOutput( '<table>' );

    structDelete( timers, "Calibration" );

    for ( var key in timers ) {
      writeOutput( '<tr><td>#key#:</td><td>#numberFormat( arrayAvg( timers[ key ] ) / divider, '.00' )#</td></tr>' );
    }

    writeOutput( '<table>' );

    writeOutput( outputServerInfo( ) );

    resetTimers( );
  }

  private function resetTimers( ) {
    timers = structNew( "ordered" );
  }

  private function outputServerInfo( ) {
    var result = "CF Server: " & server.coldfusion.productName;

    if ( structKeyExists( server, "lucee" ) ) {
      result &= " " & server.lucee.version;
    } else {
      result &= " " & server.coldfusion.productVersion;
    }

    result &= "<br>Java Version: #system.getProperty( 'java.version' )#";

    return result;
  }
}