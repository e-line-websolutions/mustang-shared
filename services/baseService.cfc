component accessors=true {
  property string entityName;
  property dataService;

  public any function init() {
    var meta = getMetaData( this );

    setEntityName( listLast( meta.name, '.' ));

    return this;
  }

  public any function get() {
    if( structCount( arguments ) == 1 && dataService.isGUID( arguments[1] )) {
      return getOne( arguments[1] );

    } else if( structCount( arguments )) {
      return getSome( argumentCollection = arguments );

    } else {
      return getAll();
    }
  }

  public component function create() {
    return entityNew( getEntityName());
  }

  private any function getOne( required string id ) {
    return entityLoadByPK( getEntityName(), id );
  }

  private array function getSome() {
    return entityLoad( getEntityName(), arguments );
  }

  private array function getAll() {
    return entityLoad( getEntityName());
  }

  public any function getAsStruct( required string id ) {
    var data = get( id );

    if( !isNull( data )) {
      return dataService.processEntity( data );
    }

    return dataService.nil();
  }
}