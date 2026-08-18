--!strict
-- D20 Farm - Type Definitions

export type RollResult = {
	value: number, -- 1-20
	coinsEarned: number, -- same as value for v0.1
	timestamp: number -- os.clock()
}

export type DiceState = {
	currentFace: number, -- 1-20
	isRolling: boolean,
	lastRoll: RollResult?
}

export type CoinState = {
	total: number,
	lastEarned: number
}

return nil
