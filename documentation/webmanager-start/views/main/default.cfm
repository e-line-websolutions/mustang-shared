<cfif isNull( rc.articles ) or arrayIsEmpty( rc.articles )>
  <cfexit />
</cfif>

<cfset arrayAppend( rc.stylesheets, "/inc/css/templates/default.css" )>

<div class="row">
  <div class="col-12">
    <cfoutput>
      <cfset articleNr = 0 />
      <cfloop array="#rc.articles#" index="article">
        <cfset articleNr++ />
        <article>
          <cfif arrayLen( rc.articles ) eq 1 or articleNr eq 1>
            <h1>#article.title#</h1>
          <cfelse>
            <h4>#article.title#</h4>
          </cfif>

          <cfsavecontent variable="fullArticle">
            <cfif len(trim( article.teaser ))>
              <div class="intro">
                #article.teaser#
              </div>
            </cfif>
            #article.body#
          </cfsavecontent>

          <cfif not arrayIsEmpty( article.images )>
            <div class="row">
              <div class="col-xs-12 col-sm-6">
                #fullArticle#
              </div>
              <div class="col-xs-12 col-sm-6">
                <cfloop array="#article.images#" index="local.image">
                  <picture>
                    <source srcset="/media/#local.image.src#?s=s" media="(max-width: 500px)">
                    <source srcset="/media/#local.image.src#?s=m" media="(max-width: 1000px)">
                    <source srcset="/media/#local.image.src#?s=l" media="(max-width: 1500px)">
                    <source srcset="/media/#local.image.src#?s=x" media="(min-width: 1501px)">
                    <img srcset="/media/#local.image.src#?s=m" alt="#local.image.alt#">
                  </picture>
                </cfloop>
              </div>
            </div>
          <cfelse>
            #fullArticle#
          </cfif>
        </article>
      </cfloop>
    </cfoutput>
  </div>
</div>
