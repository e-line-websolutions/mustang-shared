component accessors=true {
  property string filePath;
  property string fileName;
  property string originalFileName;
  property numeric fileSize;
  property any fileContent;

  public file function init() {
    variables.jFileInputStream = createObject( "java", "java.io.FileInputStream" );
    return this;
  }

  public void function upload( required string uploadField, string destination="temp/" ) {
    try {
      if( destination contains '..' ) {
        throw( "path error" );
      }

      try {
        uploadState = fileUpload( request.fileUploads & "/" & destination,
                                  uploadField,
                                  "",
                                  "MakeUnique" );
        setFilePath( uploadState.serverDirectory & "/" & uploadState.serverFile );
        setOriginalFileName( uploadState.clientFile );
        setFileName( uploadState.serverFile );
        setFileSize( uploadState.fileSize  );
      } catch( any e ) {
        // TODO: file upload error handling
        rethrow;
      }
    } catch( any e ) {
      // TODO: catch all error handling
      rethrow;
    }
  }

  public string function getFileContent() {
    return fileRead( getFilePath() );
  }

  public any function getFileInputStream( required string filePath ) {
    return variables.jFileInputStream.init( filePath );
  }

  public component function getInstance(){
    return duplicate( this );
  }
}
