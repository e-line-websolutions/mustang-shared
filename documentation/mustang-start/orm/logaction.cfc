component extends="root.orm.beans.option"
          persistent=true
          table="option"
          discriminatorValue="logaction" {
  property name="cssclass" length=32 inlist=true inform=true editable=true;
  property name="logentries" singularName="logentry" fieldType="one-to-many" inverse=true cfc="root.orm.beans.logentry" fkColumn="logactionid";

  property name="name" persistent=false inlist=true inform=true editable=true;
}