---@diagnostic disable: redundant-parameter, undefined-global

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the multiRemoteCamera_Model and multiRemoteCamera_Instances
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_MultiRemoteCamera'

local funcs = {}

-- Timer to update UI via events after page was loaded
local tmrCamera = Timer.create()
tmrCamera:setExpirationTime(300)
tmrCamera:setPeriodic(false)

-- Timer to monitor camera [optionally]
local tmrMonitorCameras = Timer.create()
tmrMonitorCameras:setExpirationTime(30000)
tmrMonitorCameras:setPeriodic(true)

-- Timer to wait for camera bootUp
local tmrCameraBootUp = Timer.create()
tmrCameraBootUp:setExpirationTime(12000)
tmrCameraBootUp:setPeriodic(false)

local multiRemoteCamera_Model -- Reference to model handle
local multiRemoteCamera_Instances -- Reference to instances handle
local cameraFlow = nil -- Handle for Flow of digital camera trigger, check also Flow within /resources
local selectedInstance = 1 -- Which camera instance is currently selected
local viewerActive = false -- Should images be shown on UI
local bootUpStatus = false -- Is app curently waiting for camera bootUp
local helperFuncs = require('Sensors/MultiRemoteCamera/helper/funcs') -- general helper functions
local json = require('Sensors/MultiRemoteCamera/helper/Json') -- JSON helper functions

-- ************************ UI Events Start ********************************
-- Only to prevent WARNING messages, but these are only examples/placeholders for dynamically created events/functions
----------------------------------------------------------------
Script.serveEvent("CSK_MultiRemoteCamera.OnDeregisterCameraNUM", "MultiRemoteCamera_OnDeregisterCameraNUM")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewImageCameraNUM", "MultiRemoteCamera_OnNewImageCameraNUM")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewValueToForwardNUM", "MultiRemoteCamera_OnNewValueToForwardNUM")
Script.serveEvent("CSK_MultiRemoteCamera.OnRegisterCameraNUM", "MultiRemoteCamera_OnRegisterCameraNUM")
----------------------------------------------------------------

-- Real events
--------------------------------------------------

Script.serveEvent('CSK_MultiRemoteCamera.OnNewStatusWaitingForCameraBootUp', 'MultiRemoteCamera_OnNewStatusWaitingForCameraBootUp')
Script.serveEvent("CSK_MultiRemoteCamera.OnNewCameraList", "MultiRemoteCamera_OnNewCameraList")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewLoggingMessage", "MultiRemoteCamera_OnNewLoggingMessage")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewSelectedCam", "MultiRemoteCamera_OnNewSelectedCam")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewViewerId", "MultiRemoteCamera_OnNewViewerId")
Script.serveEvent("CSK_MultiRemoteCamera.OnCameraConnected", "MultiRemoteCamera_OnCameraConnected")
Script.serveEvent("CSK_MultiRemoteCamera.OnScanCamera", "MultiRemoteCamera_OnScanCamera")
Script.serveEvent("CSK_MultiRemoteCamera.OnCurrentCameraIP", "MultiRemoteCamera_OnCurrentCameraIP")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewIPCheck", "MultiRemoteCamera_OnNewIPCheck")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewStatusViewerActive", "MultiRemoteCamera_OnNewStatusViewerActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionStatus", "MultiRemoteCamera_OnNewGigEVisionStatus")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionParameters", "MultiRemoteCamera_OnNewGigEVisionParameters")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewColorMode", "MultiRemoteCamera_OnNewColorMode")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewShutterTime", "MultiRemoteCamera_OnNewShutterTime")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGain", "MultiRemoteCamera_OnNewGain")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewFramerate", "MultiRemoteCamera_OnNewFramerate")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewResizeFactor", "MultiRemoteCamera_OnNewResizeFactor")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewAcquisitionMode", "MultiRemoteCamera_OnNewAcquisitionMode")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewFOVX", "MultiRemoteCamera_OnNewFOVX")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewFOVY", "MultiRemoteCamera_OnNewFOVY")
Script.serveEvent('CSK_MultiRemoteCamera.OnNewImageSizeToShare', 'MultiRemoteCamera_OnNewImageSizeToShare')
Script.serveEvent("CSK_MultiRemoteCamera.OnSWTriggerActive", "MultiRemoteCamera_OnSWTriggerActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewStatusDigitalTriggerPause", "MultiRemoteCamera_OnNewStatusDigitalTriggerPause")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewHardwareTriggerDelay", "MultiRemoteCamera_OnNewHardwareTriggerDelay")
Script.serveEvent("CSK_MultiRemoteCamera.OnHWTriggerActive", "MultiRemoteCamera_OnHWTriggerActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewImageProcessingParameter", "MultiRemoteCamera_OnNewImageProcessingParameter")
Script.serveEvent("CSK_MultiRemoteCamera.OnPersistentDataModuleAvailable", "MultiRemoteCamera_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewParameterName", "MultiRemoteCamera_OnNewParameterName")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionTableContent", "MultiRemoteCamera_OnNewGigEVisionTableContent")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionConfigTableContent", "MultiRemoteCamera_OnNewGigEVisionConfigTableContent")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionCurrentParameter", "MultiRemoteCamera_OnNewGigEVisionCurrentParameter")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionParameterType", "MultiRemoteCamera_OnNewGigEVisionParameterType")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewGigEVisionValue", "MultiRemoteCamera_OnNewGigEVisionValue")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewImageFilePrefix", "MultiRemoteCamera_OnNewImageFilePrefix")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewSavingImagesPath", "MultiRemoteCamera_OnNewSavingImagesPath")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewImageSaveFormat", "MultiRemoteCamera_OnNewImageSaveFormat")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewFormatCompression", "MultiRemoteCamera_OnNewFormatCompression")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewImageQueueCamera", "MultiRemoteCamera_OnNewImageQueueCamera")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewFPSCamera", "MultiRemoteCamera_OnNewFPSCamera")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewStatusSaveAllImagesActive", "MultiRemoteCamera_OnNewStatusSaveAllImagesActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewStatusTempImageActive", "MultiRemoteCamera_OnNewStatusTempImageActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewStatusLoadParameterOnReboot", "MultiRemoteCamera_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewCameraOverviewTable", "MultiRemoteCamera_OnNewCameraOverviewTable")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewProcessingMode", "MultiRemoteCamera_OnNewProcessingMode")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewSwitchMode", "MultiRemoteCamera_OnNewSwitchMode")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewMonitoring", "MultiRemoteCamera_OnNewMonitoring")
Script.serveEvent("CSK_MultiRemoteCamera.OnNewMonitoringState", "MultiRemoteCamera_OnNewMonitoringState") --for UI
Script.serveEvent("CSK_MultiRemoteCamera.OnNewMonitoringStateCams", "MultiRemoteCamera_OnNewMonitoringStateCams")

