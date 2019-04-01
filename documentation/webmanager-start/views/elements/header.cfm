<cfoutput>
  <div class="row">
    <div class="col-8">
      <a class="navbar-brand" href="#buildUrl( rc.homepage )#">[LOGO]</a>
    </div>
    <div class="text-right col-4" id="top-right">
    </div>
  </div>
  <cfif structKeyExists( rc, 'navigation' )>
    <div id="navigation">#view( ":elements/nav-full", { path="/#rc.currentBaseMenuItem#", menuItems=rc.navigation } )#</div>
  </cfif>
</cfoutput>
