component extends="baseService" {
  public any function getByUsername( required string username, boolean deleted = false ) {
    return entityLoad( getEntityName(), { username = username, deleted = deleted }, true );
  }

  public any function getByEmail( required string email, boolean deleted = false ) {
    return entityLoad( getEntityName(), { email = email, deleted = deleted }, true );
  }
}