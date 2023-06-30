---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- Load all relevant APIs for this module
--**************************************************************************

local availableAPIs = {}

local function loadAPIs()

  CSK_MultiRemoteCamera = require 'API.CSK_MultiRemoteCamera'

  Container = require 'API.Container'
  DateTime = require 'API.DateTime'
  Engine = require 'API.Engine'
  Ethernet = require 'API.Ethernet'
  File = require 'API.File'
  Flow = require 'API.Flow'
  Image = require 'API.Image'
  Log = require 'API.Log'
  Log.Handler = require 'API.Log.Handler'
  Log.SharedLogger = require 'API.Log.SharedLogger'
  Object = require 'API.Object'
  Timer = require 'API.Timer'
  View = require 'API.View'

  -- Check if related CSK modules are available to be used
  local appList = Engine.listApps()
  for i = 1, #appList do
    if appList[i] == 'CSK_Module_PersistentData' then
      CSK_PersistentData = require 'API.CSK_PersistentData'
    elseif appList[i] == 'CSK_Module_UserManagement' then
      CSK_UserManagement = require 'API.CSK_UserManagement'
    end
  end
end

local function loadSpecificAPIs()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  Image.Provider = {}
  Image.Provider.RemoteCamera = require 'API.Image.Provider.RemoteCamera'
end

local function loadI2DSpecificAPIs()
  Image.Provider.RemoteCamera.I2DConfig = require 'API.Image.Provider.RemoteCamera.I2DConfig'
end

local function loadGigEVisionSpecificAPIs()
  Image.Provider.RemoteCamera.GigEVisionConfig = require 'API.Image.Provider.RemoteCamera.GigEVisionConfig'
end

availableAPIs.default = xpcall(loadAPIs, debug.traceback) -- TRUE if all default APIs were loaded correctly
availableAPIs.imageProvider = xpcall(loadSpecificAPIs, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.I2D = xpcall(loadI2DSpecificAPIs, debug.traceback) -- TRUE if all I2D specific APIs were loaded correctly
availableAPIs.GigEVision = xpcall(loadGigEVisionSpecificAPIs, debug.traceback) -- TRUE if all GigE Vision specific APIs were loaded correctly

return availableAPIs
--**************************************************************************