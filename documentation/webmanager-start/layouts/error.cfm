
<cfprocessingdirective pageEncoding="utf-8"><cfoutput><!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">

    <title>#len( rc.pageTitle ) ? rc.pageTitle & ' - ' : ''##i18n.translate( 'website-name' )#</title>

    <link rel="stylesheet" href="https://fonts.googleapis.com/css?family=Montserrat:400,700|Source+Sans+Pro">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0-beta.2/css/bootstrap.min.css" integrity="sha384-PsH8R72JQ3SOdhVi3uxftmaW6Vc51MKb0q5P2rRUpPvrszuE4W1povHYgTpBfshb" crossorigin="anonymous">
    <link href="https://use.fontawesome.com/releases/v5.0.6/css/all.css" rel="stylesheet">


    <link rel="stylesheet" type="text/css" href="/inc/css/error.css">
  </head>
  <body>
    <div class="container">
      <div class="row">
        <div class="col-12">
          <a class="navbar-brand" href="/"><img src="/inc/img/etrias-logo.png" height="95"></a>
        </div>
      </div>
      <div class="row">
        <div class="col-sm-8 col-xs-12">
          <h1>Oeps</h1>
          #body#
        </div>
        <div class="col-sm-4 col-xs-12 smiley">
          <span>:(</span>
        </div>
      </div>
    </div>

  </body>
</html></cfoutput>
