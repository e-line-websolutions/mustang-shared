component {
  /** Converts query to an array full of structs
    *
    * @query    A ColdFusion query
    */
  public array function toArray( required query query ) {
    var result = [];
    var meta = listToArray( query.columnList );

    for( var i=1; i<=query.recordCount; i++ ) {
      var row = {};
      for( var col in meta ) {
        row[col] = query[col][i];
      }
      arrayAppend( result, row );
    }

    return result;
  }

  /** Backports CF11's queryExecute() to CF9 & CF10
    *
    * @sql_statement  The SQL statement to execute
    * @queryParams    Array, or struct of query parameters
    * @queryOptions   Struct with query options (like datasource)
    *
    * @author   Henry Ho (henryho167@gmail.com), Mingo Hagen (email@mingo.nl)
    * @version  1, September 22, 2014
    * @version  2, December 29, 2015
    */
  public any function execute( required string sql_statement, any queryParams={}, struct queryOptions={}) {
    if( structKeyExists( server, "railo" ) ||
        structKeyExists( server, "lucee" ) || (
          structKeyExists( server, "coldfusion" ) &&
          int( listFirst( server.coldfusion.productVersion )) >= 11
        )) {
      return queryExecute( sql_statement, queryParams, queryOptions );
    }

    // normalize query params:
    var parameters = [];
    if( isArray( queryParams )) {
      for( var param in queryParams ) {
        if( isNull( param )) {
          arrayAppend( parameters, { "null" = true } );
        } else if( isSimpleValue( param )) {
          arrayAppend( parameters, { "value" = param });
        } else {
          arrayAppend( parameters, param );
        }
      }
    } else if( isStruct( queryParams )) {
      for( var key in queryParams ) {
        if( isSimpleValue( queryParams[key])) {
          arrayAppend( parameters, { "name" = key, "value" = queryParams[key]});
        } else {
          var parameter = { "name" = key };
          structAppend( parameter, queryParams[key]);
          arrayAppend( parameters, parameter );
        }
      }
    } else {
      throw "unexpected type for queryParams";
    }

    // run and return query using query.cfc:
    return new query( sql = sql_statement, parameters = parameters, argumentCollection = queryOptions ).execute().getResult();
  }

  /** Courtesy of user 'Tomalak' from http://stackoverflow.com/questions/2653804/how-to-sort-an-array-of-structs-in-coldfusion#answer-2653972
    */
  public array function arrayOfStructSort( required array base, string sortType="text", string sortOrder="ASC", string pathToSubElement="" ) {
    var tmpStruct = {};
    var returnVal = [];

    for( var i=1; i<=arrayLen( base ); i++ ) {
      tmpStruct[i] = base[i];
    }

    var keys = structSort( tmpStruct, sortType, sortOrder, pathToSubElement );

    for( var i=1; i<=arrayLen( keys ); i++ ) {
      returnVal[i] = tmpStruct[keys[i]];
    }

    return returnVal;
  }
}