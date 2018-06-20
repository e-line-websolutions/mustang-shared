<cfcomponent extends="apibase" output="false">
  <cffunction name="typeahead">
    <cfargument name="rc" />

    <cfset request.layout = false />

    <cfparam name="rc.name" default="" />
    <cfparam name="rc.field" default="firstname,infix,lastname" />

    <cfset rc.entity = "contact" />

    <cfset var result = [] />
    <cfset var query = [] />
    <cfset var maxresult = 15 />
    <cfset var queryParam = { "deleted" = true } />
    <cfset var queryStart = "SELECT t FROM #rc.entity# AS t WHERE t.deleted != :deleted AND ( " />
    <cfset var queryMid = "" />
    <cfset var queryEnd = "" />

    <cfset local.i = 0 />
    <cfloop list="#rc.field#" index="local.field">
      <cfset local.i++ />
      <cfset queryStart &= " t.#local.field# LIKE :name " />
      <cfif local.i lt listLen( rc.field )>
        <cfset queryStart &= " OR " />
      </cfif>
    </cfloop>
    <cfset queryStart &= " ) " />

    <cfif len( trim( rc.name ))>
      <!--- Search by exact string: --->
      <cfset queryParam["name"] = "#rc.name#" />
      <cfset var qry_sel_exact = ORMExecuteQuery( queryStart & queryMid & queryEnd, queryParam, false, { "maxresults" = maxresult } )/>
      <cfloop array="#qry_sel_exact#" index="local.row">
        <cfset arrayAppend( query, local.row ) />
      </cfloop>
      <cfset maxresult -= arrayLen( query ) />

      <!--- Search by first part of the string: --->
      <cfif arrayLen( query ) lt maxresult>
        <cfset queryParam["name"] = "#rc.name#%" />
        <cfset queryMid = "" />
        <cfif arrayLen( query )>
          <cfset queryMid = " AND NOT t IN ( :prev ) " />
          <cfset queryParam["prev"] = query />
        </cfif>
        <cfset var qry_sel_start = ORMExecuteQuery( queryStart & queryMid & queryEnd, queryParam, false, { "maxresults" = maxresult } )/>
        <cfloop array="#qry_sel_start#" index="local.row">
          <cfset arrayAppend( query, local.row ) />
        </cfloop>
        <cfset maxresult -= arrayLen( query ) />
      </cfif>

      <!--- Search by any part of the string: --->
      <cfif arrayLen( query ) lt maxresult>
        <cfset queryParam["name"] = "%#rc.name#%" />
        <cfset queryMid = "" />

        <cfif arrayLen( query )>
          <cfset queryMid = " AND NOT t IN ( :prev ) " />
          <cfset queryParam["prev"] = query />
        </cfif>
        <cfset var qry_sel_rest = ORMExecuteQuery( queryStart & queryMid & queryEnd, queryParam, false, { "maxresults" = maxresult } )/>
        <cfloop array="#qry_sel_rest#" index="local.row">
          <cfset arrayAppend( query, local.row ) />
        </cfloop>
        <cfset maxresult -= arrayLen( query ) />
      </cfif>

      <cfloop array="#query#" index="local.row">
        <cfset local.resultItem = {
          "id"        = local.row.getID(),
          "name"      = local.row.getName()
        } />
        <cfset arrayAppend( result, local.resultItem ) />
      </cfloop>
    </cfif>

    <cfset returnAsJSON( result ) />
  </cffunction>
</cfcomponent>