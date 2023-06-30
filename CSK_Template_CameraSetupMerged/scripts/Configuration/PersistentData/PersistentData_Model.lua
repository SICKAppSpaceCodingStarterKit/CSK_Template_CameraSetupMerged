---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the PersistentData_Model definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_PersistentData'

local persistentData_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
persistentData_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Load script to communicate with the PersistentData_Model interface and give access
-- to the PersistentData_Model object.
-- Check / edit this script to see/edit functions which eg. communicate with the UI
local setPersistentData_Model_Handle = require('Configuration/PersistentData/PersistentData_Controller')
setPersistentData_Model_Handle(persistentData_Model)

persistentData_Model.data = {} -- table to hold all relevant data
persistentData_Model.contentList = '' -- list of all available module parameters within the paramerter dataset
persistentData_Model.path = Parameters.get('DataFilePath') -- name of the parameter dataset to load
persistentData_Model.tempPath = '/ram/CSK_PersistentData_Temp.bin'
persistentData_Model.initialLoading = false -- status to check if parameter dataset was successfully loaded on app/device reboot

persistentData_Model.parameters = {}
persistentData_Model.parameters.parameterNames = {} -- store table of what parameter should be loaded for what module
persistentData_Model.parameters.loadOnReboot = {} -- store table if parameter should be loaded for module on app/device reboot
persistentData_Model.parameters.totalInstances = {} -- store table of total instances to create for this module

-- INFO: following functions can also be used like this in other modules
persistentData_Model.funcs = require('Configuration/PersistentData/helper/funcs')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

local function createNewDataSet(path)
  _G.logger:info(nameOfModule .. ": Created new, empty DataSet.")
  persistentData_Model.data = {}
  persistentData_Model.contentList = ''
  persistentData_Model.path = path or '/public/CSK_PersistentData.bin'
  _G.logger:info(nameOfModule .. ": Path is = " .. persistentData_Model.path)

  Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)

  CSK_PersistentData.pageCalled()

end
Script.serveFunction("CSK_PersistentData.createNewDataSet", createNewDataSet)
persistentData_Model.createNewDataSet = createNewDataSet

-- Function to add values of a table into the data with given name as identifier for this data
---@param data any[] Values to add
---@param name string Name of parameter
local function addParameterTable(data, name)
  local tableContent = {}
  for key, value in pairs(data) do
    tableContent[key] = value
  end
  persistentData_Model.data[name] = tableContent
  _G.logger:info(nameOfModule .. ": Added data: " .. name)

  persistentData_Model.contentList = persistentData_Model.funcs.createContentList(persistentData_Model.data)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)

end
persistentData_Model.addParameterTable = addParameterTable

local function removeParameter(name)

  _G.logger:info(nameOfModule .. ": Remove data (if exist): " .. name)
  persistentData_Model.data[name] = nil

  persistentData_Model.contentList = persistentData_Model.funcs.createContentList(persistentData_Model.data)
  Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)
  CSK_PersistentData.pageCalled()

end
Script.serveFunction("CSK_PersistentData.removeParameter", removeParameter)
persistentData_Model.removeParameter = removeParameter

local function saveData()
  local fileExists = File.exists(persistentData_Model.path)
  _G.logger:info(nameOfModule .. ": File to save data already exists = " .. tostring(fileExists))

  local file = File.open(persistentData_Model.path, "wb")
  if (file ~= nil) then
    local fullData = Container.create()

    for key, value in pairs(persistentData_Model.data) do
      local subContainer = persistentData_Model.funcs.convertTable2Container(value)
      fullData:add(key, subContainer, nil)
    end

    local binaryContainer = Object.serialize(fullData, "JSON")
    local success = File.write(file, binaryContainer)
    _G.logger:info(nameOfModule .. ": Data save success = " .. tostring(success))
    File.close(file)
    Parameters.set('DataFilePath', persistentData_Model.path)
    Parameters.savePermanent()
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'OK')
    Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)

    return true
  else
    _G.logger:warning(nameOfModule .. ": Write did not work")
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'ERR')
    return false
  end
end
Script.serveFunction("CSK_PersistentData.saveData", saveData)
persistentData_Model.saveData = saveData

local function loadContent()
  local file = File.open(persistentData_Model.path, "rb")
  if (file ~= nil) then
    local fileContent = File.read(file)
    local cont = Object.deserialize(fileContent, "JSON")

    persistentData_Model.data = {}

    local containerList = Container.list(cont)
    persistentData_Model.contentList = table.concat(Container.list(cont), ',')
    Script.notifyEvent('PersistentData_OnNewContent', persistentData_Model.contentList)

    for i=1, #containerList do
      local valueKey = containerList[i]

      local subContainer = Container.get(cont, valueKey)

      local subTable = persistentData_Model.funcs.convertContainer2Table(subContainer)

      persistentData_Model.data[valueKey] = subTable
    end
    _G.logger:info(nameOfModule .. ": Loading of " .. persistentData_Model.path .. " did work.")

    File.close(file)

    if persistentData_Model.data['PersistentData_InitialParameterNames'] then
      persistentData_Model.parameters = persistentData_Model.data['PersistentData_InitialParameterNames']
    end

    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'OK')

    if persistentData_Model.initialLoading then
      CSK_PersistentData.pageCalled()
    end

    return true
  else
    _G.logger:warning(nameOfModule .. ": No persistent data file available")
    Script.notifyEvent('PersistentData_OnNewFeedbackStatus', 'ERR')

    if persistentData_Model.initialLoading then
      CSK_PersistentData.pageCalled()
    end
    return false
  end
end
Script.serveFunction("CSK_PersistentData.loadContent", loadContent)
persistentData_Model.loadContent = loadContent

-- Try to load latest parameters
persistentData_Model.initialLoading = persistentData_Model.loadContent()

local function setPath(path)
  persistentData_Model.path = path
  _G.logger:info(nameOfModule .. ': Changed path to ' .. path .. '. Try to load data if already existing...')
  Script.notifyEvent('PersistentData_OnNewDataPath', persistentData_Model.path)
  local suc = persistentData_Model.loadContent()

  if not suc then
    createNewDataSet(persistentData_Model.path)
  end

end
Script.serveFunction("CSK_PersistentData.setPath", setPath)
persistentData_Model.setPath = setPath

local function overwriteData()
  if(File.copy(persistentData_Model.tempPath, persistentData_Model.path)) then
  _G.logger:info(nameOfModule .. ': Persistent data overwritten, deleting the temporary file ...')
    File.del(persistentData_Model.tempPath)
    loadContent()
  else
    _G.logger:warning(nameOfModule .. ': Could not overwrite persistent data')
  end
end
Script.serveFunction("CSK_PersistentData.overwriteData", overwriteData)
persistentData_Model.overwriteData = overwriteData

return persistentData_Model

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************

