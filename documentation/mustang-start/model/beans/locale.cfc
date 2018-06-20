component extends="basecfc.base"
          persistent=true
           {
  property name="name" type="string" length=128 inlist=true;
  property name="deleted" type="boolean" ORMType="boolean" default=false inapi=false;
  property name="sortorder" type="numeric" ORMType="integer" default=0;

  property name="language" fieldType="many-to-one" cfc="root.model.beans.language" FKColumn="languageid" inform=true editable=true;
  property name="country" fieldType="many-to-one" cfc="root.model.beans.country" FKColumn="countryid" inform=true editable=true;
  property name="texts" fieldType="one-to-many" inverse=true cfc="root.model.beans.text" FKColumn="localeid" singularName="text";

  property name="code" persistent=false inlist=true;

  public string function getName(){
    if( isNull( variables.language )){
      var language = new Language();
      language.setName( "English" );
    }

    if( isNull( variables.country )){
      var country = new Country();
      country.setName( "US" );
    }

    return country.getName() & "/" & language.getName();
  }

  public string function getCode( string delimiter="_" ){
    if( isNull( variables.language )){
      var language = new Language();
      language.setISO2( "en" );
    }

    if( isNull( variables.country )){
      var country = new Country();
      country.setISO2( "US" );
    }

    return language.getISO2() & delimiter & country.getISO2();
  }
}