<cfoutput>
  <div class="home-bg automated-home" style="<cfif structKeyExists( rc, "coverImageId" )>background-image:url( /api/base64Image/?id=#rc.coverImageId# );</cfif>">
    <cfloop array="#rc.articles#" index="article">
      <article>
        #article.body#
      </article>
    </cfloop>
  </div>
</cfoutput>
