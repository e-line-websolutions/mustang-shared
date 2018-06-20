<cfcomponent extends="apibase">
  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="validate">
    <cfargument name="rc" />

    <cfset request.layout = false />

    <cfset var result = { "valid" = false, "message" = "Invalid/missing arguments" } />

    <cfif structKeyExists( rc, "entityName" ) and
          structKeyExists( rc, "propertyName" ) and
          structKeyExists( rc, "value" )>
      <cfset local.entity = entityNew( "#rc.entityName#" ) />
      <cfset local.properties = local.entity.getInheritedProperties() />

      <cfif structKeyExists( local.properties, rc.propertyName ) and
            structKeyExists( local.properties[rc.propertyName], "requirement" )>
        <cfset local.requirement = local.properties[rc.propertyName].requirement />

        <cfset result.message = rc.i18n.translate( rc.entityName & '-' & rc.propertyName & '-' & local.requirement & '-message' ) />

        <cfswitch expression="#local.requirement#">
          <cfcase value="unique">
            <cfquery dbtype="hql" name="local.testRequirement" ormoptions="#{cacheable=true}#">
              FROM    #rc.entityName# e
              WHERE   ( e.deleted IS NULL OR e.deleted = FALSE )
                AND   #rc.propertyName# = <cfqueryparam value="#trim( urlDecode( rc.value ))#" />
            </cfquery>

            <cfif structKeyExists( rc, "entityID" ) and
                  len( trim( rc.entityID )) and
                  arrayLen( local.testRequirement ) eq 1 and
                  local.testRequirement[1].getID() eq rc.entityID>
              <cfset result.valid = true />
              <cfset result.message = "ID found: (#rc.entityID#)" />
            <cfelse>
              <cfset result.valid = ( arrayLen( local.testRequirement ) eq 0 ) />
            </cfif>

          </cfcase>
        </cfswitch>
      </cfif>
    </cfif>

    <cfset returnAsJSON( result ) />
  </cffunction>

  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="upload">
    <cfargument name="rc" />

    <cfset request.layout = false />

    <cffile action="upload" fileField="form.files[]" destination="#request.fileUploads#/temp/" nameConflict="makeUnique" />

    <cfset returnAsJSON({ "files" = [{ "name" = cffile.serverFile }]}) />
  </cffunction>

  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="download">
    <cfargument name="rc" />

    <cfset request.layout = false />

    <cfparam name="rc.filename" default="" />
    <cfparam name="rc.disposition" default="attachment" />

    <cfif not len( trim( rc.filename ))>
      <cfthrow message="Missing file name" />
    </cfif>

    <cfset var filePath = "#request.fileUploads#/temp/#rc.filename#" />

    <cfif not fileExists( filePath )>
      <cfthrow message="File does not exist" />
    </cfif>

    <cfset var Files = createObject( "java", "java.nio.file.Files" ) />
    <cfset var Paths = createObject( "java", "java.nio.file.Paths" ) />
    <cfset var URI = createObject( "java", "java.net.URI" ) />
    <cfset var mime = Files.probeContentType( Paths.get( URI.init( "File:///" & replace( filePath, '\', '/', 'all' )))) />

    <cfheader name="content-disposition" value="#rc.disposition#; filename=#rc.filename#">
    <cfcontent type="#mime#" file="#filePath#" reset="true" />
    <cfabort />
  </cffunction>

  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="displayInlineEditLine">
    <cfargument name="rc" />

    <cfset request.layout = false />
    <cfsetting showdebugoutput="false" />

    <cfparam name="rc.entityName" />
    <cfparam name="rc.formdata" />

    <cfset rc.entity = entityNew( "#rc.entityName#" ) />

    <cfif len( trim( rc.formdata )) and isJSON( rc.formdata )>
      <cfset local.formdata = deserializeJSON( rc.formdata ) />
      <cfif isStruct( local.formdata )>
        <cfloop collection="#local.formdata#" item="key">
          <cftry>
            <cfset evaluate( "rc.entity.set#key#('#local.formdata[key]#')" ) />
            <cfcatch></cfcatch>
          </cftry>
        </cfloop>
      </cfif>
    </cfif>
  </cffunction>
</cfcomponent>