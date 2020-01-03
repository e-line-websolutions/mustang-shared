component extends="baseService" accessors=true {
  property logService;

  public component function getByFQA(
    required  string fqa,
    any locale,
    boolean deleted = false,
    struct options = { cacheable = true },
    contentTable = 'content'
  ) {
    var hql_from = ' FROM ' & contentTable & ' c ';
    var hql_where = ' WHERE c.fullyqualifiedaction = :fqa AND c.deleted != :deleted ';

    var params = { 'fqa' = fqa, 'deleted' = !deleted };

    if ( !isNull( locale ) ) {
      hql_where &= ' AND c.locale = :locale';
      params[ 'locale' ] = locale;
    }

    var result = ormExecuteQuery( hql_from & hql_where, params, options );

    if ( arrayIsEmpty( result ) ) {
      return entityNew( contentTable );
    }

    if ( arrayLen( result ) > 1 ) {
      logService.writeLogLevel( 'More than 1 text found for fqa: #fqa# in table: #contentTable#' );
    }

    return result[ 1 ];
  }
}