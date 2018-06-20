<cfparam name="rc.subnav" default="" />
<cfparam name="rc.subnavHideHome" default=true />

<cfset local.filesMenuItemPointer = listFindNoCase( rc.subnav, "files" ) />
<cfif local.filesMenuItemPointer>
  <cfset rc.subnav = listDeleteAt( rc.subnav, local.filesMenuItemPointer ) />
</cfif>

<cfoutput>
  <ul class="nav nav-pills flex-column" id="side-menu">
    <cfif not rc.subnavHideHome>
      <li class="nav-item"><a class="nav-link#( getSection() eq 'main' )?' active':''#" href="#buildURL( ':' )#">#i18n.translate( getSubsystem() & ':main.default' )#</a></li>
    </cfif>
    <cfloop list="#rc.subnav#" index="local.fqa">
      <cfif listFirst( local.fqa, '=' ) eq "external">
        <cfset local.subsystem = "" />
        <cfset local.section = "" />
        <cfset local.href = listRest( local.fqa, '=' ) />
        <cfset local.active = false />
        <cfset local.label = i18n.translate( local.fqa ) />
      <cfelse>
        <cfset local.subsystem = getSubsystem( local.fqa ) />
        <cfset local.section = getSection( local.fqa ) />
        <cfif local.section eq "-">
          <li style="border:0;">&nbsp;</li>
          <cfcontinue />
        </cfif>
        <cfset local.href = buildURL( local.subsystem & ':' & local.section ) />
        <cfset local.active = ( local.subsystem eq getSubSystem() and local.section eq getSection() ) />
        <cfset local.label = i18n.translate( local.subsystem & ':' & local.section & '.default' ) />
      </cfif>

      <li class="nav-item">
        <a class="nav-link #local.active?' active':''#" href="#local.href#">#local.label#</a>
        <cfif isDefined( "rc.subsubnav" ) and
              (
                ( isSimpleValue( rc.subsubnav ) and len( trim( rc.subsubnav ))) or
                ( isArray( rc.subsubnav ) and arrayLen( rc.subsubnav ))
              ) and getSection() eq local.section>
          <ul class="nav nav-second-level">
            <cfif isSimpleValue( rc.subsubnav )>
              <cfloop list="#rc.subsubnav#" index="local.subsubitem">
                <li class="nav-item"><a class="nav-link#( getfullyqualifiedaction() eq '#subsystem#:#section#.#local.subsubitem#' )?' active':''#" href="#buildURL('.#local.subsubitem#')#">#i18n.translate( '#subsystem#:#section#.#local.subsubitem#' )#</a></li>
              </cfloop>
            <cfelse>
              <cfloop array="#rc.subsubnav#" index="local.subsubitem">
                <cfset local.active = true />
                <cfloop collection="#local.subsubitem.querystring#" item="local.key">
                  <cfif not structKeyExists( rc, local.key ) or not rc[local.key] eq local.subsubitem.querystring[local.key]>
                    <cfset local.active = false />
                    <cfbreak />
                  </cfif>
                </cfloop>
                <li class="nav-item"><a class="nav-link#local.active?' active':''#" href="#buildURL( action='.#local.subsubitem.action#', querystring=local.subsubitem.querystring)#">#local.subsubitem.label#</a></li>
              </cfloop>
            </cfif>
          </ul>
        </cfif>
      </li>
    </cfloop>
  </ul>

  <cfif structKeyExists( rc, "subnavwell" ) and len( trim( rc.subnavwell ))>
    <div class="well well-sm" style="margin:15px;">
      #rc.subnavwell#
    </div>
  </cfif>
</cfoutput>