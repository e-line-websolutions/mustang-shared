<cfscript>
  param input.groupId="";
  param input.documentId="";
  param input.documentName="";
  param input.formData="";

  for ( var key in input.formData ) {
    if ( compareNoCase( left( tmp_currentAttribute, 9 ), 'DOCDBFLD_' ) != 0 ) {
      structDelete( input.formData, key );
    }
  }
</cfscript>

<cfif not isNumeric( input.groupId ) or input.groupId lte 0>
  <cfthrow message="Error: missing attribute: <strong>groupId</strong>">
</cfif>

<cfif len( trim( input.documentName ) ) eq 0 and val( input.documentId ) lte 0>
  <cfthrow message="Error: missing attribute: <strong>documentName</strong>">
</cfif>

<cftransaction action="BEGIN" isolation="SERIALIZABLE">
  <cftry>
    <cfif not isNumeric( input.documentId ) or input.documentId lte 0>
      <cfquery dataSource="#ds#" name="docdb.qry_insert_document">
        DECLARE @nProductID INT
        SET @nProductID = ( SELECT ISNULL( MAX( product_nID ), 0 ) + 1 FROM tbl_product )

        INSERT INTO tbl_product (
          product_nID,
          product_sNaam,
          product_x_nGroepID,
          product_nBwsID,
          Product_nClickCount
        ) VALUES (
          @nProductID,
          <cfqueryparam cfsqltype="cf_sql_varchar" value="#input.documentName#">,
          <cfqueryparam cfsqltype="cf_sql_integer" value="#input.groupId#">,
          <cfqueryparam cfsqltype="cf_sql_integer" value="#variables.websiteId#">,
          0
        )

        SELECT @nProductID AS nProductID
      </cfquery>
      <cfset input.documentId = docdb.qry_insert_document.nProductID />
    </cfif>

    <cfloop collection="#input.formData#" item="docdb.formField">
      <cfquery datasource="#ds#" name="docdb.qry_select_fieldID">
        SELECT    eigenschap_nID,
                  eigenschap_x_nTypeID

        FROM      dbo.tbl_eigenschap

        WHERE     eigenschap_nBwsID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#variables.websiteId#">
          AND     (
                    LOWER( eigenschap_sNaam ) = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#lCase( docdb.formField )#" /> OR
                    dbo.variableFormat( eigenschap_sNaam ) = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#docdb.formField#" />
                  )
      </cfquery>

      <cfscript>
        docdb.nFieldID    = docdb.qry_select_fieldID.Eigenschap_nID;
        docdb.sFieldValue = input.formData[ "docdbfld_#docdb.formField#" ];
      </cfscript>

      <!--- INVOKE FILE UPLOAD MECHANISM FOR FILE FIELDS --->
      <cfif docdb.qry_select_fieldID.eigenschap_x_nTypeID eq 6 and len( trim( docdb.sFieldValue ))>
        <cffile action="upload"
          destination   = "#variables.config.mediaRoot#/sites/site#variables.websiteId#/images/"
          fileField     = "form.docdbfld_#docdb.formField#"
          nameConflict  = "makeUnique"
        />
        <cfset docdb.sFieldValue = cffile.serverFile />
      </cfif>

      <cfif docdb.nFieldID gt 0>
        <cfscript>
          docdb.sFieldName  = 'savedData_sNaam';
          docdb.sFieldType  = "CF_SQL_VARCHAR";
          docdb.nFieldLen   = 250;

          switch ( docdb.qry_select_fieldID.eigenschap_x_nTypeID ) {
            case 1:
            case 2:
            case 3:
            case 7:
              docdb.sFieldName  = "savedData_x_nValueID";
              docdb.sFieldType  = "CF_SQL_INTEGER";
              docdb.nFieldLen   = 128;
              break;
            case 5:
              docdb.sFieldName  = 'savedData_sText';
              docdb.sFieldType  = "CF_SQL_LONGVARCHAR";
              docdb.nFieldLen   = 1073741823;
              break;
            case 14:
              docdb.sFieldName  = 'savedData_dDateTime';
              docdb.sFieldType  = "CF_SQL_TIMESTAMP";
              docdb.nFieldLen   = 128;
              break;
            case 12:
              docdb.sFieldName  = 'savedData_x_nLinkedProductID';
              docdb.sFieldType  = "CF_SQL_INTEGER";
              docdb.nFieldLen   = 128;
              break;
          }
        </cfscript>

        <!---
          Special case: when you provide a value like this: +1 or -15 this
          next piece calculates the value that will be saved:
        --->
        <cfif listFind( '+,-', left( docdb.sFieldValue, 1 )) and listLen( docdb.sFieldValue ) eq 1>
          <cfquery datasource="#ds#" name="qry_check_existingData">
            SELECT    #docdb.sFieldName#

            FROM      dbo.tbl_savedData

            WHERE     savedData_x_nProductID    = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.documentId#" />
              AND     savedData_x_nEigenschapID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.nFieldID#" />
          </cfquery>

          <cfscript>
            docdb.sFieldValue = evaluate( val( qry_check_existingData.SavedData_sNaam ) & docdb.sFieldValue );
          </cfscript>
        </cfif>

        <!--- REMOVE OLD DATA AND INSERT THE NEW: --->
        <cfquery dataSource="#ds#">
          DECLARE @nMaxID INT

          DELETE
          FROM    tbl_SavedData
          WHERE   savedData_x_nEigenschapID = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.nFieldID#" />
            AND   savedData_x_nProductID    = <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.documentId#" />

          <cfloop list="#docdb.sFieldValue#" index="listItem">
            <!--- TAKE CARE OF THE MAXIMUM LENGTH ALLOWED BY THE DATABASE --->
            <cfscript>
              save_value = listItem;
              null = false;

              if( listFindNoCase( "CF_SQL_LONGVARCHAR,CF_SQL_VARCHAR", docdb.sFieldType ))
              {
                save_value = replace( left( save_value, docdb.nFieldLen ), ',', chr( 0182 ), 'all' );

                if( not len( trim( save_value )))
                  null = true;
              }

              if( listFindNoCase( "CF_SQL_INTEGER", docdb.sFieldType ))
              {
                save_value = val( save_value );
                if( save_value eq 0 )
                  null = true;
              }
            </cfscript>

            SET @nMaxID = ( SELECT ISNULL( MAX( savedData_nID ), 0 ) + 1 AS nMaxID FROM tbl_SavedData )

            INSERT INTO tbl_SavedData (
              savedData_nID,
              #docdb.sFieldName#,
              savedData_x_nProductID,
              savedData_x_nEigenschapID
            ) VALUES (
              @nMaxID,
              <cfqueryparam CFSQLType="#docdb.sFieldType#" value="#save_value#" maxLength="#docdb.nFieldLen#" null="#null#" />,
              <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#input.documentId#" />,
              <cfqueryparam CFSQLType="CF_SQL_INTEGER" value="#docdb.nFieldID#" />
            )
          </cfloop>
        </cfquery>
      <cfelse>
        <!--- [mjh] THROW an error, if someone wants to update a field wich doesn't exist --->
        <cfthrow message="Error, no field found by the name of <strong>#docdb.formField#</strong>. Please contact the website administrator.">
      </cfif>
    </cfloop>
    <cftransaction action="commit" />
    <cfcatch>
      <cftransaction action="rollback" />
      <cfdump var="#cfcatch#">
      <cfabort>
    </cfcatch>
  </cftry>
</cftransaction>