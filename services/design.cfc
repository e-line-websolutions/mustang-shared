<cfcomponent>
  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="init">
    <cfreturn this />
  </cffunction>

  <!--- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ --->
  <cffunction name="load">
    <cfset var tempColor = "" />
    <cfset var design = {
      "logo"    = "",
      "font"    = {
        "family" = "",
        "size" = "",
        "color" = ""
      },
      "colors"  = [
        "##052D57",
        "##5196E0",
        "##6781A4",
        "##D98876",
        "##DC3725"
      ]
    } />

    <cfreturn design />
  </cffunction>
</cfcomponent>