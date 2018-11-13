<cfparam name="input.sLimitToLanguage" default="" />

<cfquery datasource="#ds#" name="qry_select_base_assetmeta" cachedwithin="#createTimespan( 1, 0, 0, 0 )#">
  SELECT    tbl_assetMeta.assetmeta_nID

  FROM      tbl_assetMeta
            INNER JOIN mid_assetmetaAssetmeta ON tbl_assetMeta.assetmeta_nID = mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nChildID

  WHERE     mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nParentID = 0
    AND     tbl_assetMeta.assetmeta_x_nBwsID = <cfqueryparam cfsqltype="cf_sql_integer" value="#variables.websiteId#" />
    AND     tbl_assetMeta.assetmeta_x_nTypeID IN (2, 4)
    AND     tbl_assetMeta.assetmeta_x_nBmID = 14
    AND     tbl_assetMeta.assetmeta_x_nStatusID = 100
</cfquery>

<cfheader statuscode="200" statustext="OK" />
<cfcontent type="text/xml" reset="yes" /><?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="https://www.sitemaps.org/schemas/sitemap/0.9"><cfmodule
  template="/mustang/lib/webmanager/customtags/recursive_sitemapxml.cfm"
  assetmeta_nID="#qry_select_base_assetmeta.assetmeta_nID#"
  sLimitToLanguage="#input.sLimitToLanguage#"
  datasource="#variables.ds#"
  useHttps="#variables.config.useHttps#"></urlset>