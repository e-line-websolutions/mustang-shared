<!--- cfoutput>
  <br />
  <div class="well">
    <form action="#buildURL('main.saveQuickAdd')#" method="post">
      <fieldset>
        <legend>#i18n.translate('quick-add')#</legend>
        <div class="form-group row">
          <label for="firstname">#i18n.translate('firstname')#</label>
          <input type="text" class="form-control input-sm" name="firstname" id="firstname" placeholder="#i18n.translate('placeholder-firstname')#">
        </div>
        <div class="form-group row">
          <label for="firstname">#i18n.translate('lastname')#</label>
          <input type="text" class="form-control input-sm" name="lastname" id="lastname" placeholder="#i18n.translate('placeholder-lastname')#">
        </div>
        <div class="form-group row">
          <label for="firstname">#i18n.translate('phone')#</label>
          <input type="text" class="form-control input-sm" name="phone" id="phone" placeholder="#i18n.translate('placeholder-phone')#">
        </div>
        <div class="form-group row">
          <label for="firstname">#i18n.translate('email')#</label>
          <input type="text" class="form-control input-sm" name="email" id="email" placeholder="#i18n.translate('placeholder-email')#">
        </div>

        <button type="submit" class="btn btn-primary btn-sm">#i18n.translate('save')#</button>
      </fieldset>
    </form>
  </div>
</cfoutput --->