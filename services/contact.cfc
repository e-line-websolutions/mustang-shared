component extends="baseService" {
  public any function getByUsername( required string username, boolean deleted = false ) {
    var entities = ormExecuteQuery(
      'FROM   #getEntityName()#
       WHERE  deleted = false AND
              LOWER( username ) = :username',
      { 'username' = lCase( username ) }
    );
    if ( !arrayIsEmpty( entities ) ) {
      return entities[ 1 ];
    }
  }

  public any function getByEmail( required string email, boolean deleted = false ) {
    var entities = ormExecuteQuery(
      'FROM   #getEntityName()#
       WHERE  deleted = false AND
              LOWER( email ) = :email',
      { 'email' = lCase( email ) }
    );
    if ( !arrayIsEmpty( entities ) ) {
      return entities[ 1 ];
    }
  }
}