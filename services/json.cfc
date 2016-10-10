/**
  * Copyright 2009 Nathan Mische
  *
  * Licensed under the Apache License, Version 2.0 ( the "License" );
  * you may not use this file except in compliance with the License.
  * You may obtain a copy of the License at
  *
  *     http://www.apache.org/licenses/LICENSE-2.0
  *
  * Unless required by applicable law or agreed to in writing, software
  * distributed under the License is distributed on an "AS IS" BASIS,
  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  * See the License for the specific language governing permissions and
  * limitations under the License.
  *
  * @version 2.0 2016 Scripted by @mjhagen
 */
component {
  this.deserialize = deserializeFromJSON;
  this.serialize = serializeToJSON;
  this.deserializeJSON = deserializeFromJSON;
  this.serializeJSON = serializeToJSON;
  this.isLuceeRailo = structKeyExists( server, "lucee" ) || structKeyExists( server, "railo" );

  variables.escapeVals = [
    "\,"",/,\b,\t,\n,\f,\r",
    "\,"",/,#chr( 8 )#,#chr( 9 )#,#chr( 10 )#,#chr( 12 )#,#chr( 13 )#",
    '\,",/,b,t,n,f,r',
    '\,",/,#chr( 8 )#,#chr( 9 )#,#chr( 10 )#,#chr( 12 )#,#chr( 13 )#'
  ];

  public component function init( ) {
    return this;
  }

  /** Converts a JSON (JavaScript Object Notation) string data representation into CFML data, such as a CFML structure or array.
    *
    * @JSONVar A string that contains a valid JSON construct, or variable that represents one.
    * @strictMapping A Boolean value that specifies whether to convert the JSON strictly, as follows:
    *  <ul>
    *    <li><code>true:</code> ( Default ) Convert the JSON string to ColdFusion data types that correspond directly to the JSON data types.</li>
    *    <li><code>false:</code> Determine if the JSON string contains representations of ColdFusion queries, and if so, convert them to queries.</li>
    *  </ul>
    */
  public any function deserializeFromJSON( required string JSONVar, boolean strictMapping = true ) {
    var _data = trim( JSONVar );
    var ar = [ ];
    var st = { };
    var stringPattern = "^"".+""|'.+'$";

    if ( isNumeric( _data ) ) {
      return val( _data );
    } else if ( _data == "null" ) {
      return "null";
    } else if ( listFindNoCase( "true,false", _data ) ) {
      return _data;
    } else if ( _data == "''" || _data == '""' ) {
      return "";
    } else if ( reFind( stringPattern, _data ) == 1 ) {
      _data = mid( _data, 2, len( _data ) - 2 );

      if ( find( "\b", _data ) || find( "\t", _data ) || find( "\n", _data ) || find( "\f", _data ) || find( "\r", _data ) || find( "\\", _data ) || find(
        "\/",
        _data
      ) ) {
        var curCharIndex = 0;
        var dJSONString = [ ];

        while ( true ) {
          curCharIndex = curCharIndex + 1;
          if ( curCharIndex GT len( _data ) ) {
            break;
          } else {
            var curChar = mid( _data, curCharIndex, 1 );
            if ( curChar == "\" ) {
              curCharIndex = curCharIndex + 1;
              curChar = mid( _data, curCharIndex, 1 );
              var pos = listFind( variables.escapeVals[ 3 ], curChar );
              if ( pos ) {
                arrayAppend( dJSONString, ListGetAt( variables.escapeVals[ 4 ], pos ) );
              } else {
                arrayAppend( dJSONString, "\" & curChar );
              }
            } else {
              arrayAppend( dJSONString, curChar );
            }
          }
        }

        return arrayToList( dJSONString, "" );
      }

      return replaceList( _data, variables.escapeVals[ 1 ], variables.escapeVals[ 2 ] );
    } else if ( ( left( _data, 1 ) == "[" && right( _data, 1 ) == "]" ) || ( left( _data, 1 ) == "{" && right( _data, 1 ) == "}" ) ) {
      var dataType = "";
      if ( left( _data, 1 ) == "[" && right( _data, 1 ) == "]" ) {
        dataType = "array";
      } else if ( reFindNoCase( '^\{"ROWCOUNT":[0-9]+, "COLUMNS":\[( "[^"]+", ? )+\], "DATA":\{( "[^"]+":\[.*\], ? )+\}\}$', _data, 0 ) == 1 && !strictMapping ) {
        dataType = "queryByColumns";
      } else if ( reFindNoCase( '^\{"COLUMNS":\[( "[^"]+", ? )+\], "DATA":\[( \[.*\], ? )+\]\}$', _data, 0 ) == 1 && !strictMapping ) {
        dataType = "query";
      } else {
        dataType = "struct";
      }

      _data = trim( mid( _data, 2, len( _data ) - 2 ) );

      if ( len( _data ) == 0 ) {
        if ( dataType == "array" ) {
          return ar;
        } else {
          return st;
        }
      }

      var dataSize = len( _data ) + 1;
      var i = 1;
      var inQuotes = false;
      var nestingLevel = 0;
      var startPos = 1;

      while ( i <= dataSize ) {
        var skipIncrement = false;
        var char = mid( _data, i, 1 );

        if ( char == '"' ) {
          inQuotes = !inQuotes;
        } else if ( char == "\" && inQuotes ) {
          i = i + 2;
          skipIncrement = true;
        } else if ( ( char == "," && !inQuotes && nestingLevel == 0 ) || i == len( _data ) + 1 ) {
          var dataStr = trim( mid( _data, startPos, i - startPos ) );

          if ( dataType == "array" ) {
            arrayappend( ar, deserializeFromJSON( dataStr, strictMapping ) );
          } else if ( dataType == "struct" || dataType == "query" || dataType == "queryByColumns" ) {
            var colonPos = reFind( '"\s{0,}:', dataStr, 2, true );
            var structKey = trim( mid( dataStr, 1, colonPos.pos[ 1 ] ) );

            if ( ( left( structKey, 1 ) == "'" && right( structKey, 1 ) == "'" ) ||
               ( left( structKey, 1 ) == '"' && right( structKey, 1 ) == '"' ) ) {
              structKey = len( structKey ) > 2 ? mid( structKey, 2, len( structKey ) - 2 ) : "";
            }

            var structVal = mid( dataStr, colonPos.pos[ 1 ] + colonPos.len[ 1 ], len( dataStr ) - colonPos.pos[ 1 ] );

            if ( dataType == "struct" && len( structKey ) ) {
              st[ structKey ] = deserializeFromJSON( structVal, strictMapping );
            } else if ( dataType == "queryByColumns" ) {
              var qRows = 0;
              if ( structKey == "rowcount" ) {
                qRows = deserializeFromJSON( structVal, strictMapping );
              } else if ( structKey == "columns" ) {
                var qCols = deserializeFromJSON( structVal, strictMapping );
                st = QueryNew( arrayToList( qCols ) );
                if ( qRows ) {
                  QueryAddRow( st, qRows );
                }
              } else if ( structKey == "data" ) {
                var qData = deserializeFromJSON( structVal, strictMapping );
                ar = structKeyArray( qData );

                for ( var j = 1; j <= ArrayLen( ar ); j++ ) {
                  for ( var qRows = 1; qRows <= st.recordcount; qRows++ ) {
                    var qCol = ar[ j ];
                    QuerySetCell( st, qCol, qData[ qCol ][ qRows ], qRows );
                  }
                }
              }
            } else if ( dataType == "query" ) {
              if ( structKey == "columns" ) {
                var qCols = deserializeFromJSON( structVal, strictMapping );
                st = QueryNew( arrayToList( qCols ) );
              } else if ( structKey == "data" ) {
                var qData = deserializeFromJSON( structVal, strictMapping );
                for ( var qRows = 1; qRows <= ArrayLen( qData ); qRows++ ) {
                  QueryAddRow( st );
                  for ( var j = 1; j <= ArrayLen( qCols ); j++ ) {
                    var qCol = qCols[ j ];
                    QuerySetCell( st, qCol, qData[ qRows ][ j ], qRows );
                  }
                }
              }
            }
          }

          startPos = i + 1;
        } else if ( "{[" CONTAINS char && !inQuotes ) {
          nestingLevel = nestingLevel + 1;
        } else if ( "]}" CONTAINS char && !inQuotes ) {
          nestingLevel = nestingLevel - 1;
        }

        if ( !skipIncrement ) {
          i++;
        }
      }

      if ( dataType == "array" ) {
        return ar;
      }

      return st;
    }

    throw( "JSON parsing failure.", "jsonService.deserializeFromJSON.parsingError", "" );
  }

  /** Converts ColdFusion data into a JSON (JavaScript Object Notation) representation of the data.
    *
    * @variable A ColdFusion data value or variable that represents one.
    * @serializeQueryByColumns A Boolean value that specifies how to serialize ColdFusion queries.
    *  <ul>
    *    <li><code>false</code>: (Default) Creates an object with two entries: an array of column names and an array of row arrays. This format is required by the HTML format cfgrid tag.</li>
    *    <li><code>true</code>: Creates an object that corresponds to WDDX query format.</li>
    *  </ul>
    * @strictMapping A Boolean value that specifies whether to convert the ColdFusion data strictly, as follows:
    *  <ul>
    *    <li><code>false:</code> (Default) Convert the ColdFusion data to a JSON string using ColdFusion data types.</li>
    *    <li><code>true:</code> Convert the ColdFusion data to a JSON string using underlying Java/SQL data types.</li>
    *  </ul>
    */
  public string function serializeToJSON( required any variable, boolean serializeQueryByColumns = false, boolean strictMapping = false ) {
    var escapeToVals = variables.escapeVals[ 1 ];
    var escapeVals = variables.escapeVals[ 2 ];
    var _data = variable;
    var className = strictMapping ? __getClassName( _data ) : "";

    if ( len( className ) ) {
      if ( compareNoCase( className, "java.lang.String" ) == 0 ) {
        return '"' & replaceList( _data, escapeVals, escapeToVals ) & '"';
      } else if ( compareNoCase( className, "java.lang.Boolean" ) == 0 ) {
        return _data ? true : false;
      } else if ( compareNoCase( className, "java.lang.Integer" ) == 0 ) {
        return toString( _data );
      } else if ( compareNoCase( className, "java.lang.Long" ) == 0 ) {
        return toString( _data );
      } else if ( compareNoCase( className, "java.lang.Float" ) == 0 ) {
        return toString( _data );
      } else if ( compareNoCase( className, "java.lang.Double" ) == 0 ) {
        return toString( _data );
      }
    } else {
      if ( isBinary( _data ) ) {
        throw "JSON serialization failure: Unable to serialize binary data to JSON.";
      } else if ( isBoolean( _data ) && !isNumeric( _data ) ) {
        return _data ? true : false; // replaceList( yesNoFormat( _data ), 'Yes,No', 'true,false' );
      } else if ( isNumeric( _data ) && len( trim( _data ) ) == len( val( _data ) ) ) {
        if ( __getClassName( _data ) == "java.lang.String" ) {
          return val( _data ).toString( );
        } else {
          return _data.toString( );
        }
      } else if ( __isValidDate( _data ) ) {
        return '"#DateFormat( _data, "mmmm, dd yyyy" )# #TimeFormat( _data, "HH:mm:ss" )#"';
      } else if ( isSimpleValue( _data ) ) {
        return __writeJsonUtf8String( _data );
      } else if ( this.isLuceeRailo && isXML( _data ) ) {
        return '"' & replaceList( toString( _data ), escapeVals, escapeToVals ) & '"';
      } else if ( isCustomFunction( _data ) ) {
        return serializeToJSON( getMetadata( _data ), serializeQueryByColumns, strictMapping );
      } else if ( isObject( _data ) ) {
        return "{}";
      } else if ( isArray( _data ) ) {
        var dJSONString = [ ];

        for ( var _dataEl in _data ) {
          if ( !isNull( _dataEl ) ) {
            var tempVal = serializeToJSON( _dataEl, serializeQueryByColumns, strictMapping );
            arrayAppend( dJSONString, tempVal );
          }
        }

        return "[" & arrayToList( dJSONString, "," ) & "]";
      } else if ( isStruct( _data ) ) {
        var dJSONString = [ ];
        var arKeys = structKeyArray( _data );

        for ( var i = 1; i <= arrayLen( arKeys ); i++ ) {
          var tempVal = "null";

          if ( isDefined( "_data.#arKeys[ i ]#" ) ) {
            tempVal = serializeToJSON( _data[ arKeys[ i ] ], serializeQueryByColumns, strictMapping );
          }

          arrayAppend( dJSONString, '"' & arKeys[ i ] & '":' & tempVal );
        }

        return "{" & arrayToList( dJSONString, "," ) & "}";
      } else if ( isQuery( _data ) ) {
        var dJSONString = [ ];
        var recordcountKey = "ROWCOUNT";
        var columnlistKey = "COLUMNS";
        var columnlist = "";
        var dataKey = "DATA";
        var md = getMetadata( _data );
        var columnJavaTypes = { };

        for ( var i = 1; i <= arrayLen( md ); i++ ) {
          columnlist = listAppend( columnlist, UCase( md[ i ].Name ), ', ' );
          columnJavaTypes[ md[ i ].Name ] = "";

          if ( structKeyExists( md[ i ], "TypeName" ) ) {
            columnJavaTypes[ md[ i ].Name ] = __getJavaType( md[ i ].TypeName );
          }
        }

        if ( serializeQueryByColumns ) {
          arrayAppend( dJSONString, '"#recordcountKey#":' & _data.recordcount );
          arrayAppend( dJSONString, ', "#columnlistKey#":[' & listQualify( columnlist, '"' ) & ']' );
          arrayAppend( dJSONString, ', "#dataKey#":{' );

          var colDel = "";

          for ( var column in listToArray( columnlist ) ) {
            arrayAppend( dJSONString, colDel );
            arrayAppend( dJSONString, '"#column#":[' );

            var rowDel = "";

            for ( var i = 1; i <= _data.recordcount; i++ ) {
              arrayAppend( dJSONString, rowDel );

              if ( ( strictMapping || this.isLuceeRailo ) && len( columnJavaTypes[ column ] ) ) {
                tempVal = serializeToJSON( JavaCast( columnJavaTypes[ column ], _data[ column ][ i ] ), serializeQueryByColumns, strictMapping );
              } else {
                tempVal = serializeToJSON( _data[ column ][ i ], serializeQueryByColumns, strictMapping );
              }

              arrayAppend( dJSONString, tempVal );
              rowDel = ",";
            }

            arrayAppend( dJSONString, ']' );
            colDel = ",";
          }

          arrayAppend( dJSONString, '}' );
        } else {
          arrayAppend( dJSONString, '"#columnlistKey#":[' & listQualify( columnlist, '"' ) & ']' );
          arrayAppend( dJSONString, ', "#dataKey#":[' );

          var rowDel = "";

          for ( var i = 1; i <= _data.recordcount; i++ ) {
            arrayAppend( dJSONString, rowDel );
            arrayAppend( dJSONString, '[' );

            var colDel = "";

            for ( var column in listToArray( columnlist ) ) {
              arrayAppend( dJSONString, colDel );

              if ( ( strictMapping || this.isLuceeRailo ) && len( columnJavaTypes[ column ] ) ) {
                tempVal = serializeToJSON( JavaCast( columnJavaTypes[ column ], _data[ column ][ i ] ), serializeQueryByColumns, strictMapping );
              } else {
                tempVal = serializeToJSON( _data[ column ][ i ], serializeQueryByColumns, strictMapping );
              }

              arrayAppend( dJSONString, tempVal );
              colDel = ",";
            }

            arrayAppend( dJSONString, ']' );
            rowDel = ",";
          }

          arrayAppend( dJSONString, ']' );
        }

        return "{" & arrayToList( dJSONString, "" ) & "}";
      } else if ( isXML( _data ) ) {
        return '"' & replaceList( toString( _data ), escapeVals, escapeToVals ) & '"';
      }
    }

    return "{}";
  }

  /** Maps SQL to Java types. Returns blank string for unhandled SQL types.
    * @sqlType A SQL datatype.
    */
  private string function __getJavaType( required string sqlType ) {
    switch ( sqlType ) {
      case "bit" :
        return "boolean";

      case "tinyint" :
      case "smallint" :
      case "integer" :
        return "int";

      case "bigint" :
        return "long";

      case "real" :
      case "float" :
        return "float";

      case "double" :
        return "double";

      case "char" :
      case "varchar" :
      case "longvarchar" :
        return "string";
    }

    return "";
  }

  /** Returns a variable's underlying java Class name.
    *
    * @data A variable.
    */
  private string function __getClassName( required any data ) {
    try {
      return data.getClass( ).getName( );
    } catch ( any e ) {
      return "";
    }
  }

  /** Returns a valid json escaped string
    *
    * @data A string to serialze.
    */
  private string function __writeJsonUtf8String( required string data ) {
    var javaInteger = createObject( "java", "java.lang.Integer" );
    var result = '"';
    var end = len( data );

    for ( var i = 0; i < end; i++ ) {
      var nextChar = data.charAt( i );

      if ( asc( nextChar ) < 32 ) {
        if ( nextChar == chr( 8 ) ) {
          result &= "\b";
        } else if ( nextChar == chr( 9 ) ) {
          result &= "\t";
        } else if ( nextChar == chr( 10 ) ) {
          result &= "\n";
        } else if ( nextChar == chr( 12 ) ) {
          result &= "\f";
        } else if ( nextChar == chr( 13 ) ) {
          result &= "\r";
        } else {
          result &= "\u#right( '0000' & javaInteger.toHexString( nextChar ), 4 )#";
        }
      } else if ( nextChar == '\' || nextChar == '/' || nextChar == '"' ) {
        result &= "\" & nextChar;
      } else {
        result &= nextChar;
      }
    }

    result &= '"';

    return result;
  }

  private boolean function __isValidDate( required potentialDate ) {
    var delims = "- /.";

    if ( __getClassName( potentialDate ) contains "date" ) {
      return true;
    }

    if ( !isSimpleValue( potentialDate ) ) {
      return false;
    }

    if ( listLen( potentialDate, delims ) == 3 ) {
      var basicDateTest = "^([\d]{2}[#delims#][\d]{2}[#delims#][\d]{4})|([\d]{4}[#delims#][\d]{2}[#delims#][\d]{2})|([\d]{2}[#delims#][\d]{2}[#delims#][\d]{2})$";
      if ( reFind( basicDateTest, potentialDate ) == 0 ) {
        return false;
      }
    }

    try {
      lsParseDateTime( potentialDate, getLocale( ) );
      return true;
    } catch ( any e ) {
    }

    return false;
  }
}