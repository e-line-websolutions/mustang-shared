<cfoutput>
  <div class="modal-header">
    <!--- <button type="button" class="close" data-dismiss="modal"><span aria-hidden="true">&times;</span><span class="sr-only">#i18n.translate( 'close' )#</span></button> --->
    <h5 class="modal-title text-muted">#rc.modalContent.title#</h5>
  </div>
  <div class="modal-body">#body#</div>
  <cfif not arrayIsEmpty( rc.modalContent.buttons )>
    <div class="modal-footer">
      <cfloop array="#rc.modalContent.buttons#" index="local.button">
        <button type="button" class="btn #local.button.classes#">#i18n.translate( local.button.title )#</button>
      </cfloop>
    </div>
  </cfif>
</cfoutput>

<!--- Don't include global layout for this, since that includes all kinds of js includes and other uglyness --->
<cfset disableLayout() />