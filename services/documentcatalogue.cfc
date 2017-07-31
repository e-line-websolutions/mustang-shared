component accessors=true {
  property ds;
  property websiteId;
  property utilityService;
  property queryService;

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

  public array function getDocuments( numeric documentId, numeric groupId, string whereConfig ) {
    var docdb = { };
    var input = arguments;
    include "/mustang/lib/webmanager/modules/documentcatalogue/docdb_load_documents.cfm";
    return queryService.toArray( qry_select_document );
  }
}