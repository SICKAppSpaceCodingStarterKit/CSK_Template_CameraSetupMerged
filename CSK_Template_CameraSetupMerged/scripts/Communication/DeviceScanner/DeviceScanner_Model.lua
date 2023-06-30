---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find the DeviceScanner_Model definition
-- including its parameters and functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************
local nameOfModule = 'CSK_DeviceScanner'

local deviceScanner_Model = {}

-- Check if CSK_UserManagement module can be used if wanted
deviceScanner_Model.userManagementModuleAvailable = CSK_UserManagement ~= nil or false

-- Load script to communicate with the DeviceScanner_Model UI and give access
-- to the DeviceScanner_Model object.
-- Check / edit this script to see/edit functions which communicate with the UI
local setDeviceScanner_Model_Handle = require('Communication/DeviceScanner/DeviceScanner_Controller')
setDeviceScanner_Model_Handle(deviceScanner_Model)

deviceScanner_Model.funcs = require('Communication/DeviceScanner/helper/funcs')

deviceScanner_Model.runningSystem = Engine.getTypeName() -- Get type name of device app is running on

-- Scanner for devices
deviceScanner_Model.scanner = Command.Scan.create() --Scan for other devices
deviceScanner_Model.foundDevices = {} -- List of devices found via scan
deviceScanner_Model.interfaces = Engine.getEnumValues("EthernetInterfaces") -- Available interfaces of device running the app
if #deviceScanner_Model.interfaces > 1 then
  table.insert(deviceScanner_Model.interfaces, 1, 'ALL')
end
deviceScanner_Model.interfaceSelection = deviceScanner_Model.interfaces[1] -- Select first interface
deviceScanner_Model.interfaceList = deviceScanner_Model.funcs.createStringList(deviceScanner_Model.interfaces) -- List of interfaces to select for scan
if deviceScanner_Model.runningSystem ~= 'SICK AppEngine' then
  deviceScanner_Model.serialNo = Engine.getSerialNumber() -- Serial No of device
else
  deviceScanner_Model.serialNo = 987654321 -- Serial dummy
end

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to scan for connected devices
---@return string[] deviceScanner_Model.foundDevices Found devices
local function scanDevice()
  _G.logger:info(nameOfModule .. ": ...Scanning...")

  deviceScanner_Model.scanner = Command.Scan.create()

  if deviceScanner_Model.interfaceSelection ~= 'ALL' and #deviceScanner_Model.interfaces ~= 1 then
    deviceScanner_Model.scanner:setInterface(deviceScanner_Model.interfaceSelection)
  end

  deviceScanner_Model.foundDevices = {}
  local devices = deviceScanner_Model.scanner:scan()

  if #devices >=1 then
    for i=1, #devices do
      local deviceInfos = {}
      deviceInfos.macAddress = Command.Scan.DeviceInfo.getMACAddress(devices[i])
      deviceInfos.interface = Command.Scan.DeviceInfo.getEthernetInterface(devices[i])
      deviceInfos.ipAddress = Command.Scan.DeviceInfo.getIPAddress(devices[i])
      deviceInfos.subnetMask = Command.Scan.DeviceInfo.getSubnetMask(devices[i])
      deviceInfos.defaultGateway = Command.Scan.DeviceInfo.getDefaultGateway(devices[i])
      deviceInfos.dhcp = Command.Scan.DeviceInfo.getDHCPClientEnabled(devices[i])
      deviceInfos.devName = Command.Scan.DeviceInfo.getDeviceName(devices[i])
      deviceInfos.serialNo = Command.Scan.DeviceInfo.getSerialNumber(devices[i])

      _G.logger:info(nameOfModule .. ': Found Device No. ' .. tostring(i) .. ' = ' .. deviceInfos.devName)
      -- Make sure that the device not just found itself.
      if deviceScanner_Model.serialNo ~= deviceInfos.serialNo then
        _G.logger:info(nameOfModule .. ": Add device to list.")
        table.insert(deviceScanner_Model.foundDevices, deviceInfos)
      else
        _G.logger:info(nameOfModule .. ": Only found system itself.")
      end
    end

  else
    _G.logger:info(nameOfModule .. ": Nothing found.")
  end
  return deviceScanner_Model.foundDevices
end
deviceScanner_Model.scanDevice = scanDevice

--- Function to send IP-Setting to device.
---@param mac string MAC address of device to configure
---@param ipAddress string IP address to set
---@param subnetMask string Subnet mask to set
---@param defaultGateway string Gateway to set
---@param dhcp boolean Status of DHCP
local function sendSettingToDevice(mac, ipAddress, subnetMask, defaultGateway, dhcp)
  local success = Command.Scan.configure(deviceScanner_Model.scanner, mac, ipAddress, subnetMask, defaultGateway, dhcp)
  _G.logger:info(nameOfModule .. ": Success of setting new config to device = " .. tostring(success))
  if success then
    Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'success')
  else
    Script.notifyEvent("DeviceScanner_OnNewScanStatus", 'error')
  end
end
deviceScanner_Model.sendSettingToDevice = sendSettingToDevice

return deviceScanner_Model

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************