component accessors=true {
  property queryService;
  property utilityService;
  property datasource;
  property websiteId;

  variables.safeDelim = chr( 0182 );

  public component function init( ds, websiteId ) {
    variables.datasource = ds;
    variables.websiteId = websiteId;
    variables.queryOptions = { "datasource" = variables.datasource };
    return this;
  }

  public struct function getPageData( required string seoPath ) {
    var result = { };

    result.variableFormat = utilityService.variableFormat;
    result.basePath = "";
    result.navPath = "";
    result.currentBaseMenuItem = "";

    var seoPathArray = listToArray( seoPath, "/" );

    if ( !arrayIsEmpty( seoPathArray ) && listFindNoCase( "uk,fr", seoPathArray[ 1 ] ) ) {
      result.basePath = "/#seoPathArray[ 1 ]#";
    } else {
      arrayPrepend( seoPathArray, "nl" );
    }

    var pathLength = arrayLen( seoPathArray );

    if ( pathLength > 1 ) {
      result.currentBaseMenuItem = seoPathArray[ 2 ];
    }

    for ( var i = 1; i <= pathLength; i++ ) {
      var seoPathArrayAtCurrentLevel = utilityService.arrayTrim( seoPathArray, i );
      var currentMenuId = getMenuIdFromPath( seoPathArrayAtCurrentLevel );

      if ( i == pathLength ) {
        result.articles = getArticles( currentMenuId );
      }

      if ( currentMenuId > 0 ) {
        result[ "navLevel" & i ] = getMenuItems( currentMenuId );

        if ( seoPathArray[ i ] != "nl" && i > 1 && pathLength > 1 && i <= ( min( 2, pathLength ) ) ) {
          result.navPath &= "/" & seoPathArray[ i ];
        }
      }
    }

    result.pageTitle = replace( arrayToList( utilityService.arrayReverse( seoPathArray ), variables.safeDelim ), variables.safeDelim, ' - ', 'all' );

    return result;
  }

  public numeric function getMenuIdFromPath( required any path ) {
    var pathArray = isArray( path ) ? path : listToArray( path, "/" );
    var pathLength = arrayLen( pathArray );

    if ( pathLength == 0 ) {
      return - 1;
    }

    var sql_from = " FROM vw_selectAsset AS nav_level_1 ";
    var sql_where = " WHERE nav_level_1.assetmeta_x_nBwsID = :websiteId AND nav_level_1.assetmeta_x_nTypeID = 2 AND nav_level_1.assetmeta_x_nBmID = 14 AND dbo.variableFormat( nav_level_1.assetcontent_sTitleText ) LIKE :nav_level_1_name ";
    var queryParams = {
      "nav_level_1_name" = replace( pathArray[ 1 ], "-", "_", "all" ),
      "websiteId" = variables.websiteId
    };

    for ( var i = 2; i <= pathLength; i++ ) {
      sql_from &= " INNER JOIN mid_assetmetaAssetmeta AS link_#i-1#_#i# ON nav_level_#i-1#.assetmeta_nID = link_#i-1#_#i#.assetmetaAssetmeta_x_nParentID ";
      sql_from &= " INNER JOIN vw_selectAsset AS nav_level_#i# ON link_#i-1#_#i#.assetmetaAssetmeta_x_nChildID = nav_level_#i#.assetmeta_nID ";
      sql_where &= " AND nav_level_#i#.assetmeta_x_nBwsID = :websiteId AND nav_level_#i#.assetmeta_x_nTypeID = 2 AND nav_level_#i#.assetmeta_x_nBmID = 14 AND dbo.variableFormat( nav_level_#i#.assetcontent_sTitleText ) LIKE :nav_level_#i#_name ";
      queryParams[ "nav_level_#i#_name" ] = replace( pathArray[ i ], "-", "_", "all" );
    }

    var sql_select = " SELECT nav_level_#pathLength#.assetmeta_nID ";

    var sql = sql_select & sql_from & sql_where;

    var pathQuery = queryService.execute( sql, queryParams, queryOptions );

    if ( pathQuery.recordCount == 1 ) {
      return pathQuery.assetmeta_nID[ 1 ];
    }

    return - 1;
  }

  public array function getMenuItems( required numeric parentId ) {
    var sql = "
      SELECT    vw_selectAsset.assetcontent_sTitleText

      FROM      mid_assetmetaAssetmeta
                INNER JOIN vw_selectAsset ON mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nChildID = vw_selectAsset.assetmeta_nID

      WHERE     vw_selectAsset.assetmeta_x_nBwsID = :websiteId
        AND     vw_selectAsset.assetmeta_x_nTypeID = 2
        AND     vw_selectAsset.assetmeta_x_nBmID = 14
        AND     vw_selectAsset.assetmeta_x_nStatusID = 100
        AND     mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nParentID = :parentId

      ORDER BY  vw_selectAsset.assetmeta_nSortKey,
                vw_selectAsset.assetcontent_sTitleText
    ";

    var queryParams = {
      "parentId" = parentId,
      "websiteId" = variables.websiteId
    };

    var navigationQuery = queryService.execute( sql, queryParams, queryOptions );

    return listToArray( valueList( navigationQuery.assetcontent_sTitleText, variables.safeDelim ), variables.safeDelim );
  }

  public array function getArticles( required numeric pageId ) {
    var sql = "
      SELECT    vw_selectAsset.assetmeta_nid                AS [articleId],
                vw_selectAsset.assetmeta_dcreationdatetime  AS [creationDate],
                vw_selectAsset.assetcontent_stitletext      AS [title],
                vw_selectAsset.assetcontent_sintrotext      AS [teaser],
                vw_selectAsset.assetcontent_sbodytext       AS [body]

      FROM      mid_assetmetaAssetmeta
                INNER JOIN vw_selectAsset ON mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nChildID = vw_selectAsset.assetmeta_nID

      WHERE     vw_selectAsset.assetmeta_x_nBwsID = :websiteId
        AND     vw_selectAsset.assetmeta_x_nTypeID = 3
        AND     vw_selectAsset.assetmeta_x_nBmID = 14
        AND     vw_selectAsset.assetmeta_x_nStatusID = 100
        AND     mid_assetmetaAssetmeta.assetmetaAssetmeta_x_nParentID = :pageId

      ORDER BY  vw_selectAsset.assetmeta_nSortKey,
                vw_selectAsset.assetcontent_sTitleText
    ";

    var queryParams = {
      "pageId" = pageId,
      "websiteId" = variables.websiteId
    };

    return queryService.toArray( queryService.execute( sql, queryParams, queryOptions ) );
  }

  public struct function getArticle( required numeric articleId ) {
    return { };
  }
}