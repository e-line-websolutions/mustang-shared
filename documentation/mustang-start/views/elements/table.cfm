<cfparam name="local.alldata" default="#[]#" />
<cfparam name="local.columns" default="#[]#" />
<cfparam name="local.lineview" default=":elements/line" />
<cfparam name="local.lineactions" default="" />
<cfparam name="local.confirmactions" default="" />
<cfparam name="local.classColumn" default="" />
<cfparam name="local.queryString" default="#{}#" />

<cfoutput>
  <table class="table table-sm table-striped">
    <thead>
      <tr>
        <th width="45">&nbsp;</th>
        <cfset indexNr = 0 />
        <cfloop array="#local.columns#" index="column">
          <cfset outputName = structKeyExists( column.data, "label" ) ? column.data.label : column.name />
          <cfset indexNr++ />
          <cfset columnClass = "" />
          <cfif structKeyExists( column, "class" )>
            <cfset columnClass = column.class />
          </cfif>
          <th class="#columnClass#" nowrap="nowrap">
            <cfif structKeyExists( column.data, "fieldType" ) and (
              column.data.fieldType contains 'to-one' or
              column.data.fieldType eq 'column'
            )>
              <cfset qs = duplicate( local.queryString ) />
              <cfset qs["orderby"] = column.name />
              <cfif rc.orderby eq column.name and rc.d eq 0>
                <cfset qs["d"] = 1 />
              </cfif>
              <cfset sortLink = buildURL(
                action      = getFullyQualifiedAction(),
                queryString = qs
              ) />
              <a href="#sortLink#">#i18n.translate( outputName )#</a>&nbsp;<cfif listFindNoCase( rc.orderby, column.name )><i class="fa fa-sort-#rc.d?'desc':'asc'#"></i></cfif>
            <cfelse>
              #i18n.translate( outputName )#
            </cfif>
          </th>
        </cfloop>
        <cfif len( local.lineactions )>
          <th></th>
        </cfif>
      </tr>
    </thead>
    <tbody>
      <cfif structKeyExists( local.queryString, 'offset' )>
        <cfset rowNr = local.queryString.offset + 1 />
      <cfelse>
        <cfset rowNr = 1 />
      </cfif>
      <cfloop array="#local.alldata#" index="data">
        <cfset params = {
          "data" = data,
          "columns" = local.columns,
          "lineactions" = local.lineactions,
          "confirmactions" = local.confirmactions,
          "class" = "#( data.getDeleted() eq true ? 'deleted' : '' )#",
          "classColumn" = local.classColumn,
          "rowNr" = rowNr++
        } />
        #view( local.lineview, params )#
      </cfloop>
    </tbody>
  </table>
</cfoutput>