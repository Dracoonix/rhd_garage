Storage = {}

local function GroupFormat (groupData)
    local gJob = 'nil'

    if groupData and next(groupData) then
        local jobTable = {}
        local formatTable = '{%s}'
        for job, level in pairs(groupData) do
            jobTable[#jobTable + 1] = ('["%s"] = %d'):format(job, level)
        end
        gJob = formatTable:format(table.concat(jobTable, ', '))
    end

    return gJob
end

local function SaveGarage(garageData)
    local result = {}
    local Format = [[
    ["%s"] = {
        type = {%s},
        blip = %s,
        zones = {
            points = {
                %s
            },
            thickness = "%s"
        },
        spawnPoint = %s
        job = %s,
        gang = %s,
        impound = %s,
        shared = %s,
        vehicles = {%s},
        interaction = %s
    },
]]
    for label, data in pairs(garageData) do

        local points = {}
        for _, point in pairs(data.zones.points) do
            points[#points + 1] = ('vec3(%s, %s, %s)'):format(point.x, point.y, point.z)
        end

        local spawnpoint = nil
        if data.spawnPoint and #data.spawnPoint > 0 then
        local pf = [[{
            %s
        },
        ]]
            spawnpoint = {}
            for _, p in pairs(data.spawnPoint) do
                spawnpoint[#spawnpoint+1] = ('vec4(%s, %s, %s, %s)'):format(p.x, p.y, p.z, p.w)
            end
            spawnpoint = pf:format(table.concat(spawnpoint, ',\n\t\t\t'))
        end

        local interaction = nil
        if data.interaction then
            if type(data.interaction) == "table" then
                local f = [[{
            model = "%s",
            coords = vec4(%s, %s, %s, %s)
        },]]
                local model = data.interaction.model
                local coords = data.interaction.coords
                interaction = f:format(model, coords.x, coords.y, coords.z, coords.w)
            else
                local f = [["%s"]]
                interaction = f:format(data.interaction)
            end
        end

        local vehicles = {}
        if data.vehicles then
            for _, t in pairs(data.vehicles) do
                vehicles[#vehicles+1] = ('%q'):format(tostring(t))
            end
        end
    
        local gType = {}
        for _, t in pairs(data.type) do
            gType[#gType+1] = ('%q'):format(tostring(t))
        end

        print(json.encode(data.vehicles))

        result[#result+1] = Format:format(
            label,
            table.concat(gType, ', '),
            data.blip and ('{ type = %s, color = %s }'):format(data.blip.type, data.blip.color) or 'nil',
            table.concat(points, ',\n\t\t\t\t'),
            data.zones.thickness,
            spawnpoint,
            GroupFormat(data.job),
            GroupFormat(data.gang),
            data.impound or 'nil',
            data.shared or 'nil',
            table.concat(vehicles, ', ') or 'nil',
            interaction
        ):gsub('[%s]-[%w]+ = "?nil"?,?', '')

    end
    GarageZone = garageData
    GlobalState.rhd_garage_zone = garageData
    local serializedData = ('return {\n%s}'):format(table.concat(result, "\n"))
    SaveResourceFile(GetCurrentResourceName(), 'data/garage.lua', serializedData, -1)
end

local function SaveVehicleName(dataName)
    local result = {}
    local NameFormat = [[
    ["%s"] = {
        name = "%s"
    },
]]
    for plate, data in pairs(dataName) do
        result[#result + 1] = NameFormat:format(plate, data.name)
    end
    CNV = dataName
    local serializedData = ('return {\n%s}'):format(table.concat(result, "\n"))
    SaveResourceFile(GetCurrentResourceName(), 'data/customname.lua', serializedData, -1)
end

Storage.save = {
    garage = SaveGarage,
    vehname = SaveVehicleName,
}
