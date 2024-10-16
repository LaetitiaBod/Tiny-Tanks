local Enemies = {}

local character = require("player")
local bullets = require("bullets")
local E_STATES = require("enemy_states")

Enemies.ENEMY_SAND = 2
Enemies.ENEMY_RED = 3
Enemies.ENEMY_BLACK = 4

function Enemies.load()
    -- initialize lists
    Enemies.list = {}
    Enemies.mines = {}
end

function Enemies.update(_dt, _map)
    
    -- update the landmines
    Enemies.UpdateMineSprite(_dt)
    
    -- update the enemies
    for _, enemy in ipairs(Enemies.list) do
        -- timer for shoot
        enemy.weapon.cooldown = enemy.weapon.cooldown - _dt
        
        -- NONE
        -- ----------------
        if enemy.state == E_STATES.NONE then
            -- initialize the enemy to "wandering" state
            enemy.status = "wandering"
            enemy.state = E_STATES.CHG_DIR

        -- CHG_DIR
        -- ----------------
        elseif enemy.state == E_STATES.CHG_DIR then
            if enemy.status == "wandering" then
                -- choose a random rotation
                enemy.targeted_rotation = math.random(0, 360)
                -- points the weapon in the direction of the enemy
                enemy.weapon_rotation = enemy.rotation
            end
            -- the enemy must reach a target
            if enemy.status == E_STATES.CHASE or enemy.status == E_STATES.FLEEING or enemy.status == E_STATES.FIXING then
                -- aim the target
                Enemies.Aim(_dt, enemy, enemy.target)
                enemy.targeted_rotation = enemy.weapon_rotation
                -- try to avoid obstacles
                if enemy.collided then
                    enemy.targeted_rotation = enemy.rotation + 60
                    if enemy.targeted_rotation > 360 then enemy.targeted_rotation = enemy.targeted_rotation - 360 end
                end
            end
            -- go to rotate state
            enemy.state = E_STATES.ROTATE

        -- ROTATE
        -- ----------------
        elseif enemy.state == E_STATES.ROTATE then
            -- if the enemy must reach a target, continue to aim it
            if enemy.status == E_STATES.CHASE or enemy.status == E_STATES.FLEEING or enemy.status == E_STATES.FIXING then
                Enemies.Aim(_dt, enemy, enemy.target)
            end

            -- calcul difference between actual rotation and the desired rotation
            local difference = enemy.rotation - enemy.targeted_rotation

            if difference <= -180 or (difference >= 0 and difference <= 180) then
                -- turn left
                enemy.rotation = enemy.rotation - (enemy.rotation_speed * _dt)
                enemy.weapon_rotation = enemy.weapon_rotation - (enemy.rotation_speed * _dt)
                
                -- normalizes angle
                if enemy.rotation <= 0 then enemy.rotation = 360 end
                if enemy.weapon_rotation <= 0 then enemy.weapon_rotation = 360 end

                -- the desired rotation is reached, go to move state
                if (enemy.rotation - enemy.targeted_rotation) <= 0 and difference >= -180 then 
                    if enemy.status == E_STATES.FIXING then 
                        enemy.state = E_STATES.FIXING
                    else
                        enemy.state = E_STATES.MOVE
                    end
                end
            else
                -- turn right
                enemy.rotation = enemy.rotation + (enemy.rotation_speed * _dt)
                enemy.weapon_rotation = enemy.weapon_rotation + (enemy.rotation_speed * _dt)
                
                -- normalizes angle
                if enemy.rotation >= 360 then enemy.rotation = 0 end
                if enemy.weapon_rotation >= 360 then enemy.weapon_rotation = 0 end

                -- the desired rotation is reached, go to move state
                if (enemy.rotation - enemy.targeted_rotation) >= 0 and difference <= 180 then
                    if enemy.status == E_STATES.FIXING then 
                        enemy.state = E_STATES.FIXING
                    else
                        enemy.state = E_STATES.MOVE
                    end
                end
            end

        -- MOVE
        -- ----------------
        elseif enemy.state == E_STATES.MOVE then
            -- timer for landing mines
            enemy.landing_mines_timer = enemy.landing_mines_timer + _dt

            -- create a landmine
            if enemy.landing_mines_timer > 7 then
                Enemies.CreateMine(enemy)
                enemy.state = E_STATES.LAND_MINES
            end
            
            -- check if there is broken allies nearby
            if Enemies.FindBrokenAllies(enemy) then return end

            -- check if the enemy collides
            enemy.collided = MovesAndCollisions(_dt, _map, enemy)
            if enemy.collided then
                enemy.state = E_STATES.CHG_DIR
            end

            -- distance with the player
            local distance_player = math.dist(enemy.x, enemy.y, character.x, character.y)

            -- player is too far => wandering
            if distance_player > enemy.range_detection and enemy.target ~= nil then
                enemy.status = "wandering"
                enemy.target = nil
                enemy.state = E_STATES.CHG_DIR

            -- player is detected => chasing
            elseif distance_player < enemy.range_detection and distance_player >= enemy.range_attack then
                if enemy.status ~= E_STATES.CHASE then enemy.state = E_STATES.CHASE end

            -- player is in range => attacking
            elseif distance_player < enemy.range_attack and distance_player >= enemy.range_fleeing then
                enemy.state = E_STATES.ATTACK

            -- player is too close => fleeing
            elseif distance_player < enemy.range_fleeing and enemy.status ~= E_STATES.FLEEING then
                enemy.state = E_STATES.FLEEING
            end

        -- CHASE
        -- ----------------
        elseif enemy.state == E_STATES.CHASE then
            -- check if there is broken allies nearby
            if Enemies.FindBrokenAllies(enemy) then return end

            enemy.target = character
            enemy.status = E_STATES.CHASE
            enemy.state = E_STATES.CHG_DIR
            
        -- ATTACK
        -- ----------------
        elseif enemy.state == E_STATES.ATTACK then
            -- check if there is broken allies nearby
            if Enemies.FindBrokenAllies(enemy) then return end

            enemy.status = E_STATES.ATTACK
            Enemies.Aim(_dt, enemy, character)
            bullets.Shoot(enemy, _map)

            -- distance with the player
            local distance_player = math.dist(enemy.x, enemy.y, character.x, character.y)

            -- player moves away => chasing
            if distance_player > enemy.range_attack and distance_player < enemy.range_detection then
                enemy.state = E_STATES.CHASE

            -- player is too close => fleeing
            elseif distance_player < enemy.range_fleeing then
                enemy.state = E_STATES.FLEEING
            end
        
        -- FLEEING
        -- ----------------
        elseif enemy.state == E_STATES.FLEEING then
            -- check if there is broken allies nearby
            if Enemies.FindBrokenAllies(enemy) then return end
            
            enemy.status = E_STATES.FLEEING
            enemy.target = {}

            -- choose where to flee : the farthest corner of the map from the player
            if character.x > screen_width-character.x then enemy.target.x = 0 else enemy.target.x = screen_width end
            if character.y > screen_height-character.y then enemy.target.y = 0 else enemy.target.y = screen_width end

            enemy.state = E_STATES.CHG_DIR
        
        -- FIXING
        -- ----------------
        elseif enemy.state == E_STATES.FIXING then

            -- go to the broken ally
            if enemy.status ~= E_STATES.FIXING then
                enemy.status = E_STATES.FIXING
                enemy.state = E_STATES.CHG_DIR
            else
                -- the ally is already repaired
                if enemy.target.status ~= "broken" then
                    enemy.wrench.frame = 0
                    enemy.fixing_timer = 0
                    enemy.status = "wandering"
                    enemy.state = E_STATES.CHG_DIR
                end
                -- check if an obstacle is in the way
                enemy.collided = MovesAndCollisions(_dt, _map, enemy)
                if enemy.collided then
                    enemy.state = E_STATES.CHG_DIR
                end

                -- distance with the broken ally
                local distance_target = math.dist(enemy.x, enemy.y, enemy.target.x, enemy.target.y)

                -- the enemy is close enough to his ally to repair it
                if distance_target < 40 then
                    -- frames for wrench animation
                    enemy.wrench.frame = enemy.wrench.frame + 2*_dt
                    if enemy.wrench.frame > #enemy.wrench.image+1 then
                        enemy.wrench.frame = 0
                    end
                    enemy.speed = 0

                    -- timer for fixing time
                    enemy.fixing_timer = enemy.fixing_timer + _dt

                    -- the ally has finished being repaired
                    if enemy.fixing_timer > 4 then
                        -- reset timers and frames
                        enemy.wrench.frame = 0
                        enemy.smoke.frame = 0
                        enemy.fixing_timer = 0
                        -- set states to wandering
                        enemy.target.status = "wandering"
                        enemy.status = "wandering"
                        enemy.state = E_STATES.CHG_DIR
                        enemy.target.state = E_STATES.CHG_DIR
                    end
                end
            end

        -- BROKEN
        -- ----------------
        elseif enemy.state == E_STATES.BROKEN then
            enemy.status = E_STATES.BROKEN
            -- frames for smoke animation
            enemy.smoke.frame = enemy.smoke.frame + 2*_dt
            if enemy.smoke.frame > #enemy.smoke.image+1 then
                enemy.smoke.frame = 0
            end
            -- check if all the enemies are broken
            _map.LevelWon(Enemies.list)

        -- LAND MINES
        -- ----------------
        elseif enemy.state == E_STATES.LAND_MINES then
            enemy.status = "land mines"
            enemy.speed = 0

            -- timer for dropping time
            enemy.landing_mines_timer = enemy.landing_mines_timer + _dt

            -- the enemy has finished to drop the mine
            if enemy.landing_mines_timer > 9 then
                -- reset the timer
                enemy.landing_mines_timer = 0
                -- set state to wandering
                enemy.status = "wandering"
                enemy.state = E_STATES.MOVE 
            end
        end

        -- Allows bullets to move
        bullets.BulletVelocity(enemy, _map, character, Enemies)
    end
