// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function translate( label )
{
  if( label in translations )
  {
    return translations[label]
  }
  else
  {
    $.getJSON( ajaxUrl( 'adminapi' + _subsystemDelimiter + 'i18n' , 'translations' ), {}, function( response, state, e ){
      translations = response;
    });
    return '';
  }
}

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function batchTranslate( labels )
  {

}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function convertCelsiusToFahrenheit( c )
{
  if( isNaN( c ) || c.length == 0 )
    return '';

  var f = ( c * 1.8 + 32 ).toFixed( 2 ).replace( '.00', '' );

  return isNaN( f ) ? 0 : f;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function convertFahrenheitToCelsius( f )
{
  if( isNaN( f ) || f.length == 0 )
    return '';

  var c = (( f - 32 ) * ( 5 / 9 )).toFixed( 2 ).replace( '.00', '' );

  return isNaN( c ) ? 0 : c;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Used for submitting forms as JSON data
$.fn.serializeObject = function()
{
   var o = {};
   var a = this.serializeArray();
   $.each(a, function() {
       if (o[this.name]) {
           if (!o[this.name].push) {
               o[this.name] = [o[this.name]];
           }
           o[this.name].push(this.value || '');
       } else {
           o[this.name] = this.value || '';
       }
   });
   return o;
};


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// UUID function
function generateUUID()
{
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace( /[xy]/g, function( c ){ var r = Math.random()*16|0, v = c == 'x' ? r : (r&0x3|0x8); return v.toString(16); });
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function replaceTag(tag) {
  return tagsToReplace[tag] || tag;
}


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function safe_tags_replace(str) {
  return str.replace(/[&<>]/g, replaceTag);
}