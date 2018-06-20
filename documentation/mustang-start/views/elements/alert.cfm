<cfparam name="rc.alert" type="struct" default="#{}#" />
<cfparam name="rc.alert.class" type="string" default="" />
<cfparam name="rc.alert.text" type="string" default="" />
<cfparam name="rc.alert.stringVariables" type="struct" default="#{}#" />

<cfif len( trim( rc.alert.text ))>
  <cfoutput>
    <div class="row">
      <div class="col-lg-12">
        <div class="alert alert-dismissable alert-#rc.alert.class#">
          <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
          #i18n.translate( label = rc.alert.text, stringVariables = rc.alert.stringVariables )#
        </div>
      </div>
    </div>
  </cfoutput>
</cfif>