<cfprocessingdirective pageEncoding="utf-8" />

<cfparam name="local.dialogName" default="#createUUID()#" />
<cfparam name="rc.namePrepend" default="" />
<cfparam name="local.namePrepend" default="#rc.namePrepend#" />

<cfset local.viewParams = {
  namePrepend = local.namePrepend
} />

<cfoutput>
  <div class="card" id="#local.dialogName#">
    <div class="card-block">#view( ":elements/edit", local.viewParams )#</div>
  </div>
</cfoutput>