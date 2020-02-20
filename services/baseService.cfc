component accessors=true {
  property string entityName;
  property dataService;

  public any function init( ) {
    var meta = getMetaData( this );

    variables.entityName = listLast( meta.name, '.' );

    return this;
  }

  public any function get( ) {
    var argsToPass = { };
    for( key in arguments ) {
      if( !isNull( arguments[ key ] ) ) {
        argsToPass[ key ] = arguments[ key ];
      }
    }

    if( structIsEmpty( argsToPass ) ) {
      return getAll( );
    }

    if( structCount( argsToPass ) > 1 ) {
      return getSome( argumentCollection = argsToPass );
    }

    var allArgKeys = structKeyArray( argsToPass );
    var firstArg = argsToPass[ allArgKeys[ 1 ] ];

    if( dataService.isGUID( firstArg ) ) {
      return getOne( firstArg );
    }
  }

  public component function create( ) {
    return entityNew( variables.entityName );
  }

  private any function getOne( required string id ) {
    return entityLoadByPK( variables.entityName, id );
  }

  private array function getSome( ) {
    return entityLoad( variables.entityName, arguments );
  }

  private array function getAll( ) {
    return entityLoad( variables.entityName );
  }

  public any function getAsStruct( required string id ) {
    var data = get( id );

    if( !isNull( data ) ) {
      return dataService.processEntity( data );
    }

    return dataService.nil( );
  }
}