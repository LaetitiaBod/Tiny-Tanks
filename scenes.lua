local Scene = {}
local musicManager = require("musicManager")


Scene.menu_img = nil
Scene.title_img = nil
Scene.next_level = nil
Scene.win = nil
Scene.game_over = nil

function Scene.loadMenu()
    Scene.menu_img = love.graphics.newImage("images/menu.png")
    Scene.title_img = love.graphics.newImage("images/titleTiny.png")
    Scene.next_level = love.graphics.newImage("images/nextLevel.png")
    Scene.win = love.graphics.newImage("images/win.png")
    Scene.game_over = love.graphics.newImage("images/gameOver.png")
end

function Scene.drawMenu()
    love.graphics.draw(Scene.menu_img, 0, 0)
    love.graphics.draw(Scene.title_img, 0, 0)
end


function Scene.loadNextLevel(_MM)
    _MM.PlayMusic(3)
end

function Scene.drawNextLevel(_map)
    love.graphics.setColor( 1,1,1, 0.5)
    _map.draw()
    ResetColor()
    love.graphics.draw(Scene.next_level, 0, 0)
end

function Scene.loadWin(_MM)
    _MM.PlayMusic(4)
end

function Scene.drawWin(_map)
    love.graphics.setColor( 1,1,1, 0.5)
    _map.draw()
    ResetColor()
    love.graphics.draw(Scene.win, 0, 0)
end

function Scene.drawGameOver(_map)
    love.graphics.setColor( 1,1,1, 0.5)
    _map.draw()
    ResetColor()
    love.graphics.draw(Scene.game_over, 0, 0)
end

return Scene