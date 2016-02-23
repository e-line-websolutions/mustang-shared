component accessors=true {
  property framework;
  property contentService;
  property localeService;
  property translationService;

  public void function load( rc ) {
    rc.displaytitle = translationService.translate( framework.getfullyqualifiedaction() );
    rc.content = contentService.getByFQA( framework.getfullyqualifiedaction(), localeService.get( translationService.getLocaleID() ));

    if( !structKeyExists( rc, "topnav" )){
      rc.topnav = "";
    }

    rc.subnavHideHome = false;

    if( framework.getSubsystem() == framework.getDefaultSubsystem()){
      var reload = true;

      lock scope="session" timeout="5" type="readonly" {
        if( structKeyExists( session, "subnav" )){
          rc.subnav = session.subnav;
          reload = false;
        }
      }

      if( !rc.config.appIsLive || request.reset ){
        reload = true;
      }

      if( reload ){
        rc.subnav = "";

        if( rc.auth.isLoggedIn && !isNull( rc.auth.role.menulist )) {
          var roleSubnav = rc.auth.role.menulist;
        }

        if( isNull( roleSubnav )){
          var roleSubnav = "";
        }

        if( len( trim( roleSubnav ))){
          for( var navItem in listToArray( roleSubnav )){
            if( navItem == "-" || rc.auth.role.can( "view", navItem )){
              rc.subnav = listAppend( rc.subnav, navItem );
            }
          }
        } else {
          var hiddenMenuitems = "base";
          var subnav = [];
          var tempSortOrder = 9001;

          for( var entityPath in directoryList( request.root & '/model', false, 'name', '*.cfc' )){
            var entityName = reverse( listRest( reverse( getFileFromPath( entityPath )), "." ));
            var sortOrder = tempSortOrder++;
            var entity = getMetaData( createObject( "root.model." & entityName ));

            if( structKeyExists( entity, "hide" ) ||
                listFindNoCase( hiddenMenuitems, entityName ) ||
                ( rc.auth.isLoggedIn && !rc.auth.role.can( "view", entityName ))) {
              continue;
            }

            if( structKeyExists( entity, "sortOrder" )){
              sortOrder = entity["sortOrder"];
            }

            subnav[sortOrder] = entityName;
          }

          for( var menuItem in subnav ) {
            if( !isNull( menuItem ) && len( trim( menuItem ))) {
              rc.subnav = listAppend( rc.subnav, menuItem );
            }
          }
        }
      }

      lock scope="session" timeout="5" type="exclusive" {
        session.subnav = rc.subnav;
      }
    }
  }
}