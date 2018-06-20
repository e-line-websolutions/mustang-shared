<cfparam name="local.generatedBody" default="" />
<cfparam name="local.headerTitle" default="" />

<cfif not isDefined( "rc.content" )>
  <cfset rc.content = entityNew( "content" ) />
  <cfset rc.content.setTitle( rc.displaytitle ) />
</cfif>

<cfif len( trim( rc.content.getTitle()))>
  <cfset local.headerTitle &= rc.content.getTitle() />
<cfelseif getSection() eq "main" and rc.auth.isLoggedIn>
  <cfset local.headerTitle &= '#i18n.translate( 'welcome' )# #rc.auth.user.firstname#' />
</cfif>

<cfif len( trim( rc.content.getSubTitle()))>
  <cfset local.headerTitle &= ' <small>#rc.content.getSubTitle()#</small>' />
</cfif>

<cfif rc.auth.isLoggedIn and rc.auth.role.can( "change", "content" )>
  <cfset local.editContentLink = buildURL(
    action = ":content.edit",
    querystring = {
      "returnTo" = getFullyQualifiedAction()
    }
  ) />
  <cfset local.headerTitle &= '<a class="btn btn-default pull-right text-muted" href="#local.editContentLink#" title="#i18n.translate('edit-content')#"><i class="fa fa-pencil"></i></a>' />
</cfif>

<cfoutput>
  <div class="row content">
    <div class="col-lg-12">
      <!--- <h1 class="page-header">#local.headerTitle#</h1> --->
      <div class="hidden-xs">#view( ":elements/breadcrumbs" )#</div>

      #view( ":elements/alert" )#

      <cfif isDefined( "rc.content" ) and len( trim( rc.content.getBody()))>
        <p>#rc.content.getBody()#</p>
      </cfif>

      #local.generatedBody#
    </div>
  </div>
</cfoutput>