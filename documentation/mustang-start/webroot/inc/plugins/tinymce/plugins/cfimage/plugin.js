tinymce.PluginManager.add( 'cfimage', function( editor, url ){
  editor.addButton( 'cfimage', {
    icon: 'image',
    onclick: function() {
      editor.windowManager.open({
        width     : 800,
        height    : 600,
        title     : 'Select, or upload image.',
        url       : './?action=api:image.browse',
        buttons   : [{ text: 'Cancel', onclick: 'close' }]
      });
    }
  });
});