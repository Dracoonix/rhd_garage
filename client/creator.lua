local Zones = lib.load('client.zone')
local Zones_Creator = lib.load('modules.zone')
local spawnPoint = lib.load('modules.spawnpoint')
local pedcreator = lib.load('modules.pedcreator')

--- Blip Input
---@param impound boolean
---@return promise
local function blipInput(impound)
    local p = promise.new()
    CreateThread(function()
        local results = { type = impound and 68 or 357, color = 3 }
        local blipinput = lib.inputDialog('BLIP', {
            { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"),  placeholder = '357' },
            { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), placeholder = '3' },
        })

        local hi = blipinput
        results.type = hi and hi[1] or results.type
        results.color = hi and hi[2] or results.color
        p:resolve(results)
    end)

    return p
end

--- Create garage input
local function createGarage()
    Zones_Creator.startCreator({
        type = "poly",
        onCreated = function(zones)
            local input = lib.inputDialog('Criação de Garagens', {
                { type = 'input',    label = locale("rhd_garage:input.admin.creator_labelgarage"), placeholder = 'Murai Garage',                                           required = true },
                {
                    type = 'multi-select',
                    label = locale("rhd_garage:input.admin.creator_typevehicle"),
                    options = {
                        { value = "car",        label = "Carros" },
                        { value = "boat",       label = "Barcos" },
                        { value = "helicopter", label = "Helicóptero" },
                        { value = "planes",     label = "Aviões" },
                        { value = "motorcycle", label = "Motocicleta" },
                        { value = "cycles",     label = "Bicicleta" },
                    },
                    required = true
                },
                -- { type = 'checkbox', label = "Use Blip"}, -- DESATIVADO: use o criador de blips
                { type = 'checkbox', label = "Impound",                                            description = "Marque se for depósito de carros apreendidos." },
                { type = 'checkbox', label = "Compartilhada",                                      description = "Marque os carros da garagem puderem ser compartilhados." },
                { type = 'checkbox', label = "Definir Locais de Spawn",                            description = "Defina as vagas desta garagem." },
                {
                    type = 'select',
                    label = "Abrir garagem",
                    options = {
                        { value = "radial",     label = "Usando Radial Menu" },
                        { value = "keypressed", label = "Usando Tecla E" },
                        { value = "targetped",  label = "Usando NPC com Target" }
                    },
                    required = true
                },
            })
            if input then
                local tPed = input[7] == 'targetped'
                local Impound = not input[5] and input[4] or false
                local label = input[1]
                local gtype = input[2]
                local blip = input[3] and Citizen.Await(blipInput(Impound)) or nil
                local shared = input[5]
                local sp = input[6] and Citizen.Await(spawnPoint.create(zones, true)) or nil
                local interact = tPed and Citizen.Await(pedcreator.start(zones)) or input[7]

                if tPed and not input[6] then
                    Wait(1000)
                    sp = Citizen.Await(spawnPoint.create(zones, true)) or nil
                end

                GarageZone[label] = {
                    type = gtype,
                    blip = blip,
                    zones = zones,
                    impound = Impound,
                    shared = shared,
                    spawnPoint = sp,
                    interaction = interact
                }

                utils.notify(locale("rhd_garage:notify.admin.success_create", label), "success")
                Zones.save(GarageZone)
            end
        end
    })
end

--- Delete garage by index
---@param garage {index: string}
local function delete(garage)
    GarageZone[garage.index] = nil
    utils.notify(locale("rhd_garage:notify.admin.success_deleted", garage.index), "success")
    Zones.save(GarageZone)
end

