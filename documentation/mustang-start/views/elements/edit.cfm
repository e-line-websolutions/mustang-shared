<cfparam name="local.data" default="#rc.data#" />
<cfparam name="local.entity" default="#rc.entity#" />
<cfparam name="local.columns" default="#rc.columns#" />
<cfparam name="local.editable" default="#rc.editable#" />
<cfparam name="local.hideDelete" default="#rc.hideDelete#" />
<cfparam name="local.formPrepend" default="#rc.formPrepend#" />
<cfparam name="local.formAppend" default="#rc.formAppend#" />
<cfparam name="local.fieldOverride" default="" />
<cfparam name="local.namePrepend" default="#rc.namePrepend#" />
<cfparam name="local.modal" default="#rc.modal#" />
<cfparam name="local.inline" default="#rc.inline#" />
<cfparam name="local.canBeLogged" default="#rc.canBeLogged#" />
<cfparam name="local.tabs" default="#rc.tabs#" />

<cfset instanceVars = local.data.getInstanceVariables( ) />

<cfparam name="instanceVars.settings.useForViews" default="#local.entity#" />

<cfif local.modal>
  <cfsetting showdebugoutput="false" />
</cfif>

<cfif not structKeyExists( local, "#local.entity#id" ) and structKeyExists( rc, "#local.entity#id" )>
  <cfset local[ "#local.entity#id" ] = rc[ "#local.entity#id" ] />
</cfif>

