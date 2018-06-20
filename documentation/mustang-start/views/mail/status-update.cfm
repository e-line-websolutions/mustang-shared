<cfprocessingdirective pageEncoding="utf-8" />

<cfoutput>
  <cfif not isNull( view.content ) and len( trim( view.content.body ) )>
    <p>#view.content.body#</p>
  </cfif>

  <cfif not isNull( view.records ) and not arrayIsEmpty( view.records )>
    <table width="100%">
      <cfloop array="#view.records#" index="record">
        <cfparam name="record.description" default="" />
        <cfparam name="record.status" default="200" />
        <cfparam name="record.message" default="" />
        <tr>
          <td style="color:#record.status eq 200 ? '##20df20' : 'red'#" width="0%" nowrap="nowrap">#record.status eq 200 ? '✔' : '✘'#</td>
          <td width="100%">#record.description#</td>
        </tr>
        <cfif len( record.message )>
          <tr>
            <td>&nbsp;</td>
            <td style="color:#record.status eq 200 ? 'black' : 'red'#">#record.message#</td>
          </tr>
        </cfif>
        <cfif structKeyExists( record, "extraInfo" ) and len( record.extraInfo )>
          <tr>
            <td>&nbsp;</td>
            <td>#record.extraInfo#</td>
          </tr>
        </cfif>
      </cfloop>
    </table>
  </cfif>
</cfoutput>