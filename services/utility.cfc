<cfcomponent output="false" accessors="true">
  <cfproperty name="emailService" />

  <cfscript>
  public any function init( ) {
    return this;
  }

  public string function parseStringVariables( required string stringToParse, struct stringVariables = { } ) {
    if ( not isDefined( "stringVariables" ) or not structCount( stringVariables ) ) {
      return stringToParse;
    }

    for ( var key in stringVariables ) {
      if ( not isNull( stringVariables[ key ] ) ) {
        stringToParse = replaceNoCase( stringToParse, '###key###', stringVariables[ key ], 'all' );
      }
    }

    return stringToParse;
  }

  public void function limiter( numeric duration = 5, numeric maxAttempts = 100, numeric timespan = 10 ) {
    var cacheID = hash( "rate_limiter_" & CGI.REMOTE_ADDR );
    var rate = cacheGet( cacheId );
    var cacheTime = createTimeSpan( 0, 0, 0, timespan );

    if ( isNull( rate ) ||
        !isStruct( rate ) ||
        !structKeyExists( rate, "start" ) ||
        !structKeyExists( rate, "attempts" ) ) {
      // initialize limiter:
      var rate = {
        attempts = 0,
        start = now( )
      };
      cachePut( cacheID, rate, cacheTime );
      return;
    }

    var timeout = dateDiff( "s", rate.start, now( ) );
    rate.attempts++;

    if ( timeout < duration ) {
      if ( rate.attempts > maxAttempts ) {
        writeOutput( '<p>You are making too many requests too fast, please slow down and wait #duration# seconds</p>' );
        var context = getPageContext( );
        var response = context.getResponse( ).getResponse( );

        response.setStatus( 503 );
        response.setHeader( "Retry-After", duration );

        context.getCFOutput( ).clear( );

        writeLog(
          file = "limiter",
          text = "#cgi.remote_addr# #rate.attempts# #cgi.request_method# #cgi.SCRIPT_NAME# #cgi.QUERY_STRING# #cgi.http_user_agent# #rate.start#"
        );

        // set cache timeout to duration, so user remains locked out for the duration:
        cachePut( cacheID, rate, createTimeSpan( 0, 0, 0, duration ) );
        abort;
      }

      // Update attempts:
      cachePut( cacheID, rate, cacheTime );
    } else {
      // Reset attempts:
      cachePut( cacheID, rate, cacheTime );
    }
  }

  public string function generatePassword( numeric length = 8, string type = "uc,lc,num" ) {
    if ( length <= 0 ) {
      throw( type = "util.generatePassword", message = "generatePassword(): Length must be > 0" );
    }

    if ( !listFindNoCase( type, "uc" ) &&
        !listFindNoCase( type, "lc" ) &&
        !listFindNoCase( type, "num" ) &&
        !listFindNoCase( type, "oth" ) ) {
      throw( type = "util.generatePassword", message = "generatePassword(): Type must be one or more of these: uc, lc, num, oth." );
    }

    var result = "";
    var charUsed = "";
    var illegelChars = "o,O,0,l,I,1,B,8";
    var tryChar = chr( 0 );

    while ( len( result ) < length ) {
      if ( randRange( 1, 4 ) == 1 && listFindNoCase( type, 'uc' ) ) {
        tryChar = chr( randRange( 65, 90 ) );
      } else if ( randRange( 1, 4 ) == 2 && listFindNoCase( type, 'lc' ) ) {
        tryChar = chr( randRange( 97, 122 ) );
      } else if ( randRange( 1, 4 ) == 3 && listFindNoCase( type, 'num' ) ) {
        tryChar = chr( randRange( 48, 57 ) );
      } else if ( randRange( 1, 4 ) == 4 && listFindNoCase( type, 'oth' ) ) {
        var oth = [ chr( randRange( 33, 47 ) ), chr( randRange( 58, 64 ) ), chr( randRange( 91, 96 ) ), chr( randRange( 123, 126 ) ) ];
        tryChar = oth[ randRange( 1, 4 ) ];
      }

      if ( tryChar == chr( 0 ) ||
          tryChar == charUsed ||
          listFind( illegelChars, tryChar ) ) {
        continue;
      }

      result &= tryChar;
      charUsed = tryChar;
    }

    return result;
  }

  public string function capFirst( required word ) {
    word = trim( word );

    if ( len( word ) <= 1 ) {
      return uCase( word );
    }

    return uCase( left( word, 1 ) ) & right( word, len( word ) - 1 );
  }

  public string function variableFormat( inputString ) {
    var result = "";

    inputString = lCase( trim( inputString ) );
    var len = len( trim( inputString ) );

    for ( var i = 1; i <= len; i++ ) {
      var char = mid( inputString, i, 1 );

      if ( !( ( char >= 'a' && char <= 'z' ) || ( char >= 'A' && char <= 'Z' ) || isNumeric( char ) ) ) {
        if ( char == ' ' || char == '_' || char == '-' ) {
          result &= '-';
        }
      } else {
        result &= char;
      }
    }

    return result;
  }

  /**
   * Sorts an array of structures based on a key in the structures.
   *
   * @param aofS      Array of structures. (Required)
   * @param key       Key to sort by. (Required)
   * @param sortOrder Order to sort by, asc or desc. (Optional)
   * @param sortType  Text, textnocase, or numeric. (Optional)
   * @param delim     Delimiter used for temporary data storage. Must not exist in data. Defaults to a period. (Optional)
   * @return Returns a sorted array.
   * @author Nathan Dintenfass
   * @version 1, April 4, 2013
   */
  public array function arrayOfStructsSort( required array aOfS, required string key ) {
    var sortOrder = "asc";
    var sortType = "textnocase";
    var delim = ".";
    var sortArray = [ ];
    var returnArray = [ ];
    var count = arrayLen( aOfS );
    var ii = 1;

    if ( arraylen( arguments ) > 2 ) {
      sortOrder = arguments[ 3 ];
    }

    if ( arraylen( arguments ) > 3 ) {
      sortType = arguments[ 4 ];
    }

    if ( arraylen( arguments ) > 4 ) {
      delim = arguments[ 5 ];
    }

    for ( ii = 1; ii <= count; ii++ ) {
      sortArray[ ii ] = aOfS[ ii ][ key ] & delim & ii;
    }

    arraySort( sortArray, sortType, sortOrder );

    for ( ii = 1; ii <= count; ii++ ) {
      returnArray[ ii ] = aOfS[ listLast( sortArray[ ii ], delim ) ];
    }

    return returnArray;
  }

  public array function arrayRotateTo( required array inputArray, required string searchFor ) {
    if ( !arrayFindNoCase( inputArray, searchFor ) ) {
      throw( "inputArray must contain searchFor string." );
    }

    var failsafe = 0;

    while ( inputArray[ 1 ] != searchFor && failsafe < arrayLen( inputArray ) ) {
      failsafe++;
      inputArray = arrayShift( inputArray );
    }

    return inputArray;
  }

  public array function arrayShift( required array inputArray ) {
    arrayPrepend( inputArray, inputArray[ arrayLen( inputArray ) ] );
    arrayDeleteAt( inputArray, arrayLen( inputArray ) );

    return inputArray;
  }

  public array function arrayTrim( required array inputArray, required numeric trimAt ) {
    var result = [ ];
    var len = min( arrayLen( inputArray ), trimAt );

    for ( var i = 1; i <= len; i++ ) {
      arrayAppend( result, inputArray[ i ] );
    }

    return result;
  }

  public array function arrayReverse( required array inputArray ) {
    var len = arrayLen( inputArray );
    var end = ceiling( len / 2 );
    for ( var i = 1; i <= end; i++ ) {
      var temp = inputArray[ i ];
      inputArray[ i ] = inputArray[ ( len + 1 ) - i ];
      inputArray[ ( len + 1 ) - i ] = temp;
    }
    return inputArray;
  }

  public string function base64URLEncode( required string value ) {
    var bytes = charsetDecode( value, "utf-8" );
    var encodedValue = binaryEncode( bytes, "base64" );

    encodedValue = replace( encodedValue, "+", "-", "all" );
    encodedValue = replace( encodedValue, "/", "_", "all" );
    encodedValue = replace( encodedValue, "=", "", "all" );

    return encodedValue;
  }

  public string function base64URLDecode( required string value ) {
    value = replace( value, "-", "+", "all" );
    value = replace( value, "_", "/", "all" );
    value &= repeatString( "=", ( 4 - ( len( value ) % 4 ) ) );
    var bytes = binaryDecode( value, "base64" );
    return charsetEncode( bytes, "utf-8" );
  }

  public string function encryptForUrl( stringToEncrypt, encryptKey ) {
    return base64URLEncode( toBase64( encrypt( stringToEncrypt, encryptKey ) ) );
  }

  public string function decryptForUrl( stringToEncrypt, encryptKey ) {
    return decrypt( toString( toBinary( base64URLDecode( stringToEncrypt ) ) ), encryptKey );
  }

  public boolean function fileExistsUsingCache( required string absolutePath ) {
    var cachedPaths = cacheGet( "cachedPaths-#request.appName#" );

    if ( isNull( cachedPaths ) || request.reset ) {
      var cachedPaths = { };
    }

    if ( !structKeyExists( cachedPaths, absolutePath ) ) {
      cachedPaths[ absolutePath ] = fileExists( absolutePath );
      cachePut( "cachedPaths-#request.appName#", cachedPaths );
    }

    return cachedPaths[ absolutePath ];
  }

  public struct function mergeStructs( required struct from, struct to = { } ) {
    // also append nested struct keys:
    for ( var key in to ) {
      if ( isStruct( to[ key ] ) && structKeyExists( from, key ) ) {
        structAppend( to[ key ], from[ key ] );
      }
    }

    // copy the other keys:
    structAppend( to, from );

    return to;
  }

  public string function updateLocale( string newLocale = "" ) {
    try {
      var result = setLocale( newLocale );
      writeLog( text = "Locale changed to #newLocale#", file = request.appName );
      return result;
    } catch ( any e ) {
      var errorMessage = "Error setting locale to '#newLocale#'";
      writeLog( text = errorMessage, file = request.appName );
      savecontent variable="local.messageBody" {
        writeDump( newLocale );
        writeDump( e );
      }
      emailService.send( "bugs@mstng.info", "bugs@mstng.info", "updateLocale Error", messageBody );
      throw( errorMessage, "utilityService.updateLocale.invalidLocaleError" );
    }
  }

  public string function enterFormat( string source="" ) {
    return reReplace( source, '\n', '<br />', 'all' );
  }

  </cfscript>

  <cffunction name="cfcontent" output="false" access="public">
    <cfcontent attributeCollection="#arguments#" />
  </cffunction>

  <cffunction name="cfheader" output="false" access="public">
    <cfheader attributeCollection="#arguments#" />
  </cffunction>

  <cffunction name="cfschedule" output="false" access="public">
    <cfif structIsEmpty( arguments )>
      <cfreturn />
    </cfif>
    <cfset arguments.operation = "HTTPRequest" />
    <cfschedule attributeCollection="#arguments#" />
  </cffunction>

  <cffunction name="setCFSetting" output="false" access="public">
    <cfargument name="settingName" type="string" required="true" hint="requesttimeout,showdebugoutput,enablecfoutputonly" />
    <cfargument name="settingValue" type="any" required="true" />

    <cfswitch expression="#settingName#">
      <cfcase value="requesttimeout">
        <cfsetting requesttimeout="#settingValue#" />
      </cfcase>
      <cfcase value="enablecfoutputonly">
        <cfsetting enablecfoutputonly="#settingValue#" />
      </cfcase>
      <cfcase value="showdebugoutput">
        <cfsetting showdebugoutput="#settingValue#" />
      </cfcase>
    </cfswitch>
  </cffunction>

  <cffunction name="getDbInfo" output="false" access="public">
    <cfargument name="datasource" required=true />
    <cfdbinfo name="dbinfo" type="version" datasource="#datasource#" />
    <cfreturn dbinfo />
  </cffunction>

  <cffunction name="cfinvoke">
    <cfargument name="comp" />
    <cfargument name="func" />
    <cfargument name="args" default="#{}#" />
    <cfinvoke component="#comp#" method="#func#" returnvariable="local.result">
      <cfloop collection="#args#" item="local.key">
        <cfinvokeargument name="#key#" value="#args[key]#" />
      </cfloop>
    </cfinvoke>
    <cfif not isNull( result )>
      <cfreturn result />
    </cfif>
  </cffunction>
</cfcomponent>
