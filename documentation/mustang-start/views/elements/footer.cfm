<cfoutput>
  <cfif rc.debug and rc.config.showDebug>
    <cfset allLocales = entityLoad( 'locale' ) />
    <cfset fqa = getfullyqualifiedaction() />
    <div class="whitespace"></div>
    <div class="card border-danger">
      <div class="card-body">
        <h4>#request.appName# DEBUG INFO</h4>
        <small>
          Powered by FW/1 version #variables.framework.version#.<br />
          | <a href="#buildURL( ':app.docs?x=' & randRange( 1000, 9999 ))#">Docs</a>
          | <a href="#buildURL( ':app.loc' )#">LoC</a>
          | <a href="#buildURL( ':app.diagram' )#">Diagram</a>
          <cfif isFrameworkReloadRequest()>
            | <span class="label label-danger">Reloaded</span>
          <cfelse>
            | <a href="#buildURL( fqa, '?reload=1' )#">Reload</a>
          </cfif>
          <cfif request.reset>
            | <span class="label label-danger">Database Reloaded</span>
          <cfelseif isFrameworkReloadRequest()>
            | <span class="label label-success">Database Updated</span>
          </cfif>
          <br />Current FQA: <strong>#fqa#</strong>
          <br />Language:
          <cfloop array="#allLocales#" index="locale">
            <a class="label label-#rc.currentlocaleID eq locale.getID()?'info':'default'#" href="#buildURL( fqa, '?localeid=#locale.getID()#' )#">#locale.getCode()#</a>
          </cfloop>
          <br />Is logged in: #rc.auth.isLoggedIn#
        </small>
      </div>
    </div>
    <hr />
  </cfif>
  <div id="timer">#( getTickCount() - rc.startTime )#ms</div>
</cfoutput>