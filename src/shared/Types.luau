--[[
    Types.luau
    Shared type definitions for the D20 idle dice game.
    Used by both server and client code for consistent type annotations.
]]

export type DiceInfo = {
    id: number,
    name: string,
    color: Color3,
    cost: number,
    multiplier: number,
    owned: boolean,
}

export type GameState = {
    coins: number,
    diceOwned: { DiceInfo },
    totalRolls: number,
}

export type RollResult = {
    rolls: { number },
    total: number,
    isCritical: boolean,
    coinsEarned: number,
}

export type ShopItem = {
    diceInfo: DiceInfo,
    canAfford: boolean,
    price: number,
}

return {
    DiceInfo = DiceInfo,
    GameState = GameState,
    RollResult = RollResult,
    ShopItem = ShopItem,
}
