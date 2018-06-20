<cfparam name="local.passwordLabel" default="reset-password" />

<cfoutput>
  <cfsavecontent variable="local.add_to_head">
    <script src="/inc/plugins/other/sha1-min.js"></script>
    <script src="/inc/plugins/other/xkcd-password.js"></script>
  </cfsavecontent>
  <cfhtmlhead text="#local.add_to_head#" />

  <cfsavecontent variable="local.formappend">
    <cfif rc.editable>
      <hr />
      <div class="form-group row">
        <label for="password" class="col-lg-3 control-label">#i18n.translate( local.passwordLabel )#</label>
        <div class="col-lg-9">
          <input type="text" name="password" class="form-control" placeholder="#i18n.translate( 'placeholder-password' )#" />
          <button title="http://xkcd.com/936/" type="button" id="generate-password" class="btn btn-default btn-sm" style="margin-top:5px;">#i18n.translate( 'generate' )#</button>
        </div>
      </div>
    </cfif>
  </cfsavecontent>

  #view( ":elements/edit",{formappend=local.formappend})#
</cfoutput>