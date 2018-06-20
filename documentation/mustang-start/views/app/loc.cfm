<div class="centercenter">
  <div class="col-lg-offset-4 col-lg-4">
    <table class="table">
      <thead>
        <tr>
          <th>Type</th>
          <th>Lines</th>
        </tr>
      </thead>

      <tbody>
        <cfset local.total = 0 />
        <cfloop array="#structSort( rc.files, 'numeric', 'desc' )#" index="key">
          <cfoutput>
            <tr>
              <td>#key#</td>
              <td>#rc.files[key]#</td>
            </tr>
          </cfoutput>
          <cfset local.total += rc.files[key] />
        </cfloop>

        <tr>
          <th>Total</th>
          <td><cfoutput>#local.total#</cfoutput></td>
        </tr>
      </tbody>
    </table>

    <table class="table">
      <thead>
        <tr>
          <th>Date</th>
          <th>File</th>
        </tr>
      </thead>

      <tbody>
        <cfloop query="rc.lastmod">
          <tr>
            <th><small class="text-muted"><cfoutput>#lsDateFormat( datelastmodified, 'dd/mm' )#<br>#lsTimeFormat( datelastmodified, 'HH:mm' )#</cfoutput></small></th>
            <td><cfoutput><span class="text-muted">#directory#\</span><b>#name#</b></cfoutput></td>
          </tr>
        </cfloop>
      </tbody>
    </table>
  </div>
  <div class="clearfix"></div>
</div>