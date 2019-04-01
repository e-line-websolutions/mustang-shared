component accessors=true {
  public void function addMediaQueriesToRequestScope( required struct requestContext ) {
    requestContext[ "mediaQueries" ] = [
      { "size" = "s", "width" = 100 },
      { "size" = "m", "width" = 480 },
      { "size" = "l", "width" = 768 },
      { "size" = "x", "width" = 1024 }
    ];
  }
}