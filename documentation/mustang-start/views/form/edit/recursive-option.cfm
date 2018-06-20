<cfparam name="local.options" type="array" default="#[]#" />
<cfparam name="local.selected" default="" />
<cfparam name="local.hideChooseOption" default="false" />

<cfoutput>
  <cfif not local.hideChooseOption>
    <option value="">#i18n.translate( 'choose' )#</option>
  </cfif>

  <cfloop array="#local.options#" index="local.option">
    <cfset local.viewOptions = { options = local.option.getChildren(), selected = local.selected, hideChooseOption = true } />

    <cfif arrayLen( local.option.getChildren())>
      <optgroup label="#local.option.getName()#">#view( "form/edit/recursive-option", local.viewOptions )#</optgroup>
    <cfelse>
      <option value="#local.option.getID()#"#local.selected eq local.option.getID()?' selected="selected"':''##local.option.getEnterFreeText()?' class="enterfreetext"':''#>#local.option.getName()#</option>
    </cfif>
  </cfloop>
</cfoutput>