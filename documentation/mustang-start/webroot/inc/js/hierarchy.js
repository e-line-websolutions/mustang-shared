  // TODO: Hierarchy, tree display:
  $( "#hierarchy" ).tree({
    dataSource  : function( options, callback )
                  {
                    var parent = "null";

                    if( "attr" in options )
                    {
                      parent = options.attr["id"];
                    }

                    var afca = $.ajax({
                      url       : ajaxUrl( "adminapi" + _subsystemDelimiter + "hierarchy", "load", {
                                    entity  : _entity,
                                    id      : parent
                                  }),
                      dataType  : "json",
                      success   : function( response )
                                  {
                                    callback( response )

                                    if( parent == "null" )
                                    {
                                      $( "#hierarchy" ).tree( 'discloseVisible' );
                                    }
                                  }
                    });
                  },
    cacheItems: true,
    folderSelect: false
  });

  $( "#hierarchy" ).on( "loaded.fu.tree", function( e, el ){
    // disable remove button:
    $( el ).find( ".tree-branch[haschildren=true]" ).find( ".hierarchy-remove" ).toggleClass( "text-muted" ).prop( "disabled", true );
  });

  $( document ).on( "click", ".hierarchy-add", function(){
    var $this = $( this );
    self.location = $this.closest( ".tree-branch" ).data( "addurl" );
  });

  $( document ).on( "click", ".hierarchy-edit", function(){
    var $this = $( this );
    self.location = $this.closest( ".tree-branch" ).data( "editurl" );
  });

  $( document ).on( "click", ".hierarchy-remove", function(){
    var $this = $( this );
    var $modal = $( createModal( 'confirm' ));

    $( 'body' ).append( $modal );

    var modalJSON = JSON.stringify({
      "title" : translate( 'modal-confirm-title' ),
      "body" : translate( 'modal-confirm-body' ),
      "buttons" : [
        {
          "title" : translate( 'modal-confirm-no' ),
          "classes" : 'btn-default btn-modal-close'
        },
        {
          "title" : translate( 'modal-confirm-yes' ),
          "classes" : 'btn-primary modal-confirm-yes'
        }
      ]
    });

    $( '.modal-content' , $modal ).load(
      ajaxUrl( 'adminapi' + _subsystemDelimiter + 'modal', 'confirm', { "modalContentAsJSON" : modalJSON }),
      function(){
        $( 'button.btn-modal-close' , $modal ).click( function(){
          var $parent = $( this ).parents( '.modal' );
          removeModal( $parent );
        });

        $( 'button.modal-confirm-yes' , $modal ).click( function(){
          // console.log( 'going to... ' + $this.closest( ".tree-branch" ).data( "removeurl" ));
          // self.location = $this.closest( ".tree-branch" ).data( "removeurl" );
        });

        $modal.modal();
      }
    );

    return false;
  });

  $( document ).on( "click", ".expand-all", function(){
    $( "#hierarchy" ).tree( "discloseAll" );
  });

  $( document ).on( "click", ".collapse-all", function(){
    $( "#hierarchy" ).tree( "closeAll" );
  });

  $( document ).on( "click", ".add-toplevel-group", function(){
    self.location = ajaxUrl( "" + _entity, "new", { "parent" : "null" });
  });