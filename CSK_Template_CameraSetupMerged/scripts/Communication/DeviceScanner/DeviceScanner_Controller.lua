---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter

--***************************************************************
-- Inside of this script, you will find the necessary functions,
-- variables and events to communicate with the DeviceScanner_Model
--***************************************************************

--**************************************************************************
--************************ Start Global Scope ******************************
--**************************************************************************

local nameOfModule = 'CSK_DeviceScanner'

-- Timer to update UI via events after page was loaded
local tmrDeviceScanner = Timer.create()
tmrDeviceScanner:setExpirationTime(300)
tmrDeviceScanner:setPeriodic(false)

-- Temp values to preset config of scanned devices
local currentIP = '-'
local currentSubnet = '-'
local currentGateway = '-'
local currentDHCP = false
local selectedDeviceNo = ''

-- Reference to global handle
local deviceScanner_Model

-- ************************ UI Events Start ********************************

Script.serveEvent("CSK_DeviceScanner.OnNewScanStatus", "DeviceScanner_OnNewScanStatus")
Script.serveEvent("CSK_DeviceScanner.OnNewInterfaceList", "DeviceScanner_OnNewInterfaceList")
Script.serveEvent("CSK_DeviceScanner.OnNewInterfaceSelected", "DeviceScanner_OnNewInterfaceSelected")
Script.serveEvent("CSK_DeviceScanner.OnNewDeviceTable", "DeviceScanner_OnNewDeviceTable")
Script.serveEvent("CSK_DeviceScanner.OnNewIP", "DeviceScanner_OnNewIP")
Script.serveEvent("CSK_DeviceScanner.OnNewSubnetMask", "DeviceScanner_OnNewSubnetMask")
Script.serveEvent("CSK_DeviceScanner.OnNewGateway", "DeviceScanner_OnNewGateway")
Script.serveEvent("CSK_DeviceScanner.OnNewDHCPStatus", "DeviceScanner_OnNewDHCPStatus")
Script.serveEvent("CSK_DeviceScanner.OnNewErrorActive", "DeviceScanner_OnNewErrorActive")
Script.serveEvent("CSK_DeviceScanner.OnDeviceSelected", "DeviceScanner_OnDeviceSelected")

Script.serveEvent("CSK_DeviceScanner.OnUserLevelOperatorActive", "DeviceScanner_OnUserLevelOperatorActive")
Script.serveEvent("CSK_DeviceScanner.OnUserLevelMaintenanceActive", "DeviceScanner_OnUserLevelMaintenanceActive")
Script.serveEvent("CSK_DeviceScanner.OnUserLevelServiceActive", "DeviceScanner_OnUserLevelServiceActive")
Script.serveEvent("CSK_DeviceScanner.OnUserLevelAdminActive", "DeviceScanner_OnUserLevelAdminActive")

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
  Script.notifyEvent("DeviceScanner_OnUserLevelOperatorActive", status)
end

--- Function to react on status change of Maintenance user level
---@param status boolean Status if Maintenance level is active
local function handleOnUserLevelMaintenanceActive(status)
  Script.notifyEvent("DeviceScanner_OnUserLevelMaintenanceActive", status)
end

--- Function to react on status change of Service user level
---@param status boolean Status if Service level is active
local function handleOnUserLevelServiceActive(status)
  Script.notifyEvent("DeviceScanner_OnUserLevelServiceActive", status)
end

--- Function to react on status change of Admin user level
---@param status boolean Status if Admin level is active
local function handleOnUserLevelAdminActive(status)
  Script.notifyEvent("DeviceScanner_OnUserLevelAdminActive", status)
end

--- Function to get access to the deviceScanner_Model object
---@param handle handle Handle of deviceScanner_Model object
local function setDeviceScanner_Model_Handle(handle)
  deviceScanner_Model = handle
  if deviceScanner_Model.userManagementModuleAvailable then
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
  if deviceScanner_Model.userManagementModuleAvailable then
    -- Trigger CSK_UserManagement module to provide events regarding user role
    CSK_UserManagement.pageCalled()
  else
    -- If CSK_UserManagement is not active, show everything
    Script.notifyEvent("DeviceScanner_OnUserLevelOperatorActive", true)
    Script.notifyEvent("DeviceScanner_OnUserLevelMaintenanceActive", true)
    Script.notifyEvent("DeviceScanner_OnUserLevelServiceActive", true)
    Script.notifyEvent("DeviceScanner_OnUserLevelAdminActive", true)
  end
end

--- Function to send all relevant values to UI on resume
local function handleOnExpiredTmrDeviceScanner()

  updateUserLevel()

  Script.notifyEvent("DeviceScanner_OnDeviceSelected", false)
  Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'empty')
  Script.notifyEvent("DeviceScanner_OnNewInterfaceList", deviceScanner_Model.interfaceList)
  Script.notifyEvent("DeviceScanner_OnNewInterfaceSelected", deviceScanner_Model.interfaceSelection)
  currentIP = '-'
  currentSubnet = '-'
  currentGateway = '-'
  currentDHCP = false
  Script.notifyEvent('DeviceScanner_OnNewErrorActive', false)
  Script.notifyEvent('DeviceScanner_OnNewIP', '-')
  Script.notifyEvent('DeviceScanner_OnNewSubnetMask', '-')
  Script.notifyEvent('DeviceScanner_OnNewGateway', '-')
  Script.notifyEvent('DeviceScanner_OnNewDHCPStatus', false)
  Script.notifyEvent('DeviceScanner_OnNewDeviceTable', deviceScanner_Model.funcs.createJsonList(deviceScanner_Model.foundDevices))
