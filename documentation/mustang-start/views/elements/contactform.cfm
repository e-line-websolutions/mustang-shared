<cfoutput>
	<form class="form-horizontal form-validator" method="post" action="#buildURL('home:accountant.saveContact')#">
		<input type="hidden" name="returnURL" value="#rc.returnURL#">

		<cfif structKeyExists(rc, 'formfields')>
		  <cfloop array="#structKeyArray(rc.formfields)#" index="local.field">
		    <input type="hidden" name="#local.field#" value="#rc.formfields[local.field]#">
		  </cfloop>
		</cfif>

		<cfif structKeyExists( rc , 'contactID' ) and len(trim( rc.contactID ))>
			<input type="hidden" name="contactID" value="#rc.contactID#">
		</cfif>

    <div class="form-group row">
      <label class="col-sm-4 control-label">#request.i18n.translate( 'security-role' )#</label>
      <div class="col-sm-8">
        <select name="securityrole" class="form-control">
          <option value="#rc.secutiryRoleEntrepreneurSU.getID()#"#isDefined('rc.securityRole') and rc.securityRole.getID() eq rc.secutiryRoleEntrepreneurSU.getID()?' selected':''#>#request.i18n.translate( rc.secutiryRoleEntrepreneurSU.getName() )#</option>
          <option value="#rc.secutiryRoleEntrepreneur.getID()#"#isDefined('rc.securityRole') and rc.securityRole.getID() eq rc.secutiryRoleEntrepreneur.getID()?' selected':''#>#request.i18n.translate( rc.secutiryRoleEntrepreneur.getName() )#</option>
        </select>
      </div>
    </div>

		<cfset local.formfields = [
      ['firstname','text'],
      ['infix','text'],
      ['lastname','text'],
      ['phone_mobile','text'],
      ['function','text'],
      ['email','email'],
      ['username','text'],
      ['password','text'],
      ['photo','file']
		]>

		<cfloop from="1" to="#arrayLen(local.formfields)#" index="local.n">
      <cfset local.fieldname = local.formfields[local.n][1]>
      <cfset local.fieldtype = local.formfields[local.n][2]>

	    <cfif isDefined("rc.contact") and structKeyExists( rc.contactInfo , local.fieldname )>
		    <cfset local.fieldvalue = rc.contactInfo[local.fieldname]>
		  <cfelse>
        <cfset local.fieldvalue = "">
		  </cfif>

	    <cfif ( local.fieldname neq "password" or (local.fieldname eq "password" and not isDefined("rc.contact")) ) and
			      ( local.fieldname neq "username" or (local.fieldname eq "username" and not isDefined("rc.contact")) )>
		    <div class="form-group row">
		      <label class="col-sm-4 control-label">#request.i18n.translate( local.fieldname )#</label>
		      <div class="col-sm-8">
		      	<cfif local.fieldtype eq "file">
							<div class="fileinput">
		            <cfset local.showUploadButton = true />
		            <input type="hidden" name="#local.fieldname#" value="#local.fieldvalue#" />



                <div#local.showUploadButton and not len(trim( local.fieldvalue ))?' class="alert" style=" display:none;"':' class="alert alert-success"'#>
                 <cfif len(trim( local.fieldvalue ))>#local.fieldvalue#</cfif>
                </div>

		            <span role="button" class="btn btn-primary fileinput-button"#local.showUploadButton?'':' style="display:none;"'#>
		              <i class="fa fa-plus"></i>
		              <span>#i18n.translate( "select-file" )#</span>
		              <input type="file" data-name="#local.fieldname#" />
		            </span>

		            <div class="progress" style="margin-top:5px; display:none;">
		              <div class="progress-bar progress-bar-success" role="progressbar" aria-valuemin="0" aria-valuemax="100" style="width: 0%"></div>
		            </div>
		          </div>
						<cfelse>
						  <input type="#local.fieldtype#" name="#local.fieldname#" class="form-control" value="#local.fieldvalue#">
	          </cfif>
		      </div>
		    </div>
        </cfif>
    </cfloop>
	</form>
</cfoutput>