local spawnPoint = {}

local vehicleList = {
    'kuruma',
    'guardian',
}

local curVehicle = nil
local busy = false
local mode = 'raycast'
local glm = require "glm"
local debugzone = require 'modules.debugzone'

local function CancelPlacement()
    DeleteVehicle(curVehicle)
    busy = false
    curVehicle = nil
end

--- Create Spawn Points
---@param zone OxZone
---@param required boolean
---@return promise?
function spawnPoint.create(zone, required)
    if not zone then return end
    if busy then return end
    local vehIndex = 1
    local vehicle = vehicleList[vehIndex]
    local polygon = glm.polygon.new(zone.points)

    local text = [[
    [X]: Finalizar
    [Enter]: Adicionar Pontos
    [Setas Cima/Baixo]: Altura
    [Setas Direita/Esquerda]: Rotacionar Veículo
    [Mouse Scroll Cima/Baixo]: Mudar Veículo
    ]]

    utils.drawtext('show', text)
    lib.requestModel(vehicle, 1500)
    curVehicle = CreateVehicle(vehicle, 1.0, 1.0, 1.0, 0, false, false)
    SetEntityAlpha(curVehicle, 150, true)
    SetEntityCollision(curVehicle, false, false)
    FreezeEntityPosition(curVehicle, true)

    local vc = {}
    local heading = 0.0
    local prefixZ = 0.0
    
    local results = promise.new()
    CreateThread(function()
        busy = true

        while busy do
            local hit, coords

            CurrentCoords = GetEntityCoords(curVehicle)
            
            if mode == 'raycast' then
                hit, coords = utils.raycastCam(20.0)
            end
           
            local inZone = glm.polygon.contains(polygon, CurrentCoords, zone.thickness / 4)
            local outlineColour = inZone and {255, 255, 255, 255} or {240, 5, 5, 1}
            SetEntityDrawOutline(curVehicle, true)
            SetEntityDrawOutlineColor(outlineColour[1], outlineColour[2], outlineColour[3], outlineColour[4])
            debugzone.start(polygon, zone.thickness)

            if hit == 1 then
                SetEntityCoords(curVehicle, coords.x, coords.y, coords.z + prefixZ)
            end

            DisableControlAction(0, 174, true)
            DisableControlAction(0, 175, true)
            DisableControlAction(0, 73, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 172, true)
            DisableControlAction(0, 173, true)
            DisableControlAction(0, 21, true)
            
            if IsDisabledControlPressed(0, 174) then
                heading = heading + 0.5
                if heading > 360 then heading = 0.0 end
            end

            if IsDisabledControlPressed(0, 175) then
                heading = heading - 0.5
                if heading < 0 then heading = 360.0 end
            end

            if IsDisabledControlJustPressed(0, 172) then
                prefixZ += 0.1
            end

            if IsDisabledControlJustPressed(0, 173) then
                prefixZ -= 0.1
            end

            if IsDisabledControlJustPressed(0, 14) then
                local newIndex = vehIndex+1
                local newModel = vehicleList[newIndex]
                if newModel then
                    DeleteEntity(curVehicle)
                    lib.requestModel(newModel)
                    local veh = CreateVehicle(newModel, 1.0, 1.0, 1.0, 0, false, false)
                    SetEntityAlpha(veh, 150, true)
                    SetEntityCollision(veh, false, false)
                    FreezeEntityPosition(veh, true)
                    curVehicle = veh
                    vehIndex = newIndex
                    object = newModel
                end
            end

            if IsDisabledControlJustPressed(0, 15) then
                local newIndex = vehIndex-1

                if newIndex >= 1 then
                    local newModel = vehicleList[newIndex]
                    if newModel then
                        DeleteEntity(curVehicle)
                        lib.requestModel(newModel)
                        local veh = CreateVehicle(newModel, 1.0, 1.0, 1.0, 0, false, false)
                        SetEntityAlpha(veh, 150, true)
                        SetEntityCollision(veh, false, false)
                        FreezeEntityPosition(veh, true)
                        curVehicle = veh
                        vehIndex = newIndex
                        object = newModel
                    end
                end
            end

            if IsDisabledControlJustPressed(0, 73) then
                if required and #vc < 1 then
                    utils.notify("Você deve criar pelo menos pontos de desova x1", "error", 8000)
                else
                    CancelPlacement()
                end
            end

            SetEntityHeading(curVehicle, heading)

            if IsDisabledControlJustPressed(0, 176) then
                if hit == 1 then

                    if inZone then
                        vc[#vc+1] = vec4(CurrentCoords.x, CurrentCoords.y, CurrentCoords.z, heading)
                        utils.notify("Localização criada com sucesso" .. #vc, "success", 8000)
                    else
                        utils.notify("Não pode adicionar pontos de desova fora da zona", "error", 8000)
                    end
                end
            end

            Wait(1)
        end

        results:resolve(#vc > 0 and vc or false)
        utils.drawtext('hide')
    end)

    return results
end

return spawnPoint