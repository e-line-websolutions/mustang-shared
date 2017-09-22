Services and Controllers for Mustang Applications
=================================================

Default Config:

```
{
    "appIsLive": true                    // determines the state of the app, when false a nuke call causes the database to reset
  , "ownerEmail": "bugs@mstng.info"      // default sender address for emails sent by the system
  , "reloadpw": "1"                      // password to use as URL parameter: ?reload=1

  , "datasource": ""                     // name of the CF datasource
  , "nukeScript": ""                     // SQL script used to initialize the database with data
  , "useOrm": true                       // Not all apps need a database, but those that do are managed using ORM in Mustang.
  , "root": "root"                       // name of the root mapping of the app

  , "encryptKey": ""                     // basic default encrypt key

  , "showDebug": false                   // shows the FW/1 trace when true
  , "logLevel": "information"            // default log level, can be: debug, information, warning, error or fatal
  , "debugEmail": "bugs@mstng.info"      // where to send errors generated by the app
  , "debugIP": "127.0.0.1"               // who to show debug info to

  , "defaultLanguage": "en_US"           // default locale to use

  , "log": true                          // whether or not to use logging changes to records in the database
  , "logNotes": false                    // include a mandatory note with every change made to database records

  , "disableSecurity": false             // app need no login
  , "dontSecureFQA": ""                  // which fully qualified actions don't need a login
  , "contentSubsystems": ""              // which subsystems use the Mustang CMS
  , "securedSubsystems": ""              // which subsystems are secured using a login
  , "secureDefaultSubsystem": true       // is the main subsystem secured

  , "paths": { }                         // paths needed by the app, usefull for dev/staging/live environments
}
```