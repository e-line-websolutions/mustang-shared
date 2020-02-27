component extends=crud accessors=true {
  property securityService;

  public void function default( required struct rc ) {
    if( structKeyExists( rc, "orderby" ) && listFindNoCase( rc.orderby, "fullname" )) {
      rc.orderby = replaceNoCase( rc.orderby, "fullname", "lastname,firstname" );
    }
    super.default( rc = rc );
  }

  public void function save( required struct rc ) {
    if ( structKeyExists( rc, 'password' ) && len( trim( rc.password ) ) > 0 ) {
      if ( len( trim( rc.password ) ) < 2 ) {
        rc.alert = { 'class' = 'danger', 'text' = 'password-too-short' };
        framework.redirect( 'contact', 'alert' );
      }

      rc.password = form.password = securityService.hashPassword( rc.password );
    } else {
      structDelete( rc, 'password' );
      structDelete( form, 'password' );
      var posInFieldnames = listFindNoCase( form.FIELDNAMES, 'password' );
      if ( posInFieldnames ) form.FIELDNAMES = listDeleteAt( form.FIELDNAMES, posInFieldnames );
    }

    super.save( rc = rc ); // sets rc.savedEntity to the saved entity
  }
}