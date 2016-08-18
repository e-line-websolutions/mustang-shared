component {
  public string function reportError( message, file ) {
    writeLog( text = message, file = file );
    return message;
  }
}