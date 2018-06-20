<cfif not structKeyExists( rc, "content" )>
  <cfset rc.content = entityNew( "content" ) />
</cfif>

<cfoutput>
  <div class="row centercenter">
    <div class="col-lg-offset-2 col-lg-8">
      <div class="panel panel-default">
        <div class="panel-heading">
          <h3 class="panel-title">#rc.content.getTitle()#</h3>
        </div>
        <div class="panel-body">
          <cfif len( trim( rc.content.getBody()))>
            <p>#rc.content.getBody()#</p>
          </cfif>

          #view( ':elements/alert' )#

          <form class="form-horizontal" action="#buildURL( ':security.dologin' )#" method="post">
            <input type="hidden" name="origin" value="#getSubsystem()#">

            <div class="form-group row">
              <label for="username" class="col-lg-4 control-label">#i18n.translate('username')#</label>
              <div class="col-lg-8">
                <input type="text" class="form-control" name="username" id="username" placeholder="#i18n.translate('placeholder-username')#">
              </div>
            </div>
            <div class="form-group row">
              <label for="password" class="col-lg-4 control-label">#i18n.translate('password')#</label>
              <div class="col-lg-8">
                <input type="password" class="form-control" name="password" id="password" placeholder="#i18n.translate('placeholder-password')#">
              </div>
            </div>
            <div class="form-group row">
              <div class="col-lg-offset-4 col-lg-8">
                <button type="submit" class="btn btn-primary">#i18n.translate('log-in')#</button>
              </div>
            </div>
          </form>
        </div>
      </div>
    </div>
    <div class="clearfix"></div>
  </div>
</cfoutput>