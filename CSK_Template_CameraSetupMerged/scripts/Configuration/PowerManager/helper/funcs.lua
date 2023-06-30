---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
--*****************************************************************
-- Inside of this script, you will find helper functions
--*****************************************************************

--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

local funcs = {}

funcs.json = require('Configuration/PowerManager/helper/Json')

-- Available status of power connector
local status = {}
status.on = 'true'
status.off = 'false'
status.on2off = 'true -> false'
status.off2on = 'false -> true'
funcs.status = status

--**************************************************************************
--********************** End Global Scope **********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Create JSON list for dynamic table
---@param contentA string Name of 'PowerConnector'
---@param contentB string State of 'Status'
---@return string jsonstring JSON string
local function createJsonList(contentA, contentB)
  local orderedTable = {}
  local connectorList = {}
  if contentA == nil then
    connectorList = {{PowerConnector = '-', Status = '-'},}
  else

    for n in pairs(contentA) do
      table.insert(orderedTable, n)
    end
    table.sort(orderedTable)

    for _, value in ipairs(orderedTable) do
      table.insert(connectorList, {PowerConnector = value, Status = contentB[value]})
    end
  end

  local jsonstring = funcs.json.encode(connectorList)
  return jsonstring
end
funcs.createJsonList = createJsonList

--- Function to convert a table into a Container object
---@param content auto[] Lua Table to convert to Container
---@return Container cont Created Container
local function convertTable2Container(content)
  local cont = Container.create()
  for key, value in pairs(content) do
    if type(value) == 'table' then
      cont:add(key, convertTable2Container(value), nil)
    else
      cont:add(key, value, nil)
    end
  end
  return cont
end
funcs.convertTable2Container = convertTable2Container

--- Function to convert a Container into a table
---@param cont Container Container to convert to Lua table
---@return auto[] data Created Lua table
local function convertContainer2Table(cont)
  local data = {}
  local containerList = Container.list(cont)
  local containerCheck = false
  if tonumber(containerList[1]) then
    containerCheck = true
  end
  for i=1, #containerList do

    local subContainer

    if containerCheck then
      subContainer = Container.get(cont, tostring(i) .. '.00')
    else
      subContainer = Container.get(cont, containerList[i])
    end
    if type(subContainer) == 'userdata' then
      if Object.getType(subContainer) == "Container" then

        if containerCheck then
          table.insert(data, convertContainer2Table(subContainer))
        else
          data[containerList[i]] = convertContainer2Table(subContainer)
        end

      else
        if containerCheck then
          table.insert(data, subContainer)
        else
          data[containerList[i]] = subContainer
        end
      end
    else
      if containerCheck then
        table.insert(data, subContainer)
      else
        data[containerList[i]] = subContainer
      end
    end
  end
  return data
end
funcs.convertContainer2Table = convertContainer2Table

return funcs

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************