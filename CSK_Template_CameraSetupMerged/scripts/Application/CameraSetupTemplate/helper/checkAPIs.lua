---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

-- Load all relevant APIs for this module
--**************************************************************************

local availableAPIs = {}

local function loadAPIs()
  CSK_CameraSetupTemplate = require 'API.CSK_CameraSetupTemplate'

  Command = {}
  Command.Scan = require 'API.Command.Scan'
  Command.Scan.DeviceInfo = require 'API.Command.Scan.DeviceInfo'
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
  Parameters = require 'API.Parameters'
  Timer = require 'API.Timer'
  View = require 'API.View'

  CSK_Logger = require 'API.CSK_Logger'
  CSK_DeviceScanner = require 'API.CSK_DeviceScanner'
  CSK_MultiRemoteCamera = require 'API.CSK_MultiRemoteCamera'
  CSK_PowerManager = require 'API.CSK_PowerManager'
  CSK_PersistentData = require 'API.CSK_PersistentData'

end

local function loadPower()
  -- If you want to check for specific APIs/functions supported on the device the module is running, place relevant APIs here
  -- e.g.:
  if not Connector then
    Connector = {}
  end
  Connector.Power = require 'API.Connector.Power'
end

local function loadImageProvder()
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
availableAPIs.power = xpcall(loadPower, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.imageProvider = xpcall(loadImageProvder, debug.traceback) -- TRUE if all specific APIs were loaded correctly
availableAPIs.I2D = xpcall(loadI2DSpecificAPIs, debug.traceback) -- TRUE if all I2D specific APIs were loaded correctly
availableAPIs.GigEVision = xpcall(loadGigEVisionSpecificAPIs, debug.traceback) -- TRUE if all GigE Vision specific APIs were loaded correctly

return availableAPIs
--**************************************************************************