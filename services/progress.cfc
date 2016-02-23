component accessors=true {
  property numeric total;
  property numeric current;
  property numeric prevTime;
  property array timers;
  property boolean done;
  property string status;

  public component function init() {
    reset();
    return this;
  }

  public void function addToTotal() {
    var persisted = getProgress();
    setTotal( persisted.total + 1 );
  }

  public void function updateProgress() {
    var persisted = getProgress();
    setCurrent( persisted.current + 1 );

    if( getPrevTime() > 0 ) {
      var timers = getTimers();
      arrayAppend( timers, getTickCount() - getPrevTime());
      setTimers( timers );
    }

    setPrevTime( getTickCount());
  }

  public void function done() {
    setCurrent( getTotal());
    setDone( true );
  }

  public struct function getProgress() {
    var millis = ( getTotal() - getCurrent()) * arrayAvg( getTimers());
    var minutes = ( millis \ ( 60 * 1000 )) mod 60;
    var seconds = ( millis \ 1000 ) mod 60;
    var timeLeft = createTimespan( 0, 0, minutes, seconds );
    var statusText = getStatus();

    var result = duplicate({
      "total" = getTotal(),
      "current" = getCurrent(),
      "done" = getDone(),
      "status" = statusText,
      "timeLeft" = lsTimeFormat( timeLeft, "mm:ss" ),
      "statusCode" = ( statusText contains "Error" ? 500 : 200 )
    });

    if( getDone()) {
      reset();
    }

    return result;
  }

  public component function getInstance( boolean reInit=false ) {
    if( !reInit ) {
      lock name="progress_#cfid#_#cftoken#" type="readonly" timeout="5" {
        if( !structKeyExists( session, "progress" )) {
          reInit = true;
        }
      }
    }

    if( reInit ) {
      lock name="progress_#cfid#_#cftoken#" type="exclusive" timeout="5" {
        session.progress = init();
      }
    }

    lock name="progress_#cfid#_#cftoken#" type="readonly" timeout="5" {
      var progressInstance = session.progress;
    }

    return progressInstance;
  }

  public void function setStatus( required string status ) {
    variables.status = status;
  }

  private numeric function calculateTime() {
    if( getTotal() == 0 || getCurrent() == 0 || arrayLen( getTimers()) == 0 ) {
      return 0;
    }

    var avgTime = arrayAvg( getTimers()) / 1000; // seconds per step
    var steps = getTotal() / getCurrent(); // number of steps

    return avgTime * steps;
  }

  private void function reset() {
    setTotal( 0 );
    setCurrent( 0 );
    setTimers( [] );
    setDone( true );
    setStatus( "Waiting" );
    setPrevTime( getTickCount());
  }
}