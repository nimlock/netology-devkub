
// this file returns the params for the current qbec environment
// you need to add an entry here every time you add a new environment.

local env = std.extVar('qbec.io/env');
local paramsMap = {
  _: import './environments/base.libsonnet',
  stage: import './environments/stage.libsonnet',
  production: import './environments/production.libsonnet',
};

if std.objectHas(paramsMap, env) then paramsMap[env] else error 'environment ' + env + ' not defined in ' + std.thisFile
