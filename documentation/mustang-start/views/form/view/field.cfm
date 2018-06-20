<cfprocessingdirective pageEncoding="utf-8" />

<cfparam name="local.namePrepend" default="" />
<cfparam name="local.column" default="#{}#" />
<cfparam name="local.column.name" default="" />
<cfparam name="local.inlist" default=false />

<cfif isNull( local.column ) or not isStruct( local.column ) or not structCount( local.column )><cfexit /></cfif>

<cfif isNull( local.val )>
  <cfif isNull( local.data )><cfexit /></cfif>
  <cfset local.val = evaluate( 'local.data.get#local.column.name#()' ) />

  <cfif structKeyExists( local.data, "displayName" )>
    <cfset local.val = local.data.getDisplayName() />
  </cfif>

  <cfif structKeyExists( local.column, "data" ) and
        isStruct( local.column.data ) and
        structKeyExists( local.column.data, "fieldType" ) and
        structKeyExists( local.column.data, "saved" ) and
        structKeyExists( local.column.data, "entityName" ) and
        isSimpleValue( local.column.data.fieldType ) and
        isSimpleValue( local.column.data.saved ) and
        isSimpleValue( local.column.data.entityName ) and
        len( trim( local.column.data.fieldType )) and
        len( trim( local.column.data.saved )) and
        len( trim( local.column.data.entityName ))>
    <cfswitch expression="#local.column.data.fieldType#">
      <cfcase value="many-to-one">
        <cfset local.val = entityLoadByPK( local.column.data.entityName, local.column.data.saved ) />
      </cfcase>
    </cfswitch>
  </cfif>
</cfif>

<cfoutput>
  <cfif not isNull( local.val )>
    <div#inlist?'':' class="form-control-static"'#>
      <cfif structKeyExists( local.column.data, "type" ) and listFindNoCase( "bit,boolean", local.column.data.type )>
        <cfif isBoolean( local.val ) and local.val>
          <i class="fa fa-check"></i>
        </cfif>

      <!--- column --->
      <cfelseif isSimpleValue( local.val )>
        <cfif structKeyExists( local.column.data, "listmask" )>
          <cfset local.val = replaceNoCase( local.column.data.listmask, '{val}', local.val, 'all' ) />
        </cfif>

        <cfif structKeyExists( local.column.data, "translateOptions" )>
          <cfset local.val = i18n.translate( local.val ) />
        </cfif>

        <cfif (
                structKeyExists( local.column, "dataType" ) and
                local.column.dataType eq "json"
              )
              or
              (
                structKeyExists( local.column, "data" ) and
                isStruct( local.column.data ) and
                structKeyExists( local.column.data, "dataType" ) and
                local.column.data.dataType eq "json"
              )>
          <pre class="prettyprint">#htmlEditFormat( local.val )#</pre>
        <cfelseif
          structKeyExists( local.column, "data" ) and
          isStruct( local.column.data ) and
          structKeyExists( local.column.data, "ORMType" ) and
          local.column.data.ORMType eq "boolean"
        >
          #i18n.translate( local.val & '-' & local.column.name )#
        <cfelseif
          structKeyExists( local.column, "data" ) and
          isStruct( local.column.data ) and (
            ( structKeyExists( local.column.data, "ORMType" ) and local.column.data.ORMType eq "float" ) or
            ( structKeyExists( local.column.data, "type" ) and local.column.data.type eq "numeric" )
          )
        >
          #lsNumberFormat( local.val, ',.00' )#
        <cfelseif
          structKeyExists( local.column, "data" ) and
          isStruct( local.column.data ) and
          structKeyExists( local.column.data, "ORMType" ) and
          local.column.data.ORMType eq "string"
        >
          <cfif structKeyExists( local.column.data, "translateOptions" )>
            <cfset local.val = i18n.translate( local.val ) />
          </cfif>
          #local.val#
        <cfelseif isDate( local.val ) and (
            ( structKeyExists( local.column.data, "ORMType" ) and local.column.data.ORMType eq "timestamp" ) or
            ( structKeyExists( local.column.data, "type" ) and (
              local.column.data.type eq "timestamp" or
              local.column.data.type eq "date"
            ) )
          )>

          <cfif year( local.val ) gt 10000>
            #i18n.translate( "infinite" )#
          <cfelse>
            #lsDateFormat( local.val, i18n.translate( 'defaults-dateformat-small' ))#<br />
            #lsTimeFormat( local.val, 'HH:mm:ss' )#
          </cfif>
        <cfelseif structKeyExists( local.column.data, "formfield" ) and
                  local.column.data.formfield eq "file">
          <a href="#buildURL( 'adminapi:crud.download?filename=' & local.val )#">#local.val#</a>
        <cfelse>
          #replace( local.val, '#chr( 13 )##chr( 10 )#', '<br />', 'all' )#
        </cfif>

      <!--- to many --->
      <cfelseif isArray( local.val ) and arrayLen( local.val )>
        #view( 'form/view/to-many', { val = local.val, column=local.column, inlist=local.inlist })#

      <!--- to one --->
      <cfelseif isObject( local.val )>
        #view( 'form/view/to-one', { val=local.val, column=local.column, formElementName=local.namePrepend & local.column.name, inlist=local.inlist })#

      </cfif>
    </div>
  </cfif>
</cfoutput>