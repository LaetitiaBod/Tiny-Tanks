local E_STATES = {}

-- initial state
E_STATES.NONE = "none"

-- change direction state
E_STATES.CHG_DIR = "change dir"
-- rotate state
E_STATES.ROTATE = "rotate"
-- move state
E_STATES.MOVE = "move"

-- chasing state
E_STATES.CHASE = "chase"
-- attacking state
E_STATES.ATTACK = "attack"
-- fleeing state
E_STATES.FLEEING = "fleeing"

-- fixing state
E_STATES.FIXING = "fixing"
-- broken state
E_STATES.BROKEN = "broken"

-- landing mines state
E_STATES.LAND_MINES = "land mines"

return E_STATES