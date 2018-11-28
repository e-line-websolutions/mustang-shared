component extends="root.model.beans.logged"
          persistent=true
          joinColumn="id"
          defaultSort="lastname,email" {
  property name="username" length="64" inform=true orderinform=1 editable=true;
  property name="password" length="60" type="string";
  property name="firstname" length="32" inform=true orderinform=2 editable=true;
  property name="infix" length="16" inform=true orderinform=3 editable=true;
  property name="lastname" length="64" inform=true orderinform=4 editable=true;
  property name="email" length="128" inform=true orderinform=5 editable=true inlist=true orderinlist=2;
  property name="lastLoginDate" ORMType="timestamp" inlist=true;
  property name="phone" length="16" inform=true orderinform=6 editable=1;
  property name="photo" length="128";
  property name="securityrole" fieldtype="many-to-one" cfc="root.model.beans.securityrole" fkcolumn="securityroleid" inform=true editable=true inlist=true;
  property name="createdObjects" singularname="createdObject" fieldtype="one-to-many" inverse=true cfc="root.model.beans.logged" fkcolumn="createcontactid";
  property name="updatedObjects" singularname="updatedObject" fieldtype="one-to-many" inverse=true cfc="root.model.beans.logged" fkcolumn="updatecontactid";
  property name="contactLogEntries" singularname="contactLogEntry" fieldtype="one-to-many" inverse=true cfc="root.model.beans.logentry" fkcolumn="contactid" inapi=false;
  property name="receiveStatusUpdate" type="boolean" default=0 inlist=true;
  property name="name" persistent="false" inlist=true orderinlist=1;

  public string function getFullname( ) {
    param variables.firstname="";
    param variables.infix="";
    param variables.lastname="";
    param variables.username="";

    var result = variables.firstname & ' ' & trim( variables.infix & ' ' & variables.lastname );

    if ( !len( trim( result ) ) ) {
      result = variables.username;
    }

    return result;
  }

  public string function getName( ) {
    return getFullname( );
  }
}