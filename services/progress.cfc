component accessors=true {
  property array timers;
  property boolean done;
  property numeric current;
  property numeric prevTime;
  property numeric total;
  property string status;

  public component function init( ) {
    reset( );
    return this;
  }

  public void function addToTotal( ) {
    var persisted = getProgress( );
    variables.total = persisted.total + 1;
  }

  public void function updateProgress( ) {
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
    variables.current = variables.total;
    variables.done = true;
  }

  public struct function getProgress( ) {
    var statusText = variables.status;

    var result = duplicate(
      {
        "current" = variables.current,
        "done" = variables.done,
        "status" = statusText,
        "statusCode" = ( statusText contains "Error" ? 500 : 200 ),
        "timeLeft" = getCalculatedTimeLeft( ),
        "total" = variables.total
      }
    );

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
    writeLog( text = "#variables.name# - " & status, file = "progressService" );
    variables.status = status;
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
    variables.total = 0;
    variables.current = 0;
    variables.timers = [ ];
    variables.done = true;
    variables.status = "Waiting";
    variables.prevTime = getTickCount( );
    variables.name = createUUID( );
  }

  private string function getCalculatedTimeLeft( ) {
    var millis = ( variables.total - variables.current ) * arrayAvg( variables.timers );
    var days = ( millis \ ( 24 * 60 * 60 * 1000 ) ) mod 60;
    var hours = ( millis \ ( 60 * 60 * 1000 ) ) mod 60;
    var minutes = ( millis \ ( 60 * 1000 ) ) mod 60;
    var seconds = ( millis \ 1000 ) mod 60;

    return "#numberFormat( days, '00' )#:#numberFormat( hours, '00' )#:#numberFormat( minutes, '00' )#:#numberFormat( seconds, '00' )#";
  }
}