Script.serveEvent("CSK_MultiRemoteCamera.OnUserLevelOperatorActive", "MultiRemoteCamera_OnUserLevelOperatorActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnUserLevelMaintenanceActive", "MultiRemoteCamera_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnUserLevelServiceActive", "MultiRemoteCamera_OnUserLevelServiceActive")
Script.serveEvent("CSK_MultiRemoteCamera.OnUserLevelAdminActive", "MultiRemoteCamera_OnUserLevelAdminActive")

Script.serveEvent('CSK_MultiRemoteCamera.OnNewCameraModel', 'MultiRemoteCamera_OnNewCameraModel')
Script.serveEvent('CSK_MultiRemoteCamera.OnNewNumberOfCameras', 'MultiRemoteCamera_OnNewNumberOfCameras')

--************************* UI Events End **********************************
--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

-- Functions to forward logged in user roles via CSK_UserManagement module (if available)
-- ***********************************************
--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("MultiRemoteCamera_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("MultiRemoteCamera_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("MultiRemoteCamera_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("MultiRemoteCamera_OnUserLevelAdminActive", status)
end

-- Function to check for selected camera trigger mode
---@param mode string Trigger mode
local function checkTriggerMode(mode)
  if mode == 'SOFTWARE_TRIGGER' then
    Script.notifyEvent('MultiRemoteCamera_OnHWTriggerActive', false)
    Script.notifyEvent('MultiRemoteCamera_OnSWTriggerActive', true)
  elseif mode == 'HARDWARE_TRIGGER' then
    Script.notifyEvent('MultiRemoteCamera_OnSWTriggerActive', false)
    Script.notifyEvent('MultiRemoteCamera_OnHWTriggerActive', true)
  else
    Script.notifyEvent('MultiRemoteCamera_OnSWTriggerActive', false)
    Script.notifyEvent('MultiRemoteCamera_OnHWTriggerActive', false)
  end
end

--- Function to check if inserted string is a valid IP
---@param ip string String to check for valid IP
---@return boolean status Result if IP is valid
local function checkIP(ip)
  if not ip then return false end
  local a,b,c,d=ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a=tonumber(a)
  b=tonumber(b)
  c=tonumber(c)
  d=tonumber(d)
  if not a or not b or not c or not d then return false end
  if a<0 or 255<a then return false end
  if b<0 or 255<b then return false end
  if c<0 or 255<c then return false end
  if d<0 or 255<d then return false end
  return true
end

--- Function to forward data updates from instance threads to Controller part of module
---@param eventname string Eventname to use to forward value
---@param value auto Value to forward
local function handleOnNewValueToForward(eventname, value)
  Script.notifyEvent(eventname, value)
end

--- Function to get access to the multiRemoteCamera_Model
---@param handle handle Handle of multiRemoteCamera_Model object
local function setMultiRemoteCamera_Model_Handle(handle)
  multiRemoteCamera_Model = handle
  Script.releaseObject(handle)
end
funcs.setMultiRemoteCamera_Model_Handle = setMultiRemoteCamera_Model_Handle

--- Function to get access to the multiRemoteCamera_Instances
---@param handle handle Handle of multiRemoteCamera_Instances object
local function setMultiRemoteCamera_Instances_Handle(handle)
  multiRemoteCamera_Instances = handle
  if multiRemoteCamera_Instances[selectedInstance].userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)

  for i = 1, #multiRemoteCamera_Instances do
    Script.register("CSK_MultiRemoteCamera.OnNewValueToForward" .. tostring(i) , handleOnNewValueToForward)
  end

end
funcs.setMultiRemoteCamera_Instances_Handle = setMultiRemoteCamera_Instances_Handle

--- Function to send all relevant values to CamerOverview UI on resume
local function handleUpdateCameraOverviewPage()
  -- Update Camera-Overview
  local data = {}
  local k=1
  for i=1, #multiRemoteCamera_Instances do
    if multiRemoteCamera_Instances[i].isConnected then
      data [k]= {
      cameraName = 'camera ' .. tostring(i),
      cameraModel = multiRemoteCamera_Instances[i].parameters.cameraModel,
      IP = multiRemoteCamera_Instances[i].parameters.cameraIP,
      cameraType = multiRemoteCamera_Instances[i].parameters.colorMode,
      triggerMode = multiRemoteCamera_Instances[i].parameters.acquisitionMode,
      shutterTime = tostring(multiRemoteCamera_Instances[i].parameters.shutterTime),
      gainFactor =  tostring(multiRemoteCamera_Instances[i].parameters.gain),
      loadOnReboot = tostring(multiRemoteCamera_Instances[i].parameterLoadOnReboot),
      monitoring = tostring(multiRemoteCamera_Instances[i].parameters.monitorCamera),
      monitoringState = tostring(multiRemoteCamera_Instances[i].cameraIsPingAble)}
      if multiRemoteCamera_Instances[i].parameters.gigEvision then
        data[k].cameraType = "-"
      end

      k = k + 1
    end

  end
  if data == nil then
  data [1]= {
      cameraName = nil,
      IP = nil,
      cameraType = nil,
      triggerMode = nil,
      shutterTime = nil,
      gainFactor =  nil,
      loadOnReboot = nil}
  end

  local jsonstring = json.encode(data)
  Script.notifyEvent("MultiRemoteCamera_OnNewCameraOverviewTable", jsonstring)
end

--- Function to update user levels
local function updateUserLevel()
  if multiRemoteCamera_Instances[selectedInstance].userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("MultiRemoteCamera_OnUserLevelOperatorActive", true)
    Script.notifyEvent("MultiRemoteCamera_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("MultiRemoteCamera_OnUserLevelServiceActive", true)
    Script.notifyEvent("MultiRemoteCamera_OnUserLevelAdminActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrCamera()

  updateUserLevel()
  Script.notifyEvent('MultiRemoteCamera_OnNewNumberOfCameras', string.format("%s", #multiRemoteCamera_Instances))
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusWaitingForCameraBootUp', bootUpStatus)
  Script.notifyEvent('MultiRemoteCamera_OnNewCameraList', helperFuncs.createStringListBySize(#multiRemoteCamera_Instances))
  Script.notifyEvent('MultiRemoteCamera_OnNewSelectedCam', selectedInstance)
  Script.notifyEvent('MultiRemoteCamera_OnNewViewerId', 'multiRemoteCameraViewer' .. tostring(selectedInstance))
  Script.notifyEvent('MultiRemoteCamera_OnCameraConnected', multiRemoteCamera_Instances[selectedInstance].isConnected)
  Script.notifyEvent('MultiRemoteCamera_OnScanCamera', false)
  Script.notifyEvent('MultiRemoteCamera_OnCurrentCameraIP', multiRemoteCamera_Instances[selectedInstance].parameters.cameraIP)
  Script.notifyEvent('MultiRemoteCamera_OnNewColorMode', multiRemoteCamera_Instances[selectedInstance].parameters.colorMode)
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusViewerActive', viewerActive)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'viewerActive', viewerActive)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionStatus', multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision)
  if multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision then
    Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionParameters', multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterList)
    Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionCurrentParameter', multiRemoteCamera_Instances[selectedInstance].gigEVisionCurrentParameter)
    Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionParameterType', multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterType)
    Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionValue', tostring(multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterValue))
    if multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterUITable then
      Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionTableContent', multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterUITable)
    end
    if multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable then
      Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionConfigTableContent', multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable)
    end
  end
  Script.notifyEvent('MultiRemoteCamera_OnNewMonitoring', multiRemoteCamera_Instances[selectedInstance].parameters.monitorCamera)
  Script.notifyEvent('MultiRemoteCamera_OnNewSwitchMode', multiRemoteCamera_Instances[selectedInstance].parameters.switchMode)

  Script.notifyEvent('MultiRemoteCamera_OnNewShutterTime', multiRemoteCamera_Instances[selectedInstance].parameters.shutterTime)
  Script.notifyEvent('MultiRemoteCamera_OnNewGain', multiRemoteCamera_Instances[selectedInstance].parameters.gain)
  Script.notifyEvent('MultiRemoteCamera_OnNewFramerate', multiRemoteCamera_Instances[selectedInstance].parameters.framerate)
  Script.notifyEvent('MultiRemoteCamera_OnNewResizeFactor', multiRemoteCamera_Instances[selectedInstance].imageProcessingParams:get('resizeFactor'))
  Script.notifyEvent('MultiRemoteCamera_OnNewAcquisitionMode', multiRemoteCamera_Instances[selectedInstance].parameters.acquisitionMode)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageQueueCamera', '-')
  Script.notifyEvent('MultiRemoteCamera_OnNewFPSCamera', '-')
  Script.notifyEvent('MultiRemoteCamera_OnNewFOVX', {multiRemoteCamera_Instances[selectedInstance].parameters.xStartFOV, multiRemoteCamera_Instances[selectedInstance].parameters.xEndFOV})
  Script.notifyEvent('MultiRemoteCamera_OnNewFOVY', {multiRemoteCamera_Instances[selectedInstance].parameters.yStartFOV, multiRemoteCamera_Instances[selectedInstance].parameters.yEndFOV})
  checkTriggerMode(multiRemoteCamera_Instances[selectedInstance].parameters.acquisitionMode)
  Script.notifyEvent('MultiRemoteCamera_OnNewHardwareTriggerDelay', multiRemoteCamera_Instances[selectedInstance].parameters.hardwareTriggerDelay)
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusDigitalTriggerPause', multiRemoteCamera_Instances[selectedInstance].digTriggerStatus)
  Script.notifyEvent('MultiRemoteCamera_OnNewParameterName', multiRemoteCamera_Instances[selectedInstance].parametersName)
  Script.notifyEvent('MultiRemoteCamera_OnPersistentDataModuleAvailable', multiRemoteCamera_Instances[selectedInstance].persistentModuleAvailable)
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusSaveAllImagesActive', multiRemoteCamera_Instances[selectedInstance].parameters.saveAllImages)
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusTempImageActive', multiRemoteCamera_Instances[selectedInstance].parameters.tempSaveImage)
  Script.notifyEvent('MultiRemoteCamera_OnNewSavingImagesPath', multiRemoteCamera_Instances[selectedInstance].parameters.savingImagePath)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageFilePrefix', multiRemoteCamera_Instances[selectedInstance].parameters.imageFilePrefix)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageSaveFormat', multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat)
  if multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'jpg' then
    Script.notifyEvent('MultiRemoteCamera_OnNewFormatCompression', multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveJpgFormatCompression)
  elseif multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'png' then
    Script.notifyEvent('MultiRemoteCamera_OnNewFormatCompression', multiRemoteCamera_Instances[selectedInstance].parameters.imageSavePngFormatCompression)
  end
  Script.notifyEvent('MultiRemoteCamera_OnNewLoggingMessage', "")
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusLoadParameterOnReboot', multiRemoteCamera_Instances[selectedInstance].parameterLoadOnReboot)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'activeInUI', true)
  Script.notifyEvent('MultiRemoteCamera_OnNewProcessingMode', multiRemoteCamera_Instances[selectedInstance].parameters.processingMode)
  Script.notifyEvent('MultiRemoteCamera_OnNewMonitoringState', multiRemoteCamera_Instances[selectedInstance].cameraIsPingAble)
  Script.notifyEvent('MultiRemoteCamera_OnNewCameraModel', multiRemoteCamera_Instances[selectedInstance].parameters.cameraModel)
  handleUpdateCameraOverviewPage()
end
Timer.register(tmrCamera, "OnExpired", handleOnExpiredTmrCamera)

--- Function to periodically ping cameras to monitor connection status
local function handleOnExpiredTmrMonitorCameras()
  for i=1, #multiRemoteCamera_Instances do
    if multiRemoteCamera_Instances[i].parameters.monitorCamera and multiRemoteCamera_Instances[i].isConnected then
     multiRemoteCamera_Instances[i]:pingCamera()
     Script.notifyEvent('MultiRemoteCamera_OnNewMonitoringStateCams', i, multiRemoteCamera_Instances[i].cameraIsPingAble)

     if multiRemoteCamera_Instances[i].cameraIsPingAble then
        _G.logger:info(nameOfModule .. ": Ping camera " .. tostring(i) .." with ip: " .. multiRemoteCamera_Instances[i].parameters.cameraIP .." : " .. tostring(multiRemoteCamera_Instances[i].cameraIsPingAble))
     else
        _G.logger:warning(nameOfModule .. ": Ping camera " .. tostring(i) .." with ip: " .. multiRemoteCamera_Instances[i].parameters.cameraIP .." : " .. tostring(multiRemoteCamera_Instances[i].cameraIsPingAble))
        tmrCamera:start() -- Update UI
     end
    end
  end
end
Timer.register(tmrMonitorCameras, "OnExpired", handleOnExpiredTmrMonitorCameras)

local function pageCalled()
  if _G.availableAPIs.imageProvider then
    updateUserLevel() -- try to hide user specific content asap
    tmrCamera:start()
  end
  return ''
end
Script.serveFunction("CSK_MultiRemoteCamera.pageCalled", pageCalled)

-- Function to get access to the flow object
---@param handle Flow Handle of Flow
local function setFlowHandle(handle)
  cameraFlow = handle
end
funcs.setFlowHandle = setFlowHandle

local function setSelectedCam(camNo)
  selectedInstance = camNo
  _G.logger:info(nameOfModule .. ": New selected camera = " .. tostring(selectedInstance))
  multiRemoteCamera_Instances[selectedInstance].activeInUI = true
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'activeInUI', true)
  tmrCamera:start()
end
Script.serveFunction("CSK_MultiRemoteCamera.setSelectedCam", setSelectedCam)

local function getSelectedCam()
  return selectedInstance
end
Script.serveFunction("CSK_MultiRemoteCamera.getSelectedCam", getSelectedCam)

local function getInstancesAmount ()
  return #multiRemoteCamera_Instances
end
Script.serveFunction('CSK_MultiRemoteCamera.getInstancesAmount', getInstancesAmount )

local function addInstance()
  _G.logger:info(nameOfModule .. ": Add instance")
  table.insert(multiRemoteCamera_Instances, multiRemoteCamera_Model.create(#multiRemoteCamera_Instances+1))

  multiRemoteCamera_Instances[#multiRemoteCamera_Instances].parameters.switchMode = multiRemoteCamera_Instances[1].parameters.switchMode

  for i = 1, #multiRemoteCamera_Instances do
    multiRemoteCamera_Instances[i].parameters.camSum = #multiRemoteCamera_Instances

    -- If cameras are in switchMode, reconfig all cameras with new info of camera amount
    if multiRemoteCamera_Instances[i].parameters.switchMode == true then
      multiRemoteCamera_Instances[i]:setNewConfig()
    end

  end
  Script.deregister("CSK_MultiRemoteCamera.OnNewValueToForward" .. tostring(#multiRemoteCamera_Instances) , handleOnNewValueToForward)
  Script.register("CSK_MultiRemoteCamera.OnNewValueToForward" .. tostring(#multiRemoteCamera_Instances) , handleOnNewValueToForward)
  pageCalled()
end
Script.serveFunction('CSK_MultiRemoteCamera.addInstance', addInstance)

local function resetInstances()
  _G.logger:info(nameOfModule .. ": Reset instances.")
  setSelectedCam(1)
  local totalAmount = #multiRemoteCamera_Instances
  while totalAmount > 1 do
    Script.releaseObject(multiRemoteCamera_Instances[totalAmount])
    multiRemoteCamera_Instances[totalAmount] =  nil
    totalAmount = totalAmount - 1
  end
  pageCalled()
end
Script.serveFunction('CSK_MultiRemoteCamera.resetInstances', resetInstances)

-- ********************* UI Setting / Submit Functions Start ********************

local function setCameraModel (camModel)
  _G.logger:info(nameOfModule .. ": Set camera model = " .. tostring(camModel))
  multiRemoteCamera_Instances[selectedInstance].parameters.cameraModel = camModel
end
Script.serveFunction('CSK_MultiRemoteCamera.setCameraModel', setCameraModel )

local function setCameraIP(ip)
  _G.logger:info(nameOfModule .. ": Setting new IP = " .. ip .. ' for camera No.' .. tostring(selectedInstance))
  if checkIP(ip) == true then
    multiRemoteCamera_Instances[selectedInstance].parameters.cameraIP = ip
    Script.notifyEvent('MultiRemoteCamera_OnNewIPCheck', false)
  else
    Script.notifyEvent('MultiRemoteCamera_OnNewIPCheck', true)
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setCameraIP", setCameraIP)

local function getCameraIP()
  return multiRemoteCamera_Instances[selectedInstance].parameters.cameraIP
end
Script.serveFunction("CSK_MultiRemoteCamera.getCameraIP", getCameraIP)

local function connectCamera()
  -- Try to connect the camera
  _G.logger:info(nameOfModule .. ": Try to connecto to camera no. " .. tostring(selectedInstance))
  multiRemoteCamera_Instances[selectedInstance]:connectCamera()
  if multiRemoteCamera_Instances[selectedInstance].isConnected and multiRemoteCamera_Instances[selectedInstance].parameters.monitorCamera then
    handleOnExpiredTmrMonitorCameras ()
    tmrMonitorCameras:start() --Timer wird einmal inital gestartet.
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.connectCamera", connectCamera)

local function disconnectCamera()
  _G.logger:info(nameOfModule .. ": Disconnect camera no. " .. tostring(selectedInstance))
  multiRemoteCamera_Instances[selectedInstance]:disconnectCamera()
end
Script.serveFunction("CSK_MultiRemoteCamera.disconnectCamera", disconnectCamera)

local function startCamera()
  _G.logger:info(nameOfModule .. ": Start camera no. " .. tostring(selectedInstance))
  multiRemoteCamera_Instances[selectedInstance]:startCamera()
end
Script.serveFunction("CSK_MultiRemoteCamera.startCamera", startCamera)

local function stopCamera()
  _G.logger:info(nameOfModule .. ": Stop camera no. " .. tostring(selectedInstance))
  multiRemoteCamera_Instances[selectedInstance]:stopCamera()
end
Script.serveFunction("CSK_MultiRemoteCamera.stopCamera", stopCamera)

local function setGigEVision(status)
  -- Check if GigEVision / I2D is supported on device
  if status == true and _G.availableAPIs.GigEVision == true then
    multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision = true
  elseif status == true and _G.availableAPIs.GigEVision == false then
    multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision = false
  elseif status == false and _G.availableAPIs.I2D == true then
    multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision = false
  elseif status == false and _G.availableAPIs.I2D == false then
    multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision = true
  end
  _G.logger:info(nameOfModule .. ": Set GigEVision of camera no. " .. tostring(selectedInstance) .. ": " .. tostring(multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision))

  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionStatus', multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision)
end
Script.serveFunction("CSK_MultiRemoteCamera.setGigEVision", setGigEVision)

local function getGigEVision()
  return multiRemoteCamera_Instances[selectedInstance].parameters.gigEvision
end
Script.serveFunction("CSK_MultiRemoteCamera.getGigEVision", getGigEVision)

local function setSwitchMode (status)
  for i = 1, #multiRemoteCamera_Instances do
    multiRemoteCamera_Instances[i].parameters.switchMode = status
    multiRemoteCamera_Instances[i]:setNewConfig()
  end
  _G.logger:info(nameOfModule .. ": Set camera switch mode for all cameras = " .. tostring(status))
end
Script.serveFunction("CSK_MultiRemoteCamera.setSwitchMode", setSwitchMode)

local function setCameraMonitoring (state)
  multiRemoteCamera_Instances[selectedInstance].parameters.monitorCamera = state
  _G.logger:info(nameOfModule .. ": Status of camera monitoring of camera no. " .. tostring(selectedInstance) .. " = " .. tostring(state))
  if state == true and multiRemoteCamera_Instances[selectedInstance].isConnected then
    handleOnExpiredTmrMonitorCameras ()
    tmrMonitorCameras:start()
  else
    local result = false
    for i=1, #multiRemoteCamera_Instances do
      if multiRemoteCamera_Instances[i].parameters.monitorCamera and multiRemoteCamera_Instances[i].isConnected then
        result = true
      end
    end
    if not result then
      tmrMonitorCameras:stop()
      _G.logger:info(nameOfModule .. ": Camera Monitoring complete deactivated")
    end
  end
  pageCalled()
end
Script.serveFunction("CSK_MultiRemoteCamera.setCameraMonitoring", setCameraMonitoring)

local function setColorMode(mode)
  _G.logger:info(nameOfModule .. ": Set color mode = " .. tostring(mode))
  multiRemoteCamera_Instances[selectedInstance]:setColorMode(mode)
end
Script.serveFunction("CSK_MultiRemoteCamera.setColorMode", setColorMode)

local function getColorMode()
  return multiRemoteCamera_Instances[selectedInstance].parameters.colorMode
end
Script.serveFunction("CSK_MultiRemoteCamera.getColorMode", getColorMode)

local function setAcquisitionMode(mode)
  _G.logger:info(nameOfModule .. ": Set acquisition mode = " .. tostring(mode))
  multiRemoteCamera_Instances[selectedInstance].digTriggerStatus = false
  Script.notifyEvent("MultiRemoteCamera_OnNewStatusDigitalTriggerPause", false)
  checkTriggerMode(mode)
  multiRemoteCamera_Instances[selectedInstance]:setAcquisitionMode(mode)
  handleUpdateCameraOverviewPage()
end
Script.serveFunction("CSK_MultiRemoteCamera.setAcquisitionMode", setAcquisitionMode)

local function getAcquisitionMode()
  return multiRemoteCamera_Instances[selectedInstance].parameters.acquisitionMode
end
Script.serveFunction("CSK_MultiRemoteCamera.getAcquisitionMode", getAcquisitionMode)

local function setHardwareTriggerDelay(value)
  _G.logger:info(nameOfModule .. ": Set hardware trigger delay = " .. tostring(value))
  multiRemoteCamera_Instances[selectedInstance].parameters.hardwareTriggerDelay = value
  if multiRemoteCamera_Instances[selectedInstance].parameters.triggerDelayBlockName ~= nil and cameraFlow ~= nil then
    cameraFlow:updateParameter(multiRemoteCamera_Instances[selectedInstance].parameters.triggerDelayBlockName, "DelayTime", value)
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setHardwareTriggerDelay", setHardwareTriggerDelay)

local function getHardwareTriggerDelay()
  return multiRemoteCamera_Instances[selectedInstance].parameters.hardwareTriggerDelay
end
Script.serveFunction("CSK_MultiRemoteCamera.getHardwareTriggerDelay", getHardwareTriggerDelay)

local function setDigitalTriggerPause()
  if multiRemoteCamera_Instances[selectedInstance].digTriggerStatus == true then
    multiRemoteCamera_Instances[selectedInstance].digTriggerStatus = false
    _G.logger:info(nameOfModule .. ": Set trigger pause: false")
    Script.notifyEvent("MultiRemoteCamera_OnNewStatusDigitalTriggerPause", multiRemoteCamera_Instances[selectedInstance].digTriggerStatus)
    multiRemoteCamera_Instances[selectedInstance]:startCamera()
  else
    multiRemoteCamera_Instances[selectedInstance].digTriggerStatus = true
    _G.logger:info(nameOfModule .. ": Set trigger pause: true")
    Script.notifyEvent("MultiRemoteCamera_OnNewStatusDigitalTriggerPause", multiRemoteCamera_Instances[selectedInstance].digTriggerStatus)
    multiRemoteCamera_Instances[selectedInstance]:stopCamera()
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setDigitalTriggerPause", setDigitalTriggerPause)

local function setFOVX(values)
  _G.logger:info(nameOfModule .. ": Preset FOV X = " .. tostring(values[1]) .. " - " .. values[2])
  multiRemoteCamera_Instances[selectedInstance].parameters.xStartFOV = values[1]
  multiRemoteCamera_Instances[selectedInstance].parameters.xEndFOV = values[2]
  Script.notifyEvent('MultiRemoteCamera_OnNewFOVX', values)
end
Script.serveFunction("CSK_MultiRemoteCamera.setFOVX", setFOVX)

local function getFOVX()
  return {multiRemoteCamera_Instances[selectedInstance].parameters.xStartFOV, multiRemoteCamera_Instances[selectedInstance].parameters.xEndFOV}
end
Script.serveFunction("CSK_MultiRemoteCamera.getFOVX", getFOVX)

local function setFOVY(values)
  _G.logger:info(nameOfModule .. ": Preset FOV Y = " .. tostring(values[1]) .. " - " .. values[2])
  multiRemoteCamera_Instances[selectedInstance].parameters.yStartFOV = values[1]
  multiRemoteCamera_Instances[selectedInstance].parameters.yEndFOV = values[2]
  Script.notifyEvent('MultiRemoteCamera_OnNewFOVY', values)
end
Script.serveFunction("CSK_MultiRemoteCamera.setFOVY", setFOVY)

local function getFOVY()
  return {multiRemoteCamera_Instances[selectedInstance].parameters.yStartFOV, multiRemoteCamera_Instances[selectedInstance].parameters.yEndFOV}
end
Script.serveFunction("CSK_MultiRemoteCamera.getFOVY", getFOVY)

local function setFOV()
  _G.logger:info(nameOfModule .. ": Set FOV")
  multiRemoteCamera_Instances[selectedInstance]:setFOV()
  Script.notifyEvent('MultiRemoteCamera_OnNewImageSizeToShare', "CSK_MultiRemoteCamera.OnNewImageCamera" .. tostring(selectedInstance))
end
Script.serveFunction("CSK_MultiRemoteCamera.setFOV", setFOV)

local function setShutterTime(shutterTime)
  _G.logger:info(nameOfModule .. ": Set shutter time = " .. tostring(shutterTime))
  multiRemoteCamera_Instances[selectedInstance]:setShutterTime(shutterTime)
  handleUpdateCameraOverviewPage()
end
Script.serveFunction("CSK_MultiRemoteCamera.setShutterTime", setShutterTime)

local function getShutterTime()
  return multiRemoteCamera_Instances[selectedInstance].parameters.shutterTime
end
Script.serveFunction("CSK_MultiRemoteCamera.getShutterTime", getShutterTime)

local function setGain(gain)
  _G.logger:info(nameOfModule .. ": Set gain = " .. tostring(gain))
  multiRemoteCamera_Instances[selectedInstance]:setGain(gain)
  handleUpdateCameraOverviewPage()
end
Script.serveFunction("CSK_MultiRemoteCamera.setGain", setGain)

local function getGain()
  return multiRemoteCamera_Instances[selectedInstance].parameters.gain
end
Script.serveFunction("CSK_MultiRemoteCamera.getGain", getGain)

local function setFramerate(framerate)
  _G.logger:info(nameOfModule .. ": Set framerate = " .. tostring(framerate))
  multiRemoteCamera_Instances[selectedInstance]:setFramerate(framerate)
end
Script.serveFunction("CSK_MultiRemoteCamera.setFramerate", setFramerate)

local function getFramerate()
  return multiRemoteCamera_Instances[selectedInstance].parameters.framerate
end
Script.serveFunction("CSK_MultiRemoteCamera.getFramerate", getFramerate)

local function setResizeFactor(factor)
  _G.logger:info(nameOfModule .. ": Set resize factor = " .. tostring(factor))
  multiRemoteCamera_Instances[selectedInstance].parameters.resizeFactor = factor
  multiRemoteCamera_Instances[selectedInstance].imageProcessingParams:update('resizeFactor', multiRemoteCamera_Instances[selectedInstance].parameters.resizeFactor)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'resizeFactor', multiRemoteCamera_Instances[selectedInstance].parameters.resizeFactor)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageSizeToShare', "CSK_MultiRemoteCamera.OnNewImageCamera" .. tostring(selectedInstance))
end
Script.serveFunction("CSK_MultiRemoteCamera.setResizeFactor", setResizeFactor)

local function getResizeFactor()
  return multiRemoteCamera_Instances[selectedInstance].imageProcessingParams:get('resizeFactor')
end
Script.serveFunction("CSK_MultiRemoteCamera.getResizeFactor", getResizeFactor)

local function setProcessingMode(mode)
  _G.logger:info(nameOfModule .. ": Set processing mode = " .. tostring(mode))
  multiRemoteCamera_Instances[selectedInstance].parameters.processingMode = mode
  multiRemoteCamera_Instances[selectedInstance].imageProcessingParams:update('mode', multiRemoteCamera_Instances[selectedInstance].parameters.processingMode)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'mode', multiRemoteCamera_Instances[selectedInstance].parameters.processingMode)
end
Script.serveFunction("CSK_MultiRemoteCamera.setProcessingMode", setProcessingMode)

local function getProcessingMode()
  return multiRemoteCamera_Instances[selectedInstance].parameters.processingMode
end
Script.serveFunction("CSK_MultiRemoteCamera.getProcessingMode", getProcessingMode)

local function cameraSoftwareTrigger()
  _G.logger:info(nameOfModule .. ": SW trigger")
  multiRemoteCamera_Instances[selectedInstance].CameraProvider:snapshot()
end
Script.serveFunction("CSK_MultiRemoteCamera.cameraSoftwareTrigger", cameraSoftwareTrigger)

local function cameraSpecificSoftwareTrigger(cameraNo)
  _G.logger:info(nameOfModule .. ": SW trigger camera no." .. tostring(cameraNo))
  multiRemoteCamera_Instances[cameraNo].CameraProvider:snapshot()
end
Script.serveFunction("CSK_MultiRemoteCamera.cameraSpecificSoftwareTrigger", cameraSpecificSoftwareTrigger)

local function setImageFilePrefix(prefix)
  _G.logger:info(nameOfModule .. ": Set image file prefix: " .. tostring(prefix))
  multiRemoteCamera_Instances[selectedInstance].parameters.imageFilePrefix = prefix
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'imageFilePrefix', prefix)
end
Script.serveFunction("CSK_MultiRemoteCamera.setImageFilePrefix", setImageFilePrefix)

local function setSavingPath(path)
  if path == '/sdcard/0/' then
    if File.exists(path) then
      _G.logger:info(nameOfModule .. ': Changed image saving path to SD Card for camera No.' .. tostring(selectedInstance))
      multiRemoteCamera_Instances[selectedInstance].parameters.savingImagePath = path
      Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'savingImagePath', '/sdcard/0/')
    else
      _G.logger:warning(nameOfModule .. ": NO SD CARD available, changed imagePath to public for camera No." .. tostring(selectedInstance))
      Script.notifyEvent('MultiRemoteCamera_OnNewLoggingMessage', "NO SD CARD available")
      multiRemoteCamera_Instances[selectedInstance].parameters.savingImagePath = '/public/'
      Script.notifyEvent('MultiRemoteCamera_OnNewSavingImagesPath', '/public/')
      Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'savingImagePath', '/public/')
    end
  else
    multiRemoteCamera_Instances[selectedInstance].parameters.savingImagePath = '/public/'
    Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'savingImagePath', '/public/')
    _G.logger:info(nameOfModule .. ': Changed saving path to public folder for camera No.' .. tostring(selectedInstance))
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setSavingPath", setSavingPath)

local function setImageSaveFormat(format)
  _G.logger:info(nameOfModule .. ": Set image save formate: " .. tostring(format))
  multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat = format
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'imageSaveFormat', format)
  Script.notifyEvent('MultiRemoteCamera_OnNewImageSaveFormat', multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat)
  if multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'jpg' then
    Script.notifyEvent('MultiRemoteCamera_OnNewFormatCompression', multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveJpgFormatCompression)
  elseif multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'png' then
    Script.notifyEvent('MultiRemoteCamera_OnNewFormatCompression', multiRemoteCamera_Instances[selectedInstance].parameters.imageSavePngFormatCompression)
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setImageSaveFormat", setImageSaveFormat)

local function setImageSaveFormatCompression(comp)
  _G.logger:info(nameOfModule .. ": Set image save compression: " .. tostring(comp))
  if multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'jpg' then
    multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveJpgFormatCompression = comp
    Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'imageSaveJpgFormatCompression', comp)
  elseif multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'png' then
    multiRemoteCamera_Instances[selectedInstance].parameters.imageSavePngFormatCompression = comp
    Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'imageSavePngFormatCompression', comp)
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.setImageSaveFormatCompression", setImageSaveFormatCompression)

local function triggerImageSaving()
  _G.logger:info(nameOfModule .. ": Trigger image saving.")
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'saveLastImage')
end
Script.serveFunction("CSK_MultiRemoteCamera.triggerImageSaving", triggerImageSaving)

local function setSaveAllImages(status)
  _G.logger:info(nameOfModule .. ": Save all images: " .. tostring(status))
  multiRemoteCamera_Instances[selectedInstance].parameters.saveAllImages = status
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'saveAllImages', status)
end
Script.serveFunction("CSK_MultiRemoteCamera.setSaveAllImages", setSaveAllImages)

