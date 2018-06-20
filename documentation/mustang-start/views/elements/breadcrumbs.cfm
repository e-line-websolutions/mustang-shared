<cfoutput>
  <cfset local.title = i18n.translate(getfullyqualifiedaction()) />

  <cfif isDefined( "rc.content" )>
    <cfif len( trim( rc.content.getHTMLTitle()))>
      <cfset local.title = rc.content.getHTMLTitle() />
    <cfelseif len( trim( rc.content.getTitle()))>
      <cfset local.title = rc.content.getTitle() />
    </cfif>
  </cfif>

  <cfif not isDefined( "rc.breadcrumbs" )>
    <cfset rc.breadcrumbs = [
      { path = buildURL( getSubsystem() & ':' ), label = i18n.translate( getSubsystem() & ':main' ) }
    ] />

    <cfif getSection() neq 'main'>
      <cfset arrayAppend( rc.breadcrumbs, { path = buildURL( getSubsystem() & ':' & getSection() & '.' ), label = i18n.translate( getSubsystem() & ':' & getSection()) } ) />
    </cfif>

    <cfset arrayAppend( rc.breadcrumbs, { label = local.title }) />
  </cfif>

  <ol class="breadcrumb">
    <cfset local.i = 0 />
    <cfloop array="#rc.breadcrumbs#" index="local.breadcrumb">
      <cfset local.i++ />
      <cfset local.class = arrayLen( rc.breadcrumbs ) eq local.i ? ' active' : '' />
      <cfif structKeyExists( local.breadcrumb, "path" )>
        <li class="breadcrumb-item#local.class#"><a href="#local.breadcrumb.path#">#local.breadcrumb.label#</a></li>
      <cfelse>
        <li class="breadcrumb-item#local.class#">#local.breadcrumb.label#</li>
      </cfif>
    </cfloop>
  </ol>
</cfoutput>