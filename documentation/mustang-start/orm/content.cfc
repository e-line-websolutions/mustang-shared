component extends="root.orm.beans.text"
          persistent=true
          joinColumn="id"

          hint="admin texts (like pages) are stored in here"
          defaultSort="fullyqualifiedaction" {
  property name="fullyqualifiedaction"  length=128  orderinform=1   inform=true editable=true inlist=true listmask='<a href="/{val}">{val}</a>' orderinlist=2;
  property name="subtitle"              length=256  orderinform=3   inform=true editable=true;
  property name="excerpt"               length=1024 orderinform=4   inform=true editable=true;
  property name="searchbox"             length=256;
  property name="actionsbox"            length=256;
  property name="htmltitle"             length=64   orderinform=8   inform=true editable=true;
  property name="htmlkeywords"          length=128  orderinform=9   inform=true editable=true;
  property name="htmldescription"       length=128  orderinform=10  inform=true editable=true;
}