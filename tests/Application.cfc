component {
  this.name = "mustangSharedTests";
  this.rootDir = getDirectoryFromPath( getCurrentTemplatePath());
  this.mappings = {
    "/tests" = this.rootDir,
    "/testbox" = this.rootDir & "../../testbox",
    "/services" = this.rootDir & "../services"
  };
}