local function setTempImageActive(status)
  _G.logger:info(nameOfModule .. ": Save temporarily latest images: " .. tostring(status))
  multiRemoteCamera_Instances[selectedInstance].parameters.tempSaveImage = status
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'tempSaveImage', status)
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusTempImageActive', status)
end
Script.serveFunction("CSK_MultiRemoteCamera.setTempImageActive", setTempImageActive)

local function setViewerActive(status)
  _G.logger:info(nameOfModule .. ": Viewer active: " .. tostring(status))
  viewerActive = status
  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'viewerActive', viewerActive)
end
Script.serveFunction("CSK_MultiRemoteCamera.setViewerActive", setViewerActive)

local function updateConfig()
  _G.logger:info(nameOfModule .. ": Update config.")
  multiRemoteCamera_Instances[selectedInstance]:setNewConfig()
end
Script.serveFunction("CSK_MultiRemoteCamera.updateConfig", updateConfig)

local function addGigEVisionConfig()
  _G.logger:info(nameOfModule .. ": Add custom GigE Vision parameter value.")
  local newConfig = {}
  newConfig.parameter = multiRemoteCamera_Instances[selectedInstance].gigEVisionCurrentParameter
  newConfig.type = multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterType
  newConfig.value = multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterValue

  table.insert(multiRemoteCamera_Instances[selectedInstance].parameters.customGigEVisionConfig, newConfig)
  multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable = multiRemoteCamera_Instances[selectedInstance].helperFuncs.createModuleJsonList('gigEConfig', multiRemoteCamera_Instances[selectedInstance].parameters.customGigEVisionConfig)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionConfigTableContent', multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable)
