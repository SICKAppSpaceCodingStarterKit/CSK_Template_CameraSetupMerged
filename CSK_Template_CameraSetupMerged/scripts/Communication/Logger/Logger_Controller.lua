---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the Logger_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************
local nameOfModule = 'CSK_Logger'

local lastMessage = '' -- Latest receivced logging message

-- Timer to update UI via events after page was loaded
local tmrLogger = Timer.create()
tmrLogger:setExpirationTime(300)
tmrLogger:setPeriodic(false)

local logger_Model -- Reference to global handle

-- ************************ UI Events Start ********************************

Script.serveEvent("CSK_Logger.OnNewMessage", "Logger_OnNewMessage")
Script.serveEvent("CSK_Logger.OnNewCompleteLogfile", "Logger_OnNewCompleteLogfile")
Script.serveEvent("CSK_Logger.OnNewFilepath", "Logger_OnNewFilepath")
Script.serveEvent("CSK_Logger.OnNewFilename", "Logger_OnNewFilename")
Script.serveEvent("CSK_Logger.OnNewFullFilePath", "Logger_OnNewFullFilePath")
Script.serveEvent('CSK_Logger.OnNewLogfileSize', 'Logger_OnNewLogfileSize')

Script.serveEvent("CSK_Logger.OnNewLogLevel", "Logger_OnNewLogLevel")
Script.serveEvent("CSK_Logger.OnNewStatusConsoleSink", "Logger_OnNewStatusConsoleSink")
Script.serveEvent("CSK_Logger.OnNewStatusAttachedToEngineLogger", "Logger_OnNewStatusAttachedToEngineLogger")
Script.serveEvent("CSK_Logger.OnNewStatusFileSinkActive", "Logger_OnNewStatusFileSinkActive")
Script.serveEvent('CSK_Logger.OnNewStatusCallbackSink', 'Logger_OnNewStatusCallbackSink')

Script.serveEvent("CSK_Logger.OnUserLevelOperatorActive", "Logger_OnUserLevelOperatorActive")
Script.serveEvent("CSK_Logger.OnUserLevelMaintenanceActive", "Logger_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_Logger.OnUserLevelServiceActive", "Logger_OnUserLevelServiceActive")
Script.serveEvent("CSK_Logger.OnUserLevelAdminActive", "Logger_OnUserLevelAdminActive")

Script.serveEvent("CSK_Logger.OnNewStatusLoadParameterOnReboot", "Logger_OnNewStatusLoadParameterOnReboot")
Script.serveEvent("CSK_Logger.OnPersistentDataModuleAvailable", "Logger_OnPersistentDataModuleAvailable")
Script.serveEvent("CSK_Logger.OnDataLoadedOnReboot", "Logger_OnDataLoadedOnReboot")
Script.serveEvent("CSK_Logger.OnNewParameterName", "Logger_OnNewParameterName")

