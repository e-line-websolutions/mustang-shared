component accessors=true {
  // Taken from http://www.bennadel.com/blog/2528-asynctaskqueue-cfc---running-low-priority-tasks-in-a-single-cfthread.htm
  // de-ben-ified by mjhagen.

  property config;
  property logService;
  property taskQueue;
  property beanFactory;

  // constructor

  public component function init( ) {
    variables.taskQueue = [ ];
    variables.taskQueueID = lCase( createUUID( ) );
    variables.threadIndex = 1;
    variables.threadName = getNewAsyncThreadName( );
    variables.isThreadRunning = false;
    variables.lockName = getAsyncTaskLockName( );
    variables.lockTimeout = 30;

    return this;
  }

  // public methods

  public component function getInstance( ) {
    return init( );
  }

  public void function addTask( required any taskMethod, any taskArguments = { } ) {
    variables.logService.writeLogLevel( "Executing task (t. #variables.threadIndex#).", "asyncQueue" );

    lock name=variables.lockName timeout=variables.lockTimeout {
      addNewTaskItem( taskMethod, taskArguments, variables.threadName );

      if ( variables.isThreadRunning ) {
        return;
      }

      variables.isThreadRunning = true;

      if ( !structKeyExists( server, "lucee" ) ) {
        var threadfixService = beanFactory.getBean( "threadfix" );
        threadfixService.cacheScriptObjects( );
      }

      thread action="run" name=variables.threadName priority="high" {
        do {
          lock name=variables.lockName timeout=variables.lockTimeout {
            var taskItem = getNextTaskItem( );
          }

          while ( structKeyExists( local, "taskItem" ) ) {
            try {
              variables.logService.writeLogLevel( "Task (t. #variables.threadIndex#) started.", "asyncQueue" );
              taskItem.taskMethod( argumentCollection = taskItem.taskArguments );
              variables.logService.writeLogLevel( "Task (t. #variables.threadIndex#) done.", "asyncQueue" );
            } catch ( any e ) {
              variables.logService.writeLogLevel( "Error executing task (t. #variables.threadIndex#). (#e.message#, #e.detail#)", "asyncQueue", "error" );
              variables.logService.dumpToFile( e, true );
              rethrow;
            }

            lock name=variables.lockName timeout=variables.lockTimeout {
              taskItem = getNextTaskItem( );
            }
          }

          lock name=variables.lockName timeout=variables.lockTimeout {
            var isQueueEmpty = !arrayLen( variables.taskQueue );
            var isQueueFull = !isQueueEmpty;

            if ( isQueueEmpty ) {
              variables.isThreadRunning = false;
              variables.threadName = getNewAsyncThreadName( );
            }
          }
        } while ( isQueueFull );
      }
    }
  }

  public void function abortQueue( ) {
    lock name=variables.lockName timeout=variables.lockTimeout {
      for ( var queuedTasks in variables.taskQueue ) {
        try {
          thread action="terminate" name=queuedTasks.threadName;
        } catch ( any e ) {
          variables.logService.dumpToFile( e, true );
        }
      }
      variables.taskQueue = [ ];
    }
  }

  // private methods

  private void function addNewTaskItem( required any taskMethod, required any taskArguments, required string threadName ) {
    if ( isArray( taskArguments ) ) {
      taskArguments = convertArgumentsArrayToCollection( taskArguments );
    }

    arrayAppend(
      variables.taskQueue,
      {
        "taskMethod" = taskMethod,
        "taskArguments" = taskArguments,
        "threadName" = threadName
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
    var index = ++variables.threadIndex;

    return "thread-#variables.taskQueueID#-#index#";
  }

  private any function getNextTaskItem( ) {
    if ( arrayLen( variables.taskQueue ) ) {
      var taskItem = variables.taskQueue[ 1 ];

      arrayDeleteAt( variables.taskQueue, 1 );

      variables.logService.writeLogLevel( "Selected task: #taskItem.taskMethod# for thread #taskItem.threadName#", "asyncQueue" );

      return taskItem;
    }
  }
}