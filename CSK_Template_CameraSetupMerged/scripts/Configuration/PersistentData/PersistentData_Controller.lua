---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate via UI with the PersistentData_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_PersistentData'

-- Reference to global handle
local persistentData_Model

-- Timer to notify all relevant events on-resume
local tmrPersistendData = Timer.create()
tmrPersistendData:setExpirationTime(300)
tmrPersistendData:setPeriodic(false)

local currentSelectedParameters = '' -- Selected Parameter

-- ************************ UI Events Start ********************************

Script.serveEvent("CSK_PersistentData.OnNewDataPath", "PersistentData_OnNewDataPath")
Script.serveEvent("CSK_PersistentData.OnNewFeedbackStatus", "PersistentData_OnNewFeedbackStatus")
Script.serveEvent("CSK_PersistentData.OnNewContent", "PersistentData_OnNewContent")
Script.serveEvent("CSK_PersistentData.OnNewDatasetList", "PersistentData_OnNewDatasetList")
Script.serveEvent("CSK_PersistentData.OnNewParameterSelection", "PersistentData_OnNewParameterSelection")

Script.serveEvent("CSK_PersistentData.OnNewParameterTableInfo", "PersistentData_OnNewParameterTableInfo")
Script.serveEvent('CSK_PersistentData.OnNewStatusTempFileAvailable', 'PersistentData_OnNewStatusTempFileAvailable')

Script.serveEvent("CSK_PersistentData.OnUserLevelOperatorActive", "PersistentData_OnUserLevelOperatorActive")
Script.serveEvent("CSK_PersistentData.OnUserLevelMaintenanceActive", "PersistentData_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_PersistentData.OnUserLevelServiceActive", "PersistentData_OnUserLevelServiceActive")
Script.serveEvent("CSK_PersistentData.OnUserLevelAdminActive", "PersistentData_OnUserLevelAdminActive")

Script.serveEvent("CSK_PersistentData.OnInitialDataLoaded", "PersistentData_OnInitialDataLoaded")
Script.serveEvent('CSK_PersistentData.OnInstanceAmountAvailable', 'PersistentData_OnInstanceAmountAvailable')