--- Set blip garage
---@param garage {index: string}
local function setBlip(garage)
    local blipContext = {
        id = "blip_setting",
        title = locale("rhd_garage:context.admin.blip_setting"),
        menu = "rhd:action_garage",
        onBack = function()

        end,
        options = {
            {
                title = locale("rhd_garage:context.admin.blip_edit"),
                icon = "pen-to-square",
                onSelect = function()
                    local blipinput = lib.inputDialog('BLIP', {
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_bliptype"),  required = true },
                        { type = 'number', label = locale("rhd_garage:input.admin.creator_blipcolor"), required = true },
                    })

                    if blipinput then
                        GarageZone[garage.index].blip = {
                            type = blipinput[1],
                            color = blipinput[2]
                        }
                        utils.notify(locale("rhd_garage:notify.admin.success_editblip"), "success")
                        Zones.save(GarageZone)
                    end
                end
            },
            {
                title = locale("rhd_garage:context.admin.blip_remove"),
                icon = "trash",
                onSelect = function()
                    GarageZone[garage.index].blip = nil
                    utils.notify("Blip foi excluído com sucesso", "success")
                    Zones.save(GarageZone)
                end
            }
        }
    }
    utils.createMenu(blipContext)
end

--- Change garage locations
---@param garage {index: string}
local function changeLocation(garage)
    Zones_Creator.startCreator({
        type = "poly",
        onCreated = function(zones)
            GarageZone[garage.index].zones = zones
            utils.notify(locale("rhd_garage:notify.admin.success_changelocation"), "success")
            Zones.save(GarageZone)
        end
    })
end

--- Teleport to garage location
---@param garage {index: string, value: table}
local function teleportToLocation(garage)
    local data = garage.value
    local coords = data.zones.points[1]
    DoScreenFadeOut(500)
    Wait(1000)
    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
    DoScreenFadeIn(500)
end

--- Change garage label
---@param garage {index: string, value: table}
local function changeGarageLabel(garage)
    local inputLabel = lib.inputDialog(locale("rhd_garage:input.admin.header_changelabel"), {
        { type = 'input', label = locale("rhd_garage:input.admin.label_changelabel"), placeholder = 'Alta Garage, Pilbox Garage, Etc', required = true, min = 1 },
    })

    if inputLabel then
        GarageZone[inputLabel[1]] = garage.value
        GarageZone[garage.index] = nil
        utils.notify(locale("rhd_garage:notify.admin.success_changelabel", inputLabel[1]))
        Zones.save(GarageZone)
    end
end