end
Script.serveFunction("CSK_MultiRemoteCamera.addGigEVisionConfig", addGigEVisionConfig)

local function removeGigEVisionConfig()
  _G.logger:info(nameOfModule .. ": Remove custom GigE Vision parameter value.")
  if multiRemoteCamera_Instances[selectedInstance].gigEVisionSelectedConfig then
    table.remove(multiRemoteCamera_Instances[selectedInstance].parameters.customGigEVisionConfig, multiRemoteCamera_Instances[selectedInstance].gigEVisionSelectedConfig)
    multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable = multiRemoteCamera_Instances[selectedInstance].helperFuncs.createModuleJsonList('gigEConfig', multiRemoteCamera_Instances[selectedInstance].parameters.customGigEVisionConfig)
    Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionConfigTableContent', multiRemoteCamera_Instances[selectedInstance].gigEVisionConfigUITable)
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.removeGigEVisionConfig", removeGigEVisionConfig)

local function setGigEVisionParameterName(name)
  _G.logger:info(nameOfModule .. ": Set GigE Vision parameter name: " .. tostring(name))
  multiRemoteCamera_Instances[selectedInstance].gigEVisionCurrentParameter = name
  multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterType = multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterAllTypes[name]
  multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterValue = multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterAllValues[name]

  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionCurrentParameter', multiRemoteCamera_Instances[selectedInstance].gigEVisionCurrentParameter)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionParameterType', multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterType)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionValue', tostring(multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterValue))
