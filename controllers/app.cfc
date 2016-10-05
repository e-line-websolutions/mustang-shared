component accessors=true {
  property framework;
  property queryService;

  public void function error( required struct rc ) {
    var pageContext = getPageContext();
    var response = pageContext.getResponse();
    var errorMessage = "";

    savecontent variable="errorMessage" {
      writeDump( cgi, false );

      if( structKeyExists( request, "exception" )) {
        writeDump( request.exception );
      }
    };

    if( rc.debug ) {
      if( listFindNoCase( "lucee,railo", server.ColdFusion.ProductName )) {
        pageContext.clear();
      } else {
        pageContext.getcfoutput().clearall();
      }

      writeOutput( errorMessage );
      abort;
    }

    response.setStatus( 500, "Internal Server Error" );
    rc.dontredirect = true;

    var mailSubject = "Error #cgi.server_name#";

    if( isDefined( "request.exception.cause.message" )) {
      mailSubject &= " - " & request.exception.cause.message;
    }

    mailService = new mail(
      to      = rc.config.debugEmail,
      from    = rc.config.debugEmail,
      subject = mailSubject,
      body    = errorMessage
    ).send();
  }

  public void function loc( required struct rc ) {
    var files = {};
    var sep = server.os.name contains 'windows' ? '\' : '/';
    var filter = {
          hidedirs = [
            '.svn',
            '.git',
            '.DS_Store',
            '__MACOSX',
            'WEB-INF',
            'CFIDE',
            'plugins',
            'docs',
            'stats',
            'diagram',
            'org'
          ],
          exts = "js,txt,cfg,cfm,cfc,css,sql,ini,json,config,hbmxml",
          filecontains = ""
        };

    var q = directoryList( request.root, true, 'query' );
    var sql = " SELECT * FROM q WHERE [type] = 'File' ";

    for( var dir in filter.hidedirs ) {
      sql &= " AND NOT directory LIKE '%#sep##dir#' ";
      sql &= " AND NOT directory LIKE '%#sep##dir##sep#' ";
      sql &= " AND NOT directory LIKE '%#sep##dir##sep#%' ";
    }

    sql &= " ORDER BY  datelastmodified DESC ";

    var lastModQuery = new query(
          dbtype = "query",
          sql = sql,
          q = q,
          maxRows = 10
        );

    rc.lastmod = lastModQuery.execute().getResult();

    var allFiles = queryService.toArray( q );

    for( var row in allFiles ) {
      if( row.type == "dir" ||
          left( row.name, 1 ) == '.' ||
          !listFind( filter.exts, listLast( row.name, '.' ))) {
        continue;
      }

      var cont = false;

      for( var dir in filter.hidedirs ) {
        if( row.directory == dir || row.directory contains "#sep##dir##sep#" || row.name == dir ) {
          cont = true;
          break;
        }
      }

      if( cont ) {
        continue;
      }

      if( row.type == "file" ) {
        var ext = listLast( row.name, '.' );

        if( !structKeyExists( files, ext )) {
          files[ext] = 0;
        }

        var filecontents = fileRead( row.directory & sep & row.name );
        var countFile = true;

        if( len( trim( filter.filecontains ))) {
          countFile = false;
          for( var word in listToArray( filter.filecontains )) {
            if( findNoCase( word, filecontents )) {
              countFile = true;
              break;
            }
          }
        }

        if( countFile ) {
          files[ext] += listLen( filecontents, chr( 10 ));
        }
      }
    }

    rc.files = files;
  }

  public void function docs( required struct rc ) {
    rc.docsPath = "#request.fileUploads#/docs";

    var coldDocService = new colddoc.ColdDoc();
    var strategy = new colddoc.strategy.api.HTMLAPIStrategy( rc.docsPath, request.appName & " " & request.version );

    coldDocService.setStrategy( strategy );
    coldDocService.generate( expandPath( "../" ), "root" );
  }

  public void function diagram( required struct rc ) {
    location( "#rc.config.webroot#/diagram", false );
  }

  public void function testService( required struct rc ) {
    param string rc.service="";

    writeDump( createObject( rc.service ));
    abort;
  }
}