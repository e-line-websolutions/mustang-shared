component extends=crud {
  public void function view() {
    super.view( rc );

    var linkedEntity = rc.data.getRelatedEntity();

    if( !isNull( linkedEntity )) {
      var prevEntries = ORMExecuteQuery( "FROM logentry AS logentry WHERE logentry.relatedEntity=:relatedEntity AND logentry.dd<:dd ORDER BY logentry.dd DESC", {
        "relatedEntity" = linkedEntity,
        "dd" = rc.data.getCreateDate()
      }, { maxresults = 1 });

      if( arrayLen( prevEntries ) == 1 ) {
        rc.prevEntry = prevEntries[1];
      }

      var nextEntries = ORMExecuteQuery( "FROM logentry AS logentry WHERE logentry.relatedEntity=:relatedEntity AND logentry.dd>:dd ORDER BY logentry.dd ASC", {
        "relatedEntity" = linkedEntity,
        "dd" = rc.data.getCreateDate()
      }, { maxresults = 1 });

      if( arrayLen( nextEntries ) == 1 ) {
        rc.nextEntry = nextEntries[1];
      }
    }
  }
}