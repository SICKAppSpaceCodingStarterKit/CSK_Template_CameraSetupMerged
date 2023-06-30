---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the PowerManager_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_PowerManager'

-- Timer to update UI via events after page was loaded
local tmrPowerManager = Timer.create()
tmrPowerManager:setExpirationTime(300)
tmrPowerManager:setPeriodic(false)

local selectedInterfaceNo = '' -- Current selected interface to edit

-- Reference to global handle
local powerManager_Model

-- ************************ UI Events Start ********************************

Script.serveEvent("CSK_PowerManager.OnUserLevelOperatorActive", "PowerManager_OnUserLevelOperatorActive")
Script.serveEvent("CSK_PowerManager.OnUserLevelMaintenanceActive", "PowerManager_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_PowerManager.OnUserLevelServiceActive", "PowerManager_OnUserLevelServiceActive")
Script.serveEvent("CSK_PowerManager.OnUserLevelAdminActive", "PowerManager_OnUserLevelAdminActive")

Script.serveEvent('CSK_PowerManager.OnNewStatusModuleIsActive', 'PowerManager_OnNewStatusModuleIsActive')
Script.serveEvent("CSK_PowerManager.OnNewInterfaceList", "PowerManager_OnNewInterfaceList")
Script.serveEvent("CSK_PowerManager.OnNewStatusLoadParameterOnReboot", "PowerManager_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_PowerManager.OnPersistentDataModuleAvailable", "PowerManager_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_PowerManager.OnDataLoadedOnReboot", "PowerManager_OnDataLoadedOnReboot")
Script.serveEvent("CSK_PowerManager.OnNewParameterName", "PowerManager_OnNewParameterName")

-- ************************ UI Events End **********************************
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
  Script.notifyEvent("PowerManager_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("PowerManager_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("PowerManager_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("PowerManager_OnUserLevelAdminActive", status)
end

--- Function to get access to the powerManager_Model object
---@param handle handle Handle of powerManager_Model object
local function setPowerManager_Model_Handle(handle)
  powerManager_Model = handle
  if powerManager_Model.userManagementModuleAvailable then
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
  if powerManager_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("PowerManager_OnUserLevelOperatorActive", true)
    Script.notifyEvent("PowerManager_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("PowerManager_OnUserLevelServiceActive", true)
    Script.notifyEvent("PowerManager_OnUserLevelAdminActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrPowerManager()

  updateUserLevel()

  Script.notifyEvent("PowerManager_OnNewStatusModuleIsActive", powerManager_Model.moduleActive)
  Script.notifyEvent("PowerManager_OnNewInterfaceList", powerManager_Model.interfaceList)
  Script.notifyEvent("PowerManager_OnPersistentDataModuleAvailable", powerManager_Model.persistentModuleAvailable)
  Script.notifyEvent("PowerManager_OnNewStatusLoadParameterOnReboot", powerManager_Model.parameterLoadOnReboot)
  Script.notifyEvent("PowerManager_OnNewParameterName", powerManager_Model.parametersName)

end
Timer.register(tmrPowerManager, "OnExpired", handleOnExpiredTmrPowerManager)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  selectedInterfaceNo = ''
  tmrPowerManager:start()
  return ''
end
Script.serveFunction("CSK_PowerManager.pageCalled", pageCalled)

local function selectInterface(selection)

  if selection == "" then
    selectedInterfaceNo = ''
  else
    local _, pos = string.find(selection, '"PowerConnector":"')
    if pos == nil then
      _G.logger:info(nameOfModule .. ": Did not find PowerConnector")
      selectedInterfaceNo = ''
    else
      pos = tonumber(pos)
      local endPos = string.find(selection, '"', pos+1)
      selectedInterfaceNo = string.sub(selection, pos+1, endPos-1)

      if selectedInterfaceNo == nil then
        selectedInterfaceNo = ''
      end
    end
  end
  _G.logger:info(nameOfModule .. ": Selected PowerConnector = " .. tostring(selectedInterfaceNo))
  if selectedInterfaceNo ~= '' then
    powerManager_Model.changeStatusOfPort(selectedInterfaceNo)
  end
end
Script.serveFunction("CSK_PowerManager.selectInterface", selectInterface)

-- *****************************************************************
-- Following functions can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  powerManager_Model.parametersName = name
  _G.logger:info(nameOfModule .. ": Set new parameter name: " .. tostring(name))
end
Script.serveFunction("CSK_PowerManager.setParameterName", setParameterName)

local function sendParameters()
  if powerManager_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(powerManager_Model.helperFuncs.convertTable2Container(powerManager_Model.parameters), powerManager_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, powerManager_Model.parametersName, powerManager_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send PowerManager parameters with name '" .. powerManager_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_PowerManager.sendParameters", sendParameters)

local function loadParameters()
  if powerManager_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(powerManager_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      powerManager_Model.parameters = powerManager_Model.helperFuncs.convertContainer2Table(data)
      powerManager_Model.setAllStatus()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_PowerManager.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  powerManager_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_PowerManager.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  _G.logger:info(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
  if powerManager_Model.moduleActive then
    if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

      _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')

      powerManager_Model.persistentModuleAvailable = false
    else

      local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

      if parameterName then
        powerManager_Model.parametersName = parameterName
        powerManager_Model.parameterLoadOnReboot = loadOnReboot
      end

      if powerManager_Model.parameterLoadOnReboot then
        loadParameters()
      end
      Script.notifyEvent('PowerManager_OnDataLoadedOnReboot')
    end
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setPowerManager_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************