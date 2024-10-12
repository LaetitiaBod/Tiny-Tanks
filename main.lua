-- Debugger Visual Studio Code tomblind.local-lua-debugger-vscode
if pcall(require, "lldebugger") then
    require("lldebugger").start()
end
-- Allows debug
io.stdout:setvbuf("no")

-- import modules
local character = require("player")
local enemies = require("enemies")
local map = require("map")
local bullets = require("bullets")
local scenes = require("scenes")
local musicManager = require("musicManager")

local cursor = love.graphics.newImage("images/crosshair010.png")

SCENE = "menu"
GOD_MODE = false

function love.load()
    -- setup the seed
    local seed = os.time()
    print(seed) -- for debug
    math.randomseed(seed)

    -- setup the window
    love.window.setMode(map.SCREEN_WIDTH, map.SCREEN_HEIGHT)
    love.window.setTitle("Tiny Tanks")

    screen_width = map.SCREEN_WIDTH
    screen_height = map.SCREEN_HEIGHT
    -- hide cursor
    love.mouse.setVisible(false)
    MM = musicManager.load()

    scenes.loadMenu()
end

function love.update(dt)
    -- FPS limit to 60
    dt = math.min(dt, 1 / 60)

    -- mouse coordinates
    mouse_x, mouse_y = love.mouse.getPosition()

    if SCENE == "play" then
        enemies.update(dt, map)
        character.update(dt, map, enemies)
        MM.PlayMusic(2)
    end
    if SCENE == "next_level" then
        MM.PlayMusic(3)
    end
    if SCENE == "win" then
        MM.PlayMusic(4)
    end
    MM.update()
end

function love.draw()
    -- MENU
    -- ----------------
    if SCENE == "menu" then
        scenes.drawMenu()

    -- GAME
    -- ----------------
    elseif SCENE == "play" then
        map.draw()
        character.draw(map)
        enemies.draw()

        -- cursor
        love.graphics.draw(cursor, mouse_x, mouse_y, 0, 1, 1, cursor:getWidth()/2, cursor:getHeight()/2)

    -- NEXT LEVEL
    -- ----------------
    elseif SCENE == "next_level" then
        scenes.drawNextLevel(map)

    -- WIN
    -- ----------------
    elseif SCENE == "win" then
        scenes.drawWin(map)

    -- GAME OVER
    -- ----------------
    elseif SCENE == "gameover" then
        scenes.drawGameOver(map)
    end

    -- GOD MODE
    -- ----------------
    if GOD_MODE then
        local god_mode = "God Mode activated"
        love.graphics.print(god_mode, 1, 1)
    end

    -- local sDebug = "Debug:"
    -- sDebug = sDebug.." Tank.y= "..tostring(character.rotation)
    -- love.graphics.print(sDebug, 10, 10)
end

function love.keypressed(key)
    -- start the game to the level 1
    if (SCENE == "menu" or SCENE == "gameover" or SCENE == "win") and key == "space" then
        SCENE = "play"
        map.currentMap = 1
        InitGame()
    -- start the next level
    elseif SCENE == "next_level" and key == "space" then
        map.currentMap = map.currentMap + 1
        SCENE = "play"
        InitGame()
    end

    -- enable the god mode
    if key == "return" then
        GOD_MODE = not GOD_MODE
    end
    -- quit the game
    if key == "escape" then
        if SCENE == "win" then
            SCENE = "menu"
        else
            love.event.quit()
        end
    end
end

function InitGame()
    enemies.load()
    map.load()
    character.load(map)
    
    CreateTanks()
end

function CreateTanks()
    local col, row
    -- find player's position and enemies' positions and create them
    for row=1, map.MAP_ROW_NB do
        for col=1, map.MAP_COL_NB do
            local tile = map[map.currentMap].Locations[row][col]
            if tile == character.PLAYER then
                character.CreatePlayer(map, col, row)
            end
            if tile == enemies.ENEMY_SAND or tile == enemies.ENEMY_RED or tile == enemies.ENEMY_BLACK then
                enemies.CreateEnemy(map, col, row, tile)
            end
        end
    end
end

