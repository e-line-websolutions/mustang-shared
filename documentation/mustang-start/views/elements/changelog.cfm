<cfparam name="local.notesInline" default="false" />
<cfparam name="local.linkToEntity" default="true" />
<cfparam name="local.activity" default="#[]#" />

<cfoutput>
  <ul class="list-group">
    <cfloop array="#local.activity#" index="logEntry">
      <cfscript>
        by = logEntry.getby();
        if ( isNull( by ) ) {
          by = entityNew( "contact" );
        }

        dd = logEntry.getdd();

        logaction = logEntry.getLogaction();
        if ( isNull( logaction ) ) {
          logaction = entityLoad( "logaction", { name = "changed" }, true );
        }

        cssClass = logaction.getCSSClass();
        if ( isNull( cssClass ) ) {
          cssClass = "default";
        }

        loggedEntity = logEntry.getRelatedEntity();
        if ( isNull( loggedEntity ) ) {
          loggedEntityName = "unknown";
          loggedEntityID = "";
        } else {
          loggedEntityName = listLast( getMetaData( loggedEntity ).name, '.' );
          loggedEntityID = loggedEntity.getID();
        }
      </cfscript>

      <li class="list-group-item list-group-item-#cssClass# justify-content-between">
        <div>
          <!--- log entry output: --->
          <cfif not isNull( dd )>
            <span class="text-muted">#i18n.translate( 'on' )#</span> #lsDateFormat( dd, i18n.translate( 'defaults-dateformat-small' ))#
            <span class="text-muted">#lCase( i18n.translate( 'at' ) )#</span> #lsTimeFormat( dd, 'HH:mm:ss' )#,
          </cfif>

          #by.getName()#

          <strong>#lCase( i18n.translate( logaction.getName( ) ) )#</strong>

          #lCase( i18n.translate( loggedEntityName ) )#

          <cfset loggedEntity = logEntry.getRelatedEntity() />
          <cfif not isNull( loggedEntity )>#loggedEntity.getName()#</cfif>

          <!--- notes and attachments: --->
          <cfif local.notesInline>
            <br />
            <cfif len( trim( logentry.getNote()))>
              <strong>#i18n.translate( 'note' )#:</strong> #logentry.getNote()#<br />
            </cfif>
            <cfif len( trim( logentry.getAttachment()))>
              <strong>#i18n.translate( 'attachment' )#:</strong> <a href="#buildURL( 'adminapi:crud.download?filename=' & logentry.getAttachment() )#">#logentry.getAttachment()#</a><br />
            </cfif>
          </cfif>
        </div>

        <!--- log entry actions: --->
        <div>
          <cfif local.linkToEntity and len( trim( loggedEntityID ))>
            <a class="btn btn-xs btn-primary pull-right" style="margin-left:5px;" href="#buildURL( '' & loggedEntityName & '.view?#loggedEntityName#id=#loggedEntityID#' )#">#i18n.translate( 'view-item' )#</a>
          </cfif>
          <a class="btn btn-xs btn-primary pull-right" style="margin-left:5px;" href="#buildURL( 'logentry.view?logentryID=#logEntry.getID()#' )#">#i18n.translate( 'view-logentry' )#</a>
        </div>
      </li>
    </cfloop>
  </ul>
</cfoutput>