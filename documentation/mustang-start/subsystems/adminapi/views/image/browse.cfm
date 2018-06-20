<cfoutput>
  <script>
    var _editor = top.tinymce.activeEditor;

    $( document ).on( 'click', '##cfimage_list img', function(){
      _editor.insertContent( '<img src="' + $( this ).attr( 'src' ) + '" />' );
      _editor.windowManager.close();
    });
  </script>

  <div class="container">
    <h4>Upload a new image:</h4>

    <form role="form" method="post" enctype="multipart/form-data" action="<cfoutput>#buildURL('.upload')#</cfoutput>">
      <div class="form-group row">
        <label for="fileUpload">Image:</label>
        <input id="fileUpload" name="file" type="file" />
      </div>

      <div class="form-group row">
        <button type="submit">Upload</button>
      </div>
    </form>

    <hr />

    <h4>Or, select a previously uploaded image:</h4>

    <div id="cfimage_list">
      <div class="row">
        <cfset counter = 0 />
        <cfloop query="rc.data">
          <cfset counter++ />

          <cfif counter MOD 4 eq 0>
            </div><div class="row">
          </cfif>

          <div class="col-xs-6 col-sm-4">
            <a href="##select" class="thumbnail"><img src="/cfimage/?src=#urlEncodedFormat( name )#" /></a>
          </div>
        </cfloop>
      </div>
    </div>
  </div>
</cfoutput>