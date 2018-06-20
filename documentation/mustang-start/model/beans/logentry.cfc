component extends="basecfc.base" persistent=true table="log"  defaultSort="dd DESC" classColumn="logaction" {
  property name="name" type="string" length=128;
  property name="deleted" type="boolean" ORMType="boolean" default=false inapi=false;
  property name="sortorder" type="numeric" ORMType="integer" default=0;

  property name="relatedEntity" fieldType="many-to-one" cfc="root.model.beans.logged" FKColumn="entityid" inform=true orderinform=1 inlist=true link=true;
  property name="logaction" fieldType="many-to-one" cfc="root.model.beans.logaction" FKColumn="logactionid" inform=true orderinform=2 inlist=true;
  property name="savedState" length=4000 dataType="json" inform=true orderinform=5;
  property name="by" fieldType="many-to-one" FKColumn="contactid" cfc="root.model.beans.contact";
  property name="dd" ORMType="timestamp" inlist=true;
  property name="ip" length=15;

  property name="note" length=1024 inform=true orderinform=6 editable=true required=true inlist=true;
  property name="attachment" length=128 inform=true orderinform=7 editable=true formfield="file";

  public string function getName( ) {
    if ( !isNull( variables.relatedEntity ) ) {
      return variables.relatedEntity.getName( ) & " log";
    }

    return "not linked to entity";
  }

  public any function enterIntoLog( string action = "init", struct newState = { }, component entityToLog ) {
    if ( isNull( entityToLog ) && !isNull( variables.relatedEntity ) ) {
      entityToLog = variables.relatedEntity;
    }

    if ( isNull( entityToLog ) ) {
      return this;
    }

    writeLog( text = "Logging entry for #entityToLog.getId( )#", file = request.appName );

    var formData = {
      "dd" = now( ),
      "ip" = cgi.remote_addr,
      "relatedEntity" = entityToLog.getId( )
    };

    if ( isDefined( "request.context.auth.userID" ) ) {
      var contact = entityLoadByPK( "contact", request.context.auth.userID );

      if ( !isNull( contact ) ) {
        formData[ "by" ] = contact;
      }
    }

    if ( len( trim( action ) ) ) {
      var logaction = entityLoad( "logaction", { name = action }, true );

      if ( isNull( logaction ) ) {
        var logaction = entityLoad( "logaction", { name = "init" }, true );
      }

      if ( !isNull( logaction ) ) {
        formData[ "logaction" ] = logaction;
      }
    }

    if ( structIsEmpty( newState ) ) {
      newState = { "init" = true, "name" = entityToLog.getName( ) };
    }

    formData[ "savedState" ] = left( serializeJson( deORM( newState ) ), 4000 );

    transaction {
      var result = save( formData );
    }

    var e = result.getRelatedEntity( );

    if ( !isNull( e ) ) {
      writeLog( text = "Entry logged for #e.getId( )#", file = request.appName );
    }

    return result;
  }
}