<cfoutput>
  <div class="row">
    <div class="col-lg-5 text-center">
      <img src="#request.webroot#/inc/img/cava-logo.min.svg" style="background-color: ##36405d; padding: 20px; width: 175px;" />
    </div>
    <div class="col-lg-7 pull-right" style="border-left:1px solid silver;">
      #util.parseStringVariables( rc.modalContent.body, { "version" = request.version })#
    </div>
  </div>
</cfoutput>