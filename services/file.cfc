component accessors=true {
  property beanFactory;
  property config;

  public component function upload( required string uploadField, string destination = 'temp/' ) {
    if ( destination contains '..' ) {
      throw( 'path security error' );
    }

    var tmpFilename = config.paths.fileUploads & '/' & destination & '/file-#createUUID()#.tmp';
    var uploadState = fileUpload( tmpFilename, uploadField, '', 'MakeUnique' );

    var fileObj = beanFactory.getBean( 'fileBean' );

    fileObj.setFilePath( uploadState.serverDirectory & '/' & uploadState.serverFile );
    fileObj.setOriginalFileName( uploadState.clientFile );
    fileObj.setFileName( uploadState.serverFile );
    fileObj.setFileSize( uploadState.fileSize );

    return fileObj;
  }

  public string function fsPathFormat( required string input, string sub = ' ', string replaceSpace = ' ', boolean toLowercase = false ) {
    var illegalChars = listToArray( '<,>,:,",/,\,|,?,*' );

    if ( sub.len() > 1 ) throw( 'substitute with a single char only' );
    if ( illegalChars.find( sub ) ) throw( 'invalid substitute char' );

    illegalChars.each( function( char ) {
      input = replace( input, char, sub, 'all' );
    } );

    input = replace( trim( input ), ' ', replaceSpace, 'all' );

    return toLowercase ? lCase( input ) : input;
  }
}