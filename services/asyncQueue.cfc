component accessors=true {
  // Taken from http://www.bennadel.com/blog/2528-asynctaskqueue-cfc---running-low-priority-tasks-in-a-single-cfthread.htm
  // de-ben-ified by mjhagen.

  // constructor

  public any function init( ) {
    variables.taskQueue = [ ];
    variables.taskQueueID = lcase( createUUID( ) );
    variables.asyncTaskThreadIndex = 1;
    variables.asyncTaskThreadName = getNewAsyncThreadName( );
    variables.isThreadRunning = false;
    variables.asyncTaskLockName = getAsyncTaskLockName( );
    variables.asyncTaskLockTimeout = 30;

    return this;
  }

  // public methods

  public void function addTask( required any taskMethod, any taskArguments = structNew() ) {
    lock name=variables.asyncTaskLockName timeout=variables.asyncTaskLockTimeout {
      addNewTaskItem( taskMethod, taskArguments );

      if ( variables.isThreadRunning ) {
        return;
      }

      variables.isThreadRunning = true;

      thread action="run" name=variables.asyncTaskThreadName priority="low" {
        do {
          lock name=variables.asyncTaskLockName timeout=variables.asyncTaskLockTimeout {
            var taskItem = getNextTaskItem( );
          }

          while ( structKeyExists( local, "taskItem" ) ) {
            try {
              taskItem.taskMethod( argumentCollection = taskItem.taskArguments );
            } catch ( any e ) {
              savecontent variable="debug" {
                writeDump( taskItem.taskArguments );
                writeDump( e );
              }
              fileWrite( "C:\TEMP\THREADOUTPUT\error-#variables.asyncTaskThreadName#.html", debug );
              // throw( "Error in thread, see C:\TEMP\THREADOUTPUT" );
            }

            lock name=variables.asyncTaskLockName timeout=variables.asyncTaskLockTimeout {
              taskItem = getNextTaskItem( );
            }
          }

          lock name=variables.asyncTaskLockName timeout=variables.asyncTaskLockTimeout {
            var isQueueEmpty = !arrayLen( variables.taskQueue );
            var isQueueFull = !isQueueEmpty;

            if ( isQueueEmpty ) {
              variables.isThreadRunning = false;
              variables.asyncTaskThreadName = getNewAsyncThreadName( );
            }
          }
        } while ( isQueueFull );
      }
    }
  }

  // private methods

  private void function addNewTaskItem( required any taskMethod, required any taskArguments ) {
    if ( isArray( taskArguments ) ) {
      taskArguments = convertArgumentsArrayToCollection( taskArguments );
    }

    arrayAppend(
      variables.taskQueue,
      {
        taskMethod = taskMethod,
        taskArguments = taskArguments
      }
    );
  }

  private struct function convertArgumentsArrayToCollection( required array argumentsArray ) {
    var argumentsCollection = getEmptyArgumentsCollection( );

    for ( var i = 1 ; i <= arrayLen( argumentsArray ) ; i++ ) {
      argumentsCollection[ i ] = argumentsArray[ i ];
    }

    return argumentsCollection;
  }

  private string function getAsyncTaskLockName( ) {
    return "lock-#variables.taskQueueID#";
  }

  private any function getEmptyArgumentsCollection( ) {
    return arguments;
  }

  private string function getNewAsyncThreadName( ) {
    var index =++ variables.asyncTaskThreadIndex;

    return "thread-#variables.taskQueueID#-#index#";
  }

  private any function getNextTaskItem( ) {
    if ( arrayLen( variables.taskQueue ) ) {
      var taskItem = variables.taskQueue[ 1 ];

      arrayDeleteAt( variables.taskQueue, 1 );

      return taskItem;
    }
  }
}