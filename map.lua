local Map = {}

local MAP_LIST = require("map_list")

Map.TileSheet = nil
Map.TileTextures = {}
Map.TileTypes = {}

Map.SCREEN_WIDTH = 1216
Map.SCREEN_HEIGHT = 832
Map.MAP_ROW_NB = 13
Map.MAP_COL_NB = 19
Map.TILE_SIZE = 64
Map.FENCE_SIZE = 16
Map.MARGIN = 4 -- some obstacles do not completely fill the tile

Map.currentMap = 1


function Map.load()
    -- Set the current map
    if MAP_LIST[Map.currentMap] ~= nil then
        Map[Map.currentMap] = MAP_LIST[Map.currentMap]
    end
    -- Load textures from a Tilesheet
    Map.InitTextures()
    -- Load obstacles and randomize some grounds
    Map.obstacles = {}
    Map.InitObstacles()
end

function Map.draw()
    Map.DrawBackground()
    Map.DrawObstacles()
end

function Map.isSolid(_tileId)
    -- Set the tiles listed as "solid"
    local tileType = Map.TileTypes[_tileId]
    if  tileType == "tileGrass_barrelBlack" or 
        tileType == "tileGrass_barrelRust" or 
        tileType == "tileSand_barrelRed" or 
        tileType == "tileSand_barrelGreen" or 
        tileType == "tileGrass_barricadeWood" or 
        tileType == "tileSand_barricadeWood" or 
        tileType == "tileGrass_crateWood" or 
        tileType == "tileSand_crateWood" or 
        tileType == "tileGrass_crateMetal" or 
        tileType == "tileSand_crateMetal"then
        return true
    end
    return false
end

function Map.isOiled(_tileId)
    -- Set the tiles listed as "oiled"
    local tileType = Map.TileTypes[_tileId]
    if  tileType == "tileGrass_oiled" or 
        tileType == "tileSand_oiled" then
        return true
    end
    return false
end

function Map.InitTextures()
    -- Load the tilesheet
    Map.TileSheet = love.graphics.newImage("images/map/terrainTiles_default.png")

    -- Size of the TileSheet
    local colNumber = Map.TileSheet:getWidth() / Map.TILE_SIZE
    local rowNumber = Map.TileSheet:getHeight() / Map.TILE_SIZE

    local c, r
    local id = 1
    Map.TileTextures[0] = nil

    -- Generates Quads depending on a TileSheet
    for r=1, rowNumber do
        for c=1, colNumber do
            Map.TileTextures[id] = love.graphics.newQuad(
                (c-1)*Map.TILE_SIZE, (r-1)*Map.TILE_SIZE,
                Map.TILE_SIZE, Map.TILE_SIZE,
                Map.TileSheet:getWidth(), Map.TileSheet: getHeight()
            )
            id = id + 1
        end
    end

    Map.TileTypes[1] = "tileGrass1"
    Map.TileTypes[2] = "tileGrass_barrelBlack"
    Map.TileTypes[3] = "fenceRed_S"
    Map.TileTypes[4] = "fenceYellow_S"
    Map.TileTypes[5] = "fence_NO"
    Map.TileTypes[6] = "fence_NE"
    Map.TileTypes[7] = "tileGrass_oiled"
    Map.TileTypes[8] = "tileGrass_barricadeWood"
    Map.TileTypes[9] = "tileGrass2"
    Map.TileTypes[10] = "tileGrass_barrelRust"
    Map.TileTypes[11] = "fenceRed_N"
    Map.TileTypes[12] = "fenceYellow_N"
    Map.TileTypes[13] = "fence_SO"
    Map.TileTypes[14] = "fence_SE"
    Map.TileTypes[15] = "tileSand_oiled"
    Map.TileTypes[16] = "tileSand_barricadeWood"
    Map.TileTypes[17] = "tileSand1"
    Map.TileTypes[18] = "tileSand_barrelRed"
    Map.TileTypes[19] = "fenceRed_O"
    Map.TileTypes[20] = "fenceYellow_O"
    Map.TileTypes[21] = "tileGrass_transitionE"
    Map.TileTypes[22] = "tileGrass_transitionW"
    Map.TileTypes[23] = "tileGrass_crateWood"
    Map.TileTypes[24] = "tileSand_crateWood"
    Map.TileTypes[25] = "tileSand2"
    Map.TileTypes[26] = "tileSand_barrelGreen"
    Map.TileTypes[27] = "fenceRed_E"
    Map.TileTypes[28] = "fenceYellow_E"
    Map.TileTypes[29] = "tileGrass_transitionN"
    Map.TileTypes[30] = "tileGrass_transitionS"
    Map.TileTypes[31] = "tileGrass_crateMetal"
    Map.TileTypes[32] = "tileSand_crateMetal"
    Map.TileTypes[33] = "tileGrass_cornerTopLeft_tileSand"
    Map.TileTypes[34] = "tileGrass_cornerBotLeft_tileSand"
    Map.TileTypes[35] = "tileGrass_cornerTopRight_tileSand"
    Map.TileTypes[36] = "tileGrass_cornerBotRight_tileSand"
    Map.TileTypes[37] = "tileSand_cornerTopLeft_tileGrass"
    Map.TileTypes[38] = "tileSand_cornerBotLeft_tileGrass"
    Map.TileTypes[39] = "tileSand_cornerTopRight_tileGrass"
    Map.TileTypes[40] = "tileSand_cornerBotRight_tileGrass"
