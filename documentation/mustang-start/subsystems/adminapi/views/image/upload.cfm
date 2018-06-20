<cfoutput>
  <script>
    var _editor = top.tinymce.activeEditor;
    _editor.insertContent( '<img src="/cfimage/?src=#urlEncodedFormat( rc.result )#" />' );
    _editor.windowManager.close();
  </script>
</cfoutput>