<cfoutput>
  <cfif getItem() eq "view" and rc.auth.role.can( "change", local.entity )>
    <a class="pull-right btn btn-primary" href="#buildURL( '.edit?#local.entity#id=#rc["#local.entity#id"]#' )#">#i18n.translate('edit')#</a>
  </cfif>

  <cfif not local.modal>
    <ul class="nav nav-tabs">
      <li class="nav-item"><a class="nav-link active" href="##form-#local.entity#" data-toggle="tab">#i18n.translate( getItem())#</a></li>
      <cfif structKeyExists( rc, "#local.entity#id" ) and local.canBeLogged>
        <cfset log = entityLoad( "logentry", { "relatedEntity" = local.data }, "dd DESC", { maxresults = 15 }) />
        <cfif isDefined( "log" ) and arrayLen( log )>
          <li class="nav-item"><a class="nav-link" href="##changelog" data-toggle="tab">#i18n.translate('changelog')#</a></li>
        </cfif>
      </cfif>
      <cfloop array="#local.tabs#" index="tab">
        <li class="nav-item"><a class="nav-link" href="##form-#tab#" data-toggle="tab" data-tabid="form-#tab#">#i18n.translate( 'tab-#tab#' )#</a></li>
      </cfloop>
    </ul>
    <div class="tab-content">
      <div class="whitespace"></div>
  </cfif>

      <div class="tab-pane active" id="form-#local.entity#">
        <div class="container-fluid">
          <div class="clearfix" style="margin-bottom: 15px">
            <small class="text-muted font-weight-bold text-xs-right pull-right">#i18n.translate( local.entity )#</small>
            <cfset numberOfSubclasses = arrayLen( rc.subclasses ) />
            <cfif local.editable and numberOfSubclasses gt 1>
              <div class="dropdown mainSubclassSelector">
                <button class="btn btn-secondary btn-sm dropdown-toggle" type="button" data-toggle="dropdown"
                  aria-haspopup="true"
                  aria-expanded="false">#i18n.translate( 'subclass' )#</button>
                <div class="dropdown-menu">
                  <cfloop from="2" to="#numberOfSubclasses#" index="i">
                    <cfset subclass = rc.subclasses[ i ] />
                    <cfset params = { } />
                    <cfif structKeyExists( local, "#local.entity#id" )>
                      <cfset params[ "#local.entity#id" ] = local[ "#local.entity#id" ] />
                    </cfif>
                    <a class="dropdown-item" href="#buildUrl( action = '#subclass#.#getItem( )#', queryString = params )#">#i18n.translate( subclass )#</a>
                  </cfloop>
                </div>
              </div>
            </cfif>
          </div>

          <cfif not local.inline>
            <form
              <cfif local.modal>
                action="javascript:void(0);"
              <cfelse>
                id="mainform" action="#buildURL('.save')#" method="post"
              </cfif>
              <cfif structKeyExists( local, "#local.entity#id" )>
                data-entityid="#local[ '#local.entity#id' ]#"
              </cfif>
              data-entity="#local.entity#"
            >
          </cfif>

          <cfif not local.modal>
            <input type="hidden" name="submitButton" value="" />
          </cfif>

          <cfif structKeyExists( rc, "returnto" )>
            <input type="hidden" name="returnto" value="#rc.returnto#" />
          </cfif>

          <cfif structKeyExists( local, "#local.entity#id" )>
            <input type="hidden" name="#local.entity#id" value="#local[ '#local.entity#id' ]#" />
          </cfif>

          <input type="hidden" name="_#local.namePrepend#subclass" value="#local.entity#" />

          <cfif len( trim( local.formprepend ))>
            #local.formprepend#
          </cfif>

          <!--- search for many-to-one fields who's ID has been passed to this form, and include as hidden field --->
          <cfset propertiesWithFK = structFindValue( rc.properties, 'many-to-one', 'all' ) />
          <cfloop array="#propertiesWithFK#" index="property">
            <cfset property = property.owner />
            <cfif structKeyExists( rc, property.fkcolumn ) and len( trim( rc[property.fkcolumn] )) and not property.fkcolumn eq '#local.entity#id'>
              <input type="hidden" name="#property.fkcolumn#" value="#rc[property.fkcolumn]#" />
            </cfif>
          </cfloop>

          <cfset i = 0 />
          <cfloop array="#local.columns#" index="column">
            <cfset i++ />
            <cfset sharedClass = "form-group row" />
            <cfset editableCheck = false />
            <cfif structKeyExists( column, "editable" ) and column.editable and local.editable and rc.auth.role.can( "change", local.entity )>
              <cfset editableCheck = true />
            </cfif>
            <cfif not editableCheck>
              <cfset sharedClass = listAppend( sharedClass, "display", " " ) />
            </cfif>
            <cfif structKeyExists( column, "affected" )>
              <cfset sharedClass = listAppend( sharedClass, "affected", " " ) />
              <cfset sharedClass = listAppend( sharedClass, column.name, " " ) />
            </cfif>

            <div class="#sharedClass#">
              <cfif structKeyExists( column, 'ORMType' ) and column.ORMType eq "boolean">
                <label for="#column.name#" class="col-sm-3 col-form-label"></label>
              <cfelse>
                <label for="#column.name#" class="col-sm-3 col-form-label" title="#column.name#">
                  #i18n.translate( column.name )#
                  <cfif isDefined( "column.hint" )>
                    <i class="fa fa-question-circle" title="#i18n.translate( 'hint-#local.entity#-#column.name#' )#"></i>
                  </cfif>

                  <cfif editableCheck and
                        not isNull( column.inlineedit ) and
                        not isNull( column.fieldtype ) and column.fieldtype contains "to-one" and
                        not isNull( column.entityname ) and len( column.entityname ) and
                        arrayLen( column.subclasses ) gt 1>
                    <cfset arrayDeleteAt( subclasses, 1 ) />

                    <div class="btn-group clearfix subclassSelector" style="display: block; margin-top: 5px;">
                      <button class="btn btn-secondary btn-sm dropdown-toggle" type="button" data-toggle="dropdown"
                        aria-haspopup="true"
                        aria-expanded="false">#i18n.translate( 'subclass' )#</button>
                      <div class="dropdown-menu">
                        <cfloop array="#subclasses#" index="subclass">
                          <a class="dropdown-item" href="#buildUrl( '#subclass#.edit?modal=1&inline=1&entity=#subclass#&namePrepend=#column.name#_' )#">#i18n.translate( subclass )#</a>
                        </cfloop>
                      </div>
                    </div>
                  </cfif>
                </label>
              </cfif>

              <div class="col-sm-9">
                <cfif editableCheck>
                  <cfset fieldparameters = {
                    "column"      = column,
                    "i"           = i,
                    "namePrepend" = local.namePrepend
                  } />
                  #view( "form/edit/field", fieldparameters )#
                <cfelse>
                  <cfset fieldparameters = {
                    "data"    = local.data,
                    "column"  = {
                                  "data" = column,
                                  "name" = column.name
                                }
                  } />
                  <cfset customView = "#getSection( )#/form/view/#column.name#" />
                  <cfif cachedFileExists( parseViewOrLayoutPath( customView, "view" ) )>
                    #view( customView, fieldparameters )#
                  <cfelse>
                    #view( "form/view/field", fieldparameters )#
                  </cfif>
                </cfif>
              </div>
            </div>
          </cfloop>

          <cfif len( trim( local.formappend ))>
            #local.formappend#
            <hr />
          </cfif>

          <cfif not local.modal>
            <div class="whitespace"></div>

            <cfif local.canBeLogged and local.editable and rc.config.log and rc.config.lognotes>
              <cfset logObject = entityNew( "logentry" ) />
              <cfset logFields = logObject.getInheritedProperties() />

              <div class="panel-group" id="collapseLogentries">
                <div class="panel panel-default">
                  <div class="panel-heading">
                    <h4 class="panel-title"><a data-toggle="collapse" data-parent="##collapseLogentries" href="##collapseLogentry"><span><i class="fa fa-caret-right text-muted"></i></span><span class="text-muted">#i18n.translate( 'logentry-addform' )#</span></a></h4>
                  </div>
                  <div id="collapseLogentry" class="panel-collapse collapse">
                    <div class="panel-body">
                      <cfloop list="note" index="logField">
                        <cfset logFields[logField].saved = '' />
                        <cfset fieldEditProperties = {
                          column=logFields[logField],
                          i=i++,
                          namePrepend="logentry_",
                          idPrepend="logentry_"
                        } />
                        <div class="form-group row">
                          <label for="logentry_#logField#" class="col-lg-3 control-label">#i18n.translate( 'logentry_' & logField )#</label>
                          <div class="col-lg-9">#view(":elements/fieldedit",fieldEditProperties)#</div>
                        </div>
                      </cfloop>
                    </div>
                  </div>
                </div>
              </div>
            </cfif>

            <div class="form-group row">
              <div class="offset-lg-3 col-lg-9">
                <cfif local.editable>
                  <button type="button" class="btn btn-default cancel-button">#i18n.translate('cancel')#</button>
                  <cfset submitButtons = [
                   {
                     "value" = "save",
                     "modal" = ""
                   }
                  ] />
                  <cfif structKeyExists( rc, 'submitButtons' ) and arrayLen( rc['submitButtons'] )>
                    <cfset submitButtons = rc['submitButtons'] />
                  </cfif>

                  <cfloop array="#submitButtons#" index="submitButton">
                    <cfif len( trim( submitButton.modal ) )>
                      <a data-toggle="modal" href="##confirm#submitButton.value#" data-name="#submitButton.value#" class="btn btn-primary #submitButton.value#-button" data-style="expand-right">#i18n.translate( submitButton.value )#</a>
                      <button type="submit" class="hidden" data-name="#submitButton.value#"></button>
                      #view( ":elements/modal",{name=submitButton.modal,yeslink=''})#
                    <cfelse>
                      <button type="submit" data-name="#submitButton.value#" class="btn btn-primary #submitButton.value#-button" data-style="expand-right"><span class="ladda-label">#i18n.translate( submitButton.value )#</span></button>
                    </cfif>
                  </cfloop>
                <cfelse>
                  <button type="button" class="btn btn-primary cancel-button">#i18n.translate('back')#</button>
                </cfif>
              </div>
            </div>

            <cfif structKeyExists( rc, "#local.entity#id" )>
              <cfif not local.hideDelete and local.editable>
                <hr />

                <cfif local.data.getDeleted() eq 1>
                  <div class="form-group row">
                    <div class="offset-lg-3 col-lg-9">
                      <a data-toggle="modal" href="##confirmrestore" class="btn btn-success">#i18n.translate('btn-#local.entity#.restore')#</a>
                    </div>
                  </div>
                  #view( ":elements/modal",{name="restore",yeslink=buildURL('.restore','?#local.entity#id=#rc[ local.entity & 'id' ]#')})#
                <cfelse>
                  <div class="form-group row">
                    <div class="offset-lg-3 col-lg-9">
                      <a data-toggle="modal" href="##confirmdelete" class="btn btn-danger">#i18n.translate('btn-#local.entity#.delete')#</a>
                    </div>
                  </div>
                  #view( ":elements/modal",{name="delete",yeslink=buildURL('.delete','?#local.entity#id=#rc[ local.entity & 'id' ]#')})#
                </cfif>
              </cfif>

              <cfif local.data.propertyExists( 'createDate' ) and isDate( local.data.getCreateDate())>
                <small class="footnotes">
                  #i18n.translate( 'created' )#:
                  <cfif local.data.propertyExists( 'createContact' )>
                    <cfset creator = local.data.getCreateContact() />
                    <cfif isDefined( "creator" )>
                      #i18n.translate('created-by')#: <a href="mailto:#creator.getEmail()#">#creator.getFullname()#</a>
                      #i18n.translate('on')#
                    </cfif>
                  </cfif>
                  #lsDateFormat( local.data.getCreateDate( ), i18n.translate( 'defaults-dateformat-small' ) )# #i18n.translate( 'at' )# #lsTimeFormat( local.data.getCreateDate(), 'HH:mm:ss' )#.
                  <cfif isDate( local.data.getUpdateDate( ) ) and dateDiff( 's', local.data.getCreateDate( ), local.data.getUpdateDate( ) ) gt 1>
                    <br />
                    #i18n.translate( 'updated' )#:
                    <cfif local.data.propertyExists( 'updateContact' )>
                      <cfset updater = local.data.getUpdateContact() />
                      <cfif isDefined( "updater" )>
                        #i18n.translate('updated-by')#: <a href="mailto:#updater.getEmail()#">#updater.getFullname()#</a>
                        #i18n.translate('on')#
                      </cfif>
                    </cfif>
                    #lsDateFormat( local.data.getUpdateDate(), i18n.translate( 'defaults-dateformat-small' ))# #i18n.translate('at')# #lsTimeFormat( local.data.getUpdateDate(), 'HH:mm:ss' )#.
                  </cfif>
                </small>
              </cfif>
            </cfif>
          </cfif>

          <cfif not local.modal>
            <div id="inlineedit-result"></div>
          </cfif>

          <cfif not local.inline>
            </form>
          </cfif>
        </div>
      </div>

      <cfset tabVars = { } />

      <cfif structKeyExists( local, "#local.entity#id" )>
        <cfset tabVars = { "entityId" = local["#local.entity#id"] } />
      </cfif>

      <cfloop array="#local.tabs#" index="tab">
        <div class="tab-pane" id="form-#tab#">#view( ":form/tabs/#instanceVars.settings.useForViews#/#tab#", tabVars, "" )#</div>
      </cfloop>

  <cfif not local.modal>
      <cfif structKeyExists( rc, "#local.entity#id" ) and local.canBeLogged>
        <cfif isDefined( "log" ) and arrayLen( log )>
          <div class="tab-pane" id="changelog">#view( ':elements/changelog', { activity = log, linkToEntity = false, notesInline = true })#</div>
        </cfif>
      </cfif>
    </div>
    <div class="modal" id="modal-dialog" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true"></div>
  </cfif>
</cfoutput>