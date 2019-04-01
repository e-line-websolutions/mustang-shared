<cfprocessingdirective pageEncoding="utf-8"><cfoutput><!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

    <title>#len( rc.pageTitle ) ? rc.pageTitle & ' - ' : ''##i18n.translate( 'website-name' )#</title>

    <cfif util.fileExistsUsingCache( root & "/www/inc/css/" & getSection( request.action ) & ".css" )>
      <link rel="stylesheet" type="text/css" href="/inc/css/#getSection( request.action )#.css?v=#request.version#">
    </cfif>

    <cfif util.fileExistsUsingCache( root & "/www/inc/css/" & getItem( request.action ) & ".css" )>
      <link rel="stylesheet" type="text/css" href="/inc/css/#getItem( request.action )#.css?v=#request.version#">
    </cfif>

    <cfif not isNull( rc.stylesheets )>
      <cfloop array="#rc.stylesheets#" index="local.stylesheet">
        <cfif util.fileExistsUsingCache( root & "/www" & local.stylesheet )>
          <link rel="stylesheet" type="text/css" href="#local.stylesheet#">
        </cfif>
      </cfloop>
    </cfif>
  </head>
  <body class="#rc.currentBaseMenuItem#">
    <div id="outer" class="container">
      <div id="header">
        #view( ":elements/header" )#
      </div>
      <div id="content">
        #view( ":elements/alert" )#
        #body#
      </div>
      <div class="row" id="footer">#view( ":elements/footer" )#</div>
    </div>

    <cfif not isNull( rc.scripts )>
      <cfloop array="#rc.scripts#" index="script">
        <script src="#script##script contains '?'?'&':'?'#v=#request.version#"></script>
      </cfloop>
    </cfif>

    <cfif util.fileExistsUsingCache( root & "/www/inc/js/" & getSection( ) & ".js" )>
      <script src="/inc/js/#getSection( )#.js?v=#request.version#"></script>
    </cfif>

    <cfif util.fileExistsUsingCache( root & "/www/inc/js/" & getItem( ) & ".js" )>
      <script src="/inc/js/#getItem( )#.js?v=#request.version#"></script>
    </cfif>

    <cfif len( trim( rc.websiteDetails.bws_sGoogleAnalytics ) )>
      <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
        ga('create', '#rc.websiteDetails.bws_sGoogleAnalytics#', '#cgi.server_name#');
        ga('send', 'pageview');
      </script>
    </cfif>
  </body>
</html></cfoutput>
