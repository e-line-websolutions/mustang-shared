component accessors=true {
  property queryService;
  property dataService;
  property logService;

  property struct allOptions;
  property array optionEntities;

  // constructor

  public component function init( queryService ) {
    structAppend( variables, arguments );

    variables.allOptions = { };
    variables.optionEntities = [ ];

    var allEntities = ormGetSessionFactory( ).getAllClassMetadata( );

    for( var key in allEntities ) {
      var entity = allEntities[ key ];
      if( entity.getMappedSuperclass( ) == "option" ) {
        arrayAppend( variables.optionEntities, key );
      }
    }

    reloadOptions( );

    return this;
  }

  // public functions

  public void function reloadOptions( ) {
    var result = { };
    var optionsInDb = __getOptionsFromDB( );

    for( var option in optionsInDb ) {
      var key = option[ 1 ];
      var value = option[ 2 ];

      if( !structKeyExists( result, key ) ) {
        result[ key ] = [ ];
      }

      arrayAppend( result[ key ], value );
    }

    variables.allOptions = result;
  }

  public any function getOptionByName( required string entityName, required string optionName, boolean createIfMissing = false ) {
    entityName = trim( entityName );

    if( !len( entityName ) ) {
      throw( "Missing entity name", "optionService.getOptionByName.missingEntityError" );
    }

    if( !arrayFindNoCase( variables.optionEntities, entityName ) ) {
      return;
    }

    optionName = trim( lCase( optionName ) );

    if( !len( optionName ) ) {
      throw( "Missing option name for #entityName#", "optionService.getOptionByName.missingOptionError" );
    }

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
      SELECT    o.*
      FROM      #queryService.escapeField( 'mustang.option', '' )# o
      WHERE     LOWER( o.type ) = :entityName
        AND     LOWER( o.name ) = :optionName
    ';

    return queryService.ormNativeQuery(
      sql,
      { "entityName" = lCase( entityName ), "optionName" = lCase( optionName ) },
      { "ignorecase" = true },
      [ entityName ],
      true
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
    return queryService.ormNativeQuery( "SELECT o.id, o.name FROM mustang.#queryService.escapeField( 'option' )# o WHERE o.name <> ''" );
  }
}