<cfparam name="local.menuItems" default="#rc.fullNavigation[ 1 ].children[ 1 ].children#" />
<cfparam name="local.path" default="" />
<cfparam name="local.n" default="1" />

<cfoutput>
  <cfif not arrayIsEmpty( local.menuItems )>
    <nav>
      <ul>
        <cfset submenu = {}>
        <cfloop array="#local.menuItems#" index="item">
          <cfif left( item.name , 1 ) neq "_">
          <cfset isActive = false>
          <cfif arrayFind( rc.navPath, local.path & "/#item.formatted#" ) >
            <cfset isActive = true>
            <cfif arrayLen( item.children ) gt 0>
              <cfset submenu = {
                "menuItems" = item.children,
                "path" = "#local.path#/#item.formatted#",
                "n" = local.n + 1
              }>
            </cfif>
          </cfif>
          <li>
            <a href="#rc.basePath##local.path#/#item.formatted#" class="nav-link#isActive?' active':''#">#item.name#</a>
          </li>
        </cfif>
        </cfloop>
      </ul>
    </nav>
  </cfif>

  <cfif structCount( submenu )>
    <div class="submenu">
      #view( ":elements/nav-full", submenu )#
    </div>
  </cfif>
</cfoutput>
