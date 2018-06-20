component extends="apibase"
{
  public function load( rc )
  {
    param name="rc.entity";
    param name="rc.id" default="null";

    var selection = {
      "parent" = entityLoadByPK( rc.entity, rc.id ),
      "deleted" = false
    };

    var items = entityLoad( rc.entity, selection );

    var result = {
      "data" = []
    };

    for( var item in items )
    {
      arrayAppend( result.data, {
        "text" = item.getName(),
        "type" = "folder",
        "attr" = {
          "id" = item.getID(),
          "hasChildren" = item.hasChild(),
          "data-editurl" = fw.buildURL( ":#rc.entity#.edit?#rc.entity#id=#item.getID()#" ),
          "data-addurl" = fw.buildURL( ":#rc.entity#.new?parent=#item.getID()#" ),
          "data-removeurl" = fw.buildURL( ":#rc.entity#.delete?#rc.entity#id=#item.getID()#" )
        }
      });
    }

    returnAsJSON( result );
  }
}