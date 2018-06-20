<cfif isNull( local.val ) or not isObject( local.val )>
  <cfexit />
</cfif>

<cfparam name="local.column" default="#{ }#" />
<cfparam name="local.column.data" default="#{ }#" />
<cfparam name="local.column.data.link" default="#false#" />

<cfset fieldlist = "" />
<cfset textvalue = local.val.getName( ) />

<cfif isNull( textvalue ) or not len( trim( textvalue ) )>
  <cfset textvalue = "noname" />
</cfif>

<cfif structKeyExists( local.column.data, "translateOptions" )>
  <cfset textvalue = i18n.translate( textvalue ) />
</cfif>

<cfif structKeyExists( local.column.data, 'affectsForm' )>
  <cfset fieldlist = local.val.getFieldList( ) />
</cfif>

<cfif len( trim( local.val.getId( ) ) ) and local.column.data.link>
  <cfset entityName = listLast( getMetaData( val ).name, '.' ) />
  <cfset fqa = "#entityName#.view" />
  <cfset link = buildURL( fqa, "", { "#entityName#id" = local.val.getId( ) } ) />
  <cfset textvalue = '<a href="#link#">#textvalue#</a>' />
</cfif>

<cfoutput>
  <span class="selectedoption" data-fieldlist="#fieldlist#">#textvalue#</span>
</cfoutput>