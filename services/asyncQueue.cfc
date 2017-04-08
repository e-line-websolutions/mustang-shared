component accessors=true {
  // Taken from http://www.bennadel.com/blog/2528-asynctaskqueue-cfc---running-low-priority-tasks-in-a-single-cfthread.htm
  // de-ben-ified by mjhagen.

  property config;
  property logService;

  // constructor

  public component function init( ) {
    variables.taskQueue = [ ];
    variables.taskQueueID = lcase( createUUID( ) );
    variables.asyncTaskThreadIndex = 1;
    variables.asyncTaskThreadName = getNewAsyncThreadName( );
    variables.isThreadRunning = false;
    variables.asyncTaskLockName = getAsyncTaskLockName( );
    variables.asyncTaskLockTimeout = 30;
    variables.queueNr = 1;

    return this;
  }

  // public methods

  public component function getInstance( ) {
    return init( );
  }

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
              logService.writeLogLevel( text = "Executed task part #variables.queueNr#.", file = "asyncQueue", type = "information" );
            } catch ( any e ) {
              logService.writeLogLevel( text = "Error executing task part #variables.queueNr#. (#e.message#)", file = "asyncQueue", type = "fatal" );
              if ( config.showDebug ) {
                logService.dumpToFile( [
                  taskItem.taskArguments,
                  e
                ] );
              }
            }

            variables.queueNr++;

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