end
Script.serveFunction("CSK_MultiRemoteCamera.setGigEVisionParameterName", setGigEVisionParameterName)

--- Function to get the current selected entry
---@param selection string Full text of selection
---@param pattern string Pattern to search for
local function setSelection(selection, pattern)
  local selected
  if selection == "" then
    selected = ''
  else
    local _, pos = string.find(selection, pattern)
    if pos == nil then
      _G.logger:info(nameOfModule .. ": Did not find selection")
      selected = ''
    else
      pos = tonumber(pos)
      local endPos = string.find(selection, '"', pos+1)
      selected = string.sub(selection, pos+1, endPos-1)
      if selected == nil then
        selected = ''
      end
    end
  end
  return selected
end

local function selectGigEVisionConfig(selection)
  _G.logger:info(nameOfModule .. ": Select GigE Vision config no." .. tostring(selection))
  multiRemoteCamera_Instances[selectedInstance].gigEVisionSelectedConfig = selection
end
Script.serveFunction("CSK_MultiRemoteCamera.selectGigEVisionConfig", selectGigEVisionConfig)

local function selectGigEVisionConfigViaUITable(selection)
  local selected = setSelection(selection, '"No":"')
  if selected ~= "" then
    _G.logger:info(nameOfModule .. ": Select GigE Vision config no." .. tostring(selected))
    multiRemoteCamera_Instances[selectedInstance].gigEVisionSelectedConfig = tonumber(selected)
  else
    _G.logger:info(nameOfModule .. ": Selection error.")
    multiRemoteCamera_Instances[selectedInstance].gigEVisionSelectedConfig = 1
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.selectGigEVisionConfigViaUITable", selectGigEVisionConfigViaUITable)

