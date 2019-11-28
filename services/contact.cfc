component extends="baseService" {
  public any function getByUsername( required string username, boolean deleted = false ) {
    return entityLoad( getEntityName(), { username = username, deleted = deleted }, true );
  }

  public any function getByEmail( required string email, boolean deleted = false ) {
    var entities = entityLoad( getEntityName(), { email = email, deleted = deleted } );
    if ( !arrayIsEmpty( entities ) ) {
      return entities[ 1 ];
    }
  }
}