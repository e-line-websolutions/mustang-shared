component accessors=true extends="apibase" {
  property framework;
  property utilityService;

  public void function before( required struct rc ) {
    param rc.modalContent={
    };

    utilityService.mergeStructs( defaultModalConfig( ), rc.modalContent );

    if ( structKeyExists( rc, "modalContentAsJSON" ) && len( trim( rc.modalContentAsJSON ) ) && isJSON( rc.modalContentAsJSON ) ) {
      utilityService.mergeStructs( deserializeJSON( rc.modalContentAsJSON ), rc.modalContent );
    }

    if ( structKeyExists( rc, "content" ) ) {
      if ( !isNull( rc.content.getTitle( ) ) ) {
        rc.modalContent.title = rc.content.getTitle( );
      }
      if ( !isNull( rc.content.getBody( ) ) ) {
        rc.modalContent.body = rc.content.getBody( );
      }
    }
  }

  public void function after( required struct rc ) {
    super.after( rc = rc );
    request.layout = true;
  }

  public void function open( required struct rc ) {
  }

  private struct function defaultModalConfig( ) {
    return {
      title = "",
      body = "",
      buttons = [
        {
          title = "close",
          classes = "btn-primary btn-modal-close"
        }
      ]
    };
  }

  public void function progress( required struct rc ) {
    param rc.modalContent.title="Progress";
    rc.modalContent.buttons = [ ];
  }
}