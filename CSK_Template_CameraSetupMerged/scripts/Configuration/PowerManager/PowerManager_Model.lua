---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the PowerManagement_Model definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_PowerManager'

local powerManager_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
powerManager_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
powerManager_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
powerManager_Model.parametersName = 'CSK_PowerManager_Parameter' -- name of parameter dataset to be used for this module
powerManager_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

-- Load script to communicate with the PowerManager_Model UI and give access
-- to the PowerManager_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setPowerManager_Model_Handle = require('Configuration/PowerManager/PowerManager_Controller')
setPowerManager_Model_Handle(powerManager_Model)

powerManager_Model.moduleActive = true -- Features provided by device (APIs available)
powerManager_Model.helperFuncs = require('Configuration/PowerManager/helper/funcs') -- General helper functions
powerManager_Model.parameters = {} -- Parameters to save persistently
powerManager_Model.status = {} -- Holding curent status of connector ports
powerManager_Model.handles = {} -- Handles of the power connectors
powerManager_Model.interfaceList = '' -- List of power connectors

-- Check if needed CROWN is available on device
if Connector == nil then
  powerManager_Model.moduleActive = false
  _G.logger:warning(nameOfModule .. ': CROWN is not available. Module is not supported...')
else
  if Connector.Power == nil then
    powerManager_Model.moduleActive = false
    _G.logger:warning(nameOfModule .. ': CROWN is not available. Module is not supported...')
  end
end

if powerManager_Model.moduleActive then
  local powerConnectors = Engine.getEnumValues("PowerConnectors") -- Get availbale connectors
  for i = 1, #powerConnectors do
    local name = powerConnectors[i]
    if not(name:match("^INMAIN$") or name:match("^P%d$") or name:match("VIN%d")) then
      local powerHandle = Connector.Power.create(name)
      if powerHandle then
        powerManager_Model.handles[name] = powerHandle
        powerManager_Model.parameters[name] = powerManager_Model.handles[name]:isEnabled()
        powerManager_Model.status[name] = tostring(powerManager_Model.handles[name]:isEnabled())
      end
    end
  end
end
powerManager_Model.interfaceList = powerManager_Model.helperFuncs.createJsonList(powerManager_Model.parameters, powerManager_Model.status)

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

local function changeStatusOfPort(portName)
  _G.logger:info(nameOfModule .. ": Change status of port " .. portName)

  for key, _ in pairs(powerManager_Model.parameters) do
    if key == portName then
      if powerManager_Model.parameters[key] == true and powerManager_Model.status[key] == powerManager_Model.helperFuncs.status.on then
        powerManager_Model.parameters[key] = false
        powerManager_Model.status[key] = powerManager_Model.helperFuncs.status.on2off

      elseif powerManager_Model.parameters[key] == false and powerManager_Model.status[key] == powerManager_Model.helperFuncs.status.on2off then
        powerManager_Model.parameters[key] = true
        powerManager_Model.status[key] = powerManager_Model.helperFuncs.status.on

      elseif powerManager_Model.parameters[key] == false and powerManager_Model.status[key] == powerManager_Model.helperFuncs.status.off then
        powerManager_Model.parameters[key] = true
        powerManager_Model.status[key] = powerManager_Model.helperFuncs.status.off2on

      elseif powerManager_Model.parameters[key] == true and powerManager_Model.status[key] == powerManager_Model.helperFuncs.status.off2on then
        powerManager_Model.parameters[key] = false
        powerManager_Model.status[key] = powerManager_Model.helperFuncs.status.off
      end

    powerManager_Model.interfaceList = powerManager_Model.helperFuncs.createJsonList(powerManager_Model.parameters, powerManager_Model.status)
    Script.notifyEvent("PowerManager_OnNewInterfaceList", powerManager_Model.interfaceList)
    return

    end
  end
end
Script.serveFunction("CSK_PowerManager.changeStatusOfPort", changeStatusOfPort)
powerManager_Model.changeStatusOfPort = changeStatusOfPort

local function getCurrentPortStatus(port)
  if powerManager_Model.handles[port] then
    return powerManager_Model.handles[port]:isEnabled()
  else
    return nil
  end
end
Script.serveFunction("CSK_PowerManager.getCurrentPortStatus", getCurrentPortStatus)
powerManager_Model.getCurrentPortStatus = getCurrentPortStatus

local function setAllStatus()
  _G.logger:info(nameOfModule .. ": Set new status.")

  for key, _ in pairs(powerManager_Model.status) do
    powerManager_Model.status[key] = tostring(powerManager_Model.parameters[key])
    powerManager_Model.handles[key]:enable(powerManager_Model.parameters[key])
  end

  powerManager_Model.interfaceList = powerManager_Model.helperFuncs.createJsonList(powerManager_Model.parameters, powerManager_Model.status)
  Script.notifyEvent("PowerManager_OnNewInterfaceList", powerManager_Model.interfaceList)
end
Script.serveFunction("CSK_PowerManager.setAllStatus", setAllStatus)
powerManager_Model.setAllStatus = setAllStatus

return powerManager_Model

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************
