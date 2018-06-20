<cfparam name="local.columns" default="#[]#" />
<cfparam name="local.lineactions" default="" />
<cfparam name="local.confirmactions" default="" />
<cfparam name="local.entity" default="#getSection()#" />
<cfparam name="local.class" default="" />
<cfparam name="local.classColumn" default="" />
<cfparam name="local.data" default="#createObject( 'basecfc.base' ).init()#" />

<cfset lineTitle = "" />
<cfset instanceVars = local.data.getInstanceVariables( ) />

<cfif local.data.propertyExists( "updateDate" )>
  <cfset updated = local.data.getUpdateDate() />
  <cfif not isDefined( "updated" ) or not isDate( updated )>
    <cfset updated = local.data.getCreateDate() />
  </cfif>
  <cfif isDefined( "updated" ) and isDate( updated )>
    <cfset lineTitle = "#i18n.translate( 'last-updated' )#: #lsDateFormat( updated, i18n.translate( 'defaults-dateformat-small' ))# #lsTimeFormat( updated, 'HH:mm:ss' )#" />
  </cfif>
</cfif>

<cfif len( trim( local.classColumn )) and local.data.propertyExists( local.classColumn )>
  <cfset local.classColumn = evaluate( "local.data.get#local.classColumn#()" ) />
  <cfif isDefined( "local.classColumn" )>
    <cfset local.class = local.classColumn.getClass() />
  </cfif>
  <cfif isNull( local.class )>
    <cfset local.class = "" />
  </cfif>
</cfif>

<cfoutput>
  <tr data-recordId="#local.data.getId()#"#len(local.class)?' class="#local.class#"':''##len(lineTitle)?' title="#lineTitle#"':''#>
    <cfif structKeyExists( local, "rowNr" )>
      <th class="rowNr">#rowNr#</th>
    </cfif>

    <cfloop array="#local.columns#" index="column">
      <cfif isDefined( "column" )>
        <td>#trim( view( "form/view/field", { data = local.data, column = column }))#</td>
      <cfelse>
        <td></td>
      </cfif>
    </cfloop>

    <cfif len( trim( local.lineactions ))>
      <td nowrap="nowrap"><div class="pull-right btn-toolbar"><div class="btn-group btn-group-sm mr-2">
        <cfloop list="#local.lineactions#" index="action">
          <cfif action eq "|">
            </div><div class="btn-group btn-group-sm mr-2">
            <cfcontinue />
          </cfif>

          <cfset entity = instanceVars.entityName />
          <cfset fwAction = listLen( action, "." ) gte 2 ? action : ( entity & action ) />
          <cfset actionLink = buildURL( action = fwAction, queryString = { "#getSection( fwAction )#id" = local.data.getID() } ) />
          <cfset cssClass = "btn btn-primary #listChangeDelims( action, '-', '.' )#" />
          <cfset aArgs = ' class="#cssClass#" href="#actionLink#"' />

          <cfif listFindNoCase( local.confirmactions, action )>
            <cfset aArgs &= ' data-toggle="modal"' />
          </cfif>

          <a#aArgs#>#i18n.translate( action )#</a>
        </cfloop>
      </div></div></td>
    </cfif>
  </tr>
</cfoutput>