component extends="baseService" {
  public component function getByFQA( required  string fqa, any locale, boolean deleted = false, struct options = { cacheable = true }, contentTable = 'content' ) {
    var hql = 'FROM #contentTable# c WHERE c.fullyqualifiedaction = :fqa AND c.deleted != :deleted';
    var params = { fqa = fqa, deleted = !deleted };

    if ( !isNull( locale ) ) {
      hql &= ' AND c.locale = :locale';
      params.locale = locale;
    }

    var result = ormExecuteQuery( hql, params, options );

    if ( arrayLen( result ) ) {
      return result[ 1 ];
    }

    var result = entityNew( contentTable );

    return result;
  }
}