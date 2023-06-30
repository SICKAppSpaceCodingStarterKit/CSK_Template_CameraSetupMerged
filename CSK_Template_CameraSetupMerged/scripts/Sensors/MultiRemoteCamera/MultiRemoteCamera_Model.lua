---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the MultiRemoteCamera_Model definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local nameOfModule = 'CSK_MultiRemoteCamera'

-- Get SIM type / firmware to adapt device specific parameters
local typeName = Engine.getTypeName()
local firmware = Engine.getFirmwareVersion()
local deviceType

if typeName == 'AppStudioEmulator' or typeName == 'SICK AppEngine' then
  deviceType = 'AppStudioEmulator'
else
  deviceType = string.sub(typeName, 1, 7)
end

-- Create kind of "class"
local multiRemoteCamera = {}
multiRemoteCamera.__index = multiRemoteCamera

--- Function to create new instance
---@param cameraNo int Number of instance
---@return table[] self Instance of multiRemoteCamera
function multiRemoteCamera.create(cameraNo)

  local self = {}
  setmetatable(self, multiRemoteCamera)

  -- Standard helper functions
  self.helperFuncs = require('Sensors/MultiRemoteCamera/helper/funcs')

  -- Check if CSK_UserManagement module can be used if wanted
  self.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

  -- Check if CSK_PersistentData module can be used if wanted
  self.persistentModuleAvailable = CSK_PersistentData ~= nil or false

  -- Default values for persistent data
  -- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
  self.parametersName = 'CSK_MultiRemoteCamera_Parameter' .. tostring(cameraNo) -- name of parameter dataset to be used for this module
  self.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

  self.isConnected = false -- Is camera connected/available
  self.activeInUI = false -- Is current camera selected via UI (see "setSelectedCam")
  self.digTriggerStatus = false -- digital trigger modus active
  self.gigEVisionParameterList = '' -- JSON list of available GigE Vision parameters
  self.gigEVisionCurrentParameter = '' -- current selected GigE Vision parameter
  self.gigEVisionParameterType = 'Integer' -- type of current selected GigE Vision parameter
  self.gigEVisionParameterValue = '-' -- Value of current selected GigE Vision parameter
  self.triggerFlow = Flow.create() -- Flow to trigger camera via cFlow
  self.cameraIsPingAble = false -- Status of latest ping check
  self.scriptIsStarted = false -- Status of processing script startedin own thread

  self.gigEVisionParameterAllNames = {} -- Name list of all available GigE Vision parameters
  self.gigEVisionParameterAllTypes = {} -- Type list of all available GigE Vision parameters
  self.gigEVisionParameterAllAccessTypes = {} -- Acces type list of all available GigE Vision parameters
  self.gigEVisionParameterAllValues = {} -- Value list of all available GigE Vision parameters
  self.gigEVisionParameterUITable = nil -- Content of GigE Vision parameters for UI table

  self.gigEVisionSelectedConfig = nil -- Selected entry of custom GigEVision setting
  self.gigEVisionConfigUITable = nil -- Content of custom GigEVision setting for UI table

  self.parameters = {}
  self.parameters.cameraNo = cameraNo -- Instance no of this camera
  self.parameters.camSum = cameraNo -- Amount of all cameras
  self.parameters.switchMode = false -- Is camera connected via switch to SIM?
  -- gigEvision or false -- GigE Vision camera?
  if _G.availableAPIs.GigEVision == true then
    self.parameters.gigEvision = true
  else
    self.parameters.gigEvision = false
  end
  self.parameters.cameraIP = '192.168.1.10' .. tostring(cameraNo) -- IP of camera
  self.parameters.shutterTime = 20000 -- Shutter time to use
  self.parameters.gain = 1.0 -- Gain
  self.parameters.framerate = 1 -- Frame rate in "FIXED_FREQUENCY" mode
  self.parameters.acquisitionMode = 'SOFTWARE_TRIGGER' -- 'FIXED_FREQUENCY' / 'SOFTWARE_TRIGGER' / 'HARDWARE_TRIGGER'
  self.parameters.hardwareTriggerDelay = 0 -- Opt. delay for HW trigger
  self.parameters.triggerDelayBlockName = nil -- Name of specific delay bock within cFlow
  self.parameters.colorMode = 'MONO8' --'COLOR8' / 'MONO8' / 'RAW8'
  self.parameters.xStartFOV = 0 -- Field of view xStart
  self.parameters.xEndFOV = 100 -- Field of view xEnd
  self.parameters.yStartFOV = 0 -- Field of view yStart
  self.parameters.yEndFOV = 100 -- Field of view yEnd
  self.parameters.processingFile = 'CSK_MultiRemoteCamera_ImageProcessing' -- Script to use for processing in thread
  self.parameters.monitorCamera = false -- Opt. monitor camera status in "CameraOverview" UI
  self.parameters.customGigEVisionConfig = {} -- Custom GigEVision setting, content are 3 tables ".parameter", ".type", ".value"
  self.parameters.cameraModel = "PicoMidiCam2" --a2A1920-51gcBAS


  -- Image processing parameters
  self.parameters.processingMode = "BOTH" -- 'SCRIPT', 'APP', 'BOTH' --> see "setProcessingMode"
  self.parameters.maxImageQueueSize = 5 -- max. size of image queue
  self.parameters.savingImagePath = '/public/' -- path of images to save (SD or public)
  self.parameters.imageFilePrefix = 'Image_' -- prefix for images to be saved
  self.parameters.saveAllImages = false -- Save all incoming images
  self.parameters.tempSaveImage = false -- Save latest image to opt. save it later
  self.parameters.resizeFactor = 1.0 -- factor to resize the incoming image, 0.1 - 1.0
  self.parameters.imageSaveFormat = 'bmp' -- bmp / jpg / png
  self.parameters.imageSaveJpgFormatCompression = 90
  self.parameters.imageSavePngFormatCompression = 6

  Script.serveEvent("CSK_MultiRemoteCamera.OnRegisterCamera" .. tostring(cameraNo), "MultiRemoteCamera_OnRegisterCamera" .. tostring(cameraNo), 'handle:1:Image.Provider.RemoteCamera')
  Script.serveEvent("CSK_MultiRemoteCamera.OnDeregisterCamera" .. tostring(cameraNo), "MultiRemoteCamera_OnDeregisterCamera" .. tostring(cameraNo), 'handle:1:Image.Provider.RemoteCamera')

  -- Parameters to give to the image processing
  self.imageProcessingParams = Container.create()
  self.imageProcessingParams:add('cameraNumber', cameraNo, "INT")
  self.imageProcessingParams:add('viewerId', 'multiRemoteCameraViewer' .. tostring(cameraNo), "STRING")
  self.imageProcessingParams:add('resizeFactor', self.parameters.resizeFactor, "FLOAT")
  self.imageProcessingParams:add('mode', self.parameters.processingMode, "STRING")
  self.imageProcessingParams:add('maxImageQueueSize', self.parameters.maxImageQueueSize, "INT")
  self.imageProcessingParams:add('savingImagePath', self.parameters.savingImagePath, "STRING")
  self.imageProcessingParams:add('imageFilePrefix', self.parameters.imageFilePrefix, "STRING")
  self.imageProcessingParams:add('saveAllImages', self.parameters.saveAllImages, "BOOL")
  self.imageProcessingParams:add('tempSaveImage', self.parameters.tempSaveImage, "BOOL")
  self.imageProcessingParams:add('imageSaveFormat', self.parameters.imageSaveFormat, "STRING")
  self.imageProcessingParams:add('imageSaveJpgFormatCompression', self.parameters.imageSaveJpgFormatCompression, "FLOAT")
  self.imageProcessingParams:add('imageSavePngFormatCompression', self.parameters.imageSavePngFormatCompression, "FLOAT")

  return self
