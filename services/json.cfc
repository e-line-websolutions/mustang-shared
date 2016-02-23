/**
  Copyright 2009 Nathan Mische

  Licensed under the Apache License, Version 2.0 ( the "License" );
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

  @version 2.0 2016 Scripted by @mjhagen
 */
component {
  this.deserializeJSON  = deserializeFromJSON;
  this.serializeJSON    = serializeToJSON;
  this.deserialize      = deserializeFromJSON;
  this.serialize        = serializeToJSON;
  this.isLuceeRailo     = structKeyExists( server, "lucee" ) || structKeyExists( server, "railo" );

  public component function init() {
    return this;
  }

  /**
    * Converts a JSON ( JavaScript Object Notation ) string data representation into CFML data, such as a CFML structure or array.
    *
    * @JSONVar A string that contains a valid JSON construct, or variable that represents one.
    * @strictMapping A Boolean value that specifies whether to convert the JSON strictly, as follows:
    *  <ul>
    *    <li><code>true:</code> ( Default ) Convert the JSON string to ColdFusion data types that correspond directly to the JSON data types.</li>
    *    <li><code>false:</code> Determine if the JSON string contains representations of ColdFusion queries, and if so, convert them to queries.</li>
    *  </ul>
    */
  public any function deserializeFromJSON( required string JSONVar, boolean strictMapping=true ) {
    var ar = [];
    var st = {};
    var dataType = "";
    var inQuotes = false;
    var startPos = 1;
    var nestingLevel = 0;
    var dataSize = 0;
    var i = 1;
    var skipIncrement = false;
    var j = 0;
    var char = "";
    var structVal = "";
    var qRows = 0;
    var qCols = "";
    var qCol = "";
    var qData = "";
    var curCharIndex = "";
    var curChar = "";
    var result = "";
    var unescapeVals = "\\,\"",\/,\b,\t,\n,\f,\r";
    var unescapeToVals = "\,"",/,#chr( 8 )#,#chr( 9 )#,#chr( 10 )#,#chr( 12 )#,#chr( 13 )#";
    var unescapeVals2 = '\,",/,b,t,n,f,r';
    var unescapetoVals2 = '\,",/,#chr( 8 )#,#chr( 9 )#,#chr( 10 )#,#chr( 12 )#,#chr( 13 )#';
    var dJSONString = "";
    var pos = 0;
    var _data = trim( JSONVar );

    if( isNumeric( _data )) {
      return val( _data );

    } else if( _data == "null" ) {
      return "null";

    } else if( listFindNoCase( "true,false", _data )) {
      return _data;

    } else if( _data == "''" || _data == '""' ) {
      return "";

    } else if( reFind( "^(""[^""]+""|'[^']+')$", _data ) == 1 ) {
      _data = mid( _data, 2, len( _data )-2 );

      if( find( "\b", _data ) || find( "\t", _data ) || find( "\n", _data ) || find( "\f", _data ) || find( "\r", _data ) || find( "\\", _data ) || find( "\/", _data )) {

        curCharIndex = 0;
        curChar =  "";
        dJSONString = [];

        while( true ) {
          curCharIndex = curCharIndex + 1;
          if( curCharIndex GT len( _data )) {
            break;
          } else {
            curChar = mid( _data, curCharIndex, 1 );
            if( curChar == "\" ) {
              curCharIndex = curCharIndex + 1;
              curChar = mid( _data, curCharIndex, 1 );
              pos = listFind( unescapeVals2, curChar );
              if( pos ) {
                arrayAppend( dJSONString, ListGetAt( unescapetoVals2, pos ));
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

      return replaceList( _data, unescapeVals, unescapeToVals );

    } else if(( left( _data, 1 ) == "[" && right( _data, 1 ) == "]" ) || ( left( _data, 1 ) == "{" && right( _data, 1 ) == "}" )) {
      if( left( _data, 1 ) == "[" && right( _data, 1 ) == "]" ) {
        dataType = "array";
      } else if( reFindNoCase( '^\{"ROWCOUNT":[0-9]+, "COLUMNS":\[( "[^"]+", ? )+\], "DATA":\{( "[^"]+":\[.*\], ? )+\}\}$', _data, 0 ) == 1 && NOT strictMapping ) {
        dataType = "queryByColumns";
      } else if( reFindNoCase( '^\{"COLUMNS":\[( "[^"]+", ? )+\], "DATA":\[( \[.*\], ? )+\]\}$', _data, 0 ) == 1 && NOT strictMapping ) {
        dataType = "query";
      } else {
        dataType = "struct";
      }

      _data = trim( mid( _data, 2, len( _data ) - 2 ));

      if( len( _data ) == 0 ) {
        if( dataType == "array" ) {
          return ar;
        } else {
          return st;
        }
      }

      dataSize = len( _data ) + 1;

      while( i <= dataSize ) {
        skipIncrement = false;
        char = mid( _data, i, 1 );

        if( char == '"' ) {
          inQuotes = NOT inQuotes;
        } else if( char == "\" && inQuotes ) {
          i = i + 2;
          skipIncrement = true;
        } else if( ( char == "," && NOT inQuotes && nestingLevel == 0 ) || i == len( _data )+1 ) {
          var dataStr = trim( mid( _data, startPos, i-startPos ));

          if( dataType == "array" ) {
            arrayappend( ar, deserializeFromJSON( dataStr, strictMapping ));
          } else if( dataType == "struct" || dataType == "query" || dataType == "queryByColumns" ) {
            var colonPos = reFind( '"\s{0,}:', dataStr, 2, true );
            var structKey = trim( mid( dataStr, 1, colonPos.pos[1] ));

            if(( left( structKey, 1 ) == "'" && right( structKey, 1 ) == "'" ) ||
               ( left( structKey, 1 ) == '"' && right( structKey, 1 ) == '"' )) {
              structKey = len( structKey ) > 2 ? mid( structKey, 2, len( structKey ) - 2 ) : "";
            }

            structVal = mid( dataStr, colonPos.pos[1]+colonPos.len[1], len( dataStr ) - colonPos.pos[1] );

            if( dataType == "struct" && len( structKey )) {
              st[structKey] = deserializeFromJSON( structVal, strictMapping );

            } else if( dataType == "queryByColumns" ) {
              if( structKey == "rowcount" ) {
                qRows = deserializeFromJSON( structVal, strictMapping );
              } else if( structKey == "columns" ) {
                qCols = deserializeFromJSON( structVal, strictMapping );
                st = QueryNew( arrayToList( qCols ));
                if( qRows ) {
                  QueryAddRow( st, qRows );
                }
              } else if( structKey == "data" ) {
                qData = deserializeFromJSON( structVal, strictMapping );
                ar = structKeyArray( qData );

                for( var j=1; j<=ArrayLen( ar ); j++ ) {
                  for( var qRows=1; qRows<=st.recordcount; qRows++ ) {
                    qCol = ar[j];
                    QuerySetCell( st, qCol, qData[qCol][qRows], qRows );
                  }
                }
              }
            } else if( dataType == "query" ) {
              if( structKey == "columns" ) {
                qCols = deserializeFromJSON( structVal, strictMapping );
                st = QueryNew( arrayToList( qCols ));
              } else if( structKey == "data" ) {
                qData = deserializeFromJSON( structVal, strictMapping );
                for( var qRows=1; qRows<=ArrayLen( qData ); qRows++ ) {
                  QueryAddRow( st );
                  for( var j=1; j<=ArrayLen( qCols ); j++ ) {
                    qCol = qCols[j];
                    QuerySetCell( st, qCol, qData[qRows][j], qRows );
                  }
                }
              }
            }
          }

          startPos = i + 1;

        } else if( "{[" CONTAINS char && NOT inQuotes ) {
          nestingLevel = nestingLevel + 1;

        } else if( "]}" CONTAINS char && NOT inQuotes ) {
          nestingLevel = nestingLevel - 1;
        }

        if( NOT skipIncrement ) {
          i = i + 1;
        }
      }

      if( dataType == "array" ) {
        return ar;
      }

      return st;

    } else {
      throw "JSON parsing failure.";
    }
  }

  /**
   * Converts ColdFusion data into a JSON (JavaScript Object Notation) representation of the data.
   *
   * @variable A ColdFusion data value or variable that represents one.
   * @serializequeryByColumns A Boolean value that specifies how to serialize ColdFusion queries.
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
  public string function serializeToJSON( required any variable, boolean serializequeryByColumns=false, boolean strictMapping=false ) {
    var jsonString = "";
    var arKeys = "";
    var colPos = 1;
    var md = "";
    var rowDel = "";
    var colDel = "";
    var className = "";
    var i = 1;
    var column = "";
    var datakey = "";
    var recordcountkey = "";
    var columnlist = "";
    var columnlistkey = "";
    var columnJavaTypes = "";
    var dJSONString = "";
    var escapeToVals = "\\,\"",\/,\b,\t,\n,\f,\r";
    var escapeVals = "\,"",/,#chr( 8 )#,#chr( 9 )#,#chr( 10 )#,#chr( 12 )#,#chr( 13 )#";

    var _data = variable;

    if( strictMapping ) {
      className = getClassName( _data );
    }

    if( len( className ) && compareNoCase( className, "java.lang.String" ) == 0 ) {
      return '"' & replaceList( _data, escapeVals, escapeToVals ) & '"';

    } else if( len( className ) && compareNoCase( className, "java.lang.Boolean" ) == 0 ) {
      return _data ? true : false; // replaceList( toString( _data ), 'YES,NO', 'true,false' );

    } else if( len( className ) && compareNoCase( className, "java.lang.Integer" ) == 0 ) {
      return toString( _data );

    } else if( len( className ) && compareNoCase( className, "java.lang.Long" ) == 0 ) {
      return toString( _data );

    } else if( len( className ) && compareNoCase( className, "java.lang.Float" ) == 0 ) {
      return toString( _data );

    } else if( len( className ) && compareNoCase( className, "java.lang.Double" ) == 0 ) {
      return toString( _data );

    } else if( isBinary( _data )) {
      throw "JSON serialization failure: Unable to serialize binary data to JSON.";

    } else if( isBoolean( _data ) && NOT isNumeric( _data )) {
      return _data ? true : false; // replaceList( yesNoFormat( _data ), 'Yes,No', 'true,false' );

    } else if( isNumeric( _data )) {
      if( getClassName( _data ) == "java.lang.String" ) {
        return val( _data ).toString();
      } else {
        return _data.toString();
      }

    } else if( isDate( _data )) {
      return '"#DateFormat( _data, "mmmm, dd yyyy" )# #TimeFormat( _data, "HH:mm:ss" )#"';

    } else if( isSimpleValue( _data )) {
      return writeJsonUtf8String( _data );

    } else if( this.isLuceeRailo && isXML( _data )) {
      return '"' & replaceList( toString( _data ), escapeVals, escapeToVals ) & '"';

    } else if( isCustomFunction( _data )) {
      return serializeToJSON( getMetadata( _data ), serializeQueryByColumns, strictMapping );

    } else if( isObject( _data )) {
      return "{}";

    } else if( isArray( _data )) {
      dJSONString = [];

      for( var _dataEl in _data ) {
        if( !isNull( _dataEl )) {
          var tempVal = serializeToJSON( _dataEl, serializeQueryByColumns, strictMapping );
          arrayAppend( dJSONString, tempVal );
        }
      }

      return "[" & arrayToList( dJSONString, "," ) & "]";

    } else if( isStruct( _data )) {
      dJSONString = [];
      arKeys = structKeyArray( _data );

      for( var i=1; i<=arrayLen( arKeys ); i++ ) {
        var tempVal = "null";

        if( isDefined( "_data.#arKeys[i]#" )  ) {
          tempVal = serializeToJSON( _data[ arKeys[i] ], serializeQueryByColumns, strictMapping );
        }

        arrayAppend( dJSONString, '"' & arKeys[i] & '":' & tempVal );
      }

      return "{" & arrayToList( dJSONString, "," ) & "}";

    } else if( isQuery( _data )) {
      dJSONString = [];
      recordcountKey = "ROWCOUNT";
      columnlistKey = "COLUMNS";
      columnlist = "";
      dataKey = "DATA";
      md = getMetadata( _data );
      columnJavaTypes = {};

      for( var i=1; i<=arrayLen( md ); i++ ) {
        columnlist = listAppend( columnlist, UCase( md[i].Name ), ', ' );
        columnJavaTypes[md[i].Name] = "";

        if( structKeyExists( md[i], "TypeName" )) {
          columnJavaTypes[md[i].Name] = getJavaType( md[i].TypeName );
        }
      }

      if( serializeQueryByColumns ) {
        arrayAppend( dJSONString, '"#recordcountKey#":' & _data.recordcount );
        arrayAppend( dJSONString, ', "#columnlistKey#":[' & listQualify( columnlist, '"' ) & ']' );
        arrayAppend( dJSONString, ', "#dataKey#":{' );

        colDel = "";

        for( column in listToArray( columnlist )) {
          arrayAppend( dJSONString, colDel );
          arrayAppend( dJSONString, '"#column#":[' );

          rowDel = "";

          for( var i=1; i<=_data.recordcount; i++ ) {
            arrayAppend( dJSONString, rowDel );

            if(( strictMapping || this.isLuceeRailo ) && len( columnJavaTypes[column] )) {
              tempVal = serializeToJSON( JavaCast( columnJavaTypes[column], _data[column][i] ), serializeQueryByColumns, strictMapping );
            } else {
              tempVal = serializeToJSON( _data[column][i], serializeQueryByColumns, strictMapping );
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

        rowDel = "";

        for( var i=1; i<=_data.recordcount; i++ ) {
          arrayAppend( dJSONString, rowDel );
          arrayAppend( dJSONString, '[' );

          colDel = "";

          for( column in listToArray( columnlist )) {
            arrayAppend( dJSONString, colDel );

            if(( strictMapping || this.isLuceeRailo ) && len( columnJavaTypes[column] )) {
              tempVal = serializeToJSON( JavaCast( columnJavaTypes[column], _data[column][i] ), serializeQueryByColumns, strictMapping );
            } else {
              tempVal = serializeToJSON( _data[column][i], serializeQueryByColumns, strictMapping );
            }

            arrayAppend( dJSONString, tempVal );
            colDel=",";
          }

          arrayAppend( dJSONString, ']' );
          rowDel = ",";
        }

        arrayAppend( dJSONString, ']' );
      }

      return "{" & arrayToList( dJSONString, "" ) & "}";

    } else if( isXML( _data )) {
      return '"' & replaceList( toString( _data ), escapeVals, escapeToVals ) & '"';
    }

    return "{}";
  }

  /**
   * Maps SQL to Java types. Returns blank string for unhandled SQL types.
   * @sqlType A SQL datatype.
   */
  private string function getJavaType( required string sqlType ) {
    switch( sqlType ) {
      case "bit" :
        return "boolean";
        break;

      case "tinyint" :
      case "smallint" :
      case "integer" :
        return "int";
        break;

      case "bigint" :
        return "long";
        break;

      case "real" :
      case "float" :
        return "float";
        break;

      case "double" :
        return "double";
        break;

      case "char" :
      case "varchar" :
      case "longvarchar" :
        return "string";
        break;

      default:
        return "";
    }
  }

  /**
   * Returns a variable's underlying java Class name.
   *
   * @data A variable.
   */
  private string function getClassName( required any data ) {
    try {
      return data.getClass().getName();
    }
    catch( any e ) {
      return "";
    }
  }

  /**
   * Returns a variable's underlying java Class name.
   *
   * @data A string to serialze.
   */
  private string function writeJsonUtf8String( required string data ) {
    var json = '"';
    var end = len( data ) - 1;
    var integer = createObject( "java","java.lang.Integer" );
    var pad = "";
    var hex = "";

    for( var i=0; i<=end; i++ ) {
      var c = data.charAt(i);

      if( c lt ' ' ) {
        if( c eq chr(8) ) {
          json &= "\b";
        } else if( c eq chr(9) ) {
          json &= "\t";
        } else if( c eq  chr(10) ) {
          json &= "\n";
        } else if( c eq  chr(12) ) {
          json &= "\f";
        } else if( c eq  chr(13) ) {
          json &= "\r";
        } else {
          hex = integer.toHexString(c);
          json &= "\u";
          pad = 4 - len(hex);
          json &= RepeatString("0", pad);
          json &= hex;
        }
      } else if( c eq '\' or c eq '/' or c eq '"' ) {
        json &= "\" & c;
      } else {
        json &= c;
      }
    }

    json &= '"';

    return json;
  }
}