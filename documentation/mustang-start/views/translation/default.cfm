<cfoutput>
  <div class="container-fluid">
    <h4>#i18n.translate('new-label')#:</h4>

    <form id="newlabel" class="form-inline">
      <div class="form-group row">
        <div class="">
          <select id="language" name="language" class="form-control">
            <cfloop array="#rc.allLanguages#" index="translationFile">
              <option value="#listFirst( translationFile, '.' )#">#i18n.translate( translationFile )#</option>
            </cfloop>
          </select>
        </div>
      </div>
      <div class="form-group row">
        <div class="">
          <input class="form-control" type="text" name="name" placeholder="#i18n.translate( 'placeholder-label' )#" />
        </div>
      </div>
      <div class="form-group row">
        <div class="">
          <input class="form-control" type="text" name="value" placeholder="#i18n.translate( 'placeholder-translation' )#" />
        </div>
      </div>
      <button id="save-translation" type="button" class="btn btn-primary">#i18n.translate( 'save' )#</button>
    </form>
  </div>

  <hr />

  <div id="toolbar">
    <button id="removeBtn" class="btn btn-default">#i18n.translate( 'remove' )#</button>
  </div>

  <table id="labels" data-toggle="table"
                     data-url="#buildURL( 'adminapi:translation.list' )#"
                     data-search="true"
                     data-locale="#rc.config.defaultLanguage#"
                     data-pagination="true"
                     data-toolbar="##toolbar">
    <thead>
      <tr>
        <th data-field="state" data-checkbox="true"></th>
        <th data-field="label" data-sortable="true" data-searchable="true" class="col-md-3">#i18n.translate('labels')#</th>
        <cfloop array="#rc.allLanguages#" index="local.translationFile">
          <th data-field="#listFirst( local.translationFile, '.' )#" data-editable="true">#i18n.translate( local.translationFile )#</th>
        </cfloop>
      </tr>
    </thead>
    <tbody></tbody>
  </table>
</cfoutput>