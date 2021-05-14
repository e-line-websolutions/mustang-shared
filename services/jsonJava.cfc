component accessors=true {
  public component function init( root, config ) {
    variables.gson = createObject( 'java', 'com.google.gson.GsonBuilder' ).serializeNulls().create();
    return this;
  }

  public string function s( required any source ) { return this.serialize(source); }
  public any function d( required string source ) { return this.deserialize(source); }

  public string function serialize( required any source ) {
    if ( server.keyExists( 'lucee' ) && !isNull( source ) ) return serializeJSON( source );

    return variables.gson.toJsonTree( source ).toString();
  }

  public any function deserialize( required string source ) {
    if ( server.keyExists( 'lucee' ) && !isNull( source ) ) return deserializeJSON( source );

    if ( isNull( source ) || !isSimpleValue( source ) || !isJSON( source ) ) return;

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
      var struct = {};
      return duplicate( variables.gson.fromJson( source, struct.getClase() ) );
    } catch ( any e ) {
      return deserializeJSON( source );
    }
  }

  public array function deserializeArray( required string source ) {
    var array = [];
    try {
      return duplicate( variables.gson.fromJson( source, array.getClass() ) );
    } catch ( any e ) {
      return deserializeJSON( source );
    }
  }

  public any function jsonFileToCf( required string path ) {
    return this.deserialize( fileRead( path, 'utf-8' ) );
  }
}