end
Timer.register(tmrDeviceScanner, "OnExpired", handleOnExpiredTmrDeviceScanner)

-- ********************* UI Setting / Submit Functions Start ********************

local function pageCalled()
  updateUserLevel() -- try to hide user specific content asap
  selectedDeviceNo = ''
  tmrDeviceScanner:start()
  return ''
end
Script.serveFunction("CSK_DeviceScanner.pageCalled", pageCalled)

local function selectInterface(selection)
  deviceScanner_Model.interfaceSelection = selection
end
Script.serveFunction("CSK_DeviceScanner.selectInterface", selectInterface)

local function scanForDevices()
  selectedDeviceNo = ''
  Script.notifyEvent("DeviceScanner_OnDeviceSelected", false)

  Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'processing')
  Script.notifyEvent('DeviceScanner_OnNewDeviceTable', deviceScanner_Model.funcs.createJsonList())
  local results = deviceScanner_Model.scanDevice()
  local jsonstring = deviceScanner_Model.funcs.createJsonList(results)
  Script.notifyEvent('DeviceScanner_OnNewDeviceTable', jsonstring)
  Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'empty')
  _G.logger:info(nameOfModule .. ": Scan finished.")
end
Script.serveFunction("CSK_DeviceScanner.scanForDevices", scanForDevices)

local function getDeviceListJSON()
  return deviceScanner_Model.funcs.createJsonList(deviceScanner_Model.foundDevices)
end
Script.serveFunction("CSK_DeviceScanner.getDeviceListJSON", getDeviceListJSON)

local function selectDevice(selection)

  if selection == "" then
    selectedDeviceNo = ''
  else
    local _, pos = string.find(selection, '"DeviceNo":"')
    if pos == nil then
      _G.logger:info(nameOfModule .. ": Did not find DeviceNo")
      selectedDeviceNo = ''
    else
      pos = tonumber(pos)
      local endPos = string.find(selection, '"', pos+1)
      selectedDeviceNo = tonumber(string.sub(selection, pos+1, endPos-1))
      if selectedDeviceNo == nil then
        selectedDeviceNo = ''
      end
    end
  end
  _G.logger:info(nameOfModule .. ": Selected DeviceNo = " .. tostring(selectedDeviceNo))
  if selectedDeviceNo ~= '' then
    Script.notifyEvent('DeviceScanner_OnNewIP', deviceScanner_Model.foundDevices[selectedDeviceNo].ipAddress)
    Script.notifyEvent('DeviceScanner_OnNewSubnetMask', deviceScanner_Model.foundDevices[selectedDeviceNo].subnetMask)
    Script.notifyEvent('DeviceScanner_OnNewGateway', deviceScanner_Model.foundDevices[selectedDeviceNo].defaultGateway)
    Script.notifyEvent('DeviceScanner_OnNewDHCPStatus', deviceScanner_Model.foundDevices[selectedDeviceNo].dhcp)
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', false)
    Script.notifyEvent("DeviceScanner_OnDeviceSelected", true)

    currentIP = deviceScanner_Model.foundDevices[selectedDeviceNo].ipAddress
    currentSubnet = deviceScanner_Model.foundDevices[selectedDeviceNo].subnetMask
    currentGateway = deviceScanner_Model.foundDevices[selectedDeviceNo].defaultGateway
    currentDHCP = deviceScanner_Model.foundDevices[selectedDeviceNo].dhcp

  else
    Script.notifyEvent("DeviceScanner_OnDeviceSelected", false)
  end
end
Script.serveFunction("CSK_DeviceScanner.selectDevice", selectDevice)

local function setDeviceIP(ip)
  _G.logger:info(nameOfModule .. ": Setting new IP = " .. ip)
  if deviceScanner_Model.funcs.checkIP(ip) == true then
    currentIP = ip
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', false)
  else
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', true)
  end
end
Script.serveFunction("CSK_DeviceScanner.setDeviceIP", setDeviceIP)

local function setSubnetMask(subnetMask)
  _G.logger:info(nameOfModule .. ": Setting new Subnet = " .. subnetMask)
  if deviceScanner_Model.funcs.checkIP(subnetMask) == true then
    currentSubnet = subnetMask
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', false)
  else
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', true)
  end
end
Script.serveFunction("CSK_DeviceScanner.setSubnetMask", setSubnetMask)

local function setGateway(gateway)
  _G.logger:info(nameOfModule .. ": Setting new Gateway = " .. gateway)
  if deviceScanner_Model.funcs.checkIP(gateway) == true then
    currentGateway = gateway
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', false)
  else
    Script.notifyEvent('DeviceScanner_OnNewErrorActive', true)
  end
end
Script.serveFunction("CSK_DeviceScanner.setGateway", setGateway)

local function setDHCP(status)
  _G.logger:info(nameOfModule .. ": Setting new DHCP = " .. status)
  currentDHCP = status
end
Script.serveFunction("CSK_DeviceScanner.setDHCP", setDHCP)

local function sendNewConfig()
  if selectedDeviceNo ~= '' then

    _G.logger:info(nameOfModule .. ": Send config to device")
    Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'processing')

    deviceScanner_Model.sendSettingToDevice(deviceScanner_Model.foundDevices[selectedDeviceNo].macAddress, currentIP, currentSubnet, currentGateway, currentDHCP)

  end
end
Script.serveFunction("CSK_DeviceScanner.sendNewConfig", sendNewConfig)

return setDeviceScanner_Model_Handle

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************