end

function Enemies.draw()

    local n
    for n = 1, #Enemies.list do
        local current_enemy = Enemies.list[n]
        -- body
        love.graphics.draw(current_enemy.body, current_enemy.x, current_enemy.y, math.rad(current_enemy.rotation + current_enemy.initial_rotation), 1, 1, current_enemy.body:getWidth()/2, current_enemy.body:getHeight()/2)
        -- weapon
        love.graphics.draw(current_enemy.weapon.img, current_enemy.x, current_enemy.y, math.rad(current_enemy.weapon_rotation + current_enemy.initial_rotation), 1, 1, current_enemy.weapon.img:getWidth()/2, 5)
        -- smoke
        if current_enemy.state == E_STATES.BROKEN and current_enemy.smoke.frame > 0 then 
            frameArrondie = math.floor(current_enemy.smoke.frame)
            love.graphics.draw(current_enemy.smoke.image[frameArrondie], current_enemy.x, current_enemy.y, 0, 1, 1, current_enemy.smoke.image[frameArrondie]:getWidth()/2, current_enemy.smoke.image[frameArrondie]:getHeight()/2)
        end
        -- wrench
        if current_enemy.status == E_STATES.FIXING and current_enemy.wrench.frame > 0 then 
            local frameArrondie = math.floor(current_enemy.wrench.frame)
            love.graphics.draw(current_enemy.wrench.image[frameArrondie], current_enemy.x, current_enemy.y, 0, 1, 1, current_enemy.wrench.image[frameArrondie]:getWidth()/2, current_enemy.wrench.image[frameArrondie]:getHeight()/2)
        end
        -- bullets
        bullets.draw(current_enemy)
        -- mines
        for k, mine in ipairs(Enemies.mines) do
            local frameArrondie = math.floor(mine.frame)
            if mine.status == "static" then
                love.graphics.draw(mine.static_image[frameArrondie], mine.x, mine.y, 0, 1, 1, mine.static_image[frameArrondie]:getWidth()/2, mine.static_image[frameArrondie]:getHeight()/2)
            elseif mine.status == "explosion" then
                love.graphics.draw(mine.explosion_image[frameArrondie], mine.x, mine.y, 0, 1, 1, mine.explosion_image[frameArrondie]:getWidth()/2, mine.explosion_image[frameArrondie]:getHeight()/2)
            end
        end
        -- love.graphics.print(current_enemy.state, current_enemy.x - 10, current_enemy.y - 10)
        -- love.graphics.print(current_enemy.status, current_enemy.x - 10, current_enemy.y - 20)
    end
    -- local sDebug = "Debug:"
    -- sDebug = sDebug.." targeted_rotation= "..tostring(Enemies.list[1].targeted_rotation)
    -- sDebug = sDebug.." landing_mines_timer= "..tostring(Enemies.list[1].landing_mines_timer)
    -- love.graphics.print(sDebug, 10, 20)
