component accessors=true {
  property config;
  property logService;
  property struct allOptions;
  property array optionEntities;

  // constructor

  public component function init( config ) {
    structAppend( variables, arguments );

    variables.allOptions = { };
    variables.optionEntities = [ ];

    param config.useOrm=true;

    if ( config.useOrm ) {
      var allEntities = ormGetSessionFactory( ).getAllClassMetadata( );

      for( var key in allEntities ) {
        var entity = allEntities[ key ];
        if( entity.getMappedSuperclass( ) == "option" ) {
          arrayAppend( variables.optionEntities, key );
        }
      }

      reloadOptions( );
    }

    return this;
  }

  // public functions

  public void function reloadOptions( ) {
    var result = { };
    var optionsInDb = __getOptionsFromDB( );

    for( var option in optionsInDb ) {
      var key = option.get( 'key' );
      var value = option.get( 'value' );

      if( !structKeyExists( result, key ) ) {
        result[ key ] = [ ];
      }

      arrayAppend( result[ key ], value );
    }

    variables.allOptions = result;
  }

  public any function getOptionByName( required string entityName, required string optionName, boolean createIfMissing = false ) {
    entityName = trim( entityName );

    if( !len( entityName ) || entityName == "ignore" ) {
      return;
    }

    if( !arrayFindNoCase( variables.optionEntities, entityName ) ) {
      return;
    }

    optionName = trim( optionName );

    if( !len( optionName ) ) {
      return;
    }

    logService.writeLogLevel( "optionService.getOptionByName( #entityName#, #optionName# ) called" );

    lock name="#request.appName#-optionService-getOptionByName-#entityName#-#optionName#" timeout="10" type="exclusive" {
      var searchOptions = __searchOptions( entityName, optionName );

      if( !isNull( searchOptions ) ) {
        return searchOptions;
      }

      if( createIfMissing ) {
        return __createNewOption( entityName, optionName );
      }
    }

    return;
  }

  // private functions

  private any function __searchOptions( required string entityName, required string optionName ) {
    var sql = '
      FROM      option o
      WHERE     o.class = :entityName
        AND     LOWER( o.name ) = :optionName
    ';

    return ORMExecuteQuery(
      sql,
      { "entityName" = lCase( entityName ), "optionName" = lCase( optionName ) },
      true,
      { "ignorecase" = true }
    );
  }

  private any function __createNewOption( required string entityName, required string optionName ) {
    optionName = trim( optionName );

    if( !len( optionName ) ) {
      return;
    }

    var newOption = entityNew( entityName );

    transaction {
      newOption.save( { "name" = optionName } );
    }

    __addOptionToCache( entityName, optionName );

    return newOption;
  }

  private void function __addOptionToCache( required string entityName, required string optionName ) {
    if( !structKeyExists( variables.allOptions, entityName ) ) {
      variables.allOptions[ entityName ] = [ ];
    }

    arrayAppend( variables.allOptions[ entityName ], optionName );
  }

  private array function __getOptionsFromDB( ) {
    return ORMExecuteQuery( "SELECT new map( type( o ) AS key, o.name AS value ) FROM option o WHERE o.name <> ''" );
  }
}