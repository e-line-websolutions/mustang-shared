component accessors=true {
  property array timers;
  property boolean done;
  property numeric current;
  property numeric prevTime;
  property numeric total;
  property string status;
  property string enabled;

  property logService;

  public component function init( ) {
    reset( );
    return this;
  }

  public void function addToTotal( ) {
    if ( !variables.enabled ) {
      return;
    }
    var persisted = getProgress( );
    variables.total = persisted.total + 1;
  }

  public void function updateProgress( ) {
    if ( !variables.enabled ) {
      return;
    }
    var persisted = getProgress( );
    variables.current = persisted.current + 1;

    if ( variables.prevTime > 0 ) {
      var timers = variables.timers;
      arrayAppend( timers, getTickCount( ) - variables.prevTime );
      variables.timers = timers;
    }

    variables.prevTime = getTickCount( );
  }

  public void function done( ) {
    if ( !variables.enabled ) {
      return;
    }
    variables.current = variables.total;
    variables.done = true;
  }

  public struct function getProgress( ) {
    if ( !variables.enabled ) {
      return {
        "current" = 0,
        "done" = true,
        "status" = "not-monitored",
        "statusCode" = 200,
        "timeLeft" = "00:00:00:00",
        "total" = 0
      };
    }

    var result = {
      "current" = variables.current,
      "done" = variables.done,
      "status" = variables.status,
      "statusCode" = ( variables.status contains "Error" ? 500 : 200 ),
      "timeLeft" = getCalculatedTimeLeft( ),
      "total" = variables.total
    };

    if ( variables.done ) {
      reset( );
    }

    return result;
  }

  public component function getInstance( boolean reInit = false ) {
    if ( !reInit ) {
      lock name="progress_#cfid#_#cftoken#" type="readonly" timeout="5" {
        if ( !structKeyExists( session, "progress" ) ) {
          reInit = true;
        }
      }
    }

    if ( reInit ) {
      lock name="progress_#cfid#_#cftoken#" type="exclusive" timeout="5" {
        session.progress = init( );
      }
    }

    lock name="progress_#cfid#_#cftoken#" type="readonly" timeout="5" {
      var progressInstance = session.progress;
    }

    return progressInstance;
  }

  public void function setStatus( required string status ) {
    if ( !variables.enabled ) {
      return;
    }
    logService.writeLogLevel( "#variables.name# - " & status, "progressService", "information" );
    variables.status = status;
  }

  public void function disable( ) {
    variables.enabled = false;
  }

  private numeric function calculateTime( ) {
    if ( variables.total == 0 || variables.current == 0 || arrayLen( variables.timers ) == 0 ) {
      return 0;
    }

    var avgTime = arrayAvg( variables.timers ) / 1000; // seconds per step
    var steps = variables.total / variables.current; // number of steps

    return avgTime * steps;
  }

  private void function reset( ) {
    variables.enabled = true;
    variables.total = 0;
    variables.current = 0;
    variables.timers = [ ];
    variables.done = true;
    variables.status = "Waiting";
    variables.prevTime = getTickCount( );
    variables.name = createUUID( );
  }

  private string function getCalculatedTimeLeft( ) {
    try {
      var millis = ( variables.total - variables.current ) * arrayAvg( variables.timers );
      var days = ( millis \ ( 24 * 60 * 60 * 1000 ) ) mod 60;
      var hours = ( millis \ ( 60 * 60 * 1000 ) ) mod 60;
      var minutes = ( millis \ ( 60 * 1000 ) ) mod 60;
      var seconds = ( millis \ 1000 ) mod 60;
    } catch ( any e ) {
      return "Out of range";
    }

    return "#numberFormat( days, '00' )#:#numberFormat( hours, '00' )#:#numberFormat( minutes, '00' )#:#numberFormat( seconds, '00' )#";
  }
}