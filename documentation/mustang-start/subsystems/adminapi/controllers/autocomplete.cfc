component extends="apibase"
{
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  public void function search( rc )
  {
    param name="rc.q" default="";
    param name="rc.entity" default="";

    var start = getTickCount();
    var metadata = getMetaData( entityNew( rc.entity ));
    var result = { "results" = [], "status" = "failed", "speed" = 0 };

    if( not structKeyExists( metadata, "table" ) or not len( trim( metadata.table )))
    {
      throw( message="This method needs a table name set on the entity." );
    }

    if( not len( trim( rc.entity )))
    {
      return returnAsJSON( result );
    }

    if( len( trim( rc.q )))
    {
      var qs = new query();
      qs.addParam( name = "name", value = "%#rc.q#%", cfsqltype = "cf_sql_varchar" );
      qs.setSQL( "
        SELECT  *
        FROM    #metadata.table#
        WHERE   NOT data IS NULL
          AND   data <> ''
          AND   CAST(( CAST( data AS json ) ->> 'name' ) AS varchar ) LIKE ( :name )
      " );
      var completed = qs.execute();

      for( var record in completed.getResult())
      {
        var jsondata = deserializeJSON( record.data );
        param name="jsondata.name" default="";
        arrayAppend( result.results, {
          "id"   = record.id,
          "text" = jsondata.name
        });
      }
    }

    result.status = "ok";
    result.speed = getTickCount() - start;

    returnAsJSON( result );
  }
}