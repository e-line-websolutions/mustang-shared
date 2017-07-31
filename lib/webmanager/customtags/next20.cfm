<cfsetting enablecfoutputonly="Yes">

<cfscript>
  /* cfparam equivalents */
  if( not isDefined( "attributes.sQueryName" ))                 { attributes.sQueryName                 = "qry_sel_data" ; }

  /* Input variables */
  if( not isDefined( "attributes.sIndexQuery" ))                { attributes.sIndexQuery                = request.site.s_NOT_SET; }
  if( not isDefined( "attributes.sIDColumn" ))                  { attributes.sIDColumn                  = request.site.s_NOT_SET; }
  if( not isDefined( "attributes.sSelectQuery" ))               { attributes.sSelectQuery               = request.site.s_NOT_SET; }
  if( not isDefined( "attributes.nResultsPerPage" ))            { attributes.nResultsPerPage            = 20; }
  if( not isDefined( "attributes.nCurrentPage" ))               { attributes.nCurrentPage               =  1; }

  if( not isNumeric( attributes.nCurrentPage ) or attributes.nCurrentPage lte 0 )
  {
    attributes.nCurrentPage = 1;
  }

  /* Return variables */
  if( not isDefined( "attributes.sReturnTotalRecordCount" ))    { attributes.sReturnTotalRecordCount    = "nTotalRecordCount"; }
  if( not isDefined( "attributes.sReturnCurrentRecordCount" ))  { attributes.sReturnCurrentRecordCount  = "nCurrentRecordCount"; }
  if( not isDefined( "attributes.sReturnTotalPageCount" ))      { attributes.sReturnTotalPageCount      = "nTotalPageCount"; }
  if( not isDefined( "attributes.sReturnExecutionTime" ))       { attributes.sReturnExecutionTime       = "nExecutionTime"; }

  sIndexQueryName = "nxt20" & hash( cgi.remote_addr & cgi.remote_host & attributes.sIndexQuery );
  reload = false;
</cfscript>

<!--- [rvl] //
            // Sanity check. If we are missing some vital arguments, we'll just
            // throw an error and see what happens (evil developer!)
            //
--->
<cfif ( attributes.sIndexQuery  eq request.site.s_NOT_SET ) or
      ( attributes.sSelectQuery eq request.site.s_NOT_SET ) or
      ( attributes.sIDColumn    eq request.site.s_NOT_SET )
>
  <cfthrow message="no index and/or select query specified" />
</cfif>

<!--- [rvl] //
            // We will rerun the query to collect the data if:
            //
            //  1.  The index query is not present in the session scope (first
            //      time hit usually, or
            //  2.  We explicitly want to rerun the query to refresh the data.
            //      this can be caused by setting the recycle variable to true
            //
--->
<cflock timeout="5" type="readOnly" scope="session">
  <cfif not structKeyExists( session, "next20" ) or
        not structKeyExists( session.next20, "query" ) or
        not structKeyExists( session.next20.query, sIndexQueryName ) or
        (
          structKeyExists( caller.attributes, "bRecycle" ) and
          caller.attributes.bRecycle
        )
  >
    <cfset reload = true />
  <cfelse>
    <cfset next20 = duplicate( session.next20 ) />
    <cfset aID = duplicate( session.next20.query[sIndexQueryName] ) />
  </cfif>
</cflock>

<cfif reload>
  <cfquery datasource="#request.db.s_DSN#" name="#sIndexQueryName#" blockfactor="100">
    SELECT #attributes.sIDColumn# AS id #preserveSingleQuotes( attributes.sIndexQuery )#
    <cfif structKeyExists( attributes, "xOrderByClause" ) and
          isArray( attributes.xOrderByClause ) and
          arrayLen( attributes.xOrderByClause )>
      ORDER BY
      <cfloop from="1" to="#arrayLen( attributes.xOrderByClause )#" index="i">
        #attributes.xOrderByClause[i][1]# #iif( attributes.xOrderByClause[i][2], de( "ASC" ), de( "DESC" ))#
        <cfif i neq arrayLen( attributes.xOrderByClause )>,</cfif>
      </cfloop>
    </cfif>
  </cfquery>

  <cfscript>
    /*
     * What we'll do here:
     *
     *  [1] Clear the 'previous' or 'older' next20 session indexing array.
     *      This way, we won't end up polluting the session scope with
     *      unneeded indexing arrays.
     *  [2] Store the count of records in a returning variable. This is for
     *      displaying (the total amount of) results
     *  [3] Lastly, make an array of all the id's that we can use later on for
     *      selecting the data we actually need right here.
     */
    next20 = {};
    next20.nRecordCount = variables[sIndexQueryName].recordCount;

    nTmpPageIndex = 1;
    lTmpID        = "";
    aID           = [request.site.n_NOT_SET];

    for(  i = 1;
          i lte variables[sIndexQueryName].recordCount;
          i++ )
    {
      lTmpID = listAppend( lTmpID, variables[sIndexQueryName].id[i] );

      if(
          (
            i mod attributes.nResultsPerPage eq 0
          ) or
          (
            i eq variables[sIndexQueryName].recordCount
          )
      ){
        aID[nTmpPageIndex] = lTmpID;
        lTmpID = "";
        nTmpPageIndex++;
      }
    }

    next20.query[sIndexQueryName] = duplicate( aID );
  </cfscript>
</cfif>

<cfscript>
  if( attributes.nCurrentPage gt arrayLen( aID ) and
      arrayLen( aID ) gt 0 )
  {
    attributes.nCurrentPage = arrayLen( aID );
  }

  // caller.docdb.nCurrentPage = attributes.nCurrentPage;
</cfscript>

<!--- [rvl] Do the actual select query --->
<cfquery datasource="#request.db.s_DSN#" name="caller.#attributes.sQueryName#" blockfactor="#attributes.nResultsPerPage#">
  #preserveSingleQuotes( attributes.sSelectQuery )#

  <cfif listLen( aID[attributes.nCurrentPage] ) eq 1>
    AND #attributes.sIDColumn# = <cfqueryparam value="#aID[attributes.nCurrentPage]#" cfsqltype="cf_sql_integer">
  <cfelseif listLen( aID[attributes.nCurrentPage] ) gt 1>
    AND #attributes.sIDColumn# IN ( #listSort( aID[attributes.nCurrentPage], 'numeric' )# )
  </cfif>

  <cfif structKeyExists( attributes, "xOrderByClause" ) and
        isArray( attributes.xOrderByClause ) and
        arrayLen( attributes.xOrderByClause )>
    ORDER BY
    <cfloop from="1" to="#arrayLen( attributes.xOrderByClause )#" index="i">
      #attributes.xOrderByClause[i][1]# #iif( attributes.xOrderByClause[i][2], de( "ASC" ), de( "DESC" ))#
      <cfif i neq arrayLen( attributes.xOrderByClause )>,</cfif>
    </cfloop>
  </cfif>
</cfquery>

<cfscript>
  /*
   * We will now return some 'extra' information about the set of results that
   * we have found here. This can be used by a navigation system to accompany
   * the retrieved data with some information about the query.
   */
  "caller.#attributes.sReturnTotalRecordCount#"   = duplicate( next20.nRecordCount );
  "caller.#attributes.sReturnCurrentRecordCount#" = listLen( aID[attributes.nCurrentPage] );
  "caller.#attributes.sReturnTotalPageCount#"     = arrayLen( aID );
  "caller.#attributes.sReturnExecutionTime#"      = cfquery.executionTime;
</cfscript>

<cfsetting enablecfoutputonly="No">