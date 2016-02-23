component accessors=true {
  public numeric function sanitizeNumericValue( number ) {
    return reReplace( number, '[^\d-\.]+', '', 'all' );
  }

  public boolean function isGUID( required string text ) {
    if( len( text ) < 32 ) {
      return false;
    }

    var validGUID = isValid( "guid", text );

    if( validGUID ) {
      return true;
    }

    return isValid( "guid", __formatAsGUID( text ));
  }

  public void function nil() {
  }

  public any function processEntity( required any data, numeric level=0, numeric maxLevel=0 ) {
    if( level == 0 ) {
      request.cacheID = createUUID();
    }

    param request.objCache = {};

    if( !structKeyExists( request.objCache, request.cacheID )) {
      request.objCache[request.cacheID] = {};
    }

    var cache = request.objCache[request.cacheID];

    if( maxLevel != 0 && level >= maxLevel ) {
      if( isObject( data ) && structKeyExists( data, "getID" )) {
        return data.getID();
      } else if ( !isSimpleValue( data )) {
        return;
      }
    }

    if( isSimpleValue( data )) {
      var result = data;

    } else if( isObject( data )) {
      var result = {};
      var md = getMetadata( data );

      if( structKeyExists( cache, data.getID())) {
        result = cache[data.getID()];
      } else {
        do {
          for( var i=1; i<=arrayLen( md.properties ); i++ ) {
            var prop = md.properties[i];

            param boolean prop.inapi=true;
            param string prop.fieldtype="column";

            if( prop.inapi && structKeyExists( data, "get" & prop.name )) {
              var allowedFieldTypes = "id,column,many-to-one,many-to-many,one-to-many";

              if( level >= 3 ) {
                allowedFieldTypes = "id,column,many-to-one";
              }

              if( level >= 4 ) {
                allowedFieldTypes = "id,column";
              }

              if( level >= 4 && !listFindNoCase( "id,name", prop.name )) {
                continue;
              }

              if( listFindNoCase( allowedFieldTypes, prop.fieldtype )) {
                var value = evaluate( "data.get#prop.name#()" );
                if( !isNull( value )) {
                  if( isObject( value ) && structKeyExists( cache, value.getID() )) {
                    continue;
                  } else {
                    result[prop.name] = processEntity( value, level + 1, maxLevel );
                  }
                }
              }
            }
          }

          if( structKeyExists( md, "extends" )) {
            md = md.extends;
          }
        } while( structKeyExists( md, "extends" ) && structKeyExists( md, "properties" ));

        cache[data.getID()] = result;
      }

    } else if( isArray( data )) {
      var result = [];
      var itemCounter = 0;

      for( var el in data ) {
        var newData = processEntity( el, level + 1, maxLevel );

        if( !isNull( newData )) {
          itemCounter++;

          if( itemCounter > 100 ) {
            arrayAppend( result, "capped at 100 results" );
            break;
          }

          arrayAppend( result, newData );
        }
      }

    } else if( isStruct( data )) {
      var result = {};
      for( var key in data ) {
        result[key] = processEntity( data[key], level + 1, maxLevel );
      }

    }

    return result;
  }

  // PRIVATE HELPER METHODS

  private string function __formatAsGUID( required string text ) {
    var massagedText = reReplace( text, '\W', '', 'all' );

    if( len( massagedText ) < 32 ) {
      return text; // return original (not my problem)
    }

    massagedText = insert( '-', massagedText, 20 );
    massagedText = insert( '-', massagedText, 16 );
    massagedText = insert( '-', massagedText, 12 );
    massagedText = insert( '-', massagedText, 8 );

    return massagedText;
  }
}