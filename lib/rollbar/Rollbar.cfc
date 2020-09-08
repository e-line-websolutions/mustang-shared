component output="false" {
  variables.access_token = '';
  variables.use_ssl_endpoint = true;
  variables.api_endpoint_ssl = 'https://api.rollbar.com/api/1/item/';
  variables.api_endpoint = 'http://api.rollbar.com/api/1/item/';
  variables.environment = 'development';

  public Rollbar function init( required struct conf ) {
    try {
      validateConf( arguments.conf );
      setAccessToken( arguments.conf );
      setAPIEndpoint( arguments.conf );
      setEnvironment( arguments.conf );
    } catch ( any e ) {
      rethrow;
    }
    return this;
  }

  public boolean function reportMessage(
    required string message,
    string level = 'info',
    struct meta = structNew(),
    struct user = structNew()
  ) {
    try {
      local.payload = getPreparedMessagePayload( arguments.message, arguments.level, arguments.meta, arguments.user );
      sendPayload( local.payload );
      return true;
    } catch ( any e ) {
      return false;
    }
  }

  public boolean function reportException( required any exception, string level = 'error', struct user = structNew() ) {
    try {
      local.payload = getPreparedExceptionPayload( arguments.exception, arguments.level, arguments.user );
      sendPayload( local.payload );
      return true;
    } catch ( any e ) {
      return false;
    }
  }

  public string function getPreparedMessagePayload(
    required string message,
    string level = 'info',
    struct meta = structNew(),
    struct user = structNew()
  ) {
    local.payload = preparePayload( arguments.level, arguments.user );
    local.payload[ 'data' ][ 'body' ][ 'message' ] = { 'body' = arguments.message };
    structAppend( local.payload[ 'data' ][ 'body' ][ 'message' ], duplicate( arguments.meta ) );
    return preparePayloadForTransmission( local.payload );
  }

  public string function getPreparedExceptionPayload( required any exception, string level = 'error', struct user = structNew() ) {
    local.payload = preparePayload( arguments.level, arguments.user );
    local.payload[ 'data' ][ 'body' ][ 'trace' ] = {};
    local.payload[ 'data' ][ 'body' ][ 'trace' ][ 'frames' ] = getStackFramesForPayload( arguments.exception );
    local.payload[ 'data' ][ 'body' ][ 'trace' ][ 'exception' ] = getExceptionParamsForPayload( arguments.exception );
    return preparePayloadForTransmission( local.payload );
  }

  public string function getAPIEndpoint() {
    if ( variables.use_ssl_endpoint ) {
      return variables.api_endpoint_ssl;
    } else {
      return variables.api_endpoint;
    }
  }




  private void function sendPayload( required string payload ) {
    local.http = new HTTP();
    local.http.setMethod( 'POST' );
    local.http.setUrl( getAPIEndpoint() );
    local.http.addParam( type = 'formfield', name = 'payload', value = '#arguments.payload#' );
    local.response = local.http.send();

    if ( local.response.getPrefix().statusCode != '200 OK' ) {
      throw(
        type = 'RollbarApiException',
        message = 'Unsuccessful: #local.response.getPrefix().statusCode# | #local.response.getPrefix().fileContent.toString()#'
      );
    }
  }

  private array function getStackFramesForPayload(
    required any exception,
    string code_param = '',
    array context_pre = [],
    array context_post = []
  ) {
    local.result = [];
    local.stack = getCurrentStackTrace();

    for ( local.frame in local.stack ) {
      arrayAppend(
        local.result,
        {
          'filename' = local.frame.template,
          'lineno' = local.frame.lineNumber,
          'method' = lCase( local.frame.function ),
          'code' = arguments.code_param,
          'context' = getContextParamsForPayload( arguments.exception )
        }
      );
    }

    return local.result;
  }

  private struct function getExceptionParamsForPayload( required any exception ) {
    local.result = { 'class' = arguments.exception.type, 'message' = arguments.exception.message };

    return local.result;
  }

  private struct function getContextParamsForPayload( required any exception ) {
    local.pre = [];
    for ( local.context in arguments.exception.tagContext ) {
      for ( local.key in listToArray( structKeyList( local.context ) ) ) {
        arrayAppend( local.pre, lCase( local.key ) & ' = ' & local.context[ local.key ] );
      }
    }
    return { 'pre' = local.pre, 'post' = [] };
  }

  // The following function was written by a different author and unfortunately
  // I cannot find the blog post anymore to give proper credit.
  private array function getCurrentStackTrace() {
    var lc = structNew();
    lc.trace = createObject( 'java', 'java.lang.Throwable' ).getStackTrace();
    lc.op = arrayNew( 1 );
    lc.elCount = arrayLen( lc.trace );
    for ( lc.i = 1; lc.i Lte lc.elCount; lc.i = lc.i + 1 ) {
      if ( listFindNoCase( 'runPage,runFunction', lc.trace[ lc.i ].getMethodName() ) ) {
        lc.info = structNew();
        lc.info[ 'Template' ] = lc.trace[ lc.i ].getFileName();
        if ( lc.trace[ lc.i ].getMethodName() Eq 'runFunction' ) {
          lc.info[ 'Function' ] = reReplace( lc.trace[ lc.i ].getClassName(), '^.+\$func', '' );
        } else {
          lc.info[ 'Function' ] = '';
        }
        lc.info[ 'LineNumber' ] = lc.trace[ lc.i ].getLineNumber();
        arrayAppend( lc.op, duplicate( lc.info ) );
      }
    }
    // Remove the entry for this function
    arrayDeleteAt( lc.op, 1 );
    return lc.op;
  }

  private struct function preparePayload( string level = 'info', user = structNew() ) {
    try {
      local.payload = {};
      local.payload[ 'access_token' ] = getAccessToken();
      local.payload[ 'data' ] = {};
      local.payload[ 'data' ][ 'environment' ] = getEnvironment();
      local.payload[ 'data' ][ 'level' ] = arguments.level;
      local.payload[ 'data' ][ 'body' ] = {};
      local.payload[ 'data' ][ 'request' ] = getRequestParamsForPayload();
      local.payload[ 'data' ][ 'person' ] = getUserParamsForPayload( arguments.user );
      local.payload[ 'data' ][ 'client' ] = getClientParamsForPayload();
      local.payload[ 'data' ][ 'server' ] = getServerParamsForPayload();
      local.payload[ 'data' ][ 'platform' ] = getPlatformForPayload();
      local.payload[ 'data' ][ 'language' ] = getLanguageForPayload();
      local.payload[ 'data' ][ 'notifier' ] = getNotifierParamsForPayload();
      return local.payload;
    } catch ( any e ) {
      toConsole( arguments, local, e );
    }
    return {};
  }

  private struct function getRequestParamsForPayload() {
    local.result = {
      'url' = getRequestUrlFromCGI(),
      'get' = url,
      'query_string' = cgi.query_string,
      'post' = form,
      'user_ip' = cgi.remote_addr,
      'body' = ''
    };

    try {
      local.reqData = getHTTPRequestData();
    } catch ( any e ) {
    }

    if ( !isNull( local.reqData ) ) {
      local.result[ 'method' ] = local.reqData.method;
      local.result[ 'headers' ] = local.reqData.headers;
      local.result[ 'body' ] = local.reqData.content;
    }

    // The following helps avoid JSON serialization issues by ColdFusion when the body is empty
    if ( !len( local.result[ 'body' ] ) ) local.result[ 'body' ] = '';

    return local.result;
  }

  private struct function getServerParamsForPayload() {
    return { 'coldfusion' = server.coldfusion, 'os' = server.os };
  }

  private string function getRequestUrlFromCGI() {
    local.result = cgi.server_name & cgi.script_name;
    if ( cgi.server_port != 80 && cgi.server_port_secure ) {
      local.result = 'https://' & local.result;
    } else {
      local.result = 'http://' & local.result;
    }
    return local.result;
  }

  private struct function getUserParamsForPayload( struct user = structNew() ) {
    if ( !structKeyExists( arguments.user, 'id' ) ) arguments.user[ 'id' ] = createUUID();
    if ( !structKeyExists( arguments.user, 'username' ) ) arguments.user[ 'username' ] = 'anonymous@' & cgi.remote_host;
    if ( !structKeyExists( arguments.user, 'email' ) ) arguments.user[ 'email' ] = 'anonymous@' & cgi.remote_host;
    return arguments.user;
  }

  private struct function getClientParamsForPayload() {
    return { 'javascript' = { 'browser' = cgi.http_user_agent } };
  }

  private struct function getNotifierParamsForPayload() {
    return { 'name' = 'RollbarCFC', 'version' = '0.0.1' };
  }

  private string function getPlatformForPayload() {
    return server.coldfusion.productname & ' ' &
    server.coldfusion.productversion & ' ' &
    server.coldfusion.productlevel & ' running on ' &
    server.os.name & ' ' & server.os.version;
  }

  private string function getLanguageForPayload() {
    return 'ColdFusion';
  }

  private string function getAccessToken() {
    return variables.access_token;
  }
  private string function getEnvironment() {
    return variables.environment;
  }

  private string function preparePayloadForTransmission( required struct payload ) {
    return serializeJSON( arguments.payload );
  }

  private void function validateConf( required struct conf ) {
    if ( !structKeyExists( arguments.conf, 'access_token' ) ) throw(
      type = 'RollbackInitException',
      message = 'Initialization hash must contain an access_token'
    );
  }

  private void function setAccessToken( required struct conf ) {
    if ( structKeyExists( arguments.conf, 'access_token' ) ) variables.access_token = arguments.conf[ 'access_token' ];
  }

  private void function setAPIEndpoint( required struct conf ) {
    if ( structKeyExists( arguments.conf, 'use_ssl' ) ) variables.use_ssl_endpoint = arguments.conf[ 'use_ssl' ];
  }

  private void function setEnvironment( required struct conf ) {
    if ( structKeyExists( arguments.conf, 'environment' ) ) variables.environment = arguments.conf[ 'environment' ];
  }

  private void function toConsole( args = '', local = '', exception = '' ) {
    writeDump(
      var = {
        'arguments' = arguments.args,
        'local' = arguments.local,
        'exception' = arguments.exception
      },
      output = 'console'
    );
  }
}