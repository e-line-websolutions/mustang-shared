component accessors=true {
  property root;
  property config;
  property framework;
  property beanFactory;
  property crudService;
  property jsonJavaService;
  property securityService;
  property utilityService;

  public any function init( fw ) {
    variables.framework = fw;

    param variables.listitems="";
    param variables.listactions=".new";
    param variables.confirmactions=".delete";
    param variables.lineactions=".view,.edit";
    param variables.showNavbar=true;
    param variables.showSearch=false;
    param variables.showAlphabet=false;
    param variables.showPager=true;
    param variables.entity=fw.getSection( );
    param array variables.submitButtons=[ ];

    variables.ormEntities=structKeyArray( ORMGetSessionFactory( ).getAllClassMetadata( ) );

    return this;
  }

  public void function before( required struct rc ) {
    if ( !rc.auth.isLoggedIn ) {
      return;
    }

    variables.entity = variables.framework.getSection( );

    param rc.useAsViewEntity=variables.entity;

    if ( arrayFindNoCase( variables.ormEntities, variables.entity ) ) {
      var object = entityNew( variables.entity );
      var entityInstanceVars = object.getInstanceVariables( );

      if ( structKeyExists( entityInstanceVars.settings, "useForViews" ) ) {
        rc.useAsViewEntity = entityInstanceVars.settings.useForViews;
      }
    }


    if ( rc.useAsViewEntity != variables.entity ) {
      var superClassControllerPath = "/#config.root#/controllers/#rc.useAsViewEntity#.cfc";

      if ( utilityService.fileExistsUsingCache( expandPath( superClassControllerPath ) ) ) {
        var superClassControllerDottedPath = "#config.root#.controllers.#rc.useAsViewEntity#";
        var superClassController = createObject( superClassControllerDottedPath );
        var fnName = "before#variables.framework.getItem( )#";

        if ( structKeyExists( superClassController, fnName ) ) {
          this[ "__" & fnName ] = superClassController[ fnName ];
          var fn = this[ "__" & fnName ];
          fn( rc = rc );
        }
      }
    }

    if ( variables.framework.getItem( ) == "edit" && !securityService.can( "change", rc.useAsViewEntity ) ) {
      rc.alert = {
        "class" = "danger",
        "text" = "privileges-error-1",
        "stringVariables" = { "section" = rc.useAsViewEntity }
      };
      variables.framework.redirect( ":", "alert" );
    }

    if ( !rc.useAsViewEntity == "main" && !securityService.can( "view", rc.useAsViewEntity ) ) {
      rc.alert = {
        "class" = "danger",
        "text" = "privileges-error-2",
        "stringVariables" = { "section" = rc.useAsViewEntity }
      };
      variables.framework.redirect( ":", "alert" );
    }

    variables.framework.setLayout( ":admin" );
  }

  public void function after( required struct rc ) {
    param rc.useAsViewEntity=variables.entity;

    if ( rc.useAsViewEntity != variables.entity ) {
      var superClassControllerPath = "/#config.root#/controllers/#rc.useAsViewEntity#.cfc";

      if ( utilityService.fileExistsUsingCache( expandPath( superClassControllerPath ) ) ) {
        var superClassControllerDottedPath = "#config.root#.controllers.#rc.useAsViewEntity#";
        var superClassController = createObject( superClassControllerDottedPath );
        var fnName = "after#variables.framework.getItem( )#";

        if ( structKeyExists( superClassController, fnName ) ) {
          this[ "__" & fnName ] = superClassController[ fnName ];
          var fn = this[ "__" & fnName ];
          fn( rc = rc );
        }
      }
    }
  }

  public void function default( required struct rc ) {
    if ( !rc.auth.isLoggedIn ) {
      return;
    }

    param rc.columns=[ ];
    param rc.offset=0;
    param rc.maxResults=30;
    param rc.d=0;// rc.d(escending) default false (ASC)
    param rc.orderby="";
    param rc.startsWith="";
    param rc.showdeleted=0;
    param rc.filters=[ ];
    param rc.filterType="contains";
    param rc.classColumn="";

    // exit controller on non crud items
    switch ( variables.framework.getSection( ) ) {
      case "main":
        var dashboard = lCase( reReplace( rc.auth.role.name, '\W+', '-', 'all' ) );

        if ( utilityService.fileExistsUsingCache( root & "/views/main/dashboard-#dashboard#.cfm" ) ) {
          variables.framework.setView( '.dashboard-#dashboard#' );
        } else {
          variables.framework.setView( '.dashboard-default' );
        }

        return;

      case "profile":
        rc.data = entityLoadByPK( "contact", rc.auth.userid );
        variables.framework.setView( 'profile.default' );
        return;
    }

    param rc.lineView=":elements/line";
    param rc.tableView=":elements/table";
    param rc.fallbackView=":elements/list";

    // default crud behaviour continues:
    rc.entity = variables.entity;

    // exit with error when trying to control a non-persisted entity
    if ( !arrayFindNoCase( variables.ormEntities, variables.entity ) ) {
      rc.fallbackView = ":app/notfound";
      variables.framework.setView( '.#variables.entity#' );
      return;
    }

    var object = entityNew( variables.entity );
    var entityInstanceVars = object.getInstanceVariables( );

    var property = "";
    var indexNr = 0;
    var orderNr = 0;
    var columnName = "";
    var columnsInList = [ ];
    var orderByString = "";
    var queryOptions = {
      ignorecase = true,
      maxResults = rc.maxResults,
      offset = rc.offset
    };

    rc.recordCounter = 0;
    rc.deleteddata = 0;
    rc.properties = entityInstanceVars.properties;
    rc.lineactions = variables.lineactions;
    rc.listactions = variables.listactions;
    rc.confirmactions = variables.confirmactions;
    rc.showNavbar = variables.showNavbar;
    rc.showSearch = variables.showSearch;
    rc.showAlphabet = variables.showAlphabet;
    rc.showPager = variables.showPager;
    rc.showAsTree = false;

    // exit out of controller if using a tree view (data retrieval goes through ajax calls instead)
    if ( structKeyExists( entityInstanceVars.settings, "list" ) ) {
      rc.tableView = ":elements/" & entityInstanceVars.settings.list;

      if ( entityInstanceVars.settings.list == "hierarchy" ) {
        rc.allColumns = { };
        rc.allData = [ ];
        rc.showAsTree = true;
        return;
      }
    }

    if ( !securityService.can( "change", variables.entity ) ) {
      var lineactionPointer = listFind( rc.lineactions, '.edit' );
      if ( lineactionPointer ) {
        rc.lineactions = listDeleteAt( rc.lineactions, lineactionPointer );
      }
    }

    if ( structKeyExists( entityInstanceVars.settings, "classColumn" ) && len( trim( entityInstanceVars.settings.classColumn ) ) ) {
      classColumn = entityInstanceVars.settings.classColumn;
    }

    rc.defaultSort = "";

    if ( structKeyExists( entityInstanceVars.settings, "defaultSort" ) ) {
      rc.defaultSort = entityInstanceVars.settings.defaultSort;
    } else if ( structKeyExists( entityInstanceVars.settings.extends, "defaultSort" ) ) {
      rc.defaultSort = entityInstanceVars.settings.extends.defaultSort;
    }

    if ( len( trim( rc.orderby ) ) ) {
      local.vettedOrderByString = "";

      for ( var orderField in listToArray( rc.orderby ) ) {
        if ( orderField contains ';' ) {
          continue;
        }

        if ( orderField contains ' ASC' || orderField contains ' DESC' ) {
          orderField = listFirst( orderField, ' ' );
        }

        if ( structKeyExists( rc.properties, orderField ) ) {
          local.vettedOrderByString = listAppend( local.vettedOrderByString, orderField );
        }
      }

      rc.orderby = local.vettedOrderByString;

      if ( len( trim( rc.orderby ) ) ) {
        rc.defaultSort = rc.orderby & ( rc.d ? ' DESC' : '' );
      }
    }

    rc.orderby = replaceNoCase( rc.defaultSort, ' ASC', '', 'all' );
    rc.orderby = replaceNoCase( rc.orderby, ' DESC', '', 'all' );

    if ( rc.defaultSort contains ' DESC' ) {
      rc.d = 1;
    } else if ( rc.defaultSort contains ' ASC' ) {
      rc.d = 0;
    }

    for ( orderByPart in listToArray( rc.defaultSort ) ) {
      orderByString = listAppend( orderByString, "mainEntity.#orderByPart#" );
    }

    if ( len( trim( rc.startsWith ) ) ) {
      rc.filters = [
        {
          "field" = "name",
          "filterOn" = replace( rc.startsWith, '''', '''''', 'all' )
        }
      ];
      rc.filterType = "starts-with";
    }

    for ( var key in rc ) {
      if ( !isSimpleValue( rc[ key ] ) ) {
        continue;
      }

      key = urlDecode( key );

      if ( listFirst( key, "_" ) == "filter" && len( trim( rc[ key ] ) ) ) {
        arrayAppend(
          rc.filters,
          {
            "field" = listRest( key, "_" ),
            "filterOn" = replace( rc[ key ], '''', '''''', 'all' )
          }
        );
      }
    }

    if ( !structKeyExists( rc, "alldata" ) ) {
      if ( arrayLen( rc.filters ) ) {
        var alsoFilterKeys = structFindKey( rc.properties, 'alsoFilter' );
        var alsoFilterEntity = "";
        var whereBlock = " WHERE 0 = 0 ";
        var whereParameters = { };
        var counter = 0;

        if ( rc.showdeleted == 0 ) {
          whereBlock &= " AND ( mainEntity.deleted IS NULL OR mainEntity.deleted = false ) ";
        }

        for ( var filter in rc.filters ) {
          if( !isArray( filter.filterOn ) ) {
            filter.filterOn = [ filter.filterOn ];
          }

          whereBlock &= " AND ( 1 = 0 ";

          for( var filterOn in filter.filterOn ) {
            if ( len( filter.field ) gt 2 && right( filter.field, 2 ) == "id" ) {
              whereBlock &= "OR mainEntity.#left( filter.field, len( filter.field ) - 2 )# = ( FROM #left( filter.field, len( filter.field ) - 2 )# WHERE id = :where_id )";
              whereParameters[ "where_id" ] = filterOn;
            } else {
              if ( filterOn == "NULL" ) {
                whereBlock &= " OR ( ";
                whereBlock &= " mainEntity.#lCase( filter.field )# IS NULL ";
              } else if ( structKeyExists( rc.properties[ filter.field ], "cfc" ) ) {
                whereBlock &= " OR ( ";
                whereBlock &= " mainEntity.#lCase( filter.field )#.id = :where_#lCase( filter.field )# ";
                whereParameters[ "where_#lCase( filter.field )#" ] = filterOn;
              } else {
                if ( rc.filterType == "contains" ) {
                  filterOn = "%#filterOn#";
                }

                filterOn = "#filterOn#%";

                whereBlock &= " OR ( ";
                whereBlock &= " mainEntity.#lCase( filter.field )# LIKE :where_#lCase( filter.field )# ";
                whereParameters[ "where_#lCase( filter.field )#" ] = filterOn;
              }

              for ( var alsoFilterKey in alsoFilterKeys ) {
                if ( alsoFilterKey.owner.name neq filter.field ) {
                  continue;
                }

                counter++;
                alsoFilterEntity &= " LEFT JOIN mainEntity.#listFirst( alsoFilterKey.owner.alsoFilter, '.' )# AS entity_#counter# ";
                whereBlock &= " OR entity_#counter#.#listLast( alsoFilterKey.owner.alsoFilter, '.' )# LIKE '#filterOn#' ";
                whereParameters[ "where_#listLast( alsoFilterKey.owner.alsoFilter, '.' )#" ] = filterOn;
              }
              whereBlock &= " ) ";
            }
          }

          whereBlock &= " ) ";
        }

        if ( structKeyExists( entityInstanceVars.settings, "where" ) && len( trim( entityInstanceVars.settings.where ) ) ) {
          whereBlock &= entityInstanceVars.settings.where;
        }

        var HQLcounter = " SELECT COUNT( mainEntity ) AS total ";
        var HQLselector = " SELECT mainEntity ";

        var HQL = "";
        HQL &= " FROM #lCase( variables.entity )# mainEntity ";
        HQL &= alsoFilterEntity;
        HQL &= whereBlock;

        HQLcounter = HQLcounter & HQL;
        HQLselector = HQLselector & HQL;

        if ( len( trim( orderByString ) ) ) {
          HQLselector &= " ORDER BY #orderByString# ";
        }

        rc.alldata = ORMExecuteQuery( HQLselector, whereParameters, queryOptions );

        if ( arrayLen( rc.alldata ) gt 0 ) {
          rc.recordCounter = ORMExecuteQuery( HQLcounter, whereParameters, { ignorecase = true } )[ 1 ];
        }
      } else {
        var HQL = " FROM #lCase( variables.entity )# mainEntity ";

        if ( rc.showDeleted ) {
          HQL &= " WHERE mainEntity.deleted = TRUE ";
        } else {
          HQL &= " WHERE ( mainEntity.deleted IS NULL OR mainEntity.deleted = FALSE ) ";
        }

        if ( len( trim( orderByString ) ) ) {
          HQL &= " ORDER BY #orderByString# ";
        }

        rc.alldata = ORMExecuteQuery( HQL, { }, queryOptions );

        if ( arrayLen( rc.alldata ) gt 0 ) {
          rc.recordCounter = ORMExecuteQuery(
            "SELECT COUNT( e ) AS total FROM #lCase( variables.entity )# AS e WHERE e.deleted != :deleted",
            { "deleted" = true },
            { ignorecase = true }
          )[ 1 ];
          rc.deleteddata = ORMExecuteQuery(
            "SELECT COUNT( mainEntity.id ) AS total FROM #lCase( variables.entity )# AS mainEntity WHERE mainEntity.deleted = :deleted",
            { "deleted" = true }
          )[ 1 ];

          if ( rc.showdeleted ) {
            rc.recordCounter = rc.deleteddata;
          }
        }
      }
    }

    rc.allColumns = { };

    var columnsInList = [ ];
    var property = "";
    var indexNr = 0;
    var orderNr = 0;

    for ( var key in rc.properties ) {
      property = rc.properties[ key ];
      orderNr++;
      rc.allColumns[ property.name ] = property;
      rc.allColumns[ property.name ].columnIndex = orderNr;

      if ( structKeyExists( property, "inlist" ) || structKeyExists( property, "showInList" ) ) {
        indexNr++;
        columnsInList[ indexNr ] = property.name;
      }
    }

    if ( len( trim( variables.listitems ) ) ) {
      columnsInList = [ ];
      for ( var listItem in variables.listitems ) {
        arrayAppend( columnsInList, listItem );
      }
    }

    if ( variables.entity == 'logged' ) {
      arrayAppend( columnsInList, "relatedEntity" );
      arrayAppend( columnsInList, "name" );
      arrayAppend( columnsInList, "dd" );
    }

    var numberOfColumns = arrayLen( columnsInList );

    try {
      for ( var columnName in columnsInList ) {
        if ( structKeyExists( rc.allColumns, columnName ) ) {
          var property = rc.allColumns[ columnName ];
          arrayAppend(
            rc.columns,
            {
              name = columnName,
              orderNr = structKeyExists( property, "cfc" ) ? 0 : property.columnIndex,
              orderInList = structKeyExists( property, "orderinlist" ) ? property.orderinlist : numberOfColumns++,
              class = structKeyExists( property, "class" ) ? property.class : '',
              data = property
            }
          );
        }
      }
    } catch ( any e ) {
      writeDump( cfcatch );
      abort;
    }

    // sort the array based on the orderInList value in the structures:
    for ( var i = 1; i lte arrayLen( rc.columns ); i++ ) {
      for ( var j = ( i - 1 ) + 1; j gt 1; j-- ) {
        if ( rc.columns[ j ].orderInList lt rc.columns[ j - 1 ].orderInList ) {
          // swap values
          var temp = rc.columns[ j ];
          rc.columns[ j ] = rc.columns[ j - 1 ];
          rc.columns[ j - 1 ] = temp;
        }
      }
    }
  }

  public void function new( required struct rc ) {
    if ( !securityService.can( "change", variables.framework.getSection( ) ) ) {
      rc.alert = {
        "class" = "danger",
        "text" = "privileges-error"
      };
      variables.framework.redirect( ".default", "alert" );
    }

    edit( rc = rc );
  }

  public void function view( required struct rc ) {
    rc.editable = false;
    edit( rc = rc );
  }

  public void function edit( required struct rc ) {
    param rc.modal=false;
    param rc.editable=true;
    param rc.inline=false;
    param rc.formprepend="";
    param rc.formappend="";
    param rc.namePrepend="";
    param rc.tabs=[];

    rc.submitButtons = variables.submitButtons;
    rc.fallbackView = ":elements/edit";

    if ( rc.modal ) {
      request.layout = false;
      rc.fallbackView = ":elements/modaledit";

      if ( rc.inline ) {
        rc.fallbackView = ":elements/inlineedit";
      }
    }

    rc.entity = variables.entity;

    // is this a loggable object?
    var object = entityNew( variables.entity );
    var entityInstanceVars = object.getInstanceVariables( );

    rc.canBeLogged = ( config.log && isInstanceOf( object, "#config.root#.model.logged" ) && rc.entity != "logentry" );

    // load form properties
    rc.properties = entityInstanceVars.properties;

    var propertiesInForm = [ ];

    for ( var key in rc.properties ) {
      if ( structKeyExists( rc.properties[ key ], "inform" ) ) {
        arrayAppend( propertiesInForm, rc.properties[ key ] );
      }
    }

    rc.hideDelete = structKeyExists( entityInstanceVars.settings, "hideDelete" );

    if ( structKeyExists( rc, "#rc.entity#id" ) && !len( trim( rc[ "#rc.entity#id" ] ) ) ) {
      structDelete( rc, "#rc.entity#id" );
    }

    if ( structKeyExists( rc, "#rc.entity#id" ) ) {
      rc.data = entityLoadByPK( rc.entity, rc[ "#rc.entity#id" ] );

      if ( !isDefined( "rc.data" ) ) {
        variables.framework.redirect( rc.entity );
      }
    }

    if ( isNull( rc.data ) ) {
      rc.data = object;
    }

    // prep the form fields and sort them in the right order
    var indexNr = 0;
    var columnsInForm = [ ];
    var numberOfPropertiesInForm = arrayLen( propertiesInForm ) + 10;

    for ( var property in propertiesInForm ) {
      if ( structKeyExists( property, "orderinform" ) && isNumeric( property.orderinform ) ) {
        indexNr = property.orderinform;
      } else {
        indexNr = numberOfPropertiesInForm++;
      }

      columnsInForm[ indexNr ] = duplicate( property );
      columnsInForm[ indexNr ].saved = "";

      var savedValue = evaluate( "rc.data.get#property.name#()" );

      if ( !isNull( savedValue ) ) {
        if ( isArray( savedValue ) ) {
          var savedValueList = "";
          for ( var individualValue in savedValue ) {
            savedValueList = listAppend( savedValueList, individualValue.getID( ) );
          }
          savedValue = savedValueList;
        }
        columnsInForm[ indexNr ].saved = savedValue;
      } else if ( structKeyExists( rc, property.name ) ) {
        columnsInForm[ indexNr ].saved = rc[ property.name ];
      }
    }

    rc.columns = [ ];

    for ( var columnInForm in columnsInForm ) {
      if ( !isNull( columnInForm ) ) {
        if ( !isNull( columnInForm.entityname ) ) {
          columnInForm.subclasses = createObject( "java", "java.util.Arrays" ).asList( entityNew( columnInForm.entityname ).getSubClasses( ) );
        }
        arrayAppend( rc.columns, columnInForm );
      }
    }
  }

  public void function delete( required struct rc ) {
    param rc.useAsViewEntity=variables.entity;

    if ( !securityService.can( "delete", variables.framework.getSection( ) ) ) {
      rc.alert = {
        "class" = "danger",
        "text" = "privileges-error"
      };
      variables.framework.redirect( rc.useAsViewEntity & ".default", "alert" );
    }

    url[ "#variables.entity#id" ] = rc[ "#variables.entity#id" ];

    variables.crudService.deleteEntity( variables.entity );

    variables.framework.redirect( rc.useAsViewEntity & ".default" );
  }

  public void function restore( required struct rc ) {
    param rc.useAsViewEntity=variables.entity;

    url[ "#variables.entity#id" ] = rc[ "#variables.entity#id" ];

    variables.crudService.restoreEntity( variables.entity );

    variables.framework.redirect( rc.useAsViewEntity & ".view", "#variables.entity#id" );
  }

  public void function save( required struct rc ) {
    param rc.useAsViewEntity=variables.entity;

    if ( structCount( form ) == 0 ) {
      rc.alert = {
        "class" = "danger",
        "text" = "global-form-error"
      };
      variables.framework.redirect( rc.useAsViewEntity & ".default", "alert" );
    }

    if ( !securityService.can( "change", variables.framework.getSection( ) ) ) {
      rc.alert = {
        "class" = "danger",
        "text" = "privileges-error"
      };
      variables.framework.redirect( rc.useAsViewEntity & ".default", "alert" );
    }

    rc.savedEntity = variables.crudService.saveEntity( variables.entity );

    if ( !( structKeyExists( rc, "dontredirect" ) && rc.dontredirect ) ) {
      if ( structKeyExists( rc, "returnto" ) ) {
        variables.framework.redirect( rc.returnto );
      } else {
        variables.framework.redirect( rc.useAsViewEntity & ".default" );
      }
    }
  }
}