end

function Enemies.CreateEnemy(_map, _col, _row, _tile)
    local enemy = {}

    enemy.state = E_STATES.NONE
    enemy.status = ""
    enemy.type = _tile

    enemy.x = _col * _map.TILE_SIZE - _map.TILE_SIZE/2
    enemy.y = _row * _map.TILE_SIZE - _map.TILE_SIZE/2
    enemy.col = _col
    enemy.row = _row
    enemy.tileId = 1

    enemy.initial_rotation = 270
    enemy.rotation = 180
    enemy.targeted_rotation = 0
    enemy.weapon_rotation = 180
    
    enemy.range_detection = 500
    enemy.range_attack = 350
    enemy.range_fleeing = 200

    enemy.collided = false
    enemy.fixing_timer = 0
    enemy.landing_mines_timer = 0

    enemy.weapon = {
        img = nil,
        img_bullet = nil,
        cooldown = 0,
        fire_rate = 2,
        bullet_speed = 3,
        cannon_length = 30
    }

    enemy.list_bullets = {}

    if enemy.type == Enemies.ENEMY_SAND then
        enemy.body = love.graphics.newImage("images/tanks/tankBody_sand_outline.png")
        enemy.weapon.img = love.graphics.newImage("images/tanks/tankSand_barrel2_outline.png")
        enemy.weapon.img_bullet = love.graphics.newImage("images/tanks/bulletSand1_outline.png")
        
        enemy.rotation_speed = 100
        enemy.speed = 100
        enemy.INITIAL_SPEED = 100

        enemy.weapon.fire_rate = 2
        enemy.weapon.bullet_speed = 3
    
    elseif enemy.type == Enemies.ENEMY_RED then
        enemy.body = love.graphics.newImage("images/tanks/tankBody_red_outline.png")
        enemy.weapon.img = love.graphics.newImage("images/tanks/tankRed_barrel3_outline.png")
        enemy.weapon.img_bullet = love.graphics.newImage("images/tanks/bulletRed3_outline.png")
        
        enemy.rotation_speed = 150
        enemy.speed = 150
        enemy.INITIAL_SPEED = 150
        
        enemy.weapon.fire_rate = 3
        enemy.weapon.bullet_speed = 5
    
    elseif enemy.type == Enemies.ENEMY_BLACK then
        enemy.body = love.graphics.newImage("images/tanks/tankBody_dark_outline.png")
        enemy.weapon.img = love.graphics.newImage("images/tanks/tankDark_barrel1_outline.png")
        enemy.weapon.img_bullet = love.graphics.newImage("images/tanks/bulletDark2_outline.png")
        
        enemy.rotation_speed = 80
        enemy.speed = 50
        enemy.INITIAL_SPEED = 50

        enemy.weapon.fire_rate = 1
        enemy.weapon.bullet_speed = 1
    end

    Enemies.LoadIcons(enemy)
    
    table.insert(Enemies.list, enemy)
