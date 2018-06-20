$(function() {
  $table = $( '#labels' );

  // edit in cell:
  $( document ).on( "editable-save.bs.table", function( e, lan, newVal ){
    $.ajax( ajaxUrl( "adminapi:translation", "save" ), {
      method : "POST",
      data : {
        "language" : lan,
        "name" : newVal.label,
        "value" : newVal[lan]
      }
    });
  });

  // add new label
  $( document ).on( "click", "#save-translation", function(){
    $.ajax( ajaxUrl( "adminapi:translation", "save" ), {
      method : "POST",
      data : $( "#newlabel" ).serializeObject(),
      success : function( result ){
        $table.bootstrapTable( 'prepend', result.data );
      }
    });
  });

  $( document ).on( "click", "#removeBtn", function(){
    var $modal = $( createModal( 'confirm' ));

    $( 'body' ).append( $modal );

    var modalJSON = JSON.stringify({
      "title" : translate( 'modal-confirm-deletelabel-title' ),
      "body" : translate( 'modal-confirm-deletelabel-body' ),
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
          var ids = $.map( $table.bootstrapTable( 'getSelections' ), function( row ){
            return row.id;
          });
          $.ajax( ajaxUrl( "adminapi:translation", "remove" ), {
            method : "POST",
            data : { "labels" : ids },
            traditional : true,
            success : function(){
              $table.bootstrapTable( 'remove', {
                field: 'id',
                values: ids
              });
            }
          });

          var $parent = $( this ).parents( '.modal' );
          removeModal( $parent );
        });

        $modal.modal();
      }
    );

    return false;
  });
});