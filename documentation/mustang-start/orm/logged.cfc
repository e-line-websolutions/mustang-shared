component extends="basecfc.base"
          persistent=true
          table="metadata"
           {
  property name;
  property type="boolean" name="deleted" default="false";
  property type="numeric" name="sortorder" default=0 ormType="integer";

  property name="createContact" fieldType="many-to-one" FKColumn="createcontactid" cfc="root.orm.beans.contact";
  property name="createDate" ORMType="timestamp";
  property name="createIP"  length=15;

  property name="updateContact" fieldType="many-to-one" FKColumn="updatecontactid" cfc="root.orm.beans.contact";
  property name="updateDate" ORMType="timestamp";
  property name="updateIP" length=15;

  property name="logEntries" singularName="logEntry" fieldType="one-to-many" inverse=true cfc="root.orm.beans.logentry" FKColumn="entityid" inapi=false;
}