end

function Enemies.Move(_dt, _enemy, _map)
    local rotation_radian = math.rad(_enemy.rotation)
    local cos_direction = math.cos(rotation_radian)
    local sin_direction = math.sin(rotation_radian)

    DetectsNextTile(_map, _enemy, _enemy.rotation)
    -- Enemies' move
    _enemy.x = _enemy.x + (_enemy.speed * _dt) * cos_direction
    _enemy.y = _enemy.y + (_enemy.speed * _dt) * sin_direction

end

function Enemies.Aim(_dt, _enemy, _target)
    -- weapon rotation
    _enemy.weapon_rotation = math.deg(math.angle(_enemy.x, _enemy.y, _target.x, _target.y))
    -- normalize the value of the radius (between 0 and 360)
    if _enemy.weapon_rotation < 0 then _enemy.weapon_rotation = _enemy.weapon_rotation + 360 end
end

function Enemies.FindBrokenAllies(_enemy)
    for _, e in ipairs(Enemies.list) do
        -- check if there is a broken ally
        if e.status == E_STATES.BROKEN then
            local distance = math.dist(_enemy.x, _enemy.y, e.x, e.y)
            -- if the ally is close enough, go to fix it
            if distance < _enemy.range_attack then
                _enemy.state = E_STATES.FIXING
                _enemy.target = e
                return true
            end
        end
    end
    return false
