component extends="root.orm.beans.logged"
          persistent=true
          joinColumn="id"
           {
  property name="title" length=128 inform=true orderinform=2 editable=true;
  property name="body" ORMType="text" inform=true editable=true;
  property name="locale" fieldType="many-to-one" cfc="root.orm.beans.locale" FKColumn="localeid";

  public string function getName() {
    return getTitle();
  }
}