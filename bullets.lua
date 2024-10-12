local Bullets = {}

local E_STATES = require("enemy_states")

function Bullets.draw(_src)
    -- bullets
    local n
    for n = 1, #_src.list_bullets do
        love.graphics.draw(_src.weapon.img_bullet, _src.list_bullets[n].x, _src.list_bullets[n].y, math.rad(_src.list_bullets[n].rotation + _src.initial_rotation), 1, 1, _src.weapon.img_bullet:getWidth()/2, _src.weapon.img_bullet:getHeight()/2)
    end
end

function Bullets.BulletVelocity(_src, _map, _character, _enemies)
    -- velocity of the bullets
    for k, bullet in ipairs(_src.list_bullets) do
        local old_row, old_col = bullet.row, bullet.col

        bullet.x = bullet.x + bullet.vx * _src.weapon.bullet_speed
        bullet.y = bullet.y + bullet.vy * _src.weapon.bullet_speed

        -- if the bullet can still bounce
        if bullet.bounce >= 0 then
            -- check collisions
            Bullets.BulletCollisions(_src, _map, bullet, k, old_row, old_col, _character, _enemies)
        else
            -- remove the bullet
            table.remove(_src.list_bullets, k)
        end
    end
end

function Bullets.BulletCollisions(_src, _map, _current_bullet, _k, _old_row, _old_col, _character, _enemies)

    -- detect the next tile depending on the rotation of the bullet
    if _current_bullet.rotation <= 90 then
        _current_bullet.col = math.floor((_current_bullet.x+_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
        _current_bullet.row = math.floor((_current_bullet.y+_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
    elseif _current_bullet.rotation > 90 and _current_bullet.rotation <= 180 then
        _current_bullet.col = math.floor((_current_bullet.x-_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
        _current_bullet.row = math.floor((_current_bullet.y+_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
    elseif _current_bullet.rotation > 180 and _current_bullet.rotation <= 270 then
        _current_bullet.col = math.floor((_current_bullet.x-_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
        _current_bullet.row = math.floor((_current_bullet.y-_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
    elseif _current_bullet.rotation > 270 then
        _current_bullet.col = math.floor((_current_bullet.x+_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
        _current_bullet.row = math.floor((_current_bullet.y-_src.weapon.img_bullet:getHeight()/2+1) / _map.TILE_SIZE) + 1
    end

    -- collisions with screen edges
    if _current_bullet.x < _map.FENCE_SIZE or _current_bullet.x > (screen_width - _map.FENCE_SIZE) then
        -- ricochet the bullet
        _current_bullet.col = _old_col
        _current_bullet.vx = _current_bullet.vx * -1
        _current_bullet.rotation = math.deg(math.pi - math.rad(_current_bullet.rotation))

        -- decreases bounce count
        _current_bullet.bounce = _current_bullet.bounce-1
    end
    if _current_bullet.y < _map.FENCE_SIZE or _current_bullet.y > (screen_height - _map.FENCE_SIZE) then
        -- ricochet the bullet
        _current_bullet.row = _old_row
        _current_bullet.vy = _current_bullet.vy * -1
        _current_bullet.rotation = math.deg(math.pi*2 - math.rad(_current_bullet.rotation))

        -- decreases bounce count
        _current_bullet.bounce = _current_bullet.bounce-1
    end
    
    -- define the actual tile
    if _current_bullet.row <= _map.MAP_ROW_NB and _current_bullet.col <= _map.MAP_COL_NB then
        _current_bullet.tileId = _map[_map.currentMap].Grid[_current_bullet.row][_current_bullet.col]
    else
        _current_bullet.tileId = nil
    end

    -- collisions with solid tiles
    if _map.isSolid(_current_bullet.tileId) then
        -- decreases bounce count
        _current_bullet.bounce = _current_bullet.bounce-1
        if _old_row ~= _current_bullet.row then
            -- ricochet the bullet
            _current_bullet.vy = _current_bullet.vy * -1
            _current_bullet.rotation = math.deg(math.pi*2 - math.rad(_current_bullet.rotation))
        else
            -- ricochet the bullet
            _current_bullet.vx = _current_bullet.vx * -1
            _current_bullet.rotation = math.deg(math.pi - math.rad(_current_bullet.rotation))
        end
        if _current_bullet.rotation < 0 then _current_bullet.rotation = _current_bullet.rotation + 360 end
    end

    -- collisions with obstacles
    for k, obs in ipairs(_map.obstacles) do
        if math.dist(obs.x, obs.y, _current_bullet.x, _current_bullet.y) < _src.weapon.img_bullet:getHeight()/2 + obs.img:getHeight()/2 then
            -- when a bullet hits an obstacle other than a hole, destroy the bullet and the obstacle
            if obs.type ~= "hole" then
                table.remove(_map.obstacles, k)
                table.remove(_src.list_bullets, _k)
            end
        break
        end
    end

    -- collisions with mines
    if _src == _character then -- only the player can destroy the mines
        for _, mine in ipairs(_enemies.mines) do
            if math.dist(mine.x, mine.y, _current_bullet.x, _current_bullet.y) < 15 then
                mine.target = "bullet"
                mine.status = "explosion"
                table.remove(_src.list_bullets, _k)
            end
        end
    end

    -- collisions with other bullets
    for k, bullet in ipairs(_src.list_bullets) do
        if k ~= _k then
            -- when a bullet hits another bullet, destroy the bullets
            if math.dist(bullet.x, bullet.y, _current_bullet.x, _current_bullet.y) < 10 then
                    table.remove(_src.list_bullets, _k)
                    table.remove(_src.list_bullets, k)
            break
            end
        end
    end

    -- collisions with the player
    if math.dist(_character.x, _character.y, _current_bullet.x, _current_bullet.y) < _character.body:getHeight()/2 then
        table.remove(_src.list_bullets, _k)
        -- kill the player
        if not GOD_MODE then
            SCENE = "gameover"
        end
    end

    -- collisions with enemies
    for _, enemy in ipairs(_enemies.list) do
        if math.dist(enemy.x, enemy.y, _current_bullet.x, _current_bullet.y) < enemy.body:getHeight()/2 then
            if _src == _character then -- only the player can break enemies
                table.remove(_src.list_bullets, _k)
                
                enemy.state = E_STATES.BROKEN
                -- check if all the enemies are broken
                _map.LevelWon(_enemies.list)
            end
        end
    end
end

function Bullets.Shoot(_src, _map)
    if _src.weapon.cooldown < 0 then
        _src.weapon.cooldown = _src.weapon.fire_rate

        local aim_direction_radian = math.rad(_src.weapon_rotation)
        
        -- Create a bullet
        Bullets.CreateBullet(
            _src, _map,
            _src.x + _src.weapon.cannon_length * math.cos(aim_direction_radian),
            _src.y + _src.weapon.cannon_length * math.sin(aim_direction_radian),
            math.cos(aim_direction_radian),
            math.sin(aim_direction_radian),
            _src.weapon_rotation
        )
    end
end

function Bullets.CreateBullet(_src, _map, _x, _y, _vx, _vy, _rotation)
    soundShoot:play()

    local bullet = {}

    bullet.x = _x
    bullet.y = _y
    bullet.vx = _vx
    bullet.vy = _vy

    bullet.rotation = _rotation
    bullet.bounce = 2
    
    bullet.row = math.floor(bullet.y / _map.TILE_SIZE)
    bullet.col = math.floor(bullet.x / _map.TILE_SIZE)
    
    table.insert(_src.list_bullets, bullet)
end

return Bullets