var translations = {};
var tagsToReplace = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;'
};

$( function( ) {
  var $doc = $( document );

  // Loading animation button
  Ladda.bind( '.ladda-button' );

  $doc.ajaxStart( function( ) {
    $( '#loading' ).show( );
  } );

  $doc.ajaxStop( function( ) {
    $( '#loading' ).hide( );
  } );

  $.getJSON( ajaxUrl( 'adminapi' + _subsystemDelimiter + 'i18n', 'translations' ), {}, function( response, state, e ) {
    translations = response;
  } );
  // Auto hide certain alerts:
  $( '.alert-dismissable' ).delay( 30000 ).fadeOut( );

  // JSON prettyfier:
  $( '.prettyprint' ).each( function( i, el ) {
    var jsonObj = JSON.parse( $( el ).html( ) );
    $( el ).html( JSON.stringify( jsonObj, null, '  ' ) );
  } );

  $doc.on( "click", "#about-app", function( ) {
    var $modal = $( createModal( '' ) );

    $( 'body' ).append( $modal );

    $( '.modal-content', $modal ).load( ajaxUrl( 'adminapi' + _subsystemDelimiter + 'modal', 'about' ), function( ) {
      $( 'button.btn-modal-close', $modal ).click( function( ) {
        var $parent = $( this ).parents( '.modal' );
        removeModal( $parent );
      } );

      $modal.modal( );
    } );

    return false;
  } );

  $doc.on( "click", ".fileinput-remove", function( ) {
    $( ".fileinput-button", $( this ).closest( ".fileinput" ) ).show( );
    $( "input[type=hidden]", $( this ).closest( ".fileinput" ) ).val( "" );
    $( this ).closest( ".alert" ).html( '' ).hide( );
  } );
} );

function createModal( id, size ) {
  if ( size == undefined ) {
    size = '';
  }

  return '<div class="modal fade" data-id="' + id + '">' + '<div class="modal-dialog ' + size + '">' + '<div class="modal-content">' + '</div>' + '</div>';
};

function removeModal( $modal ) {
  $modal.modal( 'hide' );
  $modal.on( 'hidden.bs.modal', function( ) {
    $( this ).remove( );
  } )
};

function ajaxUrl( action, method, data ) {
  var returnURL = _webroot + "/";

  if ( seoAjax ) {
    if ( action != undefined ) {
      returnURL += action;
    }

    if ( method != undefined ) {
      returnURL += "/" + method;
    }

    if ( data != undefined ) {
      var serializedData = $.param( data );

      if ( serializedData != undefined && serializedData.length ) {
        returnURL += "/?" + serializedData;
      }
    }

    return returnURL;
  } else {
    returnURL += "index.cfm?action=";

    if ( action != undefined ) {
      returnURL += action;
    }

    if ( method != undefined ) {
      returnURL += "." + method;
    }

    if ( data != undefined ) {
      var serializedData = $.param( data );

      if ( serializedData != undefined && serializedData.length ) {
        returnURL += "&" + serializedData;
      }
    }

    return returnURL;
  }
}
