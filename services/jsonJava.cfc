component accessors=true {
  public component function init( root, config ) {
    var jlPaths = [ expandPath( "/mustang/lib/json/gson-2.8.jar" ) ];

    if ( !isNull( config ) && !isNull( config.paths.jsonLib ) && directoryExists( config.paths.jsonLib ) ) {
      jlPaths = [ config.paths.jsonLib ];
    }

    var jl = new javaloader.javaloader( jlPaths );

    variables.gson = jl.create( "com.google.gson.GsonBuilder" )
      .serializeNulls( )
      .create( );

    return this;
  }

  public string function serialize( required any source ) {
    return variables.gson.toJsonTree( source ).toString( );
  }

  public any function jsonFileToCf( required string path ) {
    return this.deserialize( fileRead( path, "utf-8" ) );
  }

  public any function deserialize( required string source ) {
    source = lTrim( source );

    var firstChar = left( source, 1 );

    switch ( firstChar ) {
      case '{' : return deserializeStruct( source );
      case '[' : return deserializeArray( source );
    }

    return;
  }

  public struct function deserializeStruct( required string source ) {
    try {
      var struct = { };
      return duplicate( variables.gson.fromJson( source, struct.getClase( ) ) );
    } catch ( any e ) {
      return deserializeJSON( source );
    }
  }

  public array function deserializeArray( required string source ) {
    var array = [ ];
    return duplicate( variables.gson.fromJson( source, array.getClass( ) ) );
  }
}