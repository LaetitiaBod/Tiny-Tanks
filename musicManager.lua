-- Le futur musicManager
local musicManager = {}

-- Musics
local musicMenu = love.audio.newSource("sounds/menu.mp3", "stream")
local musicRound = love.audio.newSource("sounds/round.wav", "stream")
local musicNextLevel = love.audio.newSource("sounds/next_level.mp3", "stream")
local musicWin = love.audio.newSource("sounds/win.mp3", "stream")

-- Sounds
soundShoot = love.audio.newSource("sounds/cannon_01.wav","static")
soundLandmine = love.audio.newSource("sounds/Grenade1Short.wav","static")


function musicManager.load()
    -- Crée le MusicManager et lui ajoute 2 musique
    musicManager = CreateMusicManager()
    musicManager.addMusic(musicMenu)
    musicManager.addMusic(musicRound)
    musicManager.addMusic(musicNextLevel)
    musicManager.addMusic(musicWin)
    
    return musicManager
  end


  -- Fonction créant et renvoyant un MusicManager
function CreateMusicManager()
    local myMM = {}
    myMM.lstMusics = {} -- Liste des musiques du mixer
    myMM.currentMusic = 0 -- ID de la musique en cours
    
    -- Méthode pour ajouter une musique à la liste
    function myMM.addMusic(pMusic)
        local newMusic = {}
        newMusic.source = pMusic
        -- S'assure de faire boucler la musique
        newMusic.source:setLooping(true)
        -- Coupe le volume par défaut
        newMusic.source:setVolume(0)
        table.insert(myMM.lstMusics, newMusic)
    end
    
    -- Méthode pour mettre à jour le mixer (à appeler dans update)
    function myMM.update()
      -- Parcours toutes les musiques pour s'assurer
      -- 1) que la musique en cours à son volume à 1, sinon on l'augmente
      -- 2) que si une ancienne musique n'a pas son volume à 0, on le baisse
        for index, music in ipairs(myMM.lstMusics) do
            if index == myMM.currentMusic then
                if music.source:getVolume() < 1 then
                    music.source:setVolume(music.source:getVolume()+0.01)
                end
            else
                if music.source:getVolume() > 0 then
                    music.source:setVolume(music.source:getVolume()-0.01)
                end
            end
        end
        if SCENE == "menu" then
            myMM.PlayMusic(1)
        end
        if SCENE == "play" then
            myMM.PlayMusic(2)
        end
        if SCENE == "next_level" then
            myMM.PlayMusic(3)
        end
        if SCENE == "win" then
            musicWin:setLooping(false)
            myMM.PlayMusic(4)
        end
    end
  
    -- Méthode pour démarrer une musique de la liste (par son ID)
    function myMM.PlayMusic(pNum)
      -- Récupère la musique dans la liste et la démarre
        local music = myMM.lstMusics[pNum]
        if music.source:getVolume() == 0 and myMM.currentMusic ~= pNum then
            if myMM.currentMusic ~= 0 then 
                myMM.lstMusics[myMM.currentMusic].source:stop()
                myMM.lstMusics[myMM.currentMusic].source:setVolume(0)
            end
            music.source:play()
        end
        -- Prend note de la nouvelle musique
        -- Pour que la méthod update prenne le relai
        myMM.currentMusic = pNum
    end
    
    return myMM
end

return musicManager