---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}
-- Providing standard JSON functions
funcs.json = require('Communication/DeviceScanner/helper/Json')

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to check if inserted string is a valid IP
---@param ip string IP to check
---@return boolean status Result if IP is valid
local function checkIP(ip)
  if not ip then return false end
  local a,b,c,d=ip:match("^(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)%.(%d%d?%d?)$")
  a=tonumber(a)
  b=tonumber(b)
  c=tonumber(c)
  d=tonumber(d)
  if not a or not b or not c or not d then return false end
  if a<0 or 255<a then return false end
  if b<0 or 255<b then return false end
  if c<0 or 255<c then return false end
  if d<0 or 255<d then return false end
  return true
end
funcs.checkIP = checkIP

--- Function to create a list from a table
---@param data string[] Lua Table with entries for list
---@return string list List created of table entries
local function createStringList(data)
  local list = "["
  if #data >= 1 then
    list = list .. '"' .. data[1] .. '"'
  end
  if #data >= 2 then
    for i=2, #data do
      list = list .. ', ' .. '"' .. data[i] .. '"'
    end
  end
  list = list .. "]"
  return list
end
funcs.createStringList = createStringList

--- Function to create a json string out of a table content
---@param content string[] Lua Table with entries for list
local function createJsonList(content)
  local deviceList = {}
  if content == nil then
    deviceList = {{DeviceNo = '-', DeviceName = '-', Interface = '-', IP = '-', SubnetMask = '-', MAC = '-', DefaultGateway = '-', DHCP = '-'},}
  else
    if #content >= 1 then
      for i = 1, #content do
        table.insert(deviceList, {DeviceNo = tostring(i), DeviceName = content[i].devName,  Interface = content[i].interface, IP = content[i].ipAddress, SubnetMask = content[i].subnetMask, MAC = content[i].macAddress, DefaultGateway = content[i].defaultGateway, DHCP = content[i].dhcp})
      end
    else
      deviceList = {{DeviceNo = '-', DeviceName = '-', Interface = '-', IP = '-', SubnetMask = '-', MAC = '-', DefaultGateway = '-', DHCP = '-'},}
    end
  end

  local jsonstring = funcs.json.encode(deviceList)
  return jsonstring
end
funcs.createJsonList = createJsonList

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************