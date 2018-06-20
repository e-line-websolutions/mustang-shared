<cfparam name="rc.displaytitle" default="" />
<cfparam name="rc.useAsViewEntity" default="#getSection()#" />

<cfcontent type="text/html; charset=utf-8" /><cfoutput><!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title><cfif structKeyExists( rc, 'displaytitle' )>#rc.displaytitle# - </cfif>#request.appName#</title>

    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/css/bootstrap.min.css" integrity="sha384-/Y6pD6FV/Vv2HJnA6t+vslU6fwYXjCFtcEpHbNJ0lyAFsXTsjBbfaDjzALeQsN6M" crossorigin="anonymous">

    <link rel="stylesheet" href="//maxcdn.bootstrapcdn.com/font-awesome/4.6.3/css/font-awesome.min.css" />
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.11.0/bootstrap-table.min.css" />
    <link rel="stylesheet" href="//cdnjs.cloudflare.com/ajax/libs/x-editable/1.5.0/bootstrap3-editable/css/bootstrap-editable.css" />
    <link rel="stylesheet" href="#request.webroot#/inc/plugins/ladda/ladda.min.css" />
    <link rel="stylesheet" href="#request.webroot#/inc/plugins/jsoneditor/jsoneditor.min.css" />
    <link rel="stylesheet" href="#request.webroot#/inc/plugins/datetimepicker/bootstrap-datetimepicker.min.css" />
    <link rel="stylesheet" href="#request.webroot#/inc/css/admin.css" />
    <cfif util.fileExistsUsingCache( request.root & "/webroot/inc/css/" & rc.useAsViewEntity & ".css" )>
      <link rel="stylesheet" href="#request.webroot#/inc/css/#rc.useAsViewEntity#.css" />
    </cfif>
    <cfif util.fileExistsUsingCache( request.root & "/webroot/inc/css/" & rc.useAsViewEntity & "." & getItem() & ".css" )>
      <link rel="stylesheet" href="#request.webroot#/inc/css/#rc.useAsViewEntity#.#getItem()#.css" />
    </cfif>
  </head>
  <body>
    <cfif rc.auth.isLoggedIn>
      #view( ":elements/topnav" )#

      <div id="main" class="container-fluid">
        <div class="row">
          <nav class="col-sm-3 col-md-2 d-none d-sm-block bg-light sidebar">#view( ":elements/subnav" )#</nav>
          <main class="col-sm-9 ml-sm-auto col-md-10 pt-3">
            #view( ":elements/standard", { body = body } )#
            #view( ":elements/footer" )#
          </main>
        </div>
      </div>

    <cfelse>
      <div class="container">
        <div class="login-page">#body#</div>
      </div>
    </cfif>

    <script src="https://code.jquery.com/jquery-3.2.1.min.js" integrity="sha256-hwg4gsxgFZhOsEEamdOYGBf13FyQuiTwlAQgxVSNgt4=" crossorigin="anonymous"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.11.0/umd/popper.min.js" integrity="sha384-b/U6ypiBEHpOf/4+1nzFpr53nxSS+GLCkfwBdFNTxtclqqenISfwAzpKaMNFNmj4" crossorigin="anonymous"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta/js/bootstrap.min.js" integrity="sha384-h0AbiXch4ZDo7tp9hKZ4TsHbi047NrKGLO3SEJAg45jXxnGIfYzk4Si90RDIqNm1" crossorigin="anonymous"></script>

    <script src="//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.11.0/bootstrap-table.min.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.11.0/locale/bootstrap-table-nl-NL.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/bootstrap-table/1.11.0/extensions/editable/bootstrap-table-editable.js"></script>
    <script src="//cdnjs.cloudflare.com/ajax/libs/x-editable/1.5.0/bootstrap3-editable/js/bootstrap-editable.min.js"></script>
    <script src="#request.webroot#/inc/plugins/ladda/ladda.min.js"></script>
    <script src="#request.webroot#/inc/plugins/tinymce/jquery.tinymce.min.js"></script>
    <script src="#request.webroot#/inc/plugins/tinymce/tinymce.min.js"></script>
    <script src="#request.webroot#/inc/plugins/validator/validator.min.js"></script>
    <script src="#request.webroot#/inc/plugins/fileupload/jquery.ui.widget.js"></script>
    <script src="#request.webroot#/inc/plugins/fileupload/jquery.fileupload.js"></script>
    <script src="#request.webroot#/inc/plugins/jsoneditor/jsoneditor-minimalist.min.js"></script>
    <script src="#request.webroot#/inc/plugins/datetimepicker/bootstrap-datetimepicker.min.js"></script>
    <script type="text/javascript">
      var _webroot = "#request.webroot#";
      var _subsystemDelimiter = "#framework.subsystemDelimiter#";
      var seoAjax = true;
    </script>
    <script src="#request.webroot#/inc/js/util.js"></script>
    <script src="#request.webroot#/inc/js/admin.js"></script>
    <cfset local.jsIncludeItem = getItem() />
    <cfif listFindNoCase( "new,edit", jsIncludeItem )>
      <cfset local.jsIncludeItem = 'view' />
    </cfif>
    <cfif util.fileExistsUsingCache( request.root & "/webroot/inc/js/global.#jsIncludeItem#.js" )>
      <script src="#request.webroot#/inc/js/global.#jsIncludeItem#.js"></script>
    </cfif>
    <cfif util.fileExistsUsingCache( request.root & "/webroot/inc/js/#rc.useAsViewEntity#.#jsIncludeItem#.js" )>
      <script src="#request.webroot#/inc/js/#rc.useAsViewEntity#.#jsIncludeItem#.js"></script>
    </cfif>
  </body>
</html></cfoutput>