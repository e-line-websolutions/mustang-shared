<cfparam name="local.namePrepend" default="" />
<cfparam name="local.idPrepend" default="#local.namePrepend#" />
<cfparam name="local.allowBlank" default=false />
<cfparam name="local.chooseLabel" default="choose" />

<cfparam name="local.column" default="#{}#" />
<cfparam name="local.column.name" default="" />
<cfparam name="local.column.fieldtype" default="column" />
<cfparam name="local.column.ORMType" default="" />
<cfparam name="local.column.formfield" default="" />

<cfparam name="rc.modal" default=false />

<cfset column = local.column />
<cfset formElementName = local.namePrepend & column.name />
<cfset fieldAttributes = 'id="#local.idPrepend##column.name#"' />
<cfset singularColumnName = structKeyExists( column, "singularName" ) ? column.singularName : column.name />

<cfset columnEntityName = "" />
<cfset linkedEntityID = "" />

<cfif structKeyExists( column, "entityName" )>
  <cfset columnEntityName = column.entityName />
</cfif>

<cfif isObject( column.saved )>
  <cfset linkedEntityID = column.saved.getID() />
  <cfset columnEntityName = column.saved.getEntityName() />
</cfif>

<cfoutput>
  <cfif rc.modal and (
          (
            structKeyExists( column, "inlineedit" ) and
            (
              column.fieldtype eq "many-to-one" or
              column.fieldtype eq "many-to-many"
            )
          ) or
          column.fieldtype eq "one-to-many"
        )>
    <p class="form-control-static"><em class="text-muted">#i18n.translate('not-supported')#</em></p>
    <cfexit />
  </cfif>

  <cfif column.fieldtype contains "many">
    <cfif not isNull( column.inlineedit )>
      <cfif column.fieldtype contains "to-one">
        <div class="load-inline"
          data-entity     = "#columnEntityName#"
          data-fieldname  = "#column.name#"
          data-id         = "#linkedEntityID#"
        ></div>
      <cfelseif column.fieldtype contains "to-many">
        <cfif structKeyExists( column, "saved" )>
          <cfset savedEntities = evaluate( "rc.data.get#column.name#()" ) />
          <cfif not isDefined( "savedEntities" )>
            <cfset savedEntities = [] />
          </cfif>
          <div class="inlineblock"#arrayLen( savedEntities )?'':' style="display:none;"'#>
            <table class="table table-condensed">
              <tbody id="saved-#singularColumnName#">
                <cfloop array="#savedEntities#" index="savedEntity">
                  <cfset fieldsToDisplay = savedEntity.getFieldsToDisplay( "inlineedit-line" ) />
                  <cfif not arrayLen( fieldsToDisplay )>
                    <cfset fieldsToDisplay = [savedEntity.getName()] />
                  </cfif>
                  <tr class="inline-item">
                    <cfloop array="#fieldsToDisplay#" index="fieldToDisplay">
                      <cfif not isSimpleValue( fieldToDisplay )>
                        <cfset fieldparameters = {
                          "val"     = savedEntity,
                          "data"    = savedEntity,
                          "column"  = {
                            "name" = column.name,
                            "orderNr" = 1,
                            "class" = "",
                            "data" = savedEntity
                          }
                        } />
                        <cfset fieldToDisplay = view( 'form/view/field', fieldparameters ) />
                      </cfif>
                      <td>#fieldToDisplay#</td>
                    </cfloop>
                    <td class="col-sm-3 text-right"><a href="##confirmremove" class="btn btn-xs btn-danger remove-button" data-entity="#column.name#" data-id="#savedEntity.getID()#">#i18n.translate( "remove" )#</a></td>
                  </tr>
                </cfloop>
              </tbody>
            </table>
          </div>
        </cfif>
        <div id="#column.name#_inlineedit" class="inlineedit">
          <cfset appendFK = structKeyExists( rc, "#rc.entity#id" ) ? "&fk=#rc[ rc.entity & 'id' ]#" : "" />
          <a href="#buildURL( "#column.entityName#.new?modal=1#appendFK#&source=#column.fkColumn#" )#" class="btn btn-sm btn-primary inlineedit-modal-trigger" data-target="##modal-dialog" data-field="#singularColumnName#">#i18n.translate( 'add-#column.name#' )#</a>
        </div>
      </cfif>

    <cfelseif structKeyExists( column, "autocomplete" )>
      #view( 'form/edit/select', {
        "id"          = "#local.idPrepend##column.name#",
        "class"       = "autocomplete",
        "name"        = formElementName,
        "data"        = {
                          "entity"  = "#columnEntityName#"
                        },
        "placeholder" = i18n.translate('placeholder-#column.name#'),
        "selected"    = column.saved
      })#

    <cfelseif column.fieldtype contains "to-many">
      <cfset checkedOption = "" />
      <cfif structKeyExists( column, "saved" )>
        <cfif isSimpleValue( column.saved )>
          <cfset checkedOption = column.saved />
        <cfelseif isObject( column.saved )>
          <cfset checkedOption = column.saved.getID() />
        </cfif>
      </cfif>

      <input type="hidden" name="#formElementName#" value="" />

      <cfif structKeyExists( column, "hierarchical" )>
        <cfset checkboxes = ORMExecuteQuery( "FROM #columnEntityName# WHERE deleted=FALSE AND parent=NULL ORDER BY sortorder, name" ) />

        <div class="panel-group" id="accordion">
          <div class="panel panel-default">
            <div class="panel-heading">
              <h4 class="panel-title"><a data-toggle="collapse" data-parent="##accordion_#formElementName#" href="##collapse_#formElementName#"><span><i class="fa fa-caret-right"></i></span>#i18n.translate( 'view-change' )#</a></h4>
            </div>
            <div id="collapse_#formElementName#" class="panel-collapse collapse">
              <div class="panel-body">
                <cfloop array="#checkboxes#" index="local.checkbox">
                  <cfset viewOptions = {
                    name = formElementName,
                    boxes = local.checkbox.getChildren(),
                    checked = checkedOption
                  } />
                  <div class="#structKeyExists( column, 'affected' )?'affected #local.checkbox.getName()#':''#">#view( "form/edit/recursive-checkbox", viewOptions )#</div>
                </cfloop>
              </div>
            </div>
          </div>
        </div>
      <cfelse>
        <cfset checkboxes = ORMExecuteQuery( "FROM #columnEntityName# WHERE ( deleted IS NULL OR deleted = FALSE ) ORDER BY sortorder" ) />
        <cfset checkboxIndex = 0 />
        <cfloop array="#checkboxes#" index="option">
          <cfset checkboxIndex++ />
          <cfset required = ( checkboxIndex eq 1 and structKeyExists( column, 'required' )) ? ' data-bv-choice="true" data-bv-choice-min="1" data-bv-message="' & i18n.translate( '#column.name#-required-message' ) & '"' : '' />
          <cfset checked = listFind( checkedOption, option.getID()) ? ' checked="checked"' : '' />
          <div class="form-check">
            <label class="form-check-label">
              <input class="form-check-input" type="checkbox" name="#formElementName#" value="#option.getID()#"#checked##required# />
              #structKeyExists( column, "translateOptions" )?i18n.translate(option.getName()):option.getName()#
            </label>
          </div>
        </cfloop>
      </cfif>

    <cfelse>
      <cfset selectedOption = "" />

      <cfif structKeyExists( rc, "fk" ) and
            structKeyExists( rc, "source" ) and
            compareNoCase( rc.source, column.fkColumn ) eq 0>
        <cfset selectedOption = rc.fk />
      </cfif>

      <cfif structKeyExists( column, "saved" )>
        <cfif isSimpleValue( column.saved )>
          <cfif len( trim( column.saved ))>
            <cfset selectedOption = column.saved />
          </cfif>
        <cfelseif isObject( column.saved )>
          <cfset selectedOption = column.saved.getID() />
        </cfif>
      </cfif>

      <cfif structKeyExists( column, "hierarchical" )>
        <cfset selects = ORMExecuteQuery( "FROM #columnEntityName# WHERE deleted=FALSE AND parent=NULL ORDER BY sortorder" ) />
        <cfloop array="#selects#" index="select">
          <cfset viewOptions = { options = select.getChildren(), selected = selectedOption } />
          <cfset classNames = select.getName() />
          <cfif structKeyExists( column, "affectsform" )><cfset listAppend( classNames, affectsform, " " ) /></cfif>
          <cfif structKeyExists( column, "affected" )><cfset listAppend( classNames, affected, " " ) /></cfif>

          #view( 'form/edit/select', {
            "id"        = "#local.idPrepend##column.name#",
            "name"      = formElementName,
            "class"     = classNames,
            "data"      = {
              "optionfilter" = select.getID()
            },
            "contents"  = view( "form/edit/recursive-option", viewOptions )
          })#
        </cfloop>
      <cfelse>
        <cfquery dbtype="hql" name="options" ormoptions="#{cacheable=true}#">
          FROM      #columnEntityName#
          WHERE     deleted != <cfqueryparam cfsqltype="cf_sql_tinyint" value="1" />

          <cfif structKeyExists( column, "where" )>
            <cfset whereClause = listToArray( replaceNoCase( column.where, ' AND ', chr( 0182 ), 'all' ), chr( 0182 )) />
            <cfloop array="#whereClause#" index="whereItem">
              <cfset whereKey = trim( listFirst( whereItem, '=' )) />
              <cfset whereValue = replace( trim( listRest( whereItem, '=' )), "'", "", "all" ) />
              <cfif right( whereKey, 2 ) eq "id">
                <cfset whereEntityName = mid( whereKey, 1, len( whereKey ) - 2 ) />
                <cfset whereEntity = entityLoadByPK( whereEntityName, whereValue ) />
                <cfif not isNull( whereEntity )>
                  AND #whereEntityName# = <cfqueryparam value="#whereEntity#" />
                </cfif>
              <cfelse>
                AND #replace( whereItem, "''", "'", "all" )#
              </cfif>
            </cfloop>
          </cfif>

          ORDER BY  sortorder
        </cfquery>

        #view( 'form/edit/select', {
          "id"                = "#local.idPrepend##column.name#",
          "name"              = formElementName,
          "class"             = structKeyExists( column, "affectsform" ) ? " affectsform" : "",
          "options"           = options,
          "selected"          = selectedOption,
          "translateOptions"  = structKeyExists( column, "translateOptions" ),
          "affectsform"       = structKeyExists( column, "affectsform" ),
          "choose"            = (
                                  (
                                    column.fieldtype contains "to-one" and
                                    not structKeyExists( column, "required" )
                                  ) or
                                  local.allowBlank
                                ) ? local.chooseLabel : ""
        })#
      </cfif>
    </cfif>
  <cfelseif column.ORMType eq "boolean">
    #view( 'form/edit/checkbox', {
      "column" = column,
      "formElementName" = formElementName,
      "idPrepend" = local.idPrepend
    })#
  <cfelse>
    <cfset fieldAttributes &= ' placeholder="#i18n.translate('placeholder-#column.name#')#"' />
    <cfswitch expression="#column.formfield#">
      <cfcase value="color">
        <cfset fieldAttributes &= ' class="form-control pick-a-color" name="#formElementName#"' />
        <input #fieldAttributes# type="text" value="#column.saved#" />
      </cfcase>
      <cfcase value="file">
        <div class="fileinput">
          <cfset showUploadButton = true />
          <cfif structKeyExists( column, "saved" ) and
                isSimpleValue( column.saved ) and
                len( trim( column.saved ))>
            <cfset showUploadButton = false />
            <input type="hidden" name="#formElementName#" value="#column.saved#" />
            <cfset column.saved = '<button type="button" class="close fileinput-remove">&times;</button><a href="' & buildURL( 'adminapi:crud.download?filename=#column.saved#' ) & '">#column.saved#</a>' />
          <cfelse>
            <input type="hidden" name="#formElementName#" value="" />
            <cfset column.saved = "" />
          </cfif>
          <span role="button" class="btn btn-primary fileinput-button"#showUploadButton?'':' style="display:none;"'#>
            <i class="fa fa-plus"></i>
            <span>#i18n.translate( "select-file" )#</span>
            <input #fieldAttributes# type="file" data-name="#formElementName#" />
          </span>
          <div class="progress" style="margin-top:5px; display:none;">
            <div class="progress-bar progress-bar-success" role="progressbar" aria-valuemin="0" aria-valuemax="100" style="width: 0%"></div>
          </div>
          <div#showUploadButton?' class="alert" style=" display:none;"':' class="alert alert-success"'#>#column.saved#</div>
        </div>
      </cfcase>
      <cfdefaultcase>
        <cfparam name="column.saved" default="" />

        <cfif structKeyExists( column , "editor" )>
          #view( "form/#column.editor#", {
            "id" = "#local.idPrepend##column.name#",
            "name" = formElementName,
            "saved" = column.saved
          })#
        <cfelseif (
            structKeyExists( column, "dataType" ) and
            column.dataType eq "json"
          ) or (
            structKeyExists( column, "data" ) and
            isStruct( column.data ) and
            structKeyExists( column.data, "dataType" ) and
            column.data.dataType eq "json"
          )>
          <cfset local.saved = column.saved />
          <cfif not isSimpleValue( local.saved )>
            <cfset local.saved = serializeJSON( local.saved ) />
          </cfif>
          <div class="jsoneditorblock">
            <div class="jsoncontainer" data-value="#toBase64( local.saved )#"></div>
            <input type="hidden" name="#formElementName#" value="#htmlEditFormat( local.saved )#" />
          </div>
        <cfelseif column.formfield eq "datepicker">
          <cfset fieldAttributes = ' data-date-format="yyyy-mm-dd HH:ii:00"' />
          <cfif isDate( column.saved )>
            <cfset column.saved = "#dateFormat( column.saved, 'yyyy-mm-dd' )# #timeFormat( column.saved, 'HH:mm:00' )#" />
            <cfif year( column.saved ) gt 10000>
              <cfset column.saved = "infinite" />
            </cfif>
            <cfset fieldAttributes &= ' data-date="#column.saved#"' />
          </cfif>
          <div class="input-group date datepicker"#fieldAttributes#>
            <input type="text" class="form-control" size="16" value="#column.saved#" name="#formElementName#" />
            <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
          </div>
        <cfelseif isSimpleValue( column.saved )>
          <cfset fieldAttributes &= ' name="#formElementName#"' />
          <cfset cssClass = "form-control #column.formfield#" />

          <cfif ( structKeyExists( column, "sqltype" ) and column.sqltype contains "text" ) or
                ( structKeyExists( column, "ormtype" ) and column.ormtype contains "text" )>
            <cfif not structKeyExists( column, "plaintext" )>
              <cfset cssClass &= " tinymce" />
            </cfif>
            <cfset fieldAttributes &= ' class="#cssClass#"' />
            <textarea rows="15" #fieldAttributes#>#column.saved#</textarea>
          <cfelse>
            <cfset fieldAttributes &= ' class="#cssClass#"' />

            <cfif structKeyExists( column, "mask" )>
              <cfset fieldAttributes &= ' data-mask="#column.mask#"' />
            </cfif>

            <cfif listFindNoCase( "edit,new", getItem()) and structKeyExists( column, "required" )>
              <cfif structKeyExists( column, "regexp" )>
                <cfset fieldAttributes &= ' data-bv-regexp="true"' />
                <cfset fieldAttributes &= ' data-bv-regexp-regexp="^#column.regexp#$"' />
              </cfif>
              <cfset fieldAttributes &= ' data-bv-message="' & i18n.translate( column.name & '-required-message' ) & '"' />
              <cfif not structKeyExists( column, "allowempty" )>
                <cfset fieldAttributes &= ' required data-bv-notempty="true"' />
              </cfif>
              <cfif structKeyExists( column, "requirement" )>
                <cfswitch expression="#column.requirement#">
                  <cfcase value="unique">
                    <cfset validationURLAttributes = {
                      "entityName" = rc.entity,
                      "propertyName" = column.name
                    } />
                    <cfif isDefined( "rc.data" ) and len( trim( rc.data.getID()))>
                      <cfset validationURLAttributes["entityID"] = rc.data.getID() />
                    </cfif>
                    <cfset fieldAttributes &= ' data-bv-remote="true" data-bv-remote-name="value" data-bv-remote-url="' & buildURL( action = 'adminapi:crud.validate', queryString = validationURLAttributes ) & '"' />
                  </cfcase>
                </cfswitch>
              </cfif>
            </cfif>

            <input #fieldAttributes# type="text" value="#htmlEditFormat( column.saved )#" />
          </cfif>
        </cfif>
      </cfdefaultcase>
    </cfswitch>
  </cfif>
</cfoutput>