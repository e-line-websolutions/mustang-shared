component accessors=true {
  property logService;
  property utilityService;
  property permissionService;
  property beanfactory;

  // PUBLIC

  public struct function list(
    required string entityName,
    properties,
    showdeleted = false,
    filters = [],
    filterType,
    orderByString = '',
    maxResults = 0,
    offset = 0,
    entityInstanceVars
  ) {
    var result = {};
    var queryOptions = { ignorecase = true };
    var params = { 'deleted' = !showdeleted };

    if ( maxResults > 0 ) queryOptions.maxResults = maxResults;
    if ( offset > 0 ) queryOptions.offset = offset;

    if ( !isNull( permissionService.getFilterForEntity ) ) {
      filters.addAll( permissionService.getFilterForEntity( entityName ) );
    }

    if ( !filters.isEmpty() ) {
      var alsoFilterKeys = properties.findKey( 'alsoFilter' );
      var alsoFilterEntity = '';
      var whereBlock = ' WHERE 0 = 0 ';
      var whereParameters = {};
      var counter = 0;

      if ( showdeleted == 0 ) {
        whereBlock &= ' AND ( mainEntity.deleted IS NULL OR mainEntity.deleted = false ) ';
      }

      filters.each( function( filter ) {
        if ( !isArray( filter.filterOn ) ) {
          filter.filterOn = [ filter.filterOn ];
        }

        whereBlock &= ' AND ( 1 = 0 ';

        filter.filterOn.each( function( filterOn, idx ) {
          if ( len( filter.field ) > 2 && right( filter.field, 2 ) == 'id' ) {
            whereBlock &= 'OR mainEntity.#filter.field.left( filter.field.len() - 2 )# = ( FROM #filter.field.left( filter.field.len() - 2 )# WHERE id = :where_id_#idx# )';
            whereParameters[ 'where_id_#idx#' ] = filterOn;
          } else {
            if ( filterOn == 'NULL' ) {
              whereBlock &= ' OR ( ';
              whereBlock &= ' mainEntity.#filter.field.lCase()# IS NULL ';
            } else if ( properties[ filter.field ].keyExists( 'cfc' ) ) {
              whereBlock &= ' OR ( ';
              whereBlock &= ' mainEntity.#filter.field.lCase()#.id = :where_#filter.field.lCase()#_#idx# ';
              whereParameters[ 'where_#filter.field.lCase()#_#idx#' ] = filterOn;
            } else if ( filter.keyExists( 'operator' ) ) {
              whereBlock &= ' OR ( ';
              whereBlock &= ' mainEntity.#filter.field.lCase()# #filter.operator# :where_#filter.field.lCase()#_#idx# ';
              whereParameters[ 'where_#filter.field.lCase()#_#idx#' ] = filterOn;
            } else {
              if ( filterType == 'contains' ) {
                filterOn = '%#filterOn#';
              }

              filterOn = '#filterOn#%';

              whereBlock &= ' OR ( ';
              whereBlock &= ' mainEntity.#filter.field.lCase()# LIKE :where_#filter.field.lCase()#_#idx# ';
              whereParameters[ 'where_#filter.field.lCase()#_#idx#' ] = filterOn;
            }

            alsoFilterKeys.each( function( alsoFilterKey ) {
              if ( alsoFilterKey.owner.name eq filter.field ) {
                counter++;
                alsoFilterEntity &= ' LEFT JOIN mainEntity.#alsoFilterKey.owner.alsoFilter.listFirst( '.' )# AS entity_#counter# ';
                whereBlock &= ' OR entity_#counter#.#alsoFilterKey.owner.alsoFilter.listLast( '.' )# LIKE ''#filterOn#'' ';
                whereParameters[ 'where_#alsoFilterKey.owner.alsoFilter.listLast( '.' )#' ] = filterOn;
              }
            } );

            whereBlock &= ' ) ';
          }
        } );

        whereBlock &= ' ) ';
      } );

      if ( entityInstanceVars.settings.keyExists( 'where' ) && len( trim( entityInstanceVars.settings.where ) ) ) {
        whereBlock &= entityInstanceVars.settings.where;
      }

      var HQLcounter = ' SELECT COUNT( mainEntity ) AS total ';
      var HQLselector = ' SELECT mainEntity ';

      var HQL = '';
      HQL &= ' FROM #entityName.lCase()# mainEntity ';
      HQL &= alsoFilterEntity;
      HQL &= whereBlock;

      HQLcounter = HQLcounter & HQL;
      HQLselector = HQLselector & HQL;

      if ( len( trim( orderByString ) ) ) {
        HQLselector &= ' ORDER BY #orderByString# ';
      }

      result.alldata = ormExecuteQuery( HQLselector, whereParameters, queryOptions );

      if ( !result.alldata.isEmpty() ) {
        result.recordCounter = ormExecuteQuery( HQLcounter, whereParameters, { ignorecase = true } )[ 1 ];
      }
    } else {
      var HQL = ' FROM #entityName.lCase()# mainEntity WHERE ( mainEntity.deleted <> :deleted ) ';

      if ( len( trim( orderByString ) ) ) {
        HQL &= ' ORDER BY #orderByString# ';
      }

      result.alldata = ormExecuteQuery( HQL, params, queryOptions );

      if ( !result.alldata.isEmpty() ) {
        result.recordCounter = ormExecuteQuery(
          'SELECT COUNT( e ) AS total FROM #entityName.lCase()# AS e WHERE e.deleted != :deleted',
          params,
          { 'ignorecase' = true }
        )[ 1 ];
        result.deleteddata = ormExecuteQuery(
          'SELECT COUNT( mainEntity.id ) AS total FROM #entityName.lCase()# AS mainEntity WHERE mainEntity.deleted = :deleted',
          params
        )[ 1 ];

        if ( showdeleted ) {
          result.recordCounter = result.deleteddata;
        }
      }
    }

    return result;
  }

  public component function saveEntity( required string entityName ) {
    var formData = getFormData( );

    // Load existing, or create a new entity
    if ( formData.keyExists( "#entityName#id" ) ) {
      var entityToSave = entityLoadByPK( entityName, formData[ "#entityName#id" ] );
    } else {
      var entityToSave = entityNew( entityName );
    }

    var entityProperties = entityToSave.getInheritedProperties( );

    for ( var key in entityProperties ) {
      var fieldDefinition = entityProperties[ key ];
      param fieldDefinition.fieldType = "string";
      if ( !formData.keyExists( key ) && ( fieldDefinition.fieldType == 'boolean' || fieldDefinition.fieldType == 'bit' ) ) {
        formData[ key ] = false;
      }
    }

    var inlineEditProperties = structFindKey( entityProperties, "inlineedit", "all" );

    // add inline form as sub items to be saved along side the main entity:
    for ( var property in inlineEditProperties ) {
      var property = property.owner;
      var fieldPrefix = property.name;
      var prefixedFields = reMatchNoCase( "#fieldPrefix#_[^,]+", form.FIELDNAMES );
      var inlineData = { };

      if ( !arrayIsEmpty( prefixedFields ) ) {
        var subclass = fieldPrefix;

        if( form.keyExists( "_#fieldPrefix#_subclass" ) ) {
          subclass = form[ "_#fieldPrefix#_subclass" ];
          inlineData[ "__subclass" ] = subclass;
        }

        var pkField = "#subclass#id";

        if ( form.keyExists( pkField ) ) {
          structDelete( formData, pkField );
          inlineData[ pkField ] = form[ pkField ];
        }

        for ( var field in prefixedFields ) {
          structDelete( formData, field );

          if ( form.keyExists( field ) && len( form[ field ] ) ) {
            inlineData[ listRest( field, "_" ) ] = form[ field ];
          }
        }

        if ( !structIsEmpty( inlineData ) ) {
          formData[ fieldPrefix ] = inlineData;
        }
      }
    }

    transaction {
      var result = entityToSave.save( formData );

      // save empty fields:
      for ( var key in formData ) {
        if ( entityToSave.propertyExists( key ) && entityProperties.keyExists( key ) ) {
          var fieldDefinition = entityProperties[ key ];
          param fieldDefinition.fieldType='string';
          if ( fieldDefinition.fieldType == 'string' && isSimpleValue( formData[ key ] ) && !len( trim( formData[ key ] ) ) ) {
            invoke( entityToSave, "set#key#", { '#key#' = '' } );
          }
        }
      }
    }

    variables.logService.writeLogLevel( "Entity '#entityName#' saved" );

    return result;
  }

  public void function deleteEntity( required string entityName ) {
    changeEntityDeletedState( entityName, true );
  }

  public void function restoreEntity( required string entityName) {
    changeEntityDeletedState( entityName, false );
  }

  // PRIVATE

  private void function changeEntityDeletedState( required string entityName, required boolean state ) {
    var formData = getFormData( );

    if ( !formData.keyExists( "#entityName#id" ) ) {
      throw(
        "Cannot change deleted state of #entityName#, missing primary key",
        "missingPrimaryKeyError.changeEntityDeletedState.crudService"
      );
    }

    var entityToDelete = entityLoadByPK( entityName, formData[ "#entityName#id" ] );

    if ( !isNull( entityToDelete ) ) {
      transaction {
        variables.utilityService.cfinvoke( entityToDelete, ( state ? "delete" : "restore" ) );
      }
      variables.logService.writeLogLevel( "Entity '" & entityName & "' marked as " & ( state ? "deleted" : "restored" ) );
    }
  }

  private struct function getFormData() {
    var formData = {};
    return formData
      .append( url )
      .append( form );
  }
}
