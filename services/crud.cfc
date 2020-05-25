component accessors=true {
  property logService;
  property utilityService;
  property permissionService;
  property beanfactory;

  // PUBLIC

  public struct function list( required string entityName, properties, showdeleted, filters, filterType, orderByString, maxResults, offset, entityInstanceVars ) {
    var result = {};

    var queryOptions = {
      ignorecase = true,
      maxResults = maxResults,
      offset = offset
    };

    if ( !isNull( permissionService.getFilterForEntity ) ) {
      filters.addAll( permissionService.getFilterForEntity( entityName ) );
    }

    if ( arrayLen( filters ) ) {
      var alsoFilterKeys = structFindKey( properties, 'alsoFilter' );
      var alsoFilterEntity = "";
      var whereBlock = " WHERE 0 = 0 ";
      var whereParameters = { };
      var counter = 0;

      if ( showdeleted == 0 ) {
        whereBlock &= " AND ( mainEntity.deleted IS NULL OR mainEntity.deleted = false ) ";
      }

      for ( var filter in filters ) {
        if( !isArray( filter.filterOn ) ) {
          filter.filterOn = [ filter.filterOn ];
        }

        whereBlock &= " AND ( 1 = 0 ";

        for( var filterOn in filter.filterOn ) {
          if ( len( filter.field ) > 2 && right( filter.field, 2 ) == "id" ) {
            whereBlock &= "OR mainEntity.#left( filter.field, len( filter.field ) - 2 )# = ( FROM #left( filter.field, len( filter.field ) - 2 )# WHERE id = :where_id )";
            whereParameters[ "where_id" ] = filterOn;
          } else {
            if ( filterOn == "NULL" ) {
              whereBlock &= " OR ( ";
              whereBlock &= " mainEntity.#lCase( filter.field )# IS NULL ";
            } else if ( structKeyExists( properties[ filter.field ], "cfc" ) ) {
              whereBlock &= " OR ( ";
              whereBlock &= " mainEntity.#lCase( filter.field )#.id = :where_#lCase( filter.field )# ";
              whereParameters[ "where_#lCase( filter.field )#" ] = filterOn;
            } else {
              if ( filterType == "contains" ) {
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
      HQL &= " FROM #lCase( entityName )# mainEntity ";
      HQL &= alsoFilterEntity;
      HQL &= whereBlock;

      HQLcounter = HQLcounter & HQL;
      HQLselector = HQLselector & HQL;

      if ( len( trim( orderByString ) ) ) {
        HQLselector &= " ORDER BY #orderByString# ";
      }

      result.alldata = ORMExecuteQuery( HQLselector, whereParameters, queryOptions );

      if ( !result.alldata.isEmpty() ) {
        result.recordCounter = ORMExecuteQuery( HQLcounter, whereParameters, { ignorecase = true } )[ 1 ];
      }
    } else {
      var HQL = " FROM #lCase( entityName )# mainEntity ";

      if ( showdeleted ) {
        HQL &= " WHERE mainEntity.deleted = TRUE ";
      } else {
        HQL &= " WHERE ( mainEntity.deleted IS NULL OR mainEntity.deleted = FALSE ) ";
      }

      if ( len( trim( orderByString ) ) ) {
        HQL &= " ORDER BY #orderByString# ";
      }

      result.alldata = ORMExecuteQuery( HQL, { }, queryOptions );

      if ( !result.alldata.isEmpty() ) {
        result.recordCounter = ORMExecuteQuery(
          "SELECT COUNT( e ) AS total FROM #lCase( entityName )# AS e WHERE e.deleted != :deleted",
          { "deleted" = true },
          { ignorecase = true }
        )[ 1 ];
        result.deleteddata = ORMExecuteQuery(
          "SELECT COUNT( mainEntity.id ) AS total FROM #lCase( entityName )# AS mainEntity WHERE mainEntity.deleted = :deleted",
          { "deleted" = true }
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
    if ( structKeyExists( formData, "#entityName#id" ) ) {
      var entityToSave = entityLoadByPK( entityName, formData[ "#entityName#id" ] );
    } else {
      var entityToSave = entityNew( entityName );
    }

    var entityProperties = entityToSave.getInheritedProperties( );

    for ( var key in entityProperties ) {
      var fieldDefinition = entityProperties[ key ];
      param fieldDefinition.fieldType = "string";
      if ( !structKeyExists( formData, key ) && ( fieldDefinition.fieldType == 'boolean' || fieldDefinition.fieldType == 'bit' ) ) {
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

        if( structKeyExists( form, "_#fieldPrefix#_subclass" ) ) {
          subclass = form[ "_#fieldPrefix#_subclass" ];
          inlineData[ "__subclass" ] = subclass;
        }

        var pkField = "#subclass#id";

        if ( structKeyExists( form, pkField ) ) {
          structDelete( formData, pkField );
          inlineData[ pkField ] = form[ pkField ];
        }

        for ( var field in prefixedFields ) {
          structDelete( formData, field );

          if ( structKeyExists( form, field ) && len( form[ field ] ) ) {
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

    if ( !structKeyExists( formData, "#entityName#id" ) ) {
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

  private struct function getFormData( ) {
    var formData = { };

    structAppend( formData, url );
    structAppend( formData, form );

    return formData;
  }
}