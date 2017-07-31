<cfparam name="attributes.dsn" />
<cfparam name="attributes.tempTable" default="tmpID" />
<cfparam name="attributes.IDlist" default="" />
<cfparam name="attributes.fk" default="" />

<cfset thisTag.batch = 200 />

<!--- delete temp table runs on both start en end of this customtag: --->
<cfquery datasource="#attributes.dsn#">
  IF OBJECT_ID( 'tempdb..###attributes.tempTable#' ) IS NOT NULL
    BEGIN DROP TABLE ###attributes.tempTable#
  END;
</cfquery>

<cfif thisTag.executionMode eq "start">
  <cfset attributes.IDlist = listToArray( attributes.IDlist ) />
  <cfset thisTag.lenOfList = arrayLen( attributes.IDlist ) />

  <cfquery datasource="#attributes.dsn#">
    CREATE TABLE ###attributes.tempTable# (
      idfield int PRIMARY KEY
      <cfif len( trim( attributes.fk )) and listLen( attributes.fk, "." ) eq 2>
        FOREIGN KEY ( idfield ) REFERENCES #listFirst( attributes.fk, "." )# ( #listLast( attributes.fk, "." )# )
      </cfif>
    );
  </cfquery>

  <cfloop from="1" to="#ceiling( thisTag.lenOfList / thisTag.batch )#" index="thisTag.batchNr">
    <cfset thisTag.startAt = (thisTag.batchNr-1)*thisTag.batch+1 />
    <cfquery datasource="#attributes.dsn#">
      <cfloop from="#thisTag.startAt#" to="#min( thisTag.lenOfList, ( thisTag.startAt - 1 ) + thisTag.batch )#" index="thisTag.row">
        INSERT INTO ###attributes.tempTable# ( idfield ) VALUES ( #attributes.IDlist[thisTag.row]# );
      </cfloop>
    </cfquery>
  </cfloop>
</cfif>