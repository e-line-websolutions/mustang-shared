<cfparam name="local.name" default="" />
<cfparam name="local.yesLink" default="" />

<cfoutput>
  <div class="modal" id="confirm#local.name#" data-name="#local.name#" tabindex="-1">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header">
          <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
          <h4 class="modal-title">#i18n.translate('modal-#local.name#-title')#</h4>
        </div>
        <div class="modal-body">
          <p>#i18n.translate('modal-#local.name#-body')#</p>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-default" data-dismiss="modal">#i18n.translate('no-dont-#local.name#')#</button>
          <a href="#local.yesLink#" class="btn btn-primary">#i18n.translate('yes-#local.name#')#</a>
        </div>
      </div>
    </div>
  </div>
</cfoutput>