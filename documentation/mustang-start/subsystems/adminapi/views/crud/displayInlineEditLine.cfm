<cfparam name="rc.entityName" default="" />
<cfparam name="rc.formdata" default='{"uuid"=""}' />

<cfif isJSON( rc.formdata )>
  <cfset rc.formdata = deserializeJSON( rc.formdata ) />
</cfif>

<cfparam name="rc.formdata.uuid" default="" />

<cfset local.fieldsToDisplay = rc.entity.getFieldsToDisplay( 'inlineedit-line', rc.formdata ) />

<cfcontent type="text/html" reset="true" /><cfoutput>
  <cfswitch expression="#rc.entityName#">
    <cfdefaultcase>
      <tr class="inline-item">
        <cfloop array="#local.fieldsToDisplay#" index="local.fieldToDisplay">
          <td>#local.fieldToDisplay#</td>
        </cfloop>
        <td class="col-sm-3 text-right"><a href="##confirmremove" class="btn btn-xs btn-danger remove-button" data-entity="ajax" data-id="#htmlEditFormat( rc.formdata.uuid )#">#i18n.translate( 'remove' )#</a></td>
      </tr>
    </cfdefaultcase>
  </cfswitch>
</cfoutput><cfabort />