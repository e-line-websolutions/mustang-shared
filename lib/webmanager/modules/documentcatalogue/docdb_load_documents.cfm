<cfprocessingdirective pageEncoding="utf-8">

<cfscript>
  docdb.version = 8;
  docdb.ctidentifier = replace( createUUID( ), '-', '', 'all' );
  docdb.timers[ "variablesetup_#docdb.ctidentifier#" ] = getTickCount( );

  param input.documentId=0;
  param input.groupId=0;
  param input.whereConfig=[];
  param input.queryname='qry_select_document';
  param input.search='';
  param input.documentName='';
  param input.qOwnQry='';
  param input.bCountClicks=false;
  param input.bBackwardsCompatible=true;
  param input.bRestrictSearch=false;

  /* [mjh] 11/7/2006 Added for version 2.5.10: search fields: */
  param input.sFreetextSearch='';
  param input.lLimitFields='';
  param input.nOrderBy= - 1;
  param input.nOrderType='VARCHAR';

  // cache
  param input.queryCache=createTimeSpan( 0, 0, 0, 30 );

  docdb.queryCache = input.queryCache;

  // reload
  param input.bRecycle=false; // used by next20

  if( input.bRecycle ) {
    docdb.queryCache = createTimeSpan( 0, 0, 0, 0 );
  }

  if( not structKeyExists( input, "xOrderBy" ) ) {
    input.xOrderByClause = arrayNew( 2 );
    if( input.nOrderBy neq -1 ) {
      input.xOrderByClause[ 1 ][ 1 ] = "savedData_sNaam";
    } else {
      input.xOrderByClause[ 1 ][ 1 ] = "product_sNaam";
    }
    input.xOrderByClause[ 1 ][ 2 ] = 1;
  }

  docdb.xOrderByClause = duplicate( input.xOrderByClause );

  if( not structKeyExists( input, "nBwsID" ) ) {
    if( isDefined( "variables.websiteId" ) ) {
      input.nBwsID = variables.websiteId;
    } else {
      input.nBwsID = 0;
    }
  } else if( not val( input.nBwsID ) ) {
    input.nBwsID = 0;
  }

  request.bSearchNarrowed = false;
  docdb.bDontDisplay = true;
  docdb.sOrderByColumn = "name";
  docdb.timers[ "variablesetup_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "variablesetup_#docdb.ctidentifier#" ];
  docdb.timers[ "customselect_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<cfif len( trim( input.sFreetextSearch ) ) gt 0>
  <!--- ~~ FREE TEXT SEARCH                                                ~~ --->
  <cfquery datasource="#ds#" name="docdb.qry_select_product_nID_IN" blockfactor="100" result="freetext_qry" cachedWithin="#docdb.queryCache#">
    DECLARE @searchword NVARCHAR( 32 )
    DECLARE @bwsid      INT

    SET     @searchword = <cfqueryparam cfsqltype="cf_sql_varchar" value="%#left( input.sFreetextSearch, 30 )#%" maxlength="32" />
    SET     @bwsid = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.nBwsID#" />

      <!--- Query to search the values table (for select, checkbox, radio, etc. values) --->
      SELECT    tbl_product.product_nID

      FROM      tbl_product
                INNER JOIN tbl_savedData ON tbl_product.product_nID = tbl_savedData.savedData_x_nProductID
                INNER JOIN lst_value ON tbl_savedData.savedData_x_nValueID = lst_value.value_nID

                <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
                  LEFT OUTER JOIN mid_groepProduct ON tbl_product.product_nID = mid_groepProduct.groepProduct_x_nProductID
                </cfif>

      WHERE     tbl_product.product_nBwsID = @bwsid
        AND     lst_value.value_sNaam LIKE @searchword

      <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
        <cfif listLen( input.groupId ) gt 1>
          <cfif input.bRestrictSearch>
            <cfloop list="#input.groupId#" index="nListItem">
              AND (
                Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
                OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
              )
            </cfloop>
          <cfelse>
              AND (
                Mid_GroepProduct.GroepProduct_x_nGroepID  IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
                OR Tbl_Product.Product_x_nGroepID         IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
              )
          </cfif>
        <cfelse>
          AND (
            Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
            OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
          )
        </cfif>
      </cfif>

    UNION

      SELECT    tbl_product.product_nID

      FROM      tbl_product

                INNER JOIN tbl_savedData ON tbl_product.product_nID = tbl_savedData.savedData_x_nProductID

                <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
                  LEFT OUTER JOIN mid_groepProduct ON tbl_product.product_nID = mid_groepProduct.groepProduct_x_nProductID
                </cfif>

      WHERE     tbl_product.product_nBwsID = @bwsid
        AND     (
                  tbl_savedData.savedData_sText LIKE CAST( @searchword AS nText ) OR
                  tbl_savedData.savedData_sNaam LIKE @searchword OR
                  tbl_product.product_sNaam     LIKE @searchword
                )

      <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
        <cfif listLen( input.groupId ) gt 1>
          <cfif input.bRestrictSearch>
            <cfloop list="#input.groupId#" index="nListItem">
              AND (
                Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
                OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
              )
            </cfloop>
          <cfelse>
              AND (
                Mid_GroepProduct.GroepProduct_x_nGroepID  IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
                OR Tbl_Product.Product_x_nGroepID         IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
              )
          </cfif>
        <cfelse>
          AND (
            Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
            OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
          )
        </cfif>
      </cfif>
  </cfquery>

  <cfif docdb.qry_select_product_nID_IN.recordCount eq 0 and
        structKeyExists( input, "groupId" ) and
        val( input.groupId ) gt 0>
    <cfquery datasource="#ds#" name="docdb.qry_select_product_nID_NOTIN" blockfactor="100" result="docdb.r0" cachedWithin="#docdb.queryCache#">
      SELECT    DISTINCT
                tbl_product.product_nID

      FROM      tbl_product
                LEFT OUTER JOIN mid_groepProduct ON tbl_product.product_nID = mid_groepProduct.groepProduct_x_nProductID

      WHERE     tbl_product.product_nBwsID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.nBwsID#" />

      <cfif listLen( input.groupId ) gt 1>
        <cfif input.bRestrictSearch>
          <cfloop list="#input.groupId#" index="nListItem">
            AND (
              Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
              OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#nListItem#">
            )
          </cfloop>
        <cfelse>
            AND (
              Mid_GroepProduct.GroepProduct_x_nGroepID  IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
              OR Tbl_Product.Product_x_nGroepID         IN ( <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#input.groupId#" list="Yes"> )
            )
        </cfif>
      <cfelse>
        AND (
          Mid_GroepProduct.GroepProduct_x_nGroepID  = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
          OR Tbl_Product.Product_x_nGroepID         = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( input.groupId )#">
        )
      </cfif>
    </cfquery>
  <cfelse>
    <cfset docdb.qry_select_product_nID_NOTIN = queryNew( "Product_nID" )>
  </cfif>
<cfelseif arrayLen( input.whereConfig )>
  <cfscript>
    docdb.whereclause = [ ];

    for( local.sCurrentListItem in input.whereConfig ) {
      if( listLen( local.sCurrentListItem, "_" ) == 3 ) {
        docdb.whereclause[ arrayLen( docdb.whereclause ) + 1 ] = {
          field = listGetAt( local.sCurrentListItem, 1, '_' ),
          modifier = listGetAt( local.sCurrentListItem, 2, '_' ),
          value = replace( listGetAt( local.sCurrentListItem, 3, '_' ), '''', '', 'all' ),
          originalvalue = listGetAt( local.sCurrentListItem, 3, '_' ),
          type = 0
        };
      }
    }
  </cfscript>

  <!--- populate the type field in the whereclause --->
  <cfif arrayLen( docdb.whereclause )>
    <cfloop from="1" to="#arrayLen( docdb.whereclause )#" index="docdb.i">
      <cfquery dataSource="#ds#" name="docdb.qEigenschap" cachedWithin="#docdb.queryCache#">
        SELECT eigenschap_x_nTypeID
        FROM tbl_eigenschap
        WHERE eigenschap_nID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].field#" />
      </cfquery>
      <cfset docdb.whereclause[ docdb.i ].type = docdb.qEigenschap.eigenschap_x_nTypeID />
    </cfloop>
  </cfif>

  <!--- ~~ FIND SELECTION SECTION ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cfquery datasource="#ds#" name="docdb.qry_select_product_nID_NOTIN" blockfactor="100" result="docdb.r1" cachedWithin="#docdb.queryCache#">
    SELECT    DISTINCT
              tbl_product.product_nID

    FROM      tbl_product

              <cfloop from="1" to="#arrayLen( docdb.whereclause )#" index="docdb.i">
                <cfif docdb.whereclause[ docdb.i ].modifier eq 'neq'>
                  INNER JOIN tbl_savedData tbl_savedData#docdb.i# ON tbl_product.product_nID = tbl_savedData#docdb.i#.savedData_x_nProductID
                </cfif>
              </cfloop>

    WHERE     tbl_product.product_nBwsID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.nBwsID#" />

              <cfloop from="1" to="#arrayLen( docdb.whereclause )#" index="docdb.i">
                <cfif docdb.whereclause[ docdb.i ].modifier eq 'neq'>
                  <cfset docdb.bDontDisplay = false />
                  AND tbl_savedData#docdb.i#.savedData_x_nEigenschapID  = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].field#" />
                  <!--- AND tbl_savedData#docdb.i#.savedData_x_nValueID       = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[docdb.i].value#" /> --->

                  <cfif listFind( "1,2,3,7", docdb.whereclause[ docdb.i ].type )>
                    AND tbl_savedData#docdb.i#.savedData_x_nValueID
                  <cfelseif listFind( "12", docdb.whereclause[ docdb.i ].type )>
                    AND tbl_savedData#docdb.i#.savedData_x_nLinkedProductID
                  <cfelse>
                    <cfif isNumeric( docdb.whereclause[ docdb.i ].value ) and not find( '.', docdb.whereclause[ docdb.i ].value )>
                      <cfif input.nOrderType eq 'FLOAT'>
                        AND ISNUMERIC( tbl_savedData#docdb.i#.savedData_sNaam ) = 1
                      </cfif>

                      AND PATINDEX( '%[^0-9.]%', LTRIM( RTRIM( tbl_savedData1.savedData_sNaam ))) = 0
                      AND CAST( ISNULL( REPLACE( tbl_savedData#docdb.i#.savedData_sNaam, ',', '.' ), 0 ) AS #listFirst( input.nOrderType, "';+" )# )
                    <cfelse>
                      <cfif isNumeric( docdb.whereclause[ docdb.i ].value )>
                        AND CAST( ISNULL( REPLACE( tbl_savedData#docdb.i#.savedData_sNaam, ',', '.' ), 0 ) AS FLOAT )
                      <cfelse>
                        AND tbl_savedData#docdb.i#.savedData_sNaam
                      </cfif>
                    </cfif>
                  </cfif>

                  =

                  <cfif listFind( "1,2,3,7", docdb.whereclause[ docdb.i ].type )>
                    <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].value#" />
                  <cfelse>
                    <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#docdb.whereclause[ docdb.i ].value#" />
                  </cfif>
                </cfif>
              </cfloop>

              <cfif docdb.bDontDisplay>
                AND 0 = 1
                <cfset docdb.bDontDisplay = true />
              </cfif>
  </cfquery>

  <cfquery datasource="#ds#" name="docdb.qry_select_product_nID_IN" blockfactor="100" result="docdb.r2" cachedWithin="#docdb.queryCache#">
    SELECT    DISTINCT
              tbl_product.product_nID

    FROM      tbl_product

              <cfloop from="1" to="#arrayLen( docdb.whereclause )#" index="docdb.i">
                <cfif docdb.whereclause[ docdb.i ].modifier neq 'neq'>
                  INNER JOIN tbl_savedData tbl_savedData#docdb.i# ON tbl_product.product_nID = tbl_savedData#docdb.i#.savedData_x_nProductID
                </cfif>
              </cfloop>

    WHERE     tbl_product.product_nBwsID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.nBwsID#" />

              <cfloop from="1" to="#arrayLen( docdb.whereclause )#" index="docdb.i">
                <cfif docdb.whereclause[ docdb.i ].modifier neq 'neq'>
                  <cfset request.bSearchNarrowed = true />
                  AND tbl_savedData#docdb.i#.savedData_x_nEigenschapID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].field#" />

                  <cfif listFind( "1,2,3,7", docdb.whereclause[ docdb.i ].type )>
                    AND tbl_savedData#docdb.i#.savedData_x_nValueID
                  <cfelseif listFind( "12", docdb.whereclause[ docdb.i ].type )>
                    AND tbl_savedData#docdb.i#.savedData_x_nLinkedProductID
                  <cfelseif listFind( "14", docdb.whereclause[ docdb.i ].type )>
                    AND tbl_savedData#docdb.i#.savedData_dDateTime
                  <cfelse>
                    <cfif isNumeric( docdb.whereclause[ docdb.i ].value ) and not find( '.', docdb.whereclause[ docdb.i ].value )>
                      <cfif input.nOrderType eq 'FLOAT'>
                        AND ISNUMERIC( tbl_savedData#docdb.i#.savedData_sNaam ) = 1
                      </cfif>

                      AND PATINDEX( '%[^0-9.]%', LTRIM( RTRIM( tbl_savedData#docdb.i#.savedData_sNaam ))) = 0
                      AND CAST( ISNULL( REPLACE( tbl_savedData#docdb.i#.savedData_sNaam, ',', '.' ), 0 ) AS #listFirst( input.nOrderType, "';+" )# )
                    <cfelse>
                      <cfif isNumeric( docdb.whereclause[ docdb.i ].value )>
                        AND CAST( ISNULL( REPLACE( tbl_savedData#docdb.i#.savedData_sNaam, ',', '.' ), 0 ) AS FLOAT )
                      <cfelse>
                        AND tbl_savedData#docdb.i#.savedData_sNaam
                      </cfif>
                    </cfif>
                  </cfif>

                  <cfswitch expression="#docdb.whereclause[ docdb.i ].modifier#">
                    <cfcase value="eq">   =  </cfcase>
                    <cfcase value="lte">  <=  </cfcase>
                    <cfcase value="gte">  >=  </cfcase>
                    <cfcase value="lt">  <   </cfcase>
                    <cfcase value="gt">  >   </cfcase>
                    <cfcase value="in">  IN   </cfcase>
                  </cfswitch>

                  <cfif docdb.whereclause[ docdb.i ].modifier eq "in">
                    ( <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].value#" list="true" /> )
                  <cfelseif listFind( "1,2,3,7", docdb.whereclause[ docdb.i ].type )>
                    <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.whereclause[ docdb.i ].value#" />
                  <cfelseif listFind( "14", docdb.whereclause[ docdb.i ].type )>
                    <cfqueryparam CFSQLType="CF_SQL_TIMESTAMP" value="#docdb.whereclause[ docdb.i ].originalvalue#" />
                  <cfelse>
                    <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#docdb.whereclause[ docdb.i ].value#" />
                  </cfif>
                </cfif>
              </cfloop>
  </cfquery>
</cfif>

<cfscript>
  docdb.timers[ "customselect_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "customselect_#docdb.ctidentifier#" ];
  docdb.timers[ "next20select_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<!--- [mjh] Next 20 stuff: --->
<cfsavecontent variable="docdb.s_selectQuery"><cfoutput>
  FROM      mid_groepProduct

            RIGHT OUTER JOIN tbl_product ON  mid_groepProduct.groepProduct_x_nProductID = tbl_product.product_nID

            <cfif input.nOrderBy neq -1>
              INNER JOIN  tbl_savedData ON  tbl_savedData.savedData_x_nProductID = tbl_product.product_nID
            </cfif>

  WHERE     tbl_product.product_nBwsID = #val( trim( listFirst( input.nBwsID, "';+--" ) ) )#

            <cfif input.nOrderBy neq -1>
              AND tbl_savedData.savedData_x_nEigenschapID = #listFirst( input.nOrderBy, "';+" )#
            </cfif>

            <!--- [mjh] based on the queries above select these productid's --->
            <cfif arrayLen( input.whereConfig ) or
                len( trim( input.sFreetextSearch ) )>
              <cfif isQuery( docdb.qry_select_product_nID_IN ) and docdb.qry_select_product_nID_IN.recordcount gt 0>
                <cfset docdb.bDontDisplay = false>
                AND tbl_product.product_nID IN ( #valueList( docdb.qry_select_product_nID_IN.product_nID )# )
              <cfelseif isQuery( docdb.qry_select_product_nID_IN ) and
                        docdb.qry_select_product_nID_IN.recordcount eq 0 and
                        request.bSearchNarrowed>
                <cfset docdb.bDontDisplay = false>
                AND tbl_product.product_nID = -1
              </cfif>
              <cfif isQuery( docdb.qry_select_product_nID_NOTIN ) and docdb.qry_select_product_nID_NOTIN.recordcount gt 0>
                <cfset docdb.bDontDisplay = false>
                AND tbl_product.product_nID NOT IN ( #valueList( docdb.qry_select_product_nID_NOTIN.product_nID )# )
              </cfif>
            </cfif>

            <!--- [mjh] select the right products based on a productid, if one is provided --->
            <cfif len( trim( input.documentId ) )>
              <cfif listLen( input.documentId ) gt 1>
                <cfset docdb.bDontDisplay = false>
                AND tbl_product.product_nID IN ( #listFirst( input.documentId, "';+" )# )
              <cfelseif val( input.documentId )>
                <cfset docdb.bDontDisplay = false>
                AND tbl_product.product_nID = #val( listFirst( input.documentId, "';+" ) )#
              </cfif>
            </cfif>

            <!--- [mjh] in case of a text search on the name field: --->
            <cfif isDefined( "input.search" ) and len( trim( input.search ) )>
              <cfset docdb.bDontDisplay = false>
              <cfloop list="#trim( input.search )#" delimiters=" " index="docdb.word">
                AND tbl_product.Product_sNaam like '%#docdb.word#%'
              </cfloop>
            </cfif>

            <!--- [mjh] select by exact match on name field: --->
            <cfif isDefined( "input.documentName" ) and len( trim( input.documentName ) )>
              <cfset docdb.bDontDisplay = false>
              AND tbl_product.Product_sNaam = '#input.documentName#'
            </cfif>

            <!--- [mjh] If a group id has been given, use it to select the products: --->
            <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
              <cfset docdb.bDontDisplay = false>
              <cfif listLen( input.groupId ) gt 1>
                <cfif input.bRestrictSearch>
                  <!--- [mjh] needs to be in all groups --->
                  <cfloop list="#input.groupId#" index="nListItem">
                    AND (
                      Mid_GroepProduct.GroepProduct_x_nGroepID  = #nListItem#
                      OR tbl_product.Product_x_nGroepID         = #nListItem#
                    )
                  </cfloop>
                <cfelse>
                  <!--- [mjh] must be in at least one group: --->
                  AND (
                    Mid_GroepProduct.GroepProduct_x_nGroepID  IN ( #listFirst( input.groupId, "';+" )# )
                    OR tbl_product.Product_x_nGroepID         IN ( #listFirst( input.groupId, "';+" )# )
                  )
                </cfif>
              <cfelse>
                AND (
                  Mid_GroepProduct.GroepProduct_x_nGroepID  = #val( listFirst( input.groupId, "';+" ) )#
                  OR tbl_product.Product_x_nGroepID         = #val( listFirst( input.groupId, "';+" ) )#
                )
              </cfif>
            </cfif>

            <!--- [mjh] if no specification has been given, dont display any products: --->
            <!--- AND listContains( arrayToList( docdb.whereclause.sModifier ), 0 ) --->
            <cfif docdb.bDontDisplay OR
                  (
                    arrayLen( input.whereConfig ) AND
                    isQuery( docdb.qry_select_product_nID_IN ) AND
                    request.bSearchNarrowed AND
                    docdb.qry_select_product_nID_IN.recordcount lte 0
                  )>
              AND 0 = 1
            </cfif>
</cfoutput></cfsavecontent>

<cfscript>
  docdb.next20SelectQuery = "SELECT DISTINCT tbl_product.product_nID, tbl_product.product_sNaam ";

  if( input.nOrderBy neq -1 )
  {
    docdb.xOrderByClause[ 1 ][ 1 ] = "CAST( tbl_savedData.savedData_sNaam AS #input.nOrderType# )";
    docdb.xOrderByClause[ 1 ][ 2 ] = 1;
    docdb.next20SelectQuery &= ", #docdb.xOrderByClause[ 1 ][ 1 ]# ";
  }

  docdb.next20SelectQuery &= docdb.s_selectQuery;

  request.site.s_NOT_SET = "";
  request.site.n_NOT_SET = -1;
  request.db.s_DSN = ds;
</cfscript>

<cfset docdb.timers[ "next20tag_#docdb.ctidentifier#" ] = getTickCount( ) />
  <cfmodule template="/mustang/lib/webmanager/customtags/next20.cfm"
    sIDColumn="product_nID"
    sIndexQuery="#preserveSingleQuotes( docdb.s_selectQuery )#"
    sSelectQuery="#preserveSingleQuotes( docdb.next20SelectQuery )#"
    sQueryName="docdb.get_productIDs"
    nResultsPerPage="10000"
    nCurrentPage="1"
    xOrderByClause="#docdb.xOrderByClause#"

    sReturnTotalRecordCount    = "docdb.nTotalRecordCount"
    sReturnCurrentRecordCount  = "docdb.nCurrentRecordCount"
    sReturnTotalPageCount      = "docdb.nTotalPageCount"
    sReturnExecutionTime       = "docdb.nExecutionTime"
  >
<cfset docdb.timers[ "next20tag_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "next20tag_#docdb.ctidentifier#" ] />

<cfscript>
  input.documentId = "";
  docdb.tmpProductIDList = valueList( docdb.get_productIDs.product_nID );

  for( docdb.i = 1; docdb.i lte listLen( docdb.tmpProductIDList ); docdb.i = docdb.i + 1 )
  {
    docdb.currentProductID = listGetAt( docdb.tmpProductIDList, docdb.i );

    if( not listFind( input.documentId, docdb.currentProductID ) ) {
      input.documentId = listAppend( input.documentId, docdb.currentProductID );
    }
  }

  docdb.timers[ "next20select_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "next20select_#docdb.ctidentifier#" ];
  docdb.timers[ "fields_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>
<!--- [mjh] / Next 20 stuff: --->

<!--- [mjh] 2015-08-26 - removed this slow mofo: UPPER( dbo.variableFormat( LTRIM( RTRIM( tbl_eigenschap.eigenschap_sNaam )))) --->
<cfmodule template="/mustang/lib/webmanager/customtags/fasterIDwrapper.cfm"
          dsn="#ds#"
          IDlist="#input.documentId#"
          fk="tbl_product.product_nID">
  <cfquery dataSource="#ds#" name="docdb.qry_sel_fields" result="docdb.r3" cachedWithin="#docdb.queryCache#">
    SELECT    DISTINCT
              tbl_eigenschap.eigenschap_nID,
              tbl_eigenschap.eigenschap_sNaam,
              '' AS formattedFieldName,
              tbl_eigenschap.eigenschap_x_nTypeID,
              CASE tbl_eigenschap.eigenschap_x_nTypeID
                WHEN 14 THEN 'date'
                ELSE 'varchar'
              END AS datatype,
              mid_eigenschapGroep.eigenschapGroep_nOrderID

    FROM      tbl_eigenschap
              INNER JOIN mid_eigenschapGroep
                ON tbl_eigenschap.eigenschap_nID = mid_eigenschapGroep.eigenschapGroep_x_nEigenschapID
              INNER JOIN tbl_product
                ON mid_eigenschapGroep.eigenschapGroep_x_nGroepID = tbl_product.product_x_nGroepID
              <cfif len( trim( input.documentId ) )>
                INNER JOIN ##tmpID tempTable
                  ON tbl_product.product_nID = tempTable.idfield
              </cfif>

    WHERE     0 = 0
              <cfif not len( trim( input.documentId ) )>
                AND 0 = 1
              </cfif>

              <!---
              <cfif isDefined( "input.groupId" ) and val( input.groupId ) gt 0>
                AND tbl_product.product_x_nGroepID
                <cfif listLen( input.groupId ) eq 1>
                  = <cfqueryparam value="#input.groupId#" CFSQLType="cf_sql_integer" />
                <cfelse>
                  IN ( <cfqueryparam value="#input.groupId#" CFSQLType="cf_sql_integer" list="true" /> )
                </cfif>
              </cfif>
              --->

    ORDER BY  mid_eigenschapGroep.eigenschapGroep_nOrderID,
              tbl_eigenschap.eigenschap_sNaam
  </cfquery>
</cfmodule>

<cfscript>
  docdb.fields = { };
  docdb.defaultColumns = {
    fields = "ID,NAME,NAAM,ORDERNUM,GROEP,GROEPEN,CREATIONDATE",
    datatypes = "integer,varchar,varchar,integer,integer,varchar,date"
  };
  docdb.documentQuery = queryNew( docdb.defaultColumns.fields, docdb.defaultColumns.datatypes );
  docdb.fieldNamesInOrder = docdb.defaultColumns.fields;

  for( docdb.currentRow = 1; docdb.currentRow <= docdb.qry_sel_fields.recordCount; docdb.currentRow++ ) {
    docdb.eigenschap_nID = docdb.qry_sel_fields.eigenschap_nID[ docdb.currentRow ];
    docdb.formattedFieldName = uCase( variables.utilityService.variableFormat( docdb.qry_sel_fields.eigenschap_sNaam[ docdb.currentRow ] ) );

    querySetCell( docdb.qry_sel_fields, "formattedFieldName", docdb.formattedFieldName, docdb.currentRow );

    if( !structKeyExists( docdb.fields, docdb.eigenschap_nID ) ) {
      docdb.fields[ docdb.eigenschap_nID ] = docdb.formattedFieldName;

      if( !listFindNoCase( docdb.defaultColumns.fields, docdb.fields[ docdb.eigenschap_nID ] ) ) {
        queryAddColumn( docdb.documentQuery, docdb.fields[ docdb.eigenschap_nID ], docdb.qry_sel_fields.datatype[ docdb.currentRow ], [ ] );
        docdb.fieldNamesInOrder = listAppend( docdb.fieldNamesInOrder, docdb.fields[ docdb.eigenschap_nID ] );
      }
    }
  }

  docdb.timers[ "fields_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "fields_#docdb.ctidentifier#" ];
  docdb.timers[ "data_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<cfquery dataSource="#ds#" name="docdb.qry_sel_data" result="docdb.r4" cachedWithin="#docdb.queryCache#">
  SELECT    DISTINCT
            tbl_product.product_nID,
            tbl_savedData.savedData_x_nValueID,
            value = CASE WHEN ISNULL(tbl_savedData.savedData_x_nLinkedProductID, 0) > 0 THEN LTRIM(RTRIM(CAST(tbl_savedData.savedData_x_nLinkedProductID AS VARCHAR(128)))) WHEN NOT tbl_savedData.savedData_dDateTime IS NULL THEN LTRIM(RTRIM(CAST(tbl_savedData.savedData_dDateTime AS VARCHAR(128)))) WHEN NOT tbl_savedData.savedData_sNaam IS NULL THEN LTRIM(RTRIM(CAST(tbl_savedData.savedData_sNaam AS NVARCHAR(256)))) WHEN NOT tbl_savedData.savedData_sText IS NULL THEN LTRIM(RTRIM(CAST(tbl_savedData.savedData_sText AS NVARCHAR(3900)))) WHEN NOT lst_value.value_sNaam IS NULL THEN LTRIM(RTRIM(CAST(lst_value.value_sNaam AS NVARCHAR(256)))) ELSE NULL END,
            tbl_savedData.savedData_x_nEigenschapID

  FROM      lst_value
            RIGHT OUTER JOIN tbl_product
            LEFT OUTER JOIN tbl_savedData ON tbl_product.product_nID = tbl_savedData.savedData_x_nProductID ON lst_value.value_nID = tbl_savedData.savedData_x_nValueID
            LEFT OUTER JOIN tbl_product tbl_linkedProduct ON tbl_savedData.savedData_x_nLinkedProductID = tbl_linkedProduct.product_nID

  <cfif not len( trim( input.documentId ) )>
    WHERE 0 = 1
  <cfelse>
    WHERE tbl_product.product_nID IN ( <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.documentId#" list="true" /> )
  </cfif>

  ORDER BY  tbl_product.product_nID,
            tbl_savedData.savedData_x_nEigenschapID
</cfquery>

<cfset docdb.xDataStruct = { } />
<cfoutput query="docdb.qry_sel_data" group="product_nID">
  <cfset docdb.xDataStruct[ product_nID ] = { } />

  <cfoutput group="savedData_x_nEigenschapID">
    <cfset docdb.xDataStruct[ product_nID ][ savedData_x_nEigenschapID ] = [ ] />
    <cfoutput>
      <cfset arrayAppend( docdb.xDataStruct[ product_nID ][ savedData_x_nEigenschapID ], value ) />
    </cfoutput>
  </cfoutput>
</cfoutput>

<cfscript>
  docdb.timers[ "data_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "data_#docdb.ctidentifier#" ];
  docdb.timers[ "products_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<cfquery dataSource="#ds#" name="docdb.qry_sel_products" result="docdb.r5" cachedWithin="#docdb.queryCache#">
  SELECT    DISTINCT
            tbl_product.product_nID,
            tbl_product.product_sNaam,
            ISNULL( tbl_subgroepen.groepProduct_nOrderID, 0 ) AS ordernum,
            tbl_product.product_x_nGroepID,
            tbl_product.product_dCreated,
            tbl_subgroepen.groepProduct_x_nGroepID

  FROM      mid_groepProduct tbl_subgroepen
            INNER JOIN mid_groepProduct ON tbl_subgroepen.groepProduct_x_nProductID = mid_groepProduct.groepProduct_x_nProductID
            RIGHT OUTER JOIN tbl_product ON mid_groepProduct.groepProduct_x_nProductID = tbl_product.product_nID

  <cfif not len( trim( input.documentId ) )>
    WHERE 0 = 1
  <cfelse>
    WHERE tbl_product.product_nID IN ( <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.documentId#" list="true" /> )
    <cfif structKeyExists( input, "groupId" ) and
          len( trim( input.groupId ) ) neq 0 and
          input.groupId neq 0>
      AND (
        tbl_product.product_x_nGroepID IN ( <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.groupId#" list="Yes" /> )
        OR
        tbl_subgroepen.groepProduct_x_nGroepID IN ( <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.groupId#" list="Yes" /> )
      )
    </cfif>
  </cfif>

  ORDER BY  tbl_product.product_nID
</cfquery>

<cfscript>
  docdb.timers[ "products_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "products_#docdb.ctidentifier#" ];
  docdb.timers[ "finalize_#docdb.ctidentifier#" ] = getTickCount( );
  docdb.documentQueryRow = 0;
</cfscript>

<cfoutput query="docdb.qry_sel_products" group="product_nID">
  <cfscript>
    docdb.documentQueryRow++;

    queryAddRow( docdb.documentQuery, 1 );

    querySetCell( docdb.documentQuery, "ID", product_nID, docdb.documentQueryRow );
    querySetCell( docdb.documentQuery, "NAME", product_sNaam, docdb.documentQueryRow );
    querySetCell( docdb.documentQuery, "NAAM", product_sNaam, docdb.documentQueryRow );
    querySetCell( docdb.documentQuery, "ORDERNUM", ordernum, docdb.documentQueryRow );
    querySetCell( docdb.documentQuery, "GROEP", product_x_nGroepID, docdb.documentQueryRow );
    querySetCell( docdb.documentQuery, "CREATIONDATE", product_dCreated, docdb.documentQueryRow );

    if( structKeyExists( docdb.xDataStruct, product_nID ) ) {
      for( docdb.key in docdb.xDataStruct[ product_nID ] ) {
        if( structKeyExists( docdb.fields, docdb.key ) ) {
          docdb.fieldname = docdb.fields[ docdb.key ];
          querySetCell(
            docdb.documentQuery,
            docdb.fieldname,
            arrayToList( docdb.xDataStruct[ product_nID ][ docdb.key ], chr( 0182 ) ),
            docdb.documentQueryRow
          );
        }
      }
    }

    docdb.lSubGroupIDs = [ product_x_nGroepID ];
  </cfscript>

  <cfoutput>
    <cfscript>
      if( !arrayFind( docdb.lSubGroupIDs, groepProduct_x_nGroepID ) ) {
        arrayAppend( docdb.lSubGroupIDs, groepProduct_x_nGroepID );
      }
    </cfscript>
  </cfoutput>
  <cfset querySetCell(
    docdb.documentQuery,
    "GROEPEN",
    listChangeDelims( listSort( arrayToList( docdb.lSubGroupIDs ), 'numeric' ), chr( 0182 ) ),
    docdb.documentQueryRow
  ) />
</cfoutput>

<cfscript>
  docdb.timers[ "finalize_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "finalize_#docdb.ctidentifier#" ];
  docdb.timers[ "orderdata_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<cftry>
  <cfquery dbtype="query" name="docdb.documentQuery" result="docdb.r6">
    SELECT    *
    FROM      docdb.documentQuery
    ORDER BY  #docdb.sOrderByColumn#
  </cfquery>
  <cfcatch>
    <cfdump var="#cfcatch#">
  </cfcatch>
</cftry>

<cfscript>
  docdb.timers[ "orderdata_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "orderdata_#docdb.ctidentifier#" ];
  docdb.timers[ "log_#docdb.ctidentifier#" ] = getTickCount( );
</cfscript>

<cfif input.bCountClicks and val( input.documentId ) gt 0>
  <cfthread action="run" name="t_docdb_update_clicks" datasource="#ds#" productID="#input.documentId#">
    <cftransaction action="BEGIN" isolation="SERIALIZABLE">
      <cftry>
        <cfquery datasource="#datasource#">
          UPDATE    tbl_product
          SET       product_nClickCount = ISNULL( product_nClickCount, 0 ) + 1
          WHERE     product_nID = <cfqueryparam cfsqltype="CF_SQL_INTEGER" value="#val( productID )#">
        </cfquery>
        <cftransaction action="COMMIT" />
        <cfcatch type="database">
          <cftransaction action="ROLLBACK" />
        </cfcatch>
      </cftry>
    </cftransaction>
  </cfthread>
</cfif>

<cfscript>
  docdb.timers[ "log_#docdb.ctidentifier#" ] = getTickCount( ) - docdb.timers[ "log_#docdb.ctidentifier#" ];
  variables[ input.queryname ] = docdb.documentQuery;
</cfscript>
