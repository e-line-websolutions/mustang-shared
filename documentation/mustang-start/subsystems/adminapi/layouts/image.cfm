<cfoutput><!DOCTYPE html>
<html lang="#rc.currentlocale.getCode()#">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge">

    <cfset local.title = rc.displaytitle />

    <cfif isDefined( "rc.content" )>
      <cfif len( trim( rc.content.getHTMLTitle()))>
        <cfset local.title = rc.content.getHTMLTitle() />
      <cfelseif len( trim( rc.content.getTitle()))>
        <cfset local.title = rc.content.getTitle() />
      </cfif>
    </cfif>

    <title>#local.title#</title>

    <link rel="stylesheet" href="/inc/plugins/bootstrap/themes/default/bootstrap.min.css" />
    <link rel="stylesheet" href="/inc/plugins/bootstrap/themes/default/sb-admin-2.css" />
    <link rel="stylesheet" href="/inc/plugins/bootstrap/font-awesome/css/font-awesome.min.css" />
    <link rel="stylesheet" href="/inc/plugins/bootstrap/ladda/ladda.min.css" />
    <link rel="stylesheet" href="/inc/plugins/bootstrap/validator/bootstrapValidator.min.css" />
    <link rel="stylesheet" href="/inc/plugins/bootstrap/slider/css/bootstrap-slider.min.css" />
    <link rel="stylesheet" href="/inc/plugins/tagsinput/bootstrap-tagsinput.css" />
    <link rel="stylesheet" href="/inc/plugins/tagsinput/typeahead.js-bootstrap.css" />
    <link rel="stylesheet" href="/inc/plugins/fileupload/jquery.fileupload.css" />
    <link rel="stylesheet" href="/inc/plugins/pick-a-color/css/pick-a-color-1.2.3.min.css">

    <link rel="stylesheet" href="/inc/css/loading.css" />
    <link rel="stylesheet" href="/inc/css/default.css" />
    <link rel="stylesheet" href="/inc/css/admin.css" />

    <cfif cachedFileExists( 'inc/css/#getSubSystem()#.#getSection()#.css' )><link href="/inc/css/#getSubSystem()#.#getSection()#.css" rel="stylesheet"></cfif>

    <script>
      var _webroot = '';
      var _loggable = false;
      <cfif listFindNoCase( 'new,edit,view', getItem()) and getSection() neq 'logentry' and structKeyExists( rc, "canBeLogged" )>
        _loggable = #rc.canBeLogged?'true':'false'#;
      </cfif>
    </script>

    <script src="/inc/plugins/jquery/jquery-1.11.1.min.js"></script>
    <script src="/inc/plugins/jquery/jquery-ui.min.js"></script>

    <script src="/inc/plugins/jquery/jquery.cookie.js"></script>
    <script src="/inc/plugins/jquery/jquery.sortElements.js"></script>
    <script src="/inc/plugins/jquery/jquery.mask.js"></script>
    <script src="/inc/plugins/jquery/jquery.slimscroll.min.js"></script>

    <script src="/inc/plugins/tinymce/tinymce.min.js"></script>
    <script src="/inc/plugins/tinymce/jquery.tinymce.min.js"></script>

    <script src="/inc/plugins/fileupload/jquery.ui.widget.js"></script>
    <script src="/inc/plugins/fileupload/jquery.iframe-transport.js"></script>
    <script src="/inc/plugins/fileupload/jquery.fileupload.js"></script>

    <script src="/inc/plugins/bootstrap/bootstrap.min.js"></script>

    <script src="/inc/plugins/bootstrap/validator/bootstrapValidator.min.js"></script>
    <script src="/inc/plugins/bootstrap/themes/default/sb-admin-2.js"></script>
    <script src="/inc/plugins/bootstrap/ladda/spin.min.js"></script>
    <script src="/inc/plugins/bootstrap/ladda/ladda.min.js"></script>
    <script src="/inc/plugins/bootstrap/ladda/ladda.jquery.min.js"></script>

    <script src="/inc/plugins/bootstrap/slider/bootstrap-slider.min.js"></script>

    <script src="/inc/plugins/tagsinput/typeahead.bundle.min.js"></script>
    <script src="/inc/plugins/tagsinput/bootstrap-tagsinput.js"></script>
    <script src="/inc/plugins/pick-a-color/js/tinycolor-0.9.15.min.js"></script>
    <script src="/inc/plugins/pick-a-color/js/pick-a-color-1.2.3.min.js"></script>

    <script src="/inc/js/util.js"></script>
    <script src="/inc/js/default.js"></script>
    <script src="/inc/js/admin.js"></script>

    <cfset local.jsIncludeItem = getItem() />
    <cfif listFindNoCase( "new,edit", local.jsIncludeItem )>
      <cfset local.jsIncludeItem = 'view' />
    </cfif>

    <cfif cachedFileExists( 'inc/js/#getSubSystem()#.#getSection()#.js' )><script src="/inc/js/#getSubSystem()#.#getSection()#.js"></script></cfif>
    <cfif cachedFileExists( 'inc/js/#getSubSystem()#.global.#local.jsIncludeItem#.js' )><script src="/inc/js/#getSubSystem()#.global.#local.jsIncludeItem#.js"></script></cfif>
    <cfif cachedFileExists( 'inc/js/#getSubSystem()#.#getSection()#.#local.jsIncludeItem#.js' )><script src="/inc/js/#getSubSystem()#.#getSection()#.#local.jsIncludeItem#.js"></script></cfif>

    <!--[if lt IE 9]>
      <script src="/inc/plugins/bootstrap/compatibility/html5shiv.min.js"></script>
      <script src="/inc/plugins/bootstrap/compatibility/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>#body#</body>
</html></cfoutput>