--- Edit the spawn point
---@param garage {index:string, value:table}
local function setspawnpoint(garage)
    local asp = GarageZone[garage.index].spawnPoint or {}
    local noEmpty = asp and #asp > 0
    local context = {
        id = 'rhd:csp',
        title = 'Spawn Point',
        options = {}
    }

    if noEmpty then
        for i = 1, #asp do
            context.options[#context.options + 1] = {
                title = "Point #" .. i,
                icon = "location-dot",
                description = "click me to teleport to my location",
                onSelect = function()
                    local coords = asp[i]
                    DoScreenFadeOut(500)
                    Wait(1000)
                    SetPedCoordsKeepVehicle(cache.ped, coords.x, coords.y, coords.z)
                    DoScreenFadeIn(500)
                end
            }
        end
    end

    context.options[#context.options + 1] = {
        title = "Add Point",
        icon = "plus",
        onSelect = function()
            local pr = Citizen.Await(spawnPoint.create())
            if not pr then return end
            GarageZone[garage.index].spawnPoint = utils.mergeArray(asp, pr)
            utils.notify("The spawn point has been successfully set", "success", 8000)
            Zones.save(GarageZone)
        end
    }

    if noEmpty then
        context.options[#context.options + 1] = {
            title = "Remove Point",
            icon = 'minus',
            onSelect = function()
                local input = lib.inputDialog('REMOVE POINT', {
                    { type = 'number', label = 'point index?', placeholder = '', required = true, min = 1, max = #asp },
                })

                if input then
                    local point = asp[input[1]]
                    if point then
                        table.remove(asp, input[1])
                        GarageZone[garage.index].spawnPoint = asp
                        utils.notify("point with ID " .. input[1] .. " was successfully deleted", "success", 8000)

                        if #GarageZone[garage.index].spawnPoint < 1 then
                            GarageZone[garage.index].spawnPoint = nil
                        end

                        Zones.save(GarageZone)
                    end
                end
            end
        }
    end
    utils.createMenu(context)
end

--- Add & Remove job
---@param garage {index: string, value: table}
local function jobOptions(garage)
    local key = garage.index
    local value = garage.value

    local contextJob = {
        id = "rhd_contextJob",
        title = key,
        menu = "rhd:action_garage",
        onBack = function() end,
        options = {}
    }

    if value.job and type(value.job) == "table" then
        for name, grade in pairs(value.job) do
            contextJob.options[#contextJob.options + 1] = {
                title = locale("rhd_garage:context.admin.job_description", name, grade),
                icon = "briefcase",
                onSelect = function()
                    local contextJob2 = {
                        id = "rhd_contextJob2",
                        title = name,
                        options = {
                            {
                                title = locale("rhd_garage:context.admin.delete"),
                                icon = "trash",
                                onSelect = function()
                                    value.job[name] = nil

                                    if not next(value.job) then
                                        value.job = nil
                                    end

                                    GarageZone[key].job = value.job
                                    utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                    Zones.save(GarageZone)
                                end
                            }
                        }
                    }
                    utils.createMenu(contextJob2)
                end
            }
        end
    end

    contextJob.options[#contextJob.options + 1] = {
        title = locale("rhd_garage:context.admin.add_job"),
        icon = "plus",
        onSelect = function()
            local input = lib.inputDialog(locale("rhd_garage:input.admin.garage_access"), {
                { type = 'input',  label = locale("rhd_garage:input.admin.garage_access_job"),       placeholder = 'police, ambulance, etc', required = true },
                { type = 'number', label = locale("rhd_garage:input.admin.garage_access_grade_job"), required = true }
            })

            if input then
                if not value.job then value.job = {} end
                value.job[input[1]] = tonumber(input[2])
                GarageZone[key].job = value.job
                utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                Zones.save(GarageZone)
            end
        end
    }

    utils.createMenu(contextJob)
end

--- Add & Remove gang
---@param garage {index: string, value: table}
local function gangOptions(garage)
    local key = garage.index
    local value = garage.value

    local contextGang = {
        id = "rhd_contextGang",
        title = key,
        menu = "rhd:action_garage",
        onBack = function() end,
        options = {}
    }

    if value.gang and type(value.gang) == "table" then
        for name, grade in pairs(value.gang) do
            contextGang.options[#contextGang.options + 1] = {
                title = locale("rhd_garage:context.admin.gang_description", name, grade),
                icon = "users",
                onSelect = function()
                    local contextGang2 = {
                        id = "rhd_contextGang2",
                        title = name,
                        options = {
                            {
                                title = locale("rhd_garage:context.admin.delete"),
                                icon = "trash",
                                onSelect = function()
                                    value.gang[name] = nil

                                    if not next(value.gang) then
                                        value.gang = nil
                                    end

                                    GarageZone[key].gang = value.gang
                                    utils.notify(locale("rhd_garage:notify.admin.success_deleted_access"), "success")
                                    Zones.save(GarageZone)
                                end
                            }
                        }
                    }
                    utils.createMenu(contextGang2)
                end
            }
        end
    end

    contextGang.options[#contextGang.options + 1] = {
        title = locale("rhd_garage:context.admin.add_gang"),
        icon = "plus",
        onSelect = function()
            local input = lib.inputDialog(locale("rhd_garage:input.admin.garage_access"), {
                { type = 'input',  label = locale("rhd_garage:input.admin.garage_access_gang"),       placeholder = 'ballas, vagos, etc', required = true },
                { type = 'number', label = locale("rhd_garage:input.admin.garage_access_grade_gang"), required = true }
            })

            if input then
                if not value.gang then value.gang = {} end
                value.gang[input[1]] = tonumber(input[2])
                GarageZone[key].gang = value.gang
                utils.notify(locale("rhd_garage:notify.admin.success_added_access", input[1]))
                Zones.save(GarageZone)
            end
        end
    }

    utils.createMenu(contextGang)
end

local function setVehicles(garage)
    local key = garage.index
    local value = garage.value

    local vehicles = exports.qbx_core:GetVehiclesByHash()

    local options = {}
    for k, v in pairs(vehicles) do
        options[#options + 1] = {
            label = v.name,
            value = v.model
        }
    end

    if value.vehicles then
        for k, v in pairs(value.vehicles) do
            for k2, v2 in pairs(options) do
                if v == v2.value then
                    options[k2].selected = true
                end
            end
        end
    end

    for k, v in pairs(options) do
        if v.selected then
            options[k].icon = "check"
        end
    end

    table.sort(options, function(a, b) return a.label < b.label end)

    if not value.vehicles then value.vehicles = {} end

    local input = lib.inputDialog("Carros da Garagem", {
        { type = "multi-select", label = 'Lista', placeholder = 'Selecionar', options = options, default = value.vehicles ,searchable = true, required = false }
    })

    if input then
        if not value.vehicles then value.vehicles = {} end
        value.vehicles = input[1] or {}
        GarageZone[key].vehicles = value.vehicles
        utils.notify("Lista de Veículos alterada com sucesso!", "success", 10000)
        Zones.save(GarageZone)
    end
end

local function listGarage()
    local context = {
        id = 'rhd:list_garage',
        title = locale("rhd_garage:context.admin.listgarage_title"),
        options = {}
    }
    for k, v in pairs(GarageZone) do
        context.options[#context.options + 1] = {
            title = k,
            icon = "warehouse",
            description = locale("rhd_garage:context.admin.listgarage_description",
                v.impound and "Impound" or v.shared and "Shared" or "Public", utils.garageType("getstring", v.type)),
            onSelect = function()
                local context2 = {
                    id = "rhd:action_garage",
                    title = k,
                    menu = "rhd:list_garage",
                    onBack = function()

                    end,
                    options = {
                        {
                            title = locale("rhd_garage:context.admin.options_delete"),
                            icon = "trash",
                            onSelect = delete,
                            args = {
                                index = k
                            }
                        },
                        -- {
                        --     title = locale("rhd_garage:context.admin.blip_setting"),
                        --     icon = "map",
                        --     onSelect = setBlip,
                        --     args = {
                        --         index = k
                        --     }
                        -- },
                        {
                            title = locale("rhd_garage:context.admin.options_changelocation"),
                            icon = "location-dot",
                            onSelect = changeLocation,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.tptoloc"),
                            icon = "location-dot",
                            onSelect = teleportToLocation,
                            args = {
                                value = v
                            }
                        },
                        {
                            title = locale("rhd_garage:context.admin.options_changelabel"),
                            icon = "pen-to-square",
                            onSelect = changeGarageLabel,
                            args = {
                                index = k,
                                value = v
                            }
                        },
                        {
                            title = "Locais de Spawn",
                            icon = "location-dot",
                            onSelect = setspawnpoint,
                            args = {
                                index = k
                            }
                        },
                        {
                            title = "Definir Veículos",
                            icon = "car",
                            onSelect = setVehicles,
                            args = {
                                index = k,
                                value = v
                            }
                        }
                    }
                }

                if not v.impound and not v.gang then
                    context2.options[#context2.options + 1] = {
                        title = locale("rhd_garage:context.admin.job_title"),
                        icon = "briefcase",
                        onSelect = jobOptions,
                        args = {
                            index = k,
                            value = v
                        }
                    }
                end

                if not v.impound and not v.job then
                    context2.options[#context2.options + 1] = {
                        title = locale("rhd_garage:context.admin.gang_title"),
                        icon = "users",
                        onSelect = gangOptions,
                        args = {
                            index = k,
                            value = v
                        }
                    }
                end
                utils.createMenu(context2)
            end
        }
    end
    utils.createMenu(context)
end

CreateThread(function()
    while not fw.playerLoaded do Wait(100) end
    if fw.playerLoaded then
        Zones.refresh()
        print("Garage data has been successfully loaded")
    end
end)

AddStateBagChangeHandler("rhd_garage_zone", "global", function(bagName, key, value)
    print(json.encode(value, { indent = true }))
    if value then
        GarageZone = value
        Zones.refresh()
    end
end)

RegisterNetEvent("rhd_garage:client:createGarage", createGarage)
RegisterNetEvent("rhd_garage:client:listgarage", listGarage)
