--MIT License
--
--Copyright (c) 2023 SICK AG
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

---@diagnostic disable: undefined-global, redundant-parameter, missing-parameter
-- CreationTemplateVersion: 3.3.0
--**************************************************************************
--**********************Start Global Scope *********************************
--**************************************************************************

-- If app property "LuaLoadAllEngineAPI" is FALSE, use this to load and check for required APIs
-- This can improve performance of garbage collection
_G.availableAPIs = require('Application/CameraSetupTemplate/helper/checkAPIs') -- can be used to adjust function scope of the module related on available APIs of the device
-----------------------------------------------------------

-- Loading script regarding Logger_Model
_G.loggerModel = require('Communication/Logger/Logger_Model')
_G.logger = _G.loggerModel.sharedLogger

-- Loading script regarding DeviceScanner_Model
_G.deviceScanner_Model = require('Communication/DeviceScanner/DeviceScanner_Model')

-- Loading script regarding PowerManager_Model
_G.powerManager_Model = require('Configuration/PowerManager/PowerManager_Model')

-- Loading script regarding MultiRemoteCamera_Model
_G.multiRemoteCamera_Model = require('Sensors/MultiRemoteCamera/MultiRemoteCamera_Model')
_G.multiRemoteCameras_Instances = {}

-- Create camera instance
table.insert(_G.multiRemoteCameras_Instances, _G.multiRemoteCamera_Model.create(1))

-- Load script to communicate with the MultiRemoteCamera_Model UI
_G.multiRemoteCameraController = require('Sensors/MultiRemoteCamera/MultiRemoteCamera_Controller')
_G.multiRemoteCameraController.setMultiRemoteCamera_Instances_Handle(_G.multiRemoteCameras_Instances) -- share handle of instances

-- Loading script regarding PersistentData_Model
_G.persistentData_Model = require('Configuration/PersistentData/PersistentData_Model') -- PersistentData

-----------------------------------------------------------
-- Loading script regarding CameraSetupTemplate_Model
-- Check this script regarding CameraSetupTemplate_Model parameters and functions
_G.cameraSetupTemplate_Model = require('Application/CameraSetupTemplate/CameraSetupTemplate_Model')

--**************************************************************************
--**********************End Global Scope ***********************************
--**************************************************************************
--**********************Start Function Scope *******************************
--**************************************************************************

--- Function to react on startup event of the app
local function main()

  ----------------------------------------------------------------------------------------
  -- INFO: Please check if module will eventually load inital configuration triggered via
  --       event CSK_PersistentData.OnInitialDataLoaded
  --       (see internal variable _G.cameraSetupTemplate_Model.parameterLoadOnReboot)
  --       If so, the app will trigger the "OnDataLoadedOnReboot" event if ready after loading parameters
  --
  -- Can be used e.g. like this
  ----------------------------------------------------------------------------------------

  _G.multiRemoteCameraController.setMultiRemoteCamera_Model_Handle(_G.multiRemoteCamera_Model) -- share handle of model

  _G.logger:info("Start the CameraSetup application")
  CSK_CameraSetupTemplate.pageCalled() -- Update UI

  if _G.persistentData_Model.initialLoading then
    Script.notifyEvent('PersistentData_OnInitialDataLoaded')
  end

  -- Use following function to start default setup:
  -- Camera powered on S1/S2 and connected to ETH1 / ETH2 with IPs 192.168.1.100 / 192.168.2.100

  -- _G.cameraSetupTemplate_Model.setupDefaultConfig()

end
Script.register("Engine.OnStarted", main)

--OR

-- Call function after persistent data was loaded
--Script.register("CSK_CameraSetupTemplate.OnDataLoadedOnReboot", main)

--**************************************************************************
--**********************End Function Scope *********************************
--**************************************************************************
