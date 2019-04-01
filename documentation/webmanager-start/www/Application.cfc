component extends="mustang.webmanager" {
  request.appName = "CAVA-Website" & ( variables.cfg.appIsLive ? "" : "-dev" );
  request.domainName = "cava.cloud";
  request.version = "1.0-r" & reReplace( "$Revision: 1 $", "\D", "", "all" );

  variables.mstng.mergeStructs( {
    "websiteId" = 443,
    "navigationType" = "full",
    "imageSizes" = {
      "l" = [ 1280, 1280 ],
      "m" = [ 512, 512 ],
      "s" = [ 64, 64 ],
      "x" = [ 2000, 2000]
    },
    "config" = {
      "cacheTimeout" = {
        "short" = createTimeSpan( 0, 0, 0, 30 ),
        "medium" = createTimeSpan( 0, 0, 15, 0 ),
        "long" = createTimeSpan( 0, 4, 0, 0 ),
        "coldStorage" = createTimeSpan( 14, 0, 0, 0 )
      }
      // , "useSsl" = ( right( cgi.server_name, len( request.domainName ) ) == request.domainName )
    }
  }, variables.framework.diConfig.constants );

  arrayAppend( variables.framework.diLocations, "/root/model" );

  variables.framework.diConfig.transients = [ "scenarios", "vendors", "perfectview" ];

  param variables.framework.diConfig.exclude=[];

  arrayAppend( variables.framework.diConfig.exclude, "/model/abstracts" );
}