end

function Enemies.LoadIcons(_enemy)
    _enemy.smoke = {}
    _enemy.smoke.frame = 0
    _enemy.smoke.image = {}

    _enemy.wrench = {}
    _enemy.wrench.frame = 0
    _enemy.wrench.image = {}

    for i=0, 3 do
        _enemy.smoke.image[i] = love.graphics.newImage("images/smoke/smokeGrey"..i..".png")
    end
    for i=0, 2 do
        _enemy.wrench.image[i] = love.graphics.newImage("images/wrench/wrench"..i..".png")
    end
end

function Enemies.CreateMine(_enemy)
    local mine = {}
    mine.x = _enemy.x
    mine.y = _enemy.y
    mine.status = "static"
    mine.target = nil

    mine.frame = 0
    mine.static_image = {}
    mine.explosion_image = {}

    for i=0, 1 do
        mine.static_image[i] = love.graphics.newImage("images/mine/mine"..i..".png")
    end
    for i=0, 4 do
        mine.explosion_image[i] = love.graphics.newImage("images/mine/explosion/explosion"..i..".png")
    end
    -- if there is too much mines, destroy the oldest
    if #Enemies.mines > 10 then 
        table.remove(Enemies.mines, 1)
    end
    table.insert(Enemies.mines, mine)
end

function Enemies.UpdateMineSprite(_dt)
    for k, mine in ipairs(Enemies.mines) do
        -- defnies the number of frames depending on the status of the mine
        local frame_nb = 0
        if mine.status == "static" then
            frame_nb = 2
            mine.frame = mine.frame + 2*_dt
        elseif mine.status == "explosion" then
            soundLandmine:play()
            frame_nb = 5
            mine.frame = mine.frame + 8*_dt
        end

        -- after finishing the animation
        if mine.frame >= frame_nb then
            if mine.status == "static" then
                -- reset the frame number
                mine.frame = 0
            elseif mine.status == "explosion" then
                soundLandmine:stop()
                -- if the player has triggered the mine then game over
                if mine.target == "player" and not GOD_MODE then
                    SCENE = "gameover"
                end
                -- destroy the mine
                table.remove(Enemies.mines, k)
            end
        end
    end
end

return Enemies