function MovesAndCollisions(_dt, _map, _src)
    -- keep in memory the old position
    local old_row, old_col = _src.row, _src.col
    local old_x, old_y = _src.x, _src.y
    local collided = false -- true if there is a collision
    
    -- Movements 
    if _src == character then
        character.Keypress(_dt, _map, old_row, old_col, old_x, old_y, _src)
    else
        enemies.Move(_dt, _src, _map)
    end
    -- Collisions
    collided = Collisions(_map, old_row, old_col, old_x, old_y, _src)

    return collided
end

function DetectsNextTile(_map, _src, _rotation_detection)
    -- Detect the next tile according to the direction of the player
    if _rotation_detection <= 90 then

        _src.col = math.floor((_src.x+_src.body:getHeight()/2- _map.MARGIN) / _map.TILE_SIZE) + 1
        _src.row = math.floor((_src.y+_src.body:getHeight()/2- _map.MARGIN) / _map.TILE_SIZE) + 1

    elseif _rotation_detection > 90 and _rotation_detection <= 180 then

        _src.col = math.floor((_src.x-_src.body:getHeight()/2+ _map.MARGIN) / _map.TILE_SIZE) + 1
        _src.row = math.floor((_src.y+_src.body:getHeight()/2- _map.MARGIN) / _map.TILE_SIZE) + 1
        
    elseif _rotation_detection > 180 and _rotation_detection <= 270 then

        _src.col = math.floor((_src.x-_src.body:getHeight()/2+ _map.MARGIN) / _map.TILE_SIZE) + 1
        _src.row = math.floor((_src.y-_src.body:getWidth()/2+ _map.MARGIN) / _map.TILE_SIZE) + 1

    elseif _rotation_detection > 270 then

        _src.col = math.floor((_src.x+_src.body:getHeight()/2- _map.MARGIN) / _map.TILE_SIZE) + 1
        _src.row = math.floor((_src.y-_src.body:getWidth()/2+ _map.MARGIN) / _map.TILE_SIZE) + 1

    end
end

function Collisions(_map, _old_row, _old_col, _old_x, _old_y, _src)
    -- collisions with screen edges
    if _src.x < (_src.body:getWidth()/2) + _map.FENCE_SIZE or _src.x > (screen_width - (_src.body:getWidth()/2) - _map.FENCE_SIZE) then
        _src.col =_old_col
        _src.x = _old_x
        return true
    end
    if _src.y < (_src.body:getHeight()/2) + _map.FENCE_SIZE or _src.y > (screen_height - (_src.body:getHeight()/2) - _map.FENCE_SIZE) then
        _src.row = _old_row
        _src.y = _old_y
        return true
    end
    
    -- define the actual tile
    if _src.row <= _map.MAP_ROW_NB and _src.col <= _map.MAP_COL_NB then
        _src.tileId = _map[_map.currentMap].Grid[_src.row][_src.col]
    else
        _src.tileId = nil
    end

    -- collisions with solid tiles
    if _map.isSolid(_src.tileId) then
        _src.x = _old_x
        _src.y = _old_y
        return true
    end
    
    -- slow with oiled tiles
    if _map.isOiled(_src.tileId) then
        _src.speed = _src.INITIAL_SPEED / 2
    else
        _src.speed = _src.INITIAL_SPEED
    end
    
    -- collisions with obstacles
    for _, obs in ipairs(_map.obstacles) do
        if math.dist(obs.x, obs.y, _src.x, _src.y) < _src.body:getHeight()/2 + obs.img:getHeight()/2 then
            _src.x = _old_x
            _src.y = _old_y
            return true
        end
    end

    -- collisions with mines
    if _src == character then
        for _, mine in ipairs(enemies.mines) do
            if math.dist(mine.x, mine.y, _src.x, _src.y) < 40 then
                mine.target = "player"
                mine.status = "explosion"
            end
        end
    end

    return false
end

function math.angle(x1,y1, x2,y2) return math.atan2(y2-y1, x2-x1) end
function math.dist(x1, y1, x2, y2) return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5 end
function ResetColor() love.graphics.setColor(1,1,1,1) end