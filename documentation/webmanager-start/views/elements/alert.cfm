<cfoutput>
  <cfif structKeyExists( rc, 'alert' )>
    <div id="overlay" class="#structKeyExists( rc, 'alert' ) ? 'display show' : ''#">
      <div id="alert" class="#rc.alert.class#">
        #i18n.translate( rc.alert.text )#<br>
        <a href="" class="button button-arrow close-alert">#i18n.translate( 'close' )#</a>
      </div>
    </div>
  </cfif>
</cfoutput>