-- ************************ UI Events End **********************************

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on status change of Operator user level
---@param status boolean Status if Operator level is active
local function handleOnUserLevelOperatorActive(status)
  Script.notifyEvent("Logger_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("Logger_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("Logger_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("Logger_OnUserLevelAdminActive", status)
end

--- Function to get access to the logger_Model object
---@param handle handle Handle of logger_Model object
local function setLogger_Model_Handle(handle)
  logger_Model = handle
  if logger_Model.userManagementModuleAvailable then
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
  if logger_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("Logger_OnUserLevelOperatorActive", true)
    Script.notifyEvent("Logger_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("Logger_OnUserLevelServiceActive", true)
    Script.notifyEvent("Logger_OnUserLevelAdminActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrLogger()

  updateUserLevel()

  if logger_Model.parameters.callBackSink and not logger_Model.parameters.fileSinkActive then
    logger_Model.sendLog()
  end
  Script.notifyEvent('Logger_OnNewFilepath', logger_Model.parameters.filePath)
  Script.notifyEvent('Logger_OnNewFilename', logger_Model.parameters.fileName)
  Script.notifyEvent('Logger_OnNewFullFilePath', logger_Model.parameters.filePath .. logger_Model.parameters.fileName)
  Script.notifyEvent('Logger_OnNewLogfileSize', logger_Model.parameters.logSize)
  Script.notifyEvent('Logger_OnNewMessage', lastMessage)

  Script.notifyEvent('Logger_OnNewLogLevel', logger_Model.parameters.level)
  Script.notifyEvent('Logger_OnNewStatusConsoleSink', logger_Model.parameters.setConsoleSinkEnabled)
  Script.notifyEvent('Logger_OnNewStatusAttachedToEngineLogger', logger_Model.parameters.attachToEngineLogger)
  Script.notifyEvent('Logger_OnNewStatusFileSinkActive', logger_Model.parameters.fileSinkActive)
  Script.notifyEvent('Logger_OnNewStatusCallbackSink', logger_Model.parameters.callBackSink)

  Script.notifyEvent("Logger_OnNewStatusLoadParameterOnReboot", logger_Model.parameterLoadOnReboot)
  Script.notifyEvent("Logger_OnPersistentDataModuleAvailable", logger_Model.persistentModuleAvailable)
  Script.notifyEvent("Logger_OnNewParameterName", logger_Model.parametersName)

end
Timer.register(tmrLogger, "OnExpired", handleOnExpiredTmrLogger)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  tmrLogger:start()
  return ''
end
Script.serveFunction("CSK_Logger.pageCalled", pageCalled)

--- Function to keep latest log message
---@param message string Latest log message
local function handleOnNewMessage(message)
  lastMessage = message
end
Script.register("CSK_Logger.OnNewMessage", handleOnNewMessage)

local function setFilePath(path)
  _G.logger:info(nameOfModule .. ': Set file path to ' .. path)
  logger_Model.parameters.filePath = path
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setFilePath", setFilePath)

local function setFileName(name)
  _G.logger:info(nameOfModule .. ': Set filename to ' .. name)
  logger_Model.parameters.fileName = name
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setFileName", setFileName)

local function setLogLevel(level)
  _G.logger:info(nameOfModule .. ': Set log level to ' .. level)
  logger_Model.parameters.level = level
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setLogLevel", setLogLevel)

local function setConsoleSinkEnabled(status)
  _G.logger:info(nameOfModule .. ': Set "console sink" status to ' .. tostring(status))
  logger_Model.parameters.setConsoleSinkEnabled = status
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setConsoleSinkEnabled", setConsoleSinkEnabled)

local function setAttachToEngineLogger(status)
  _G.logger:info(nameOfModule .. ': Attach to engine logger status = ' .. tostring(status))
  logger_Model.parameters.attachToEngineLogger = status
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setAttachToEngineLogger", setAttachToEngineLogger)

local function setFileSinkActive(status)
  _G.logger:info(nameOfModule .. ': File Sink status = ' .. tostring(status))
  logger_Model.parameters.fileSinkActive = status
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction("CSK_Logger.setFileSinkActive", setFileSinkActive)

local function setLogFileSize(size)
  _G.logger:info(nameOfModule .. ': Set logfile size to ' .. tostring(size) .. ' bytes.')
  logger_Model.parameters.logSize = size
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction('CSK_Logger.setLogFileSize', setLogFileSize)

local function setCallbackSinkActive(status)
  _G.logger:info(nameOfModule .. ': Set status of callBackSink to ' .. tostring(status))
  logger_Model.parameters.callBackSink = status
  logger_Model.setupLogHandler()
  handleOnExpiredTmrLogger()
end
Script.serveFunction('CSK_Logger.setCallbackSinkActive', setCallbackSinkActive)

local function reloadLogsInUI()
  logger_Model.loadFileLog()
end
Script.serveFunction('CSK_Logger.reloadLogsInUI', reloadLogsInUI)

-- *****************************************************************
-- Following function can be adapted for CSK_PersistentData module usage
-- *****************************************************************

local function setParameterName(name)
  _G.logger:info(nameOfModule .. ': Set PersisetentData parameter name to ' .. name)
  logger_Model.parametersName = name
end
Script.serveFunction("CSK_Logger.setParameterName", setParameterName)

local function sendParameters()
  if logger_Model.persistentModuleAvailable then
    CSK_PersistentData.addParameter(logger_Model.helperFuncs.convertTable2Container(logger_Model.parameters), logger_Model.parametersName)
    CSK_PersistentData.setModuleParameterName(nameOfModule, logger_Model.parametersName, logger_Model.parameterLoadOnReboot)
    _G.logger:info(nameOfModule .. ": Send Logger parameters with name '" .. logger_Model.parametersName .. "' to CSK_PersistentData module.")
    CSK_PersistentData.saveData()
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_Logger.sendParameters", sendParameters)

local function loadParameters()
  if logger_Model.persistentModuleAvailable then
    local data = CSK_PersistentData.getParameter(logger_Model.parametersName)
    if data then
      _G.logger:info(nameOfModule .. ": Loaded parameters from CSK_PersistentData module.")
      logger_Model.parameters = logger_Model.helperFuncs.convertContainer2Table(data)
      logger_Model.setupLogHandler()
      CSK_Logger.pageCalled()
    else
      _G.logger:warning(nameOfModule .. ": Loading parameters from CSK_PersistentData module did not work.")
    end
  else
    _G.logger:warning(nameOfModule .. ": CSK_PersistentData module not available.")
  end
end
Script.serveFunction("CSK_Logger.loadParameters", loadParameters)

local function setLoadOnReboot(status)
  logger_Model.parameterLoadOnReboot = status
  _G.logger:info(nameOfModule .. ": Set new status to load setting on reboot: " .. tostring(status))
end
Script.serveFunction("CSK_Logger.setLoadOnReboot", setLoadOnReboot)

--- Function to react on initial load of persistent parameters
local function handleOnInitialDataLoaded()

  _G.logger:info(nameOfModule .. ': Try to initially load parameter from CSK_PersistentData module.')
  if string.sub(CSK_PersistentData.getVersion(), 1, 1) == '1' then

    _G.logger:warning(nameOfModule .. ': CSK_PersistentData module is too old and will not work. Please update CSK_PersistentData module.')
    logger_Model.persistentModuleAvailable = false
  else

    local parameterName, loadOnReboot = CSK_PersistentData.getModuleParameterName(nameOfModule)

    if parameterName then
      logger_Model.parametersName = parameterName
      logger_Model.parameterLoadOnReboot = loadOnReboot
    end

    if logger_Model.parameterLoadOnReboot then
      loadParameters()
    end
    Script.notifyEvent('Logger_OnDataLoadedOnReboot')
  end
end
Script.register("CSK_PersistentData.OnInitialDataLoaded", handleOnInitialDataLoaded)

-- *************************************************
-- END of functions for CSK_PersistentData module usage
-- *************************************************

return setLogger_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************