local function selectGigEVisionParameterNameViaUITable(selection)
  local selected = setSelection(selection, '"ParameterName":"')
  if selected ~= "" then
    setGigEVisionParameterName(selected)
  else
    setGigEVisionParameterName(multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterAllNames[1])
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.selectGigEVisionParameterNameViaUITable", selectGigEVisionParameterNameViaUITable)

local function setGigEVisionParameterValue(value)
  _G.logger:info(nameOfModule .. ": Set GigE Vision parameter value: " .. tostring(value))
  multiRemoteCamera_Instances[selectedInstance].gigEVisionParameterValue = value
end
Script.serveFunction("CSK_MultiRemoteCamera.setGigEVisionParameterValue", setGigEVisionParameterValue)

--- Function to update processing parameters within the processing threads
local function updateImageProcessingParameter()
  _G.logger:info(nameOfModule .. ": Update image processing parameter.")
  setProcessingMode(multiRemoteCamera_Instances[selectedInstance].parameters.processingMode)
  setResizeFactor(multiRemoteCamera_Instances[selectedInstance].parameters.resizeFactor)
  setSaveAllImages(multiRemoteCamera_Instances[selectedInstance].parameters.saveAllImages)
  setImageSaveFormat(multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat)

  if multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'jpg' then
    setImageSaveFormatCompression(multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveJpgFormatCompression)
  elseif multiRemoteCamera_Instances[selectedInstance].parameters.imageSaveFormat == 'png' then
    setImageSaveFormatCompression(multiRemoteCamera_Instances[selectedInstance].parameters.imageSavePngFormatCompression)
  end

  Script.notifyEvent('MultiRemoteCamera_OnNewImageProcessingParameter', selectedInstance, 'maxImageQueueSize', multiRemoteCamera_Instances[selectedInstance].parameters.maxImageQueueSize)

  setSavingPath(multiRemoteCamera_Instances[selectedInstance].parameters.savingImagePath)
  setImageFilePrefix(multiRemoteCamera_Instances[selectedInstance].parameters.imageFilePrefix)
  setTempImageActive(multiRemoteCamera_Instances[selectedInstance].parameters.tempSaveImage)
