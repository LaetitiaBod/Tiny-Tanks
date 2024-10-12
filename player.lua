local Tank = {}

local bullets = require("bullets")

Tank.body = nil

Tank.x = 100
Tank.y = 100
Tank.col = 1
Tank.row = 1
Tank.tileId = 1

Tank.weapon = {
    img = nil,
    img_bullet = nil
}

Tank.INITIAL_SPEED = 150
Tank.PLAYER = 0

function Tank.load(_map)
    -- Setup pictures
    Tank.body = love.graphics.newImage("images/tanks/tankBody_blue_outline.png")
    Tank.weapon.img = love.graphics.newImage("images/tanks/tankBlue_barrel2_outline.png")
    Tank.weapon.img_bullet = love.graphics.newImage("images/tanks/bulletBlue1_outline.png")

    -- Setup the actual tile
    Tank.tileId = _map[_map.currentMap].Grid[Tank.row][Tank.col]
end

function Tank.update(_dt, _map, _enemies)
    -- timer for the bullets
    Tank.weapon.cooldown = Tank.weapon.cooldown - _dt

    -- The weapon follows the mouse
    Tank.SetupWeaponRotation()
    
    -- Handle player's movements and player's collisions
    MovesAndCollisions(_dt, _map, Tank)
    
    -- Allows bullets to move
    bullets.BulletVelocity(Tank, _map, Tank, _enemies)
end

function Tank.draw(_map)
    -- character
    love.graphics.draw(Tank.body, Tank.x, Tank.y, math.rad(Tank.rotation + Tank.initial_rotation), 1, 1, Tank.body:getWidth()/2, Tank.body:getHeight()/2)
    -- weapon
    love.graphics.draw(Tank.weapon.img, Tank.x, Tank.y, math.rad(Tank.weapon_rotation + Tank.initial_rotation), 1, 1, Tank.weapon.img:getWidth()/2, 5)
    -- bullets
    bullets.draw(Tank)
end

function Tank.CreatePlayer(_map, _col, _row)
    Tank.initial_rotation = 270
    Tank.rotation = 0
    Tank.rotation_speed = 120
    Tank.weapon_rotation = 0
    Tank.speed = 150

    Tank.weapon.cooldown = 0
    Tank.weapon.fire_rate = 0.5
    Tank.weapon.bullet_speed = 2
    Tank.weapon.cannon_length = 30

    Tank.list_bullets = {}

    Tank.tileId  = tile
    Tank.col = _col
    Tank.row = _row
    Tank.x = _col * _map.TILE_SIZE - _map.TILE_SIZE/2
    Tank.y = _row * _map.TILE_SIZE - _map.TILE_SIZE/2
end

function Tank.SetupWeaponRotation()
    -- weapon rotation
    Tank.weapon_rotation = math.deg(math.angle(Tank.x, Tank.y, mouse_x, mouse_y))
    -- normalize the value of the radius (between 0 and 360)
    if Tank.weapon_rotation < 0 then Tank.weapon_rotation = Tank.weapon_rotation + 360 end
end

function Tank.Keypress(_dt, _map, old_row, old_col, old_x, old_y, _src)
    -- angle calculations
    local rotation_radian = math.rad(Tank.rotation)
    local cos_direction = math.cos(rotation_radian)
    local sin_direction = math.sin(rotation_radian)
    local rotation_detection = Tank.rotation

    -- Player's move
    if love.keyboard.isDown("z") then
        -- Move ahead
        rotation_detection = Tank.rotation
        DetectsNextTile(_map, Tank, rotation_detection)
        Tank.x = Tank.x + ((Tank.speed * 1.5) * _dt) * cos_direction
        Tank.y = Tank.y + ((Tank.speed * 1.5) * _dt) * sin_direction
        -- handle collisions
        collided = Collisions(_map, old_row, old_col, old_x, old_y, _src)
    end
    if love.keyboard.isDown("s") then
        -- Move behind
        rotation_detection = math.deg(math.rad(Tank.rotation) + math.pi)
        DetectsNextTile(_map, Tank, rotation_detection)
        Tank.x = Tank.x - (Tank.speed * _dt) * cos_direction
        Tank.y = Tank.y - (Tank.speed * _dt) * sin_direction
        -- handle collisions
        collided = Collisions(_map, old_row, old_col, old_x, old_y, _src)
    end
    -- Player's rotation
    if love.keyboard.isDown("q") then
        -- Turn left
        Tank.rotation = Tank.rotation - (Tank.rotation_speed * _dt)
        if Tank.rotation < 0 then Tank.rotation = 360 end
    end
    if love.keyboard.isDown("d") then
        -- Turn right
        Tank.rotation = Tank.rotation + (Tank.rotation_speed * _dt)
        if Tank.rotation > 360 then Tank.rotation = 0 end
    end
    -- Player's shoot
    if love.mouse.isDown(1) then
        bullets.Shoot(Tank, _map)
    end
end

return Tank