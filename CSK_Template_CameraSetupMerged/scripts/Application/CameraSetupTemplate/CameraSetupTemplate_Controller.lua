---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the CameraSetupTemplate_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_CameraSetupTemplate'

-- Timer to update UI via events after page was loaded
local tmrCameraSetupTemplate = Timer.create()
tmrCameraSetupTemplate:setExpirationTime(300)
tmrCameraSetupTemplate:setPeriodic(false)

-- Reference to global handle
local cameraSetupTemplate_Model

-- ************************ UI Events Start ********************************

-- Script.serveEvent("CSK_CameraSetupTemplate.OnNewEvent", "CameraSetupTemplate_OnNewEvent")

Script.serveEvent('CSK_CameraSetupTemplate.OnNewStatusWaitingForSetup', 'CameraSetupTemplate_OnNewStatusWaitingForSetup')

Script.serveEvent("CSK_CameraSetupTemplate.OnNewStatusLoadParameterOnReboot", "CameraSetupTemplate_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_CameraSetupTemplate.OnPersistentDataModuleAvailable", "CameraSetupTemplate_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_CameraSetupTemplate.OnNewParameterName", "CameraSetupTemplate_OnNewParameterName")
Script.serveEvent("CSK_CameraSetupTemplate.OnDataLoadedOnReboot", "CameraSetupTemplate_OnDataLoadedOnReboot")

Script.serveEvent('CSK_CameraSetupTemplate.OnUserLevelOperatorActive', 'CameraSetupTemplate_OnUserLevelOperatorActive')
Script.serveEvent('CSK_CameraSetupTemplate.OnUserLevelMaintenanceActive', 'CameraSetupTemplate_OnUserLevelMaintenanceActive')
Script.serveEvent('CSK_CameraSetupTemplate.OnUserLevelServiceActive', 'CameraSetupTemplate_OnUserLevelServiceActive')
Script.serveEvent('CSK_CameraSetupTemplate.OnUserLevelAdminActive', 'CameraSetupTemplate_OnUserLevelAdminActive')

-- ...

-- ************************ UI Events End **********************************

--[[
--- Some internal code docu for local used function
local function functionName()
  -- Do something

end
]]

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
  Script.notifyEvent("CameraSetupTemplate_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("CameraSetupTemplate_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("CameraSetupTemplate_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("CameraSetupTemplate_OnUserLevelAdminActive", status)
end

--- Function to get access to the cameraSetupTemplate_Model object
---@param handle handle Handle of cameraSetupTemplate_Model object
local function setCameraSetupTemplate_Model_Handle(handle)
  cameraSetupTemplate_Model = handle
  if cameraSetupTemplate_Model.userManagementModuleAvailable then
    -- Register on events of CSK_UserManagement module if available
    Script.register('CSK_UserManagement.OnUserLevelOperatorActive', handleOnUserLevelOperatorActive)
    Script.register('CSK_UserManagement.OnUserLevelMaintenanceActive', handleOnUserLevelMaintenanceActive)
    Script.register('CSK_UserManagement.OnUserLevelServiceActive', handleOnUserLevelServiceActive)
    Script.register('CSK_UserManagement.OnUserLevelAdminActive', handleOnUserLevelAdminActive)
  end
  Script.releaseObject(handle)
end

--- Function to update user levels
local function updateUserLevel()
  if cameraSetupTemplate_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("CameraSetupTemplate_OnUserLevelAdminActive", true)
    Script.notifyEvent("CameraSetupTemplate_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("CameraSetupTemplate_OnUserLevelServiceActive", true)
    Script.notifyEvent("CameraSetupTemplate_OnUserLevelOperatorActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrCameraSetupTemplate()

  updateUserLevel()

  -- Script.notifyEvent("CameraSetupTemplate_OnNewEvent", false)

  Script.notifyEvent("CameraSetupTemplate_OnNewStatusWaitingForSetup", cameraSetupTemplate_Model.cameraSetupStatus)

  Script.notifyEvent("CameraSetupTemplate_OnNewStatusLoadParameterOnReboot", cameraSetupTemplate_Model.parameterLoadOnReboot)
  Script.notifyEvent("CameraSetupTemplate_OnPersistentDataModuleAvailable", cameraSetupTemplate_Model.persistentModuleAvailable)
  Script.notifyEvent("CameraSetupTemplate_OnNewParameterName", cameraSetupTemplate_Model.parametersName)
  -- ...
end
Timer.register(tmrCameraSetupTemplate, "OnExpired", handleOnExpiredTmrCameraSetupTemplate)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrCameraSetupTemplate:start()
  return ''
end
Script.serveFunction("CSK_CameraSetupTemplate.pageCalled", pageCalled)

local function loadDefaultSetup()
  cameraSetupTemplate_Model.setupDefaultConfig()
end
Script.serveFunction('CSK_CameraSetupTemplate.loadDefaultSetup', loadDefaultSetup)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  cameraSetupTemplate_Model.parametersName = name
  _G.logger:info(nameOfModule .. ": Set parameter name to: " .. tostring(name))
end
Script.serveFunction("CSK_CameraSetupTemplate.setParameterName", setParameterName)

local function sendParameters()
  if cameraSetupTemplate_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(cameraSetupTemplate_Model.helperFuncs.convertTable2Container(cameraSetupTemplate_Model.parameters), cameraSetupTemplate_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, cameraSetupTemplate_Model.parametersName, cameraSetupTemplate_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send CameraSetupTemplate parameters with name '" .. cameraSetupTemplate_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_CameraSetupTemplate.sendParameters", sendParameters)

local function loadParameters()
  if cameraSetupTemplate_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(cameraSetupTemplate_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      cameraSetupTemplate_Model.parameters = cameraSetupTemplate_Model.helperFuncs.convertContainer2Table(data)
      -- If something needs to be configured/activated with new loaded data, place this here:
      -- ...
      -- ...

      CSK_CameraSetupTemplate.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_CameraSetupTemplate.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  cameraSetupTemplate_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_CameraSetupTemplate.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

    cameraSetupTemplate_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

    if parameterName then
      cameraSetupTemplate_Model.parametersName = parameterName
      cameraSetupTemplate_Model.parameterLoadOnReboot = loadOnReboot
    end

    if cameraSetupTemplate_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('CameraSetupTemplate_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setCameraSetupTemplate_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

