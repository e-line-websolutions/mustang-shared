component extends="root.orm.beans.option"
          persistent=true
          table="option"
          discriminatorValue="country" {
  property name="iso2" type="string" length=2;
  property name="iso3" type="string" length=3;
  property name="locales" singularName="locale" fieldType="one-to-many" inverse=true cfc="root.orm.beans.locale" FKColumn="countryid";
}