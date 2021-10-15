component extends="baseService" {
  public any function getByUsername( required string username, boolean deleted = false ) {
    var params = { 'deleted' = deleted, 'username' = username };
    var hql = 'FROM #variables.entityName# WHERE deleted = :deleted AND username = :username';

    var tmp = entityNew( variables.entityName );
    if ( tmp.propertyExists( 'active' ) && !username == 'admin' ) {
      params[ 'active' ] = true;
      hql &= ' AND active = :active ';
    }

    try {
      return ormExecuteQuery( hql, params, true, { ignorecase = true } );
    } catch ( any e ) {
      // returns null if more than one user is found }
    }
  }

  public any function getByEmail( required string email, boolean deleted = false ) {
    var params = { 'deleted' = deleted, 'email' = email };
    var hql = 'FROM #variables.entityName# WHERE deleted = :deleted AND email = :email';

    var tmp = entityNew( variables.entityName );
    if ( tmp.propertyExists( 'active' ) ) {
      params[ 'active' ] = true;
      hql &= ' AND active = :active ';
    }

    try {
      return ormExecuteQuery( hql, params, true, { ignorecase = true } );
    } catch ( any e ) {
      // returns null if more than one user is found }
    }
  }

  public any function getById( required string id, boolean deleted = false ) {
    var params = { 'deleted' = deleted, 'id' = id };
    var hql = 'FROM #variables.entityName# WHERE deleted = :deleted AND id = :id';

    var tmp = entityNew( variables.entityName );
    if ( tmp.propertyExists( 'active' ) ) {
      params[ 'active' ] = true;
      hql &= ' AND active = :active ';
    }

    try {
      return ormExecuteQuery( hql, params, true, { ignorecase = true } );
    } catch ( any e ) {
      // returns null if more than one user is found }
    }
  }
}
