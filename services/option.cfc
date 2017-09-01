component accessors=true {
  property dataService;
  property queryService;

  property struct allOptions;
  property struct sourceMapping;

  // constructor

  public component function init( queryService ) {
    structAppend( variables, arguments );
    variables.allOptions = { };
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
    if( !len( trim( entityName ) ) ) {
      throw( "Missing entity name", "optionService.getOptionByName" );
    }

    if( !len( trim( optionName ) ) ) {
      throw( "Missing option name for #entityName#", "optionService.getOptionByName" );
    }

    var allOptions = variables.allOptions;

    if( structKeyExists( allOptions, entityName ) ) {
      var params = { "optionname" = trim( lCase( optionName ) ) };

      var hql = "SELECT t FROM #entityName# t WHERE LOWER( t.name ) = :optionname";
      var options = { "ignorecase" = true };
      var searchOptions = ORMExecuteQuery( hql, params, true, options );

      if( !isNull( searchOptions ) ) {
        return searchOptions;
      }
    }

    if( createIfMissing ) {
      return __createNewOption( entityName, optionName );
    }

    return dataService.nil( );
  }

  // private functions

  private component function __createNewOption( required string entityName, required string optionName ) {
    optionName = trim( optionName );

    var newOption = entityNew( entityName );
    newOption.save( { "name" = optionName } );

    __addOptionToCache( entityName, optionName );

    return newOption;
  }

  private void function __addOptionToCache( required string entityName, required string optionName ) {
    var allOptions = variables.allOptions;

    if( !structKeyExists( allOptions, entityName ) ) {
      allOptions[ entityName ] = [ ];
    }

    arrayAppend( allOptions[ entityName ], optionName );

    variables.allOptions = allOptions;
  }

  private array function __getOptionsFromDB( ) {
    return queryService.ormNativeQuery( "SELECT o.id, o.name FROM mustang.#queryService.escapeField( 'option' )# o WHERE o.name <> ''" );
  }
}