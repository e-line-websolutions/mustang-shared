-- App defaults
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '163e80560fd74e7da9abc8b6010fdf8b', 0, 0, 'logaction', 'created',  'success' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '1e1705977890425fac31b5c60285989c', 0, 0, 'logaction', 'changed',  'default' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '249b01edd0ba4cbcade5a29b5e2d649f', 0, 0, 'logaction', 'restored', 'warning' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '469acd910cc442ee805b0cacbac6a851', 0, 0, 'logaction', 'removed',  'danger' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '5c9dae17a7d9828819680b8b4c6c278f', 0, 0, 'logaction', 'security', 'default textmuted' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( 'c4d5177f23ca48bd89f82f85eccb5699', 0, 0, 'logaction', 'init',     'info' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( 'c67bb518600a42fa8445ae815778b4b7', 0, 0, 'logaction', 'saved',    'success' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( '0a929769f23db911626b06c1f21463b4', 0, 0, 'logaction', 'schedule', 'primary' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, cssclass ) VALUES ( 'ba06db51c2a399078723c33490ff0ad6', 0, 0, 'logaction', 'execute',  'primary' );

INSERT INTO [option] ( id, deleted, sortorder, type, name, iso2 ) VALUES ( 'b4083d4de789b82eedf9f6572e4d545f', 0, 0, 'country', 'United States', 'US' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, iso2 ) VALUES ( 'db7d84049a2e0a53b8869ed6e08e4061', 0, 0, 'country', 'Nederland', 'NL' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, iso2 ) VALUES ( '767f71b3a78ba3025cba587f2524c0d8', 0, 0, 'language', 'English', 'en' );
INSERT INTO [option] ( id, deleted, sortorder, type, name, iso2 ) VALUES ( 'db7e77ab93ea58928a27c19d0948a679', 0, 0, 'language', 'Nederlands', 'nl' );

INSERT INTO [locale] ( id, deleted, sortorder, countryid, languageid ) VALUES ( 'b561bea9d004968f0661b5f6b4ff2acb', 0, 0, 'b4083d4de789b82eedf9f6572e4d545f', '767f71b3a78ba3025cba587f2524c0d8' );
INSERT INTO [locale] ( id, deleted, sortorder, countryid, languageid ) VALUES ( 'db8621a2bc18d3acae9833c980bd4492', 0, 0, 'db7d84049a2e0a53b8869ed6e08e4061', 'db7e77ab93ea58928a27c19d0948a679' );

INSERT INTO [securityrole] ( id, deleted, sortorder, name, loginscript, menulist ) VALUES ( 'a4163666f3b00d487aae765738a65c61', 0, 0, 'Administrator', 'main.default', 'contact' );
INSERT INTO [securityrole] ( id, deleted, sortorder, name ) VALUES ( '2b38b810f3edfa73e3706226fb9b8973', 0, 0, 'API User' );

INSERT INTO [permission] ( id, deleted, sortorder, securityroleid, section, [create], [view], change, [delete], [execute] ) VALUES ( '61ebd86e0d681ac04905ff27270d8613', 0, 0, '5a4f0453be530bf7680c5474501a0bcf', 'scenario', 0, 1, 0, 0, 0 );
INSERT INTO [permission] ( id, deleted, sortorder, securityroleid, section, [create], [view], change, [delete], [execute] ) VALUES ( 'a2fd5e91f7027e8ceec7fa1ac2b6a44e', 0, 0, '5a4f0453be530bf7680c5474501a0bcf', 'data', 1, 1, 1, 0, 0 );

INSERT INTO [permission] ( id, deleted, sortorder, securityroleid, section, [create], [view], change, [delete], [execute] ) VALUES ( '2b7a48e80e283f69a84c1696f193c869', 0, 0, '2b38b810f3edfa73e3706226fb9b8973', 'schedule', 0, 0, 0, 0, 1 );
INSERT INTO [permission] ( id, deleted, sortorder, securityroleid, section, [create], [view], change, [delete], [execute] ) VALUES ( '2498e2759f15fa9fca6c611fdb004014', 0, 0, '2b38b810f3edfa73e3706226fb9b8973', 'scenario', 0, 1, 0, 0, 0 );
INSERT INTO [permission] ( id, deleted, sortorder, securityroleid, section, [create], [view], change, [delete], [execute] ) VALUES ( '2499603ee20bbbfceb96b8027d2364e4', 0, 0, '2b38b810f3edfa73e3706226fb9b8973', 'data', 1, 1, 1, 0, 0 );

-- API user
INSERT INTO [metadata] ( id, deleted, sortorder ) VALUES ( '2b519c640c8f56be2e3b7922d688510b', 0, 0 );
INSERT INTO [contact] ( id, username, password, firstname, lastname, email, securityroleid ) VALUES ( '2b519c640c8f56be2e3b7922d688510b', 'api', '$2a$13$hbyXowvorfzmhl6SP0bAm.OkBFJwCwGRwYDmvUVcIcuPDf1hdjA7u', 'API', 'User', 'administrator+api@e-line.nl', '2b38b810f3edfa73e3706226fb9b8973' );

-- Admin user
INSERT INTO [metadata] ( id, deleted, sortorder ) VALUES ( '5a4601870f2dd49665580f275c4310d0', 0, 0 );
INSERT INTO [contact] ( id, username, password, firstname, lastname, email, securityroleid, receiveStatusUpdate ) VALUES ( '5a4601870f2dd49665580f275c4310d0', 'admin', '$2a$13$J4ieC6pzUigrbnL7XRuzEesok.RkSS4nmsey3Trirn80NEl/4t9hm', 'Mingo', 'Hagen', 'mhagen@e-line.nl', 'a4163666f3b00d487aae765738a65c61', 1 );