end

function Map.InitObstacles()
    local col, row
    for row=1, Map.MAP_ROW_NB do
        for col=1, Map.MAP_COL_NB do
            -- defines the current tile
            local tile = Map[Map.currentMap].Grid[row][col]
            -- defines the current object
            local location = Map[Map.currentMap].Locations[row][col]
            -- randomize tile grass
            if tile == 1 then
                tile = love.math.random(1, 2)
                if tile == 1 then Map[Map.currentMap].Grid[row][col] = 1
                elseif tile == 2 then Map[Map.currentMap].Grid[row][col] = 9 end
            end
            -- randomize tile sand
            if tile == 17 then
                tile = love.math.random(1, 2)
                if tile == 1 then Map[Map.currentMap].Grid[row][col] = 17
                elseif tile == 2 then Map[Map.currentMap].Grid[row][col] = 25 end
            end
            -- defines the obstacles
            if  location == MAP_LIST.OBSTACLE_BARREL or 
                location == MAP_LIST.OBSTACLE_CRATE or 
                location == MAP_LIST.OBSTACLE_HOLE or 
                location == MAP_LIST.OBSTACLE_TREE then

                local obstacle = {}
                obstacle.x = (col * Map.TILE_SIZE) - (Map.TILE_SIZE/2)
                obstacle.y = (row * Map.TILE_SIZE) - (Map.TILE_SIZE/2)
                -- creates a barrel
                if location == MAP_LIST.OBSTACLE_BARREL then
                    obstacle.img = love.graphics.newImage("images/map/barrelRust_top.png")
                    obstacle.type = "barrel"
                -- creates a crate
                elseif location == MAP_LIST.OBSTACLE_CRATE then
                    obstacle.img = love.graphics.newImage("images/map/crateWood.png")
                    obstacle.type = "crate"
                -- creates a hole
                elseif location == MAP_LIST.OBSTACLE_HOLE then
                    obstacle.img = love.graphics.newImage("images/map/hole.png")
                    obstacle.type = "hole"
                -- creates a tree
                elseif location == MAP_LIST.OBSTACLE_TREE then
                    obstacle.img = love.graphics.newImage("images/map/treeBrown_small.png")
                    obstacle.type = "tree"
                end
                -- add the obstacle to the table
                table.insert(Map.obstacles, obstacle)
            end
        end
    end
end

function Map.DrawBackground()
    -- draw each tile as background
    local col, row
    for row=1, Map.MAP_ROW_NB do
        for col=1, Map.MAP_COL_NB do
            local tile = Map[Map.currentMap].Grid[row][col]
            local textureQuad = Map.TileTextures[tile]
            if textureQuad ~= nil then
                love.graphics.draw(Map.TileSheet, textureQuad, (col-1)*Map.TILE_SIZE, (row-1)*Map.TILE_SIZE)
            end
        end
    end
end

function Map.DrawObstacles()
    -- draw each obstacles
    for k, obs in ipairs(Map.obstacles) do
        love.graphics.draw(obs.img, obs.x, obs.y, 0, 1, 1, obs.img:getWidth()/2, obs.img:getHeight()/2)
    end
end

function Map.LevelWon(_enemiesList)
    -- check if all the enemies have the status "broken"
    local isWon = true
    for _, enemy in ipairs(_enemiesList) do
        if enemy.status ~= "broken" then isWon = false end
    end
    if isWon then
        -- check if there is a next level
        if MAP_LIST[Map.currentMap+1] == nil then
            SCENE = "win"
        else
            SCENE = "next_level"
        end
    end
end

return Map