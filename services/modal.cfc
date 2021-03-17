component {
  public struct function button( string title = 'OK', string classes = 'btn-primary' ) {
    if ( !classes.findNoCase( 'btn-' ) ) {
      classes &= 'btn-primary';
    }

    return { 'title' = title, 'classes' = classes };
  }

  public struct function defaultModalConfig() {
    return {
      'title' = '',
      'body' = '',
      'buttons' = [ button( 'close', 'btn-modal-close' ) ]
    };
  }
}