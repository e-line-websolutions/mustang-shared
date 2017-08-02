component accessors=true {
  property string entityName;
  property dataService;

  public any function init( ) {
    var meta = getMetaData( this );

    setEntityName( listLast( meta.name, '.' ) );

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
    return entityNew( getEntityName( ) );
  }

  private any function getOne( required string id ) {
    return entityLoadByPK( getEntityName( ), id );
  }

  private array function getSome( ) {
    return entityLoad( getEntityName( ), arguments );
  }

  private array function getAll( ) {
    return entityLoad( getEntityName( ) );
  }

  public any function getAsStruct( required string id ) {
    var data = get( id );

    if( !isNull( data ) ) {
      return dataService.processEntity( data );
    }

    return dataService.nil( );
  }
}