<cfset local.iconTrue = '<i class="fa fa-check-circle-o" style="color:green;"></i>' />
<cfset local.iconFalse = '<i class="fa fa-circle-o" style="color:red;"></i>' />

<cfoutput>
  <div class="container-fluid">
    <form action="#buildURL( '.save' )#" method="post" id="mainform">
      <div class="form-group row">
        <label class="col-lg-3 control-label">#i18n.translate('username')#</label>
        <div class="col-lg-9">
          <input class="form-control" type="text" disabled="disabled"
            value="#rc.data.getUsername()#" />
        </div>
      </div>
      <hr />

      <div class="form-group row">
        <label for="firstname" class="col-lg-3 control-label">#i18n.translate('firstname')#</label>
        <div class="col-lg-9">
          <input tabindex="2" class="form-control" id="firstname" placeholder="#i18n.translate('placeholder-firstname')#" name="firstname" type="text"
            value="#rc.data.getFirstname()#" />
        </div>
      </div>
      <div class="form-group row">
        <label for="infix" class="col-lg-3 control-label">#i18n.translate('infix')#</label>
        <div class="col-lg-9">
          <input tabindex="3" class="form-control" id="infix" placeholder="#i18n.translate('placeholder-infix')#" name="infix" type="text"
            value="#rc.data.getinfix()#" />
        </div>
      </div>
      <div class="form-group row">
        <label for="lastname" class="col-lg-3 control-label">#i18n.translate('lastname')#</label>
        <div class="col-lg-9">
          <input tabindex="4" class="form-control" id="lastname" placeholder="#i18n.translate('placeholder-lastname')#" name="lastname" type="text"
            value="#rc.data.getlastname()#" />
        </div>
      </div>
      <div class="form-group row">
        <label for="email" class="col-lg-3 control-label">#i18n.translate('email')#</label>
        <div class="col-lg-9">
          <input tabindex="5" class="form-control" id="email" placeholder="#i18n.translate('placeholder-email')#" name="email" type="text"
            value="#rc.data.getemail()#" />
        </div>
      </div>
      <div class="form-group row">
        <label for="phone" class="col-lg-3 control-label">#i18n.translate('phone')#</label>
        <div class="col-lg-9">
          <input tabindex="6" class="form-control" id="phone" placeholder="#i18n.translate('placeholder-phone')#" name="phone" type="text"
            value="#rc.data.getphone()#" />
        </div>
      </div>

      <hr />
      <div class="form-group row">
        <div class="col-lg-offset-3 col-lg-9">
          <a href="javascript:history.go(-1)" class="btn btn-default btn-cancel">#i18n.translate( 'cancel' )#</a>
          <button type="submit" class="btn btn-primary">#i18n.translate( 'save' )#</button>
        </div>
      </div>
    </form>
  </div>
</cfoutput>