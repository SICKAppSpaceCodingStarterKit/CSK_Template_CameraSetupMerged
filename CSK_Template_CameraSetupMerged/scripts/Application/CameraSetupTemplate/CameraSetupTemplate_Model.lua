---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_CameraSetupTemplate'

local cameraSetupTemplate_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
cameraSetupTemplate_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
cameraSetupTemplate_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
cameraSetupTemplate_Model.parametersName = 'CSK_CameraSetupTemplate_Parameter' -- name of parameter dataset to be used for this module
cameraSetupTemplate_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the CameraSetupTemplate_Model interface and give access
-- to the CameraSetupTemplate_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setCameraSetupTemplate_ModelHandle = require('Application/CameraSetupTemplate/CameraSetupTemplate_Controller')
setCameraSetupTemplate_ModelHandle(cameraSetupTemplate_Model)

--Loading helper functions if needed
cameraSetupTemplate_Model.helperFuncs = require('Application/CameraSetupTemplate/helper/funcs')

cameraSetupTemplate_Model.viewer1 = View.create('viewer1') -- Viewer to show image of camera1 on application UI
cameraSetupTemplate_Model.viewer2 = View.create('viewer2') -- Viewer to show image of camera2 on application UI

cameraSetupTemplate_Model.cameraSetupStatus = false -- Status if currently waiting for camera setup / bootUp

cameraSetupTemplate_Model.tmrPowerSetup = Timer.create()
cameraSetupTemplate_Model.tmrPowerSetup:setExpirationTime(10000)
cameraSetupTemplate_Model.tmrPowerSetup:setPeriodic(false)

-- Parameters to be saved permanently if wanted
cameraSetupTemplate_Model.parameters = {}

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to handle images from camera1 of MultiRemoteCamera CSK module
---@param image Image The image captured by the sensor.
local function handleOnNewImageCamera1(image)
  _G.logger:info(nameOfModule .. ': Received new image camera1')
  cameraSetupTemplate_Model.viewer1:addImage(image)
  cameraSetupTemplate_Model.viewer1:present()
end

--- Function to handle images from camera2 of MultiRemoteCamera CSK module
---@param image Image The image captured by the sensor.
local function handleOnNewImageCamera2(image)
  _G.logger:info(nameOfModule .. ': Received new image camera2')
  cameraSetupTemplate_Model.viewer2:addImage(image)
  cameraSetupTemplate_Model.viewer2:present()
end

--- Function to configure camera setup
local function setupDefaultCameraConfig()

  -- Camera setting of camera1
  CSK_MultiRemoteCamera.setSelectedCam(1)
  CSK_MultiRemoteCamera.setCameraIP('192.168.1.100')
  CSK_MultiRemoteCamera.setProcessingMode('BOTH')
  CSK_MultiRemoteCamera.setAcquisitionMode('FIXED_FREQUENCY')
  CSK_MultiRemoteCamera.connectCamera()

  -- Add another camera instance
  CSK_MultiRemoteCamera.addInstance()

  -- Camera setting of camera2
  CSK_MultiRemoteCamera.setSelectedCam(2)
  CSK_MultiRemoteCamera.setCameraIP('192.168.2.100')
  CSK_MultiRemoteCamera.setProcessingMode('BOTH')
  CSK_MultiRemoteCamera.setAcquisitionMode('FIXED_FREQUENCY')
  CSK_MultiRemoteCamera.connectCamera()

  Script.register("CSK_MultiRemoteCamera.OnNewImageCamera1", handleOnNewImageCamera1)
  Script.register("CSK_MultiRemoteCamera.OnNewImageCamera2", handleOnNewImageCamera2)

  cameraSetupTemplate_Model.cameraSetupStatus = false
  Script.notifyEvent("CameraSetupTemplate_OnNewStatusWaitingForSetup", false)
end
Timer.register(cameraSetupTemplate_Model.tmrPowerSetup, 'OnExpired', setupDefaultCameraConfig) -- Register on timer

--- Function to setup default power configuration and trigger camera setup
local function setupDefaultConfig()
  _G.logger:info(nameOfModule .. ": Setup default config")
  cameraSetupTemplate_Model.cameraSetupStatus = true
  Script.notifyEvent("CameraSetupTemplate_OnNewStatusWaitingForSetup", true)

  if _G.availableAPIs.power then

    local powerStatus = CSK_PowerManager.getCurrentPortStatus('S1')
    if not powerStatus then
      CSK_PowerManager.changeStatusOfPort('S1')
    end
    powerStatus = CSK_PowerManager.getCurrentPortStatus('S2')
    if not powerStatus then
      CSK_PowerManager.changeStatusOfPort('S2')
    end
    CSK_PowerManager.setAllStatus()

    _G.logger:info(nameOfModule .. ": Wait 10 seconds to power the camera.")
    cameraSetupTemplate_Model.tmrPowerSetup:start()

  else

    setupDefaultCameraConfig()
  end

end
cameraSetupTemplate_Model.setupDefaultConfig = setupDefaultConfig

--*************************************************************************
--********************** End Function Scope *******************************
--*************************************************************************

return cameraSetupTemplate_Model
