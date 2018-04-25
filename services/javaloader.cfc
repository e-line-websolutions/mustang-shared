component {
  public component function new( ) {
    // if ( val( server.coldfusion.productversion ) < 10 ) {
    return new javaloader.javaloader( argumentCollection = arguments );
    // }

    // return this;
  }

  public any function create( required string className ) {
    return createObject( "java", className );
  }
}