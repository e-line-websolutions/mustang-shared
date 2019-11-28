component accessors=true {
  property config;
  property utilityService;
  property logService;

  property string filePath;
  property string fileName;
  property string originalFileName;
  property numeric fileSize;
  property any fileContent;

  public file function init( root, logService, javaloaderService ) {
    variables.jFileInputStream = createObject( 'java', 'java.io.FileInputStream' );
    variables.jFile = createObject( 'java', 'java.io.File' );
    variables.jl = javaloaderService.new( [ expandPath( "/mustang/lib/tika/tika-eval-1.22.jar" ) ] );
    return this;
  }

  public void function upload( required string uploadField, string destination = "temp/" ) {
    try {
      if ( destination contains '..' ) {
        throw( "path error" );
      }

      try {
        var uploadState = fileUpload( variables.config.paths.fileUploads & "/" & destination & "/file-#createUuid()#.tmp", uploadField, "", "MakeUnique" );
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

  public any function getFileLastModified( required string filePath ) {
    var file = variables.jFile.init( filePath );
    return createObject( 'java', 'java.util.Date' ).init( file.lastModified() );
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

    var cacheKey = "file_" & hash( filePath );

    var result = cacheGet( cacheKey );

    if ( isNull( result ) ) {
      var result = fileExists( filePath );
      cachePut( cacheKey, result, createTimeSpan( 7, 0, 0, 0 ), createTimeSpan( 1, 0, 0, 0 ) );
    }

    return result;
  }

  public string function writeBase64ImageToFile( Base64EncodedFile, location ){
    var binarycode = binaryDecode( Base64EncodedFile, 'Base64' );
    fileWrite( location , binarycode );
  }

  public string function getMimetypeFromBinaryFile( binaryFileData ) {
    return jl.create( 'org.apache.tika.Tika' ).detect( binaryFileData );
  }

  public string function getMimetype( string filePath = variables.originalFileName ) {
    switch ( getFiletype( filePath ) ) {
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

  public string function getFiletype( string filePath = variables.originalFileName ) {
    return listLast( filePath, '.' );
  }

  public string function getDigest( fileObj, string digestAlgorithms = 'SHA-256' ) {
    var digest = createObject( 'java', 'java.security.MessageDigest' ).getInstance( digestAlgorithms );
    return toBase64( digest.digest( fileObj ) );
  public string function encodeFileToBase64Binary( fileObject ) {
    var fileUtils = createObject( 'java', 'org.apache.commons.io.FileUtils' );
    var base64Encoder = createObject( 'java', 'java.util.Base64' ).getEncoder();
    return base64Encoder.encodeToString( fileUtils.readFileToByteArray( fileObject ) );
  }
}