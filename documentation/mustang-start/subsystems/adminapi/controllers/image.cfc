<cfcomponent extends="apibase">
  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="browse">
    <cfargument name="rc" />

    <cfdirectory action="list" directory="#request.fileUploads#/temp/" name="rc.data" filter="*.jpg|*.jpeg|*.png" />
  </cffunction>

  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="upload">
    <cfargument name="rc" />

    <cffile action="upload" fileField="form.file" destination="#request.fileUploads#/temp/" nameConflict="MAKEUNIQUE" />

    <cfset rc.result = cffile.serverFile />
  </cffunction>
</cfcomponent>