end

local function restartAllCameras()
  _G.logger:info(nameOfModule .. ": Restart all cameras.")
  local isOneConnected = false
  tmrMonitorCameras:stop()

  for i = 1, #multiRemoteCamera_Instances do
    multiRemoteCamera_Instances[i]:disconnectCamera()
    multiRemoteCamera_Instances[i]:connectCamera()
    updateImageProcessingParameter()
    isOneConnected = true
  end
  if isOneConnected then
    tmrMonitorCameras:start()
  end
end
Script.serveFunction('CSK_MultiRemoteCamera.restartAllCameras', restartAllCameras)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ": Set parameter name: " .. tostring(name))
  multiRemoteCamera_Instances[selectedInstance].parametersName = name
end
Script.serveFunction("CSK_MultiRemoteCamera.setParameterName", setParameterName)

local function sendParameters()
  if multiRemoteCamera_Instances[selectedInstance].persistentModuleAvailable then
    CSK_PersistentData.addParameter(helperFuncs.convertTable2Container(multiRemoteCamera_Instances[selectedInstance].parameters), multiRemoteCamera_Instances[selectedInstance].parametersName)

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiRemoteCamera_Instances[selectedInstance].parametersName, multiRemoteCamera_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance), #multiRemoteCamera_Instances)
    else
      CSK_PersistentData.setModuleParameterName(nameOfModule, multiRemoteCamera_Instances[selectedInstance].parametersName, multiRemoteCamera_Instances[selectedInstance].parameterLoadOnReboot, tostring(selectedInstance))
    end
    _G.logger:info(nameOfModule .. ": Send camera parameters with name '" .. multiRemoteCamera_Instances[selectedInstance].parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_MultiRemoteCamera.sendParameters", sendParameters)

local function loadParameters()
  if multiRemoteCamera_Instances[selectedInstance].persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(multiRemoteCamera_Instances[selectedInstance].parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      multiRemoteCamera_Instances[selectedInstance].parameters = helperFuncs.convertContainer2Table(data)
      multiRemoteCamera_Instances[selectedInstance]:setNewConfig()
      updateImageProcessingParameter()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
  pageCalled()
end
Script.serveFunction("CSK_MultiRemoteCamera.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  multiRemoteCamera_Instances[selectedInstance].parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
  handleUpdateCameraOverviewPage()
end
Script.serveFunction("CSK_MultiRemoteCamera.setLoadOnReboot", setLoadOnReboot)

--- Function to setup cameras after bootup
local function setupCamerasAfterBootUp()
  _G.logger:info(nameOfModule .. ': Setup camera after bootUp.')
  local isOneConnected = false
  for i = 1, #multiRemoteCamera_Instances do

    if multiRemoteCamera_Instances[i].parameterLoadOnReboot then
      CSK_MultiRemoteCamera.setSelectedCam(i)
      CSK_MultiRemoteCamera.loadParameters()
      CSK_MultiRemoteCamera.connectCamera()
      updateImageProcessingParameter()
      isOneConnected = true
    end
    if isOneConnected then
      tmrMonitorCameras:start()
    end
  end
  bootUpStatus = false
  Script.notifyEvent('MultiRemoteCamera_OnNewStatusWaitingForCameraBootUp', bootUpStatus)
end
Timer.register(tmrCameraBootUp, 'OnExpired', setupCamerasAfterBootUp)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  _G.logger:info(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
  -- Check if CSK_PersistentData version is > 1.x.x
  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    for j = 1, #multiRemoteCamera_Instances do
      multiRemoteCamera_Instances[j].persistentModuleAvailable = false
    end
  else

    local bootUpBreak = false

    -- Check if CSK_PersistentData version is >= 3.0.0
    if tonumber(string.sub(CSK_PersistentData.getVersion(), 1, 1)) >= 3 then
      local parameterName, loadOnReboot, totalInstances = CSK_PersistentData.getModuleParameterName(nameOfModule, '1')
      -- Check for amount if instances to create
      if totalInstances then
        local c = 2
        while c <= totalInstances do
          addInstance()
          c = c+1
        end
      end
    end

    for i = 1, #multiRemoteCamera_Instances do
      local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule, tostring(i))

      if parameterName then
        multiRemoteCamera_Instances[i].parametersName = parameterName
        multiRemoteCamera_Instances[i].parameterLoadOnReboot = loadOnReboot
      end

      if multiRemoteCamera_Instances[i].parameterLoadOnReboot then
        bootUpBreak = true
      end
    end

    if bootUpBreak then
      _G.logger:info(nameOfModule .. ": Wait for camera(s) power bootUp")

      tmrCameraBootUp:start()
      bootUpStatus = true
      Script.notifyEvent('MultiRemoteCamera_OnNewStatusWaitingForCameraBootUp', bootUpStatus)

    else
      setupCamerasAfterBootUp()
    end
  end
end
if _G.availableAPIs.imageProvider then
  Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)
end

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

-- ****************** UI Setting / Submit Functions End ********************

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************