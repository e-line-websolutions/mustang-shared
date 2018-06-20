component persistent=true extends="basecfc.base" table="option"  discriminatorColumn="type" {
  property name="name" type="string" length=128 inlist=true;
  property name="deleted" type="boolean" ORMType="boolean" default=false inapi=false;
  property name="sortorder" type="numeric" ORMType="integer" default=0;

  property persistent=false name="type" inlist=true;
  property persistent=false name="sourcecolumn" inlist=true;

  function getType() {
    return variables.instance.meta.discriminatorValue;
  }
}