Script.serveEvent('CSK_PersistentData.OnNewUserManagementTrigger', 'PersistentData_OnNewUserManagementTrigger')

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
  Script.notifyEvent("PersistentData_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("PersistentData_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("PersistentData_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("PersistentData_OnUserLevelAdminActive", status)
end

--- Function to get access to the persistentData_Model object
---@param handle handle Handle of persistentData_Model object
local function setPersistentData_Model_Handle(handle)
  persistentData_Model = handle
  if persistentData_Model.userManagementModuleAvailable then
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
  if persistentData_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    Script.notifyEvent("PersistentData_OnNewUserManagementTrigger")
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("PersistentData_OnUserLevelOperatorActive", true)
    Script.notifyEvent("PersistentData_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("PersistentData_OnUserLevelServiceActive", true)
    Script.notifyEvent("PersistentData_OnUserLevelAdminActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrPersistendData()

  updateUserLevel()

  Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)
  Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'EMPTY')
  Script.notifyEvent('PersistentData_OnNewDatasetList', persistentData_Model.funcs.createJsonList(persistentData_Model.data))
  if currentSelectedParameters ~= '' then
    Script.notifyEvent('PersistentData_OnNewParameterSelection', currentSelectedParameters)
  end
  Script.notifyEvent('PersistentData_OnNewParameterTableInfo', persistentData_Model.funcs.createJsonListForTableView(persistentData_Model.data[currentSelectedParameters]))
  Script.notifyEvent('PersistentData_OnNewStatusTempFileAvailable', File.exists(persistentData_Model.tempPath))
end
Timer.register(tmrPersistendData, "OnExpired", handleOnExpiredTmrPersistendData)

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrPersistendData:start()
  return ''
end
Script.serveFunction("CSK_PersistentData.pageCalled", pageCalled)

local function getVersion()
  if _APPNAME == 'CSK_Module_PersistentData' then
    return Engine.getCurrentAppVersion()
  else
    return '3.0.0'
  end
end
Script.serveFunction("CSK_PersistentData.getVersion", getVersion)

local function addParameter(data, name)
  local dataTable = persistentData_Model.funcs.convertContainer2Table(data)
  persistentData_Model.addParameterTable(dataTable, name)
  Script.releaseObject(data)
  tmrPersistendData:start()
end
Script.serveFunction("CSK_PersistentData.addParameter", addParameter)

local function getParameter(name)
  if persistentData_Model.data[name] ~= nil then
    local dataContainer = persistentData_Model.funcs.convertTable2Container(persistentData_Model.data[name])
    _G.logger:info(nameOfModule .. ": Provide parameter: " .. tostring(name))
    return dataContainer
  else
    _G.logger:info(nameOfModule .. ": Parameter not available: " .. tostring(name))
    return nil
  end
end
Script.serveFunction("CSK_PersistentData.getParameter", getParameter)

local function getParameterList()
 return persistentData_Model.contentList
end
Script.serveFunction("CSK_PersistentData.getParameterList", getParameterList)

local function setModuleParameterName(module, name, loadOnReboot, instance, totalInstances)
  if instance then
    local pos = module .. instance
    _G.logger:info(nameOfModule .. ': Set module parameter name: ' .. tostring(name) .. ' of instance no.' .. tostring(instance) .. ' of module ' .. tostring(module))
    persistentData_Model.parameters.parameterNames[pos] = name
    persistentData_Model.parameters.loadOnReboot[pos] = loadOnReboot

    if totalInstances then
      -- Store amount of instances to create for this module
      _G.logger:info(nameOfModule .. ': Set total instances: ' .. tostring(totalInstances))
      persistentData_Model.parameters.totalInstances[module] = totalInstances
    end

  else
    _G.logger:info(nameOfModule .. ': Set module parameter name: "' .. tostring(name) .. '" of module ' .. tostring(module))
    persistentData_Model.parameters.parameterNames[module] = name
    persistentData_Model.parameters.loadOnReboot[module] = loadOnReboot
  end

  CSK_PersistentData.addParameter(persistentData_Model.funcs.convertTable2Container(persistentData_Model.parameters), 'PersistentData_InitialParameterNames')

end
Script.serveFunction("CSK_PersistentData.setModuleParameterName", setModuleParameterName)

local function getModuleParameterName(module, instance)
  if instance then
    local pos = module .. instance
    if persistentData_Model.parameters.parameterNames[pos] then
      if not persistentData_Model.parameters.totalInstances[module] then -- available since version 3.0.0
        return persistentData_Model.parameters.parameterNames[pos], persistentData_Model.parameters.loadOnReboot[pos]
      else
        return persistentData_Model.parameters.parameterNames[pos], persistentData_Model.parameters.loadOnReboot[pos], persistentData_Model.parameters.totalInstances[module]
      end
    else
      return nil
    end
  else
    if persistentData_Model.parameters.parameterNames[module] then
      return persistentData_Model.parameters.parameterNames[module], persistentData_Model.parameters.loadOnReboot[module]
    else
      return nil
    end
  end
end
Script.serveFunction("CSK_PersistentData.getModuleParameterName", getModuleParameterName)

local function setSelectedParameterName(selection)
  if persistentData_Model.data[selection] then
    _G.logger:info(nameOfModule .. ': Selected parameter: ' .. tostring(selection))
    currentSelectedParameters = selection
  else
    _G.logger:info(nameOfModule .. ': Parameter not available: ' .. tostring(selection))
  end
  Script.notifyEvent('PersistentData_OnNewParameterTableInfo', persistentData_Model.funcs.createJsonListForTableView(persistentData_Model.data[currentSelectedParameters]))
end
Script.serveFunction("CSK_PersistentData.setSelectedParameterName", setSelectedParameterName)

local function removeParameterViaUI()
  if currentSelectedParameters ~= '' then
    _G.logger:info(nameOfModule .. ': Remove parameter: ' .. tostring(currentSelectedParameters))
    persistentData_Model.removeParameter(currentSelectedParameters)
    currentSelectedParameters = ''
    tmrPersistendData:start()
  else
    _G.logger:info(nameOfModule .. ': Parameter to remove not available.')
  end
end
Script.serveFunction("CSK_PersistentData.removeParameterViaUI", removeParameterViaUI)

local function fileUploadFinished(status)
  _G.logger:info(nameOfModule .. ': File upload: ' .. tostring(status))
  if status then
    Script.notifyEvent('PersistentData_OnNewStatusTempFileAvailable', File.exists(persistentData_Model.tempPath))
  end
end
Script.serveFunction('CSK_PersistentData.fileUploadFinished', fileUploadFinished)

return setPersistentData_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************