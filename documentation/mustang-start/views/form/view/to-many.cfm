<cfoutput>
  <cfparam name="local.val" default="#[]#" />
  <cfparam name="local.column" default="#{}#" />
  <cfparam name="local.column.data" default="#{}#" />
  <cfparam name="local.inlist" default=false />

  <cfset listedIDs = [] />
  <cfif not local.inlist><ul class="list-group"></cfif>

  <cfloop array="#local.val#" index="singleVal">
    <cfset valID        = singleVal.getID() />
    <cfset valString    = singleVal.getName() />
    <cfset linkSection  = singleVal.getEntityName() />

    <cfif arrayFind( listedIDs, valID )>
      <cfcontinue />
    </cfif>
    <cfset arrayAppend( listedIDs, valID ) />

    <cfif isNull( valString )>
      <cfset valString = i18n.translate( 'no-name' ) />
    <cfelse>
      <cfif structKeyExists( local.column.data, "translateOptions" )>
        <cfset valString = i18n.translate( valString ) />
      </cfif>
    </cfif>

    <cfif not isNull( valID ) and len( trim( valID ))>
      <cfset linkTo = buildURL( action = linkSection & '.view', queryString = { '#linkSection#id' = valID }) />
      <cfset valString = '<a href="#linkTo#"#local.inlist?' class="tag tag-pill tag-info"':''#>#valString#</a>' />
    </cfif>

    <cfif not local.inlist><li class="list-group-item p-1"></cfif>

    #valString#

    <cfif not local.inlist></li></cfif>
  </cfloop>

  <cfif not local.inlist></ul></cfif>
</cfoutput>