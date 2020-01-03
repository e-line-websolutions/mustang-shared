component accessors=true {
  property logService;
  property utilityService;

  // PUBLIC

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
        if ( entityToSave.propertyExists( key ) ) {
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
        "crudService.changeEntityDeletedState.missingPrimaryKeyError"
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