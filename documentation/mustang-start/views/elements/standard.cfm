<cfif isDefined( "body" )>
  <cfset local.contentSettings = { generatedBody = duplicate( body ) } />
<cfelse>
  <cfset local.contentSettings = { generatedBody = "" } />
</cfif>

<cfoutput>
  #view( ":elements/content", local.contentSettings )#
</cfoutput>