<cfscript>
  param name="local.data" default="#{}#";
  param name="local.choose" default="choose";
  param name="local.options" default="#[]#";
  param name="local.selected" default="";
  param name="local.affectsform" default="false";
  param name="local.translateOptions" default="false";
  param name="local.class" default="";

  local.baseAttributes = "class,name,placeholder,id";
  local.class &= " form-control";

  writeOutput( '<select' );

  for( local.attr in listToArray( local.baseAttributes ))
  {
    if(
        structKeyExists( local, local.attr )
      )
    {
      writeOutput( ' #lCase( local.attr )#="#trim( local[local.attr] )#"' );
    }
  }

  for( local.attr in local.data )
  {
    writeOutput( ' data-#lCase( local.attr )#="#trim( local.data[local.attr] )#"' );
  }

  writeOutput( '>' );

  if( len( trim( local.choose )))
  {
    writeOutput( '<option value="">#i18n.translate( local.choose )#</option>' );
  }

  if( arrayLen( local.options ))
  {
    for( local.option in local.options )
    {
      writeOutput( '<option' );

      writeOutput( ' value="#local.option.getID()#"' );

      if( listFind( local.selected, local.option.getID())){
        writeOutput( ' selected="selected"' );
      };

      writeOutput( ' data-name="#local.option.getName()#"' );

      if( local.affectsform ){
        writeOutput( ' data-fieldlist="#local.option.getFieldList()#"' );
      };

      writeOutput( '>' );

      if( local.translateOptions ){
        writeOutput( i18n.translate( local.option.getName()));
      } else {
        writeOutput( local.option.getName());
      }

      writeOutput( '</option>' );
    }
  }
  else
  {
    if( isObject( local.selected ))
    {
      writeOutput( '<option value="#local.selected.getID()#" selected="selected">#local.selected.getName()#</option>' );
    }
  }

  if( structKeyExists( local, "contents" ) and len( trim( local.contents )))
  {
    writeOutput( local.contents );
  }

  writeOutput( '</select>' );
</cfscript>