<cfset icons = ['frown-o','bomb','stethoscope','thumbs-down'] />

<cfoutput>
  <div class="container">
    <div class="jumbotron">
      <h1><i class="fa fa-#icons[randRange(1,4)]#"></i> System Error</h1>
      <p>The error has been reported to the developer of this system and will be resolved as soon as possible.</p>
      <p><a href="javascript:history.back();" class="btn btn-primary btn-lg" role="button">Back</a></p>
    </div>

    <div class="well">
      <h4>Message:</h4>
      <p class="text-muted">#request.exception.cause.message#</p>

      <h4>Detail:</h4>
      <p class="text-muted">#request.exception.cause.detail#</p>

      <cfif structKeyExists( request.exception, "TagContext" ) and
            isArray( request.exception.TagContext ) and
            arrayLen( request.exception.TagContext ) and
            isStruct( request.exception.TagContext[1] ) and
            structKeyExists( request.exception.TagContext[1], "template" ) and
            structKeyExists( request.exception.TagContext[1], "line" ) and
            isSimpleValue( request.exception.TagContext[1].template ) and
            isSimpleValue( request.exception.TagContext[1].line ) and
            len( trim( request.exception.TagContext[1].template )) and
            len( trim( request.exception.TagContext[1].line ))>
        <h4>File:</h4>
        <p class="text-muted">#request.exception.TagContext[1].template# at line #request.exception.TagContext[1].line#</p>
      </cfif>
    </div>

    <cfdump var="#request.exception#" />
  </div>
</cfoutput>