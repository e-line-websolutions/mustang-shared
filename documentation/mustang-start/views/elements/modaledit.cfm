<cfprocessingdirective pageEncoding="utf-8" />

<cfparam name="local.formappend" default="" />
<cfparam name="local.formprepend" default="" />
<cfparam name="local.fieldOverride" default="" />
<cfparam name="local.dialogName" default="#createUUID()#" />

<cfoutput>
  <div class="modal-dialog modal-lg" data-entity="#getSection()#">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title">#i18n.translate('add')#</h4>
      </div>
      <div class="modal-body">#view( ":elements/edit" )#</div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal">#i18n.translate('modal-cancel')#</button>
        <button type="button" class="btn btn-primary inlineedit-modal-save">#i18n.translate('modal-save')# #lCase( i18n.translate( getSection()))#</button>
      </div>
    </div>
  </div>
</cfoutput>