end

--- Function to update GigE Vision parameters
function multiRemoteCamera:updateGigEVision()
---------------------------------------------------------------------------------
  -- Provide GigEVision parameter list
  local currentConfig = self.CameraProvider:getConfig()
  local configParams = Image.Provider.RemoteCamera.GigEVisionConfig.getParameters(currentConfig)

  self.gigEVisionParameterAllNames = {}
  self.gigEVisionParameterAllTypes = {}
  self.gigEVisionParameterAllAccessTypes = {}
  self.gigEVisionParameterAllValues = {}

  for i = 1, #configParams do
    table.insert(self.gigEVisionParameterAllNames, configParams[i])
    self.gigEVisionParameterAllTypes[configParams[i]] = Image.Provider.RemoteCamera.GigEVisionConfig.getParameterType(currentConfig, configParams[i])
    self.gigEVisionParameterAllAccessTypes[configParams[i]] = Image.Provider.RemoteCamera.GigEVisionConfig.getParameterAccessLevel(currentConfig, configParams[i])

    if self.gigEVisionParameterAllTypes[configParams[i]] == 'GIGE_PARAM_TYPE_STRING' then
      self.gigEVisionParameterAllValues[configParams[i]] = Image.Provider.RemoteCamera.GigEVisionConfig.getParameterString(currentConfig, configParams[i])
    elseif self.gigEVisionParameterAllTypes[configParams[i]] == 'GIGE_PARAM_TYPE_FLOAT' then
      self.gigEVisionParameterAllValues[configParams[i]] = Image.Provider.RemoteCamera.GigEVisionConfig.getParameterFloat(currentConfig, configParams[i])
    elseif self.gigEVisionParameterAllTypes[configParams[i]] == 'GIGE_PARAM_TYPE_INTEGER' then
      self.gigEVisionParameterAllValues[configParams[i]] = Image.Provider.RemoteCamera.GigEVisionConfig.getParameterInteger(currentConfig, configParams[i])
    end
  end

  self.gigEVisionParameterUITable = self.helperFuncs.createModuleJsonList('gigE', self.gigEVisionParameterAllNames, self.gigEVisionParameterAllTypes, self.gigEVisionParameterAllAccessTypes, self.gigEVisionParameterAllValues)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionTableContent', self.gigEVisionParameterUITable)

  self.gigEVisionCurrentParameter = configParams[1]
  self.gigEVisionParameterType = self.gigEVisionParameterAllTypes[self.gigEVisionCurrentParameter]
  self.gigEVisionParameterValue = self.gigEVisionParameterAllValues[self.gigEVisionCurrentParameter]

  local paramList = "["
  if #configParams >= 1 then
    paramList = paramList .. '"' .. configParams[1] .. '"'
  end

  for i = 2, #configParams do
    paramList = paramList .. ', ' .. '"' .. configParams[i] .. '"'
  end
  paramList = paramList .. "]"
  self.gigEVisionParameterList = paramList

  self.gigEVisionConfigUITable = self.helperFuncs.createModuleJsonList('gigEConfig', self.parameters.customGigEVisionConfig)
  Script.notifyEvent('MultiRemoteCamera_OnNewGigEVisionConfigTableContent', self.gigEVisionConfigUITable)
