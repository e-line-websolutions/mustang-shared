component accessors=true {
  property logService;
  property struct imageSizes;
  property string sourceDir;
  property string destinationDir;
  property string hiresDir;

  variables.imageSizes = {
    "large" = [ 1280, 1280 ],
    "medium" = [ 512, 512 ],
    "small" = [ 64, 64 ]
  };

  public component function init( root, logService, imageSizes ) {
    variables.logService = logService;
    variables.logService.setConfig( { "logLevel" = "information" } );
    this.jl = new javaloader.JavaLoader( [ expandPath( "/mustang/lib/imageScaler/java-image-scaling-0.8.5.jar" ) ] );

    if ( !isNull( imageSizes ) ) {
      variables.imageSizes = imageSizes;
    }

    return this;
  }

  public void function resizeFromSourceDir( required string imageName, required string size, numeric quality = 1 ) {
    var sourcePath = "#variables.sourceDir#/#imageName#";

    if ( !isNull( variables.hiresDir ) && fileExists( "#variables.hiresDir#/2000_#imageName#" ) ) {
      sourcePath = "#variables.hiresDir#/2000_#imageName#";
    }

    if ( !fileExists( sourcePath ) ) {
      return;
    }

    resizeFromImage( sourcePath, imageName, size, quality );
  }

  public void function resizeFromPath( any sourcePath, string imageName, required string size, numeric quality = 1 ) {
    var sourceImage = imageNew( sourcePath );
    resizeFromImage( sourceImage, imageName, size, quality );
  }

  public void function resizeFromBaos( any bytes, string imageName, required string size, numeric quality = 1 ) {
    var sourceImage = imageNew( baosToImage( bytes ) );
    resizeFromImage( sourceImage, imageName, size, quality );
  }

  public void function resizeFromImage( any sourceImage, string imageName, required string size, numeric quality = 1 ) {
    setupSize( size );

    var destinationPath = "#variables.destinationDir#/#size#-#imageName#";

    if ( fileExists( destinationPath ) && !structKeyExists( url, "reload" ) ) {
      logService.writeLogLevel( "SKIPPED: #variables.destinationDir#/#size#-#imageName# already exists.", "imageScaler" );
      return;
    }

    var destinationWidth = variables.imageSizes[ size ][ 1 ];
    var destinationHeight = arrayIsDefined( variables.imageSizes[ size ], 2 ) ? variables.imageSizes[ size ][ 2 ] : destinationWidth;

    var resized = resize( sourceImage, destinationWidth, destinationHeight );
    var compressedImage = compress( resized, quality );

    fileWrite( destinationPath, compressedImage );

    logService.writeLogLevel( "SAVED: #variables.destinationDir#/#size#-#imageName#", "imageScaler" );
  }

  private any function baosToImage( required any bytes ) {
    bytes.flush();
    var imageInByte = bytes.toByteArray();
    bytes.close();
    var imageIO = createObject( "java", "javax.imageio.ImageIO" );
    return imageIO.read( createObject( "java", "java.io.ByteArrayInputStream" ).init( imageInByte ) );
  }

  private any function resize( required any sourceImage, required string width = "", required string height = "" ) {
    var d = {
      width = int( val( width ) ),
      height = int( val( height ) )
    };

    if ( width == "" || height == "" ) {
      if ( width == "" ) {
        d.width = height;
        d.height = ( sourceImage.height / sourceImage.width ) * height;
      } else {
        d.width = ( sourceImage.width / sourceImage.height ) * width;
        d.height = width;
      }
    }

    var bufferedImage = imageGetBufferedImage( sourceImage );
    var dimensionConstrain = this.jl.create( "com.mortennobel.imagescaling.DimensionConstrain" );
    var resampleOp = this.jl.create( "com.mortennobel.imagescaling.ResampleOp" );

    return resampleOp.init( dimensionConstrain.createMaxDimension( d.width, d.height ) ).filter( bufferedImage, nil( ) );
  }

  private binary function compress( required alteredImage, numeric quality = 1 ) {
    var byteArrayOutputStream = createObject( "java", "java.io.ByteArrayOutputStream" ).init( );
    var imageOutputStream = createObject( "java", "javax.imageio.stream.MemoryCacheImageOutputStream" ).init( byteArrayOutputStream );

    var imageIO = createObject( "java", "javax.imageio.ImageIO" );
    var JPEGWriter = imageIO.getImageWritersByFormatName( "jpg" ).next( );
        JPEGWriter.setOutput( imageOutputStream );

    var JPEGWriterParam = createObject( "java", "javax.imageio.plugins.jpeg.JPEGImageWriteParam" ).init( nil( ) );
        JPEGWriterParam.setCompressionMode( JPEGWriterParam.MODE_EXPLICIT );
        JPEGWriterParam.setCompressionQuality( quality );

    var IIOImage = createObject( "java", "javax.imageio.IIOImage" );
    var outputImage = IIOImage.init( alteredImage, nil( ), nil( ) );

    JPEGWriter.write( nil( ), outputImage, JPEGWriterParam );
    JPEGWriter.dispose( );

    return byteArrayOutputStream.toByteArray( );
  }

  private void function setupSize( size ) {
    if ( !structKeyExists( variables.imageSizes, size ) ) {
      throw( "Invalid size", "imageScalerService.getImage.invalidSizeError", "Valid options are #structKeyList( variables.imageSizes )#" );
    }
  }

  private void function nil( ) {
  }
}