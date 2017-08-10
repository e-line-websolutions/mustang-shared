component accessors=true {
  property config;
  property utilityService;

  property string filePath;
  property string fileName;
  property string originalFileName;
  property numeric fileSize;
  property any fileContent;

  public file function init( ) {
    variables.jFileInputStream = createObject( "java", "java.io.FileInputStream" );
    return this;
  }

  public void function upload( required string uploadField, string destination = "temp/" ) {
    try {
      if ( destination contains '..' ) {
        throw( "path error" );
      }

      try {
        var uploadState = fileUpload( request.fileUploads & "/" & destination, uploadField, "", "MakeUnique" );
        variables.filePath = uploadState.serverDirectory & "/" & uploadState.serverFile;
        variables.originalFileName = uploadState.clientFile;
        variables.fileName = uploadState.serverFile;
        variables.fileSize = uploadState.fileSize;
      } catch ( any e ) {
        // TODO: file upload error handling
        rethrow;
      }
    } catch ( any e ) {
      // TODO: catch all error handling
      rethrow;
    }
  }

  public string function getFileContent( ) {
    return fileRead( variables.filePath );
  }

  public any function getFileInputStream( required string filePath ) {
    return variables.jFileInputStream.init( filePath );
  }

  public component function getInstance( ) {
    return duplicate( this );
  }

  public void function writeToBrowser( required string filePath ) {
    var mimeType = getMimetype( filePath );
    var cacheFor = dateAdd( 'm', 1, now());

    if ( cachedFileExists( filePath ) ) {
      utilityService.cfheader( statuscode=200, statustext="OK" );
      utilityService.cfheader( name="Expires", value="#lsDateFormat( cacheFor, 'ddd, dd mmm yyyy' )# #lsTimeFormat( cacheFor, 'HH:mm:ss' )# CEST" );
      utilityService.cfheader( name="Cache-Control", value="public, max-age=604800" );
      utilityService.cfcontent( reset=true, file=filePath, type=mimeType );
      abort;
    }

    utilityService.cfheader( statuscode=404, statustext="Not Found" );
    utilityService.cfcontent( reset=true, type="text/plain" );
    writeOutput( "Media file does not exist." );
    abort;
  }

  private boolean function cachedFileExists( string filePath ) {
    param config.cacheFileExists=false;

    if ( !config.cacheFileExists ) {
      return fileExists( filePath );
    }

    var result = cacheGet( filePath );

    if ( isNull( result ) ) {
      var result = fileExists( filePath );
      cachePut( filePath, result );
    }

    return result;
  }

  private string function getMimetype( required string filePath ) {
    switch( listLast( filePath, '.' ) ) {
      case 'jpg' :
      case 'jpe' :
      case 'jpeg' :
        return "image/jpeg";
      case 'gif' :
        return "image/gif";
      case 'png' :
        return "image/png";
      case 'pdf' :
        return "application/pdf";
      case 'doc' :
        return "application/msword";
      case 'zip' :
        return "application/zip";
      case 'rar' :
        return "application/x-rar-compressed";
      case 'swf' :
        return "application/x-shockwave-flash";
      case 'svg' :
        return "image/svg+xml";
    }

    return "application/octet-stream";
  }
}
