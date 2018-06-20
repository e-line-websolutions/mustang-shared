<cfoutput>
  <!---
  <div class="row">
    <div class="well well-lg text-center col-lg-10 col-lg-offset-1" style="margin-top:50px; margin-bottom:50px;">
      <a class="btn btn-danger" href="#buildURL('.newpassword')#">#i18n.translate( 'regenerate-password' )#</a>
    </div>
  </div>
  --->

  <div class="row">
    <div class="well well-lg text-center col-lg-10 col-lg-offset-1" style="margin-bottom:50px;">
      <h4 style="margin-top:0;">#i18n.translate( 'enter-new-password' )#:</h4>

      <form action="#buildURL( 'profile.newpassword' )#" method="post">
        <input type="text" name="newPassword" value="" required />
        <button type="submit">#i18n.translate( 'save' )#</button>
      </form>
    </div>
  </div>
</cfoutput>