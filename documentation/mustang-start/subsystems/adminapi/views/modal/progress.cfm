<cfparam name="rc.progressStatus" default="" />
<cfparam name="rc.progressCount" default=0 />
<cfparam name="rc.progressMax" default=100 />

<cfoutput>
  <progress class="progress progress-striped progress-animated"
            value="#int( htmlEditFormat( rc.progressCount ) )#"
            max="#int( htmlEditFormat( rc.progressMax ) )#"
            aria-describedby="progressStatus"></progress>
  <div class="text-muted" id="progressStatus">#htmlEditFormat( rc.progressStatus )# #int( htmlEditFormat( rc.progressCount ) )#%</div>
</cfoutput>