end
    ---------------------------------------------------------------------------------

--- Function to connect the remoteCamera
function multiRemoteCamera:connectCamera()

  self.CameraProvider = Image.Provider.RemoteCamera.create()

  if self.parameters.gigEvision then
    self.CameraProvider:setType('GIGE_VISIONCAM')
  else
    self.CameraProvider:setType('I2DCAM')
  end

  -- Handle image processing
  if self.scriptIsStarted then
    _G.logger:info(nameOfModule .. ": Script is already started")
  else
    Script.startScript(self.parameters.processingFile, self.imageProcessingParams)
    self.scriptIsStarted = true
  end

  self.CameraProvider:setIPAddress(self.parameters.cameraIP)
  Script.notifyEvent("MultiRemoteCamera_OnScanCamera", true)
  self.isConnected = self.CameraProvider:connect()

  Script.notifyEvent('MultiRemoteCamera_OnCameraConnected', self.isConnected)
  _G.logger:info(nameOfModule .. ': Connection to camera = ' .. tostring(self.isConnected))
  Script.notifyEvent("MultiRemoteCamera_OnScanCamera", false)

  if self.isConnected then
    Script.notifyEvent("MultiRemoteCamera_OnRegisterCamera" .. tostring(self.parameters.cameraNo), self.CameraProvider)
    self:setNewConfig()

    if self.parameters.monitorCamera then
      self.cameraIsPingAble = true -- Set first "ping" to monitoring state
    end

  else
    _G.logger:info(nameOfModule .. ": Not possible to connect to Camera No. ".. tostring(self.parameters.cameraNo))
  end
  CSK_MultiRemoteCamera.pageCalled()
end

--- Function to disconnect from remoteCamera
function multiRemoteCamera:disconnectCamera()
  self.CameraProvider:stop()

  Script.notifyEvent("MultiRemoteCamera_OnDeregisterCamera" .. tostring(self.parameters.cameraNo), self.CameraProvider)
  Script.releaseObject(self.CameraProvider)
  self.CameraProvider = nil
  self.isConnected = false
  Script.notifyEvent('MultiRemoteCamera_OnCameraConnected', self.isConnected)
  _G.logger:info(nameOfModule .. ': Disconnected camera.')

end

--- Function to start the camera
function multiRemoteCamera:startCamera()
  self.CameraProvider:start()
end

--- Function to stop the camera
function multiRemoteCamera:stopCamera()
  self.CameraProvider:stop()
end

