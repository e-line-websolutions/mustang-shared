<cfoutput>
  <form class="form-inline">

    <label for="filterScenario">Scenario</label>  <input type="text" class="form-control" id="filterScenario">

    <label for="filterDate">Date Range</label>

    <div class="input-group date datepicker">
      <input class="form-control" size="16" type="text" value="" name="date-from">
      <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
    </div>

    <div class="input-group date datepicker">
      <input class="form-control" size="16" type="text" value="" name="date-to">
      <span class="input-group-addon"><i class="fa fa-calendar"></i></span>
    </div>

    <label for="filterErrors">Errors Only</label>     <input type="checkbox" class="form-control" id="filterErrors">

    <button type="submit" class="btn btn-primary pull-right">Filter</button>
  </form>
</cfoutput>