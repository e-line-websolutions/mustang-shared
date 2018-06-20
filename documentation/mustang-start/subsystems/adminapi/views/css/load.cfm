<cfoutput>
<cfif structKeyExists( request.design, "font" )>
  body{
    <cfif len( trim( request.design["font"]["family"] ))>font-family : #request.design["font"]["family"]#;</cfif>
    <cfif len( trim( request.design["font"]["size"] ))>font-size : #request.design["font"]["size"]#;</cfif>
    <cfif len( trim( request.design["font"]["color"] ))>color : #request.design["font"]["color"]#;</cfif>
  }
<cfelse>
  body{
    font-family: Helvetica Neue, Helvetica, Arial, sans-serif;
    font-size:16px;
  }
</cfif>

<cfloop from="1" to="#arrayLen(request.design.colors)#" index="local.i">
  .color#local.i#{ color: #request.design.colors[local.i]# !important }
  .bgcolor#local.i#{ background-color: #request.design.colors[local.i]# !important }
</cfloop>
.btn-default{
  background-color:#request.design.colors[1]#;
  border-color:#request.design.colors[2]#;
  color:white;
}
.btn-default .caret{
  border-top-color:white;
}
.btn-default:hover,.btn-default:active,.btn-default:visited{
  background-color:#request.design.colors[2]#;
  border-color:#request.design.colors[1]#;
  color:white;
}
.tooltip-inner{
  background-color:#request.design.colors[1]#;
  max-width:250px;
}
.tooltip.bottom .tooltip-arrow{
  border-bottom-color:#request.design.colors[1]#;
}
a:hover{
  color:#request.design.colors[1]#
}
</cfoutput>