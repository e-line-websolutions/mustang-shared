<cfparam name="local.name" default="" />
<cfparam name="local.boxes" type="array" default="#[]#" />
<cfparam name="local.checked" default="" />
<cfparam name="local.firstLayer" default="true" />

<cfset local.collapseID = "" />
<cfset local.collapsed = true />

<cfif local.firstLayer><div class="panel panel-default"></cfif>

<cfloop array="#local.boxes#" index="local.box">
  <cfset local.collapseID = createUUID() />

  <cfif arrayLen( local.box.getChildren())>
    <cfset local.collapsed = true />
    <cfloop array="#local.box.getChildren()#" index="child">
      <cfif listFindNoCase( local.checked, child.getID() )>
        <cfset local.collapsed = false />
        <cfbreak />
      </cfif>
    </cfloop>

    <cfset local.viewOptions = {
      name = name,
      boxes = local.box.getChildren(),
      checked = local.checked,
      firstLayer = false
    } />

    <cfoutput>
      <div class="panel-heading">
        <h4 class="panel-title">
          <a data-toggle="collapse" href="###local.collapseID#"><span><i class="fa fa-caret-#local.collapsed?'right':'down'#"></i></span>#local.box.getName()#</a>
        </h4>
      </div>
      <div id="#local.collapseID#" class="panel-collapse collapse#!local.collapsed?' in':''#">
        <div class="panel-body">#view( 'form/edit/recursive-checkbox', local.viewOptions )#</div>
      </div>
    </cfoutput>
  <cfelseif local.firstLayer>
    <cfoutput>
      <div class="panel-heading">
        <h4 class="panel-title">
          <div class="checkbox">
            <label><input type="checkbox" name="#name#" value="#local.box.getID()#"#listFindNoCase( local.checked, local.box.getID())?' checked="checked"':''##local.box.getEnterFreeText()?' class="enterfreetext"':''#>#local.box.getName()#</label>
          </div>
        </h4>
      </div>
    </cfoutput>
  <cfelse>
    <cfoutput>
      <div class="checkbox">
        <label><input type="checkbox" name="#name#" value="#local.box.getID()#"#listFindNoCase( local.checked, local.box.getID())?' checked="checked"':''##local.box.getEnterFreeText()?' class="enterfreetext"':''#>#local.box.getName()#</label>
      </div>
    </cfoutput>
  </cfif>
</cfloop>

<cfif local.firstLayer></div></cfif>