--- Function to set new camera config
function multiRemoteCamera:setNewConfig()
  if self.isConnected == true then
    _G.logger:info(nameOfModule .. ": Set new config:")
    self.CameraProvider:stop()

    if self.parameters.gigEvision then
      self.CameraConfig = Image.Provider.RemoteCamera.GigEVisionConfig.create()

      _G.logger:info(nameOfModule .. ": GigEVision Config")
      _G.logger:info(nameOfModule .. ": Mode = " .. self.parameters.acquisitionMode)
      _G.logger:info(nameOfModule .. ": Camera-Model: " .. self.parameters.cameraModel)

      if self.parameters.cameraModel == "PicoMidiCam2" then
        self.CameraConfig:setParameterString("AcquisitionMode", "Continuous")
        self.CameraConfig:setParameterString("TriggerSelector", "ExposureStart")

        if self.parameters.acquisitionMode == 'FIXED_FREQUENCY' then
          self.CameraConfig:setParameterString("TriggerMode", "Off")
          self.CameraConfig:setParameterFloat("AcquisitionFrameRate", self.parameters.framerate)

        elseif self.parameters.acquisitionMode == 'HARDWARE_TRIGGER' then
          self.CameraConfig:setParameterString("TriggerMode", "On")
          self.CameraConfig:setParameterString("TriggerSource", "Line0")
          self.CameraConfig:setParameterString("TriggerActivation", "RisingEdge")

        elseif self.parameters.acquisitionMode == 'SOFTWARE_TRIGGER' and self.parameters.gigEvision then
          self.CameraConfig:setParameterString("TriggerSource", "Software")
          self.CameraConfig:setParameterString("TriggerMode", "On")
        end

      elseif self.parameters.cameraModel == "a2A1920-51gcBAS" then
        self.CameraConfig:setParameterString("AcquisitionMode", "Continuous")
        self.CameraConfig:setParameterString("TriggerSelector", "FrameStart")
        self.CameraConfig:setParameterString("BslLightSourcePreset", "Daylight5000K")
        self.CameraConfig:setParameterString("BalanceWhiteAuto", "Off")

        if self.parameters.acquisitionMode == 'FIXED_FREQUENCY' then 
          self.CameraConfig:setParameterString("TriggerMode", "Off") 
          self.CameraConfig:setParameterInteger("AcquisitionFrameRateEnable", 1) 
          self.CameraConfig:setParameterFloat("AcquisitionFrameRate", 
          self.parameters.framerate) 

        elseif self.parameters.acquisitionMode == 'HARDWARE_TRIGGER' then 
          self.CameraConfig:setParameterString("TriggerMode", "On") 
          self.CameraConfig:setParameterString("LineSelector", "Line1") 
          self.CameraConfig:setParameterString("LineMode", "Input") 
          self.CameraConfig:setParameterString("TriggerSource", "Line1") 
          self.CameraConfig:setParameterString("TriggerActivation", "RisingEdge") 

        elseif self.parameters.acquisitionMode == 'SOFTWARE_TRIGGER' then
          self.CameraConfig:setParameterString("TriggerMode", "On") 
          self.CameraConfig:setParameterString("TriggerSource", "Software")
        end
      end

      -- Cameras on single ethernet switch mode
      if self.parameters.switchMode then
        -- Available network load divided by the amount of connected cameras = value for DeviceLinkThroughputLimit in MBit/s
        -- Insert value in byte/s (value for DeviceLinkThroughputLimit divided by 8bit)
        if deviceType == "SIM1012" or deviceType == "SIM1004" then
          self.CameraConfig:setParameterInteger("DeviceLinkThroughputLimit", 300000000 / self.parameters.camSum / 8)
        else
          self.CameraConfig:setParameterInteger("DeviceLinkThroughputLimit", 1000000000 / self.parameters.camSum / 8)
        end

      -- Set this value even if not in switch mode to prevent image errors
      else
        if deviceType == "SIM1012" or deviceType == "SIM1004" then
          self.CameraConfig:setParameterInteger("DeviceLinkThroughputLimit", 300000000 / 8)
        end
      end

      if deviceType ~= "SIM4000" then
        self.CameraConfig:setParameterInteger("[Stream]GevStreamReceiveSocketSize", 4194304)
      end

      -- Custom GigE Vision config
      if #self.parameters.customGigEVisionConfig >= 1 then
        for i = 1, #self.parameters.customGigEVisionConfig do
          local suc

          if self.parameters.customGigEVisionConfig[i].type == 'GIGE_PARAM_TYPE_INTEGER' then
            suc = self.CameraConfig:setParameterInteger(self.parameters.customGigEVisionConfig[i].parameter, tonumber(self.parameters.customGigEVisionConfig[i].value))
          elseif self.parameters.customGigEVisionConfig[i].type == 'GIGE_PARAM_TYPE_STRING' then
            suc = self.CameraConfig:setParameterString(self.parameters.customGigEVisionConfig[i].parameter, tostring(self.parameters.customGigEVisionConfig[i].value))
          elseif self.parameters.customGigEVisionConfig[i].type == 'GIGE_PARAM_TYPE_FLOAT' then
            suc = self.CameraConfig:setParameterFloat(self.parameters.customGigEVisionConfig[i].parameter, tonumber(self.parameters.customGigEVisionConfig[i].value))
          end

          _G.logger:info(nameOfModule .. ": Success of new GigEVision value for parameter " .. self.parameters.customGigEVisionConfig[i].parameter .. ", value = " .. tostring(self.parameters.customGigEVisionConfig[i].value) .. " = " .. tostring(suc))
        end
      end

    else --No GigEVision Camera
      self.CameraConfig = Image.Provider.RemoteCamera.I2DConfig.create()

      _G.logger:info(nameOfModule .. ": I2D Config")

      if self.parameters.switchMode then
        self.CameraConfig:setPacketInterval(self.parameters.camSum * 20)
      end

      _G.logger:info(nameOfModule .. ": Mode = " .. self.parameters.acquisitionMode)

      if self.parameters.acquisitionMode == 'FIXED_FREQUENCY' then
        self.CameraConfig:setFrameRate(self.parameters.framerate)
        _G.logger:info(nameOfModule .. ": Framerate = " .. self.parameters.framerate)
      elseif self.parameters.acquisitionMode == 'HARDWARE_TRIGGER' then
        self.CameraConfig:setHardwareTriggerMode("LO_HI")
      end
      self.CameraConfig:setColorMode(self.parameters.colorMode)
      _G.logger:info(nameOfModule .. ": ColorMode = " .. self.parameters.colorMode)
      self.CameraConfig:setAcquisitionMode(self.parameters.acquisitionMode)
    end

    self.CameraConfig:setShutterTime(self.parameters.shutterTime)
    self.CameraConfig:setGainFactor(self.parameters.gain)
    self.CameraConfig:setFieldOfView(self.parameters.xStartFOV, self.parameters.xEndFOV, self.parameters.yStartFOV, self.parameters.yEndFOV)

    _G.logger:info(nameOfModule .. ": Shutter time = " .. tostring(self.parameters.shutterTime))
    _G.logger:info(nameOfModule .. ": Gain = " .. tostring(self.parameters.gain))

    local configSuc = self.CameraProvider:setConfig(self.CameraConfig)
    if configSuc then
      local startSuc = self.CameraProvider:start()
      _G.logger:info(nameOfModule .. ": Starting of camera = " .. tostring(startSuc))
      if startSuc == false then
        self:disconnectCamera()
        return
      end
    else
      self:disconnectCamera()
      return
    end
    if self.parameters.gigEvision then
      self:updateGigEVision()
    end

  else
    _G.logger:info(nameOfModule .. ": Did not set new config to camera No. " .. tostring(self.parameters.cameraNo) .. ", because no camera is connected.")
  end
end

--- Function to set color mode of the camera
function multiRemoteCamera:setColorMode(mode)
  if mode ~= 'COLOR8' and mode ~= 'MONO8' and mode ~= 'RAW8' then
    mode = 'MONO8'
  end
  self.parameters.colorMode = mode
  self:setNewConfig()
end

--- Function to set the shutter time of the camera
---@param value int Shutter time
function multiRemoteCamera:setShutterTime(value)
  self.parameters.shutterTime = value
  self:setNewConfig()
end

--- Function to set the gain of the camera
---@param value float Gain
function multiRemoteCamera:setGain(value)
  self.parameters.gain = value
  self:setNewConfig()
end

--- Function to set the framerate of the camera
---@param value int Framerate
function multiRemoteCamera:setFramerate(value)
  self.parameters.framerate = value
  if self.parameters.acquisitionMode == 'FIXED_FREQUENCY' then
    self:setNewConfig()
  end
end

--- Function to set the trigger mode of the camera
---@param mode string Acquisition mode
function multiRemoteCamera:setAcquisitionMode(mode)
  self.parameters.acquisitionMode = mode
  self:setNewConfig()
end

--- Function to set the preconfigured FOV
function multiRemoteCamera:setFOV()
  self:setNewConfig()
end

--- Function to check if camera is still connected
function multiRemoteCamera:pingCamera()
  local cameraIsPingAble = false
  if self.isConnected then
    self.cameraIsPingAble = Ethernet.ping(self.parameters.cameraIP)
  else
    _G.logger:warning(nameOfModule .. ": Camera no. " .. tostring(self.parameters.cameraNo) .. " is not connected, please connect!")
  end
end

return multiRemoteCamera

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
