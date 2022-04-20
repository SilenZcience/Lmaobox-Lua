--[[
    Misc Tools for Lmaobox
    Author: LNX (github.com/lnx00)
]]

local menuLoaded, MenuLib = pcall(require, "Menu")
assert(menuLoaded, "MenuLib not found, please install it!")
assert(MenuLib.Version >= 1.35, "MenuLib version is too old, please update it!")

local ltExtendFreeze = 0

-- Menu
local menu = MenuLib.Create("Misc Tools", MenuFlags.AutoSize)
local mLegJitter = menu:AddComponent(MenuLib.Checkbox("Leg Jitter", false))
local mRageRetry = menu:AddComponent(MenuLib.Checkbox("Rage Retry", false))
local mRageHealth = menu:AddComponent(MenuLib.Slider("Min Health", 20, 100, 30))
local mNCName = menu:AddComponent(MenuLib.Textbox("Custom name..."))
menu:AddComponent(MenuLib.Button("Set name", function()
    client.Command('name "' .. mNCName:GetValue() .. '"', true)
end, ItemFlags.FullWidth))
local mExtendFreeze = menu:AddComponent(MenuLib.Checkbox("Infinite Respawn", false))
menu:AddComponent(MenuLib.Button("Enable Weapon Sway", function()
    client.SetConVar("cl_wpn_sway_interp", 0.05)
end, ItemFlags.FullWidth))
local mFLMelee = menu:AddComponent(MenuLib.Checkbox("Latency on Melee", false))
local mAutoMelee = menu:AddComponent(MenuLib.Checkbox("Auto Melee Switch", false))
local mMeleeDist = menu:AddComponent(MenuLib.Slider("Melee Distance", 100, 400, 200))

local function CreateMove(pCmd)
    local pLocal = entities.GetLocalPlayer()
    if not pLocal then return end

    local vVelocity = pLocal:EstimateAbsVelocity()

    -- Leg Jitter
    if mLegJitter:GetValue() == true then
        if (pCmd.forwardmove == 0) and (pCmd.sidemove == 0) and (vVelocity:Length2D() < 10) then
            if pCmd.command_number % 2 == 0 then
                pCmd:SetForwardMove(2)
                pCmd:SetSideMove(2)
            else
                pCmd:SetForwardMove(-2)
                pCmd:SetSideMove(-2)
            end
        end
    end

    -- Rage Retry
    if mRageRetry:GetValue() == true then
        if (pLocal:IsAlive()) and (pLocal:GetHealth() > 0 and (pLocal:GetHealth()) <= mRageHealth:GetValue()) then
            client.Command("retry", true)
        end
    end

    -- Infinite Respawn
    if mExtendFreeze:GetValue() == true then
        if (pLocal:IsAlive() == false) and (globals.RealTime() > (ltExtendFreeze + 2)) then
            client.Command("extendfreeze", true)
            ltExtendFreeze = globals.RealTime()
        end
    end

    --[[ Features that require access to the weapon ]]
    local pWeapon = pLocal:GetPropEntity("m_hActiveWeapon")
    if not pWeapon then return end

    -- Fake Latency on Melee
    if (mFLMelee:GetValue() == true) and (pLocal:IsAlive()) then
        local flActive = gui.GetValue("fake latency")
        if (pWeapon:IsMeleeWeapon() == true) and (flActive == 0) then
            gui.SetValue("fake latency", 1)
        elseif (pWeapon:IsMeleeWeapon() == false) and (flActive == 1) then
            gui.SetValue("fake latency", 0)
        end
    end

    -- [[ Features that need to iterate through all players ]]
    local players = entities.FindByClass("CTFPlayer")
    for k, vPlayer in pairs(players) do
        if vPlayer:IsValid() == false then goto continue end
        if vPlayer:IsAlive() == false then goto continue end
        if vPlayer:GetIndex() == pLocal:GetIndex() then goto continue end

        local distVector = vPlayer:GetAbsOrigin() - pLocal:GetAbsOrigin()
        local distance = distVector:Length()

        if vPlayer:GetTeamNumber() == pLocal:GetTeamNumber() then goto continue end
        if pLocal:IsAlive() == false then goto continue end

        -- Auto Melee Switch
        if (mAutoMelee:GetValue() == true) and (distance <= mMeleeDist:GetValue()) and (pWeapon:IsMeleeWeapon() == false) then
            print(distance)
            client.Command("slot3", true) -- We don't have access to pCmd.weaponselect :(
        end

        ::continue::
    end
end

local function Unload()
    MenuLib.RemoveMenu(menu)

    client.Command('play "ui/buttonclickrelease"', true)
end

callbacks.Unregister("CreateMove", "MT_CreateMove") 
callbacks.Register("CreateMove", "MT_CreateMove", CreateMove)

callbacks.Unregister("Unload", "MT_Unload") 
callbacks.Register("Unload", "MT_Unload", Unload)

client.Command('play "ui/buttonclick"', true)