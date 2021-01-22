component accessors=true {
  property utilityService;
  property javaloaderService;

  property type="string" name="filePath";
  property type="string" name="fileName";
  property type="string" name="originalFileName";
  property type="numeric" name="fileSize";
  property type="any" name="fileContent";

  public string function getFileContent() {
    return fileRead( filePath );
  }

  public any function getFileInputStream() {
    return createObject( 'java', 'java.io.FileInputStream' ).init( filePath );
  }

  public any function getFileLastModified() {
    return createObject( 'java', 'java.util.Date' ).init( createObject( 'java', 'java.io.File' ).init( filePath ).lastModified() );
  }

  public void function writeToBrowser() {
    if ( cachedFileExists( filePath ) ) {
      var cacheFor = dateAdd( 'm', 1, now() );
      utilityService.cfheader( statuscode = 200, statustext = 'OK' );
      utilityService.cfheader(
        name = 'Expires',
        value = '#lsDateFormat( cacheFor, 'ddd, dd mmm yyyy' )# #lsTimeFormat( cacheFor, 'HH:mm:ss' )# CEST'
      );
      utilityService.cfheader( name = 'Cache-Control', value = 'public, max-age=604800' );
      utilityService.cfcontent( reset = true, file = filePath, type = getMimetype( filePath ) );
      abort;
    }

    utilityService.cfheader( statuscode = 404, statustext = 'Not Found' );
    utilityService.cfcontent( reset = true, type = 'text/plain' );
    writeOutput( 'Media file does not exist.' );
    abort;
  }

  public boolean function cachedFileExists() {
    param config.cacheFileExists = false;

    if ( !config.cacheFileExists ) {
      return fileExists( filePath );
    }

    var cacheKey = 'file_' & hash( filePath );
    var result = cacheGet( cacheKey );

    if ( isNull( result ) ) {
      var result = fileExists( filePath );
      cachePut( cacheKey, result, createTimespan( 7, 0, 0, 0 ), createTimespan( 1, 0, 0, 0 ) );
    }

    return result;
  }

  public string function writeBase64ImageToFile( Base64EncodedFile, location ) {
    var binarycode = binaryDecode( Base64EncodedFile, 'Base64' );
    fileWrite( location, binarycode );
  }

  public string function getMimetype() {
    switch ( getFileExtension() ) {
      case 'jpg' :
      case 'jpe' :
        case 'jpeg' : return 'image/jpeg';
        case 'gif'  : return 'image/gif';
        case 'png'  : return 'image/png';
        case 'pdf'  : return 'application/pdf';
        case 'doc'  : return 'application/msword';
        case 'docx' : return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        case 'zip'  : return 'application/zip';
        case 'rar'  : return 'application/x-rar-compressed';
        case 'swf'  : return 'application/x-shockwave-flash';
        case 'svg'  : return 'image/svg+xml';
        case 'xls'  : return 'application/vnd.ms-excel';
        case 'xlsx' : return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        case 'xlsm' : return 'application/vnd.ms-excel.sheet.macroEnabled.12';
    }

    return 'application/octet-stream';
  }

  public string function getFileExtension() {
    return listLast( originalFileName, '.' );
  }

  public string function getFileSize() {
    return createObject( 'java', 'java.io.File' ).init( filePath ).length();
  }

  public string function getDigest( fileObject, string digestAlgorithms = 'SHA-256' ) {
    var digest = createObject( 'java', 'java.security.MessageDigest' ).getInstance( digestAlgorithms );
    return toBase64( digest.digest( fileObject ) );
  }
}