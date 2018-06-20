$(function(){
  $( document ).on( "click", "#generate-password", function(){
    $( 'input[name=password]' ).val( xkcd_pw_gen());
  });
});