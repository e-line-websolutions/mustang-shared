<cfoutput>
  <form action="#buildURL('.upload')#" method="post" enctype="multipart/form-data">
    <div class="form-group row">
      <label for="upload">#i18n.translate('upload-csv-file')#</label>
      <input type="file" id="upload" name="upload" />
      <p class="help-block">#i18n.translate('upload-csv-file.help')#</p>
    </div>

    <button type="submit" class="btn btn-default">#i18n.translate('next')#</button>
  </form>
</cfoutput>