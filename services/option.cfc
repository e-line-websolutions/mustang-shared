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
      var key = option.key;
      var value = option.value;

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

  private function __getOptionsFromDB() {
    var schema = entityNew( 'option' ).getSchemaName();

    return queryExecute( '
      SELECT  "type" AS "key",
              "name" AS "value"
      FROM    "#schema#"."option"
      WHERE   "name" <> ''''
        AND   "deleted" = false
    ', {} );
  }
}
