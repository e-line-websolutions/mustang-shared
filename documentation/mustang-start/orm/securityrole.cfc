component extends="basecfc.base"
          persistent=true
           {
  property name="name" type="string" length=128 inform=true orderinform=1 editable=true inlist=true;
  property name="deleted" type="boolean" ORMType="boolean" default=false inapi=false;
  property name="sortorder" type="numeric" ORMType="integer" default=0;

  property name="menulist" length=256 inform=true orderinform=2 editable=true;
  property name="loginscript" length=128 inform=true orderinform=3 editable=true inlist=true;

  property name="contacts" fieldtype="one-to-many" inverse=true singularName="contact" cfc="root.orm.beans.contact" FKColumn="securityroleid" cascade="delete-orphan";
  property name="permissions" fieldtype="one-to-many" inverse=true singularName="permission" cfc="root.orm.beans.permission" FKColumn="securityroleid" orderby="section" inform=true orderinform=4 editable=true inlineedit=true;

  property persistent=false name="canAccessAdmin" inlist=true;

  public boolean function getCanAccessAdmin(){
    return isAdmin();
  }

  public boolean function isAdmin(){
    return getName() == "Administrator";
  }

  public boolean function can( string action="", string section="" ){
    if( isAdmin()){
      return true;
    }

    if( !structKeyExists( session, "can" )){
      session["can"] = {};
    }

    if( !( structKeyExists( session.can, "#action#-#section#" ) && isBoolean( session.can["#action#-#section#"] ))){
      session.can["#action#-#section#"] = checkRight( action, section );
    }

    return session.can["#action#-#section#"];
  }

  public boolean function checkRight( string action="", string section="" ){
    var params = {
      "securityrole" = this,
      "section" = arguments.section
    };

    for( local.action in listToArray( arguments.action )){
      params[local.action] = true;
    }

    var findPermission = entityLoad( "permission", params );

    return ( arrayLen( findPermission ) gt 0 );
  }
}