<cfparam name="local.column" />
<cfparam name="local.formElementName" />
<cfparam name="local.idPrepend" />

<cfset local.required = "" />

<cfif not isBoolean( local.column.saved )>
  <cfset local.column.saved = false />
</cfif>

<cfset local.checked = local.column.saved ? 'checked="checked"' : '' />

<cfif structKeyExists( local.column, "required" )>
  <cfset local.requiredMessage = i18n.translate( "#local.column.name#-required-message" ) />
  <cfset local.required = 'required data-bv-message="#local.requiredMessage#" data-bv-notempty="true"' />
</cfif>

<cfset local.id = local.idPrepend & local.column.name />

<cfoutput>
  <div class="checkbox">
    <label><input type="checkbox" name="#local.formElementName#" id="#local.id#" value=1 #local.checked# #local.required# /> #i18n.translate( local.column.name )#</label>
  </div>
</cfoutput>