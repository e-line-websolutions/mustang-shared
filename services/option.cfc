component accessors=true {
  property config;
  property logService;
  property array optionEntities;

  // public functions

  public void function reloadOptions() {
    variables.optionEntities = request.allOrmEntities
      .filter( function ( k, v ) { return v.isOption; } )
      .reduce( function ( r = [], k, v ) { return r.append( k ); } );

    var result = {};
    var optionsInDb = __getOptionsFromDB();

    for ( var option in optionsInDb ) {
      var key = option.get( 'key' );
      var value = option.get( 'value' );

      if ( !structKeyExists( result, key ) ) {
        result[ key ] = [];
      }

      arrayAppend( result[ key ], value );
    }

  }

  public any function getOptionByName( required string entityName, required string optionName, boolean createIfMissing = false ) {
    if ( !variables.keyExists( 'optionEntities' ) ) reloadOptions();

    entityName = trim( entityName );
    optionName = trim( optionName );

    if ( !len( entityName ) || !len( optionName ) || entityName == 'ignore' ) {
      return;
    }

    if ( !arrayFindNoCase( variables.optionEntities, entityName ) ) {
      return;
    }

    if ( !createIfMissing ) {
      return __searchOptions( entityName, optionName );
    } else {
      lock name="#request.appName#-optionService-getOptionByName-#entityName#-#optionName#" timeout="10" type="exclusive" {
        var searchOptions = __searchOptions( entityName, optionName );

        if ( !isNull( searchOptions ) ) {
          return searchOptions;
        }

        return __createNewOption( entityName, optionName );
      }
    }

    return;
  }

  // private functions

  private any function __searchOptions( required string entityName, required string optionName ) {
    var hql = '
      FROM      option o
      WHERE     o.class = :entityName
        AND     LOWER( o.name ) = :optionName
    ';

    return ormExecuteQuery( hql, { 'entityName' = lCase( entityName ), 'optionName' = lCase( optionName ) }, true, { 'cacheable' = true } );
  }

  private any function __createNewOption( required string entityName, required string optionName ) {
    optionName = trim( optionName );

    if ( !len( optionName ) ) {
      return;
    }

    var newOption = entityNew( entityName );

    transaction {
      newOption.save( { 'name' = optionName } );
    }

    return newOption;
  }

  private array function __getOptionsFromDB() {
    var hql = '
      SELECT new map( type( o ) AS key, o.name AS value ) FROM option o WHERE o.name <> '''' AND o.deleted = false
    ';
    return ormExecuteQuery( hql, {}, false, { 'cacheable' = true } );
  }
}
