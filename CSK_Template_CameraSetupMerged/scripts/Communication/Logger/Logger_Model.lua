---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--*****************************************************************
-- Inside of this script, you will find the module definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_Logger'

local logger_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
logger_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Check if CSK_PersistentData module can be used if wanted
logger_Model.persistentModuleAvailable = CSK_PersistentData ~= nil or false

-- Load script to communicate with the Logger_Model interface and give access
-- to the Logger_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setLogger_ModelHandle = require('Communication/Logger/Logger_Controller')
setLogger_ModelHandle(logger_Model)

--Loading helper functions if needed
logger_Model.helperFuncs = require('Communication/Logger/helper/funcs')

logger_Model.sharedLogger = Log.SharedLogger.create('ModuleLogger') -- Shared Logger used by all CSK modules
logger_Model.tempLog = {} -- This will hold temporarely the latest 200 messages to show on UI if Log is not saved in a file
logger_Model.logger = Log.Handler.create() -- Main logger handle

-- Parameters to be saved permanently if wanted
logger_Model.parameters = {}

logger_Model.parameters.filePath = '/public/' -- path to store the logfile
logger_Model.parameters.fileName = 'CSK_Logfile.txt' -- Name of the logfile

--> INFO: File / path on SD card should be used to reduce write accesses on the internal flash storage of the device

logger_Model.parameters.level = 'ALL' -- Log level to react on
logger_Model.parameters.setConsoleSinkEnabled = true -- Log also console messages
logger_Model.parameters.attachToEngineLogger = false -- Attach logger to internal engine logger messages
logger_Model.parameters.fileSinkActive = false -- Store logs in a file
logger_Model.parameters.logSize = 10240 -- Maximum size of the log file in bytes before truncating. Has to be in the range [1024,104857600] bytes.
logger_Model.parameters.callBackSink = true -- Status to use callback sink for incoming log messages if FileSink is active (to optimize log performance if deactivated)

-- Default values for persistent data
-- If available, following values will be updated from data of CSK_PersistentData module (check CSK_PersistentData module for this)
logger_Model.parametersName = 'CSK_Logger_Parameter' -- name of parameter dataset to be used for this module
logger_Model.parameterLoadOnReboot = false -- Status if parameter dataset should be loaded on app/device reboot

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to load logfile out of file and notify via event to send e.g. to UI
local function loadFileLog()
  if File.exists(logger_Model.parameters.filePath .. logger_Model.parameters.fileName) then
    local logFile = File.open(logger_Model.parameters.filePath .. logger_Model.parameters.fileName, 'rb')
    local logContent = File.read(logFile)
    File.close(logFile)
    Script.notifyEvent('Logger_OnNewCompleteLogfile', tostring(logContent))
  else
    Script.notifyEvent('Logger_OnNewCompleteLogfile', "No Log available")
  end
end
logger_Model.loadFileLog = loadFileLog

--- Function to notify temp log via event to send e.g. to UI
local function sendLog()
  local tempLog2Send = ''
  for i=#logger_Model.tempLog, 1, -1 do
    tempLog2Send = tempLog2Send .. logger_Model.tempLog[i] .. '\n'
  end
  Script.notifyEvent('Logger_OnNewCompleteLogfile', tempLog2Send)
end
logger_Model.sendLog = sendLog

--- Callback sink function to process incoming log messages ( e.g. from other modules)
---@param message string Content of the transmitted logging message
---@param path string Source path of the component that emitted the logging message
---@param level string Log level (severity) of the message.
---@param timestamp number Timestamp as milliseconds since epoch (unix timestamp)
---@param appName string Name of the App that emitted the logging message (optional)
---@param appPosition string File and line position in the App source code (optional)
---@param sourceApi string Name of the API that the logging message was sent from (optional)
local function loggerCallback(message, path, level, timestamp, appName, appPosition, sourceApi)

  Script.notifyEvent('Logger_OnNewMessage', '[' .. level .. '] ' .. message)

  table.insert(logger_Model.tempLog, 1, DateTime.getTime() .. ': [' .. level .. '] ' .. message)

  if #logger_Model.tempLog == 200 then
    table.remove(logger_Model.tempLog, 200)
  end

  sendLog()
end

--- Function to setup the logger
local function setupLogHandler()
  logger_Model.logger = Log.Handler.create()
  if logger_Model.parameters.attachToEngineLogger then
    logger_Model.logger:attachToEngineLogger()
  end

  logger_Model.logger:attachToSharedLogger('ModuleLogger')
  logger_Model.logger:setConsoleSinkEnabled(logger_Model.parameters.setConsoleSinkEnabled)

  if logger_Model.parameters.fileSinkActive then
    logger_Model.logger:addFileSink(logger_Model.parameters.filePath .. logger_Model.parameters.fileName, logger_Model.parameters.logSize)
  end
  logger_Model.logger:setLevel(logger_Model.parameters.level)

  if logger_Model.parameters.callBackSink then
    Log.Handler.addCallbackSink(logger_Model.logger, loggerCallback)
  end

  logger_Model.logger:applyConfig()

end
logger_Model.setupLogHandler = setupLogHandler
setupLogHandler()

return logger_Model

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************