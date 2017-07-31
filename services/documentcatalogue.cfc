component accessors=true {
  property ds;
  property websiteId;
  property utilityService;
  property queryService;
  property fw;

  public array function getModuleContent( required array moduleConfig ) {
    switch ( moduleConfig[ 1 ] ) {
      case "sOutputFormat=asList" :
        return getDocuments( argumentCollection = {
          groupId = moduleConfig[ 2 ],
          whereConfig = moduleConfig[ 3 ]
        } );

      default :
        throw(
          "Module mode is unsupported.",
          "documentcatalogueService.getModuleContent.unsuportedModeError",
          "Currently only 'list of documents' is supported for the Document Manager."
        );
    }
  }

  public any function getDocumentById( required numeric documentId ) {
    var result = getDocuments( documentId = documentId );

    if ( arrayLen( result ) == 1 ) {
      return result[ 1 ];
    }
  }

  public array function getDocumentsByGroupId( required numeric groupId ) {
    return getDocuments( groupId = groupId );
  }

  public array function searchDocuments( required string whereConfig ) {
    return getDocuments( whereConfig = whereConfig );
  }

  public array function getDocuments( numeric documentId, numeric groupId, array whereConfig ) {
    var docdb = { };
    var input = arguments;
    include "/mustang/lib/webmanager/modules/documentcatalogue/docdb_load_documents.cfm";
    return queryService.toArray( qry_select_document );
  }

  public any function getFields( required numeric groupId, string fieldIds default=''){
    fw.frameworkTrace( "<b>documentcatalogue</b>: getFields() called." );

    var whereStatement = "";
    var queryParams = { "groupId" = arguments.groupId };

    if( listLen( arguments.fieldIds ) ){
      whereStatement = "AND tbl_eigenschap.eigenschap_nID IN (:fieldIds)";
      queryParams['fieldIds'] = {
        value = arguments.fieldIds,
        list = true
      };
    }

    var sql = "
      SELECT    tbl_groep.groep_sNaam               form_sName,
                tbl_groep.groep_sText               form_sText,
                tbl_groep.groep_sImage              form_sImage,
                tbl_eigenschap.eigenschap_nID       field_nID,
                tbl_eigenschap.eigenschap_sNaam     field_sName,
                tbl_eigenschap.eigenschap_bRequired field_bRequired,
                tbl_eigenschap.eigenschap_sMessage  field_sMessage,
                lst_formType.type_nID               fieldType_nID,
                lst_formType.type_sNaam             fieldType_sName,
                lst_value.value_nID                 fieldValue_nID,
                lst_value.value_sNaam               fieldValue_sName

      FROM      lst_formType
                INNER JOIN tbl_eigenschap
                INNER JOIN mid_eigenschapGroep ON
                  tbl_eigenschap.eigenschap_nID = mid_eigenschapGroep.eigenschapGroep_x_nEigenschapID
                INNER JOIN tbl_groep ON
                  mid_eigenschapGroep.eigenschapGroep_x_nGroepID = tbl_groep.groep_nID ON
                  lst_formType.type_nID = tbl_eigenschap.eigenschap_x_nTypeID
                LEFT OUTER JOIN lst_value
                INNER JOIN mid_eigenschapValue ON
                  lst_value.value_nID = mid_eigenschapValue.eigenschapValue_x_nValueID ON
                  tbl_eigenschap.eigenschap_nID = mid_eigenschapValue.eigenschapValue_x_nEigenschapID

      WHERE     tbl_groep.groep_nID = :groupId
      #whereStatement#

      ORDER BY  mid_eigenschapGroep.eigenschapGroep_nOrderID,
                mid_eigenschapValue.eigenschapValue_nOrderID
    ";


    var queryResult = queryService.execute( sql, queryParams, { "datasource" = ds } );

    if ( queryResult.recordCount == 0 ) {
      return;
    }

    var fields = queryService.toArray( queryResult );
    return fields;

  }
}
