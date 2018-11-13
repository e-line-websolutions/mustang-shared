<cfsetting enablecfoutputonly="Yes">

<cfscript>
  param attributes.assetmeta_nID =- 1;
  param attributes.nItteration = 1;
  param attributes.nMaxItterations = 10;
  param attributes.bShowChangefreq = false;
  param attributes.bShowPriority = false;
  param attributes.sLimitToLanguage = "";
  param attributes.datasource = "";
  param attributes.useHttps = "";

  sWebsiteURL = 'http#attributes.useHttps?'s':''#://#cgi.SERVER_NAME#';

  param attributes.path = sWebsiteURL;

  if ( !isDefined( 'request.nGlobalRowCounter' ) || attributes.nItteration == 1 ) {
    request.nGlobalRowCounter = 0;
  }
</cfscript>

<!--- [SBH] Select menu items --->
<cfquery datasource="#attributes.datasource#" name="qry_sel_assetmeta" cachedwithin="#createTimespan( 1, 0, 0, 0 )#">
  SELECT    menu_nID              = menu.assetmeta_nID,
            menu_sName            = dbo.variableFormatMstng( menu.assetcontent_sTitleText ),
            article_dLastmodified = ISNULL(
                                      ISNULL(
                                        ISNULL(
                                          MAX( article.assetmeta_dModifiedDateTime ),
                                          MAX( article.assetmeta_dCreationDateTime )),
                                        menu.assetmeta_dModifiedDateTime ),
                                      menu.assetmeta_dCreationDateTime
                                    )

  FROM      tbl_assetMeta AS article
            INNER JOIN mid_assetmetaAssetmeta AS menu_article ON article.assetmeta_nID = menu_article.assetmetaAssetmeta_x_nChildID
            RIGHT OUTER JOIN mid_assetmetaAssetmeta AS menu_parent
            INNER JOIN vw_selectAsset AS menu ON menu_parent.assetmetaAssetmeta_x_nChildID = menu.assetmeta_nID
            LEFT OUTER JOIN vw_subassetCounter ON menu.assetmeta_nID = vw_subassetCounter.assetmetaAssetmeta_x_nParentID ON menu_article.assetmetaAssetmeta_x_nParentID = menu.assetmeta_nID

  WHERE     menu_parent.assetmetaAssetmeta_x_nParentID = <cfqueryparam cfsqltype="cf_sql_integer" value="#attributes.assetmeta_nID#">
            AND menu.assetmeta_x_nTypeID IN ( 2, 4 )
            AND menu.assetmeta_x_nBmID = 14
            AND LEFT( menu.assetcontent_sTitleText, 1 ) <> '_'
            <cfif attributes.nItteration eq 1 and len( trim( attributes.sLimitToLanguage ) )>
              AND menu.assetcontent_sTitleText = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#attributes.sLimitToLanguage#" />
            </cfif>

  GROUP BY  menu.assetmeta_nID,
            dbo.variableFormatMstng( menu.assetcontent_sTitleText ),
            menu.assetmeta_dModifiedDateTime,
            menu.assetmeta_dCreationDateTime
</cfquery>

<!--- [SBH] Loop query --->
<cfloop query="qry_sel_assetmeta">
  <!--- [SBH] XML Content --->
  <cfscript>
    sLink = '#attributes.path#/#menu_sName#/';

    writeOutput( chr( 10 ) & '<url>' );
    writeOutput( chr( 10 ) & '  <loc>#xmlFormat( sLink )#</loc>' );
    writeOutput( chr( 10 ) & '  <lastmod>' & dateFormat( article_dLastmodified, 'YYYY-MM-DD' ) & '</lastmod>' );

    if ( attributes.bShowChangefreq ) {
      writeOutput( chr( 10 ) & '  <changefreq>weekly</changefreq>' );
    }

    if ( attributes.bShowPriority ) {
      writeOutput( chr( 10 ) & '  <priority>0.5</priority>' );
    }

    writeOutput( chr( 10 ) & '</url>' );

    request.nGlobalRowCounter = request.nGlobalRowCounter + 1;
  </cfscript>

  <cfif attributes.nItteration lte attributes.nMaxItterations>
    <cfmodule template="#getFileFromPath( getCurrentTemplatePath() )#"
      assetmeta_nID = "#menu_nID#"
      nItteration = "#int( attributes.nItteration + 1 )#"
      path = "#attributes.path#/#menu_sName#"
      bShowChangefreq = "#attributes.bShowChangefreq#"
      bShowPriority = "#attributes.bShowPriority#"
      sLimitToLanguage = "#attributes.sLimitToLanguage#"
      datasource = "#attributes.datasource#"
      useHttps = "#attributes.useHttps#">
  </cfif>
</cfloop>

<cfsetting enablecfoutputonly="No">