<cfparam name="local.tableview" default="#rc.tableView#" />

<cfset searchFields = [] />
<cfset nonSortedIndex = 1000 />
<cfloop collection="#rc.allColumns#" item="key">
  <cfif structKeyExists( rc.allColumns[key], "searchable" )>
    <cfset rc.showSearch = true />
    <cfif not structKeyExists( rc.allColumns[key], "orderinsearch" )>
      <cfset rc.allColumns[key]["orderinsearch"] = nonSortedIndex++ />
    </cfif>
    <cfset arrayAppend( searchFields, rc.allColumns[key] ) />
  </cfif>
</cfloop>
<cfset searchFields = util.arrayOfStructsSort( searchFields, 'orderinsearch' ) />

<cfoutput>
  <cfif rc.showAsTree>
    <cfset params = {
      alldata = rc.alldata,
      columns = rc.columns,
      lineactions = rc.lineactions,
      lineview = rc.lineview,
      classColumn = rc.classColumn
    } />

    #view( local.tableview, params )#
  <cfelse>
    <cfsavecontent variable="list_header">
      <cfif rc.showSearch>
        <cfif isDefined( "rc.content" )>
          <h3>#rc.content.getSearchbox()#</h3>
        </cfif>
        <form action="#buildURL( getfullyqualifiedaction())#" method="post" class="form-horizontal" role="form">
          <div class="row">
            <cfloop array="#searchFields#" index="searchField">
              <cfset key = searchField.name />
              <cfset searchField.saved = structKeyExists( rc, "filter_#key#" )?rc["filter_#key#"]:"" />
              <cfset param = { column = searchField, namePrepend = "filter_", allowBlank = true, chooseLabel = "all" } />
              <div class="form-group row">
                <label for="search_#key#" class="col-sm-3 control-label">#i18n.translate( 'filter_' & key )#</label>
                <div class="col-sm-6">#view( "form/edit/field", param )#</div>
                <cfif structKeyExists( searchField, "filterType" ) and len( trim( searchField.filterType ))>
                  <div class="col-sm-3">
                    <cfloop list="#searchField.filterType#" index="filterType">
                      <div class="radio"><label><input name="filterType" value="#filterType#" type="radio"#rc.filterType eq filterType?' checked="checked"':''#> #i18n.translate( filterType )#</label></div>
                    </cfloop>
                  </div>
                </cfif>
              </div>
            </cfloop>

            <div class="form-group row">
              <div class="col-sm-offset-3 col-sm-9">
                <div class="checkbox">
                  <label>
                    <input type="checkbox" name="showdeleted" value="1"#rc.showdeleted?' checked="checked"':''# /> #i18n.translate( 'include-deleted' )#
                  </label>
                </div>
              </div>
            </div>

            <div class="form-group row">
              <div class="col-sm-offset-3 col-sm-6">
                <button type="submit" class="btn btn-primary ladda-button" data-style="zoom-in"><span class="ladda-label"><i class="fa fa-search"></i> #i18n.translate('search')#</span></button>
              </div>
            </div>
          </div>
        </form>
        <div class="whitespace"></div>
      </cfif>

      <cfif rc.showNavbar and len( trim( rc.listactions ))>
        <cfset allowedActions = "" />
        <cfloop list="#rc.listactions#" index="action">
          <cfif rc.auth.role.can( "change", getSection())>
            <cfset allowedActions = listAppend( allowedActions, action ) />
          </cfif>
        </cfloop>

        <cfif len( trim( allowedActions ))>
          <nav class="navbar navbar-light bg-faded">
            <div class="btn-group">
              <cfloop list="#allowedActions#" index="key">
                <cfset action = key />
                <cfif left( action, 1 ) eq '.'>
                  <cfset action = "#getSubsystem()#:#getSection()##action#" />
                </cfif>
                <cfset icon = i18n.translate( label="fa-#key#", alternative="" ) />
                <a class="btn btn-sm btn-primary" href="#buildURL( action )#"><cfif len( icon )><i class="fa #icon#"></i> </cfif>#i18n.translate( 'btn-' & action )#</a>
              </cfloop>
            </div>
          </nav>
        </cfif>
      </cfif>
    </cfsavecontent>

    <cfif len( trim( list_header ))>
      #list_header#
    </cfif>

    <cfif rc.showAlphabet>
      <ul class="pagination alphabet">
        <cfloop from="1" to="26" index="i">
          <cfset letter = chr( i + 64 ) />
          <li><a href="#buildURL(getfullyqualifiedaction(),'?startsWith='&letter)#">#letter#</a></li>
        </cfloop>
      </ul>
    </cfif>

    <cfif arrayLen( rc.alldata ) eq 0>
      <div class="whitespace"></div>
      <div class="alert alert-warning">
        <p>#i18n.translate( 'no-results' )#</p>
      </div>
    <cfelse>
      <cfset queryString = {} />

      <cfif val( rc.offset )>
        <cfset queryString["offset"] = rc.offset />
      </cfif>

      <cfif len( trim( rc.startsWith ))>
        <cfset queryString["startsWith"] = rc.startsWith />
      </cfif>

      <cfif rc.showdeleted neq 0>
        <cfset queryString["showdeleted"] = rc.showdeleted />
      </cfif>

      <cfif rc.filterType neq 'contains'>
        <cfset queryString["filterType"] = rc.filterType />
      </cfif>

      <cfloop collection="#rc#" item="key">
        <cfset key = urlDecode( key ) />
        <cfif listFirst( key, "_" ) eq "filter" and isSimpleValue( rc[key] ) and len( trim( rc[key] ))>
          <cfset queryString[lCase( key )] = lCase( rc[key] ) />
        </cfif>
      </cfloop>

      <cfset params = {
        alldata = rc.alldata,
        columns = rc.columns,
        lineactions = rc.lineactions,
        lineview = rc.lineview,
        classColumn = rc.classColumn,
        queryString = queryString
      } />

      #view( local.tableview, params )#

      <cfif rc.showPager>
        <cfif rc.orderby neq rc.defaultSort>
          <cfset queryString["orderby"] = rc.orderby />
        </cfif>

        <cfif structKeyExists( rc, "d" ) and rc.d eq 1>
          <cfset queryString["d"] = 1 />
        </cfif>

        <cfset prevOffset = rc.offset - rc.maxResults />
        <cfif prevOffset lt 0>
          <cfset prevOffset = 0 />
        </cfif>

        <cfset prevQS = duplicate( queryString ) />

        <cfif prevOffset neq 0>
          <cfset prevQS["offset"] = prevOffset />
        <cfelse>
          <cfset structDelete( prevQS, "offset" ) />
        </cfif>

        <cfset nextOffset = rc.offset + rc.maxResults />
        <cfif nextOffset gt rc.recordCounter>
          <cfset nextOffset = rc.recordCounter />
        </cfif>

        <cfset nextQS = duplicate( queryString ) />
        <cfset nextQS["offset"] = nextOffset />

        <div class="text-xs-center">
          <ul class="pagination pagination-sm">
            <cfif rc.offset lte 0>
              <li class="page-item previous disabled"><a class="page-link" href="##">&larr; #i18n.translate( 'prev' )#</a></li>
            <cfelse>
              <li class="page-item previous"><a class="page-link" href="#buildURL( action = getfullyqualifiedaction(), querystring = prevQS)#">&larr; #i18n.translate( 'prev' )#</a></li>
            </cfif>

            <li class="page-item"><span class="page-link">#rc.recordCounter# #i18n.translate( 'record' & ( rc.recordCounter eq 1?'':'s' ))#</span></li>

            <cfif max( rc.offset, nextOffset ) gte rc.recordCounter>
              <li class="page-item next disabled"><a class="page-link" href="##">#i18n.translate( 'next' )# &rarr;</a></li>
            <cfelse>
              <li class="page-item next"><a class="page-link" href="#buildURL( action = getfullyqualifiedaction(), querystring = nextQS)#">#i18n.translate( 'next' )# &rarr;</a></li>
            </cfif>
          </ul>
        </div>
      </cfif>
    </cfif>
  </cfif>
</cfoutput>