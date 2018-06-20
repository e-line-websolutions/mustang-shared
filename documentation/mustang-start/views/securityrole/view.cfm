<cfif not structKeyExists( local, "role" )>
  <cfset local.role = rc.data />
</cfif>

<cfset local.iconTrue = '<i class="fa fa-check-circle-o" style="color:green;"></i>' />
<cfset local.iconFalse = '<i class="fa fa-circle-o" style="color:red;"></i>' />
<cfset local.privileges = "create,view,change,delete,execute" />

<cfsavecontent variable="local.formappend"><cfoutput>
  <div class="panel panel-default">
    <div class="panel-heading">
      <h4 class="panel-title">#local.role.getName()#</h4>
    </div>

    <div id="collapseRoleItems" class="panel-collapse collapse in">
      <div class="panel-body">
        <table class="table table-condensed table-bordered">
          <tr>
            <th></th>
            <cfloop list="#local.privileges#" index="local.privilege">
              <th class="text-center">#i18n.translate( local.privilege )#</th>
            </cfloop>
          </tr>
          <cfloop array="#local.role.getPermissions()#" index="local.securityRole">
            <tr>
              <th>#local.securityRole.getSection()#</th>
              <cfloop list="#local.privileges#" index="local.privilege">
                <td class="text-center">#evaluate( "local.securityRole.get#local.privilege#()" )?local.iconTrue:local.iconFalse#</td>
              </cfloop>
            </tr>
          </cfloop>
        </table>
      </div>
    </div>
  </div>
</cfoutput></cfsavecontent>

<cfoutput>#view( ':elements/edit', { formappend = local.formappend })#</cfoutput>