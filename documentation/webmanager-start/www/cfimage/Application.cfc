component extends="framework.zero" {

  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  public void function onRequest(){
    if( not structKeyExists( variables, 'config' )) variables.config  = application.config;


    var imageName = listFirst( trim( url.src ), "/" );
    var sourcePath = "#variables.config.mediaRoot#/#imageName#";
    writeToBrowser( fileReadBinary( sourcePath ));
  }
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  private void function writeToBrowser( required binary compressedImage ){
    var imageIO = createObject( "java", "javax.imageio.ImageIO" );
    var byteArrayInputStream = createObject( "java", "java.io.ByteArrayInputStream" ).init( compressedImage );

    finishedImage = imageIO.read( byteArrayInputStream );

    var response = getPageContext().getFusionContext().getResponse();
        response.setHeader( "Content-Type", "image/jpg" );

    var outputStream = response.getResponse().getOutputStream();

    imageIO.write( finishedImage, "jpg", outputStream );
    abort;
  }

}
