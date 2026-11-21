local addonName = ...
local enabled = true

-- name and nameplate settings to override while the UI is hidden.
local hiddenValues = {
    { "targetHighlightAlwaysShown", "0" },
    { "Outline", "0" },
    { "UnitNameNPC", "0" },
    { "UnitNameHostleNPC", "0" },
    { "UnitNameInteractiveNPC", "0" },
    { "UnitNameFriendlySpecialNPCName", "0" },
    { "UnitNameNonCombatCreatureName", "0" },
    { "UnitNameForceHideMinus", "1" },
    { "UnitNameFriendlyPetName", "0" },
    { "UnitNameEnemyPetName", "0" },
    { "UnitNameFriendlyMinionName", "0" },
    { "UnitNameEnemyMinionName", "0" },
    { "UnitNameFriendlyGuardianName", "0" },
    { "UnitNameEnemyGuardianName", "0" },
    { "UnitNameFriendlyTotemName", "0" },
    { "UnitNameEnemyTotemName", "0" },
    { "nameplateShowFriendlyNpcs", "0" },
}

-- keep player settings for names in SHOW mode
local playerSettings = {
    "UnitNameOwn",
    "UnitSurnameOwn",
    "UnitNameFocused",
    "UnitNameFriendlyPlayerName",
    "UnitNameEnemyPlayerName",
    "UnitNameGuildTitle",
    "UnitNamePlayerGuild",
    "UnitNamePlayerPVPTitle",
    "nameplateShowFriendlyPlayers",
    "nameplateShowEnemies",
}

-- for remembering which overrides took effect so only they are cleared
local activeOverrides = {}

-- restore previous overriden settings
local function ClearOverride(name)
    C_CVar.RemoveTempCVar(name)
    activeOverrides[name] = nil
end

local function ClearOverrides()
    for name in pairs(activeOverrides) do
        ClearOverride(name)
    end
end

-- tracks only temporary changes the client accepted
local function ApplyOverride(name, value)
    local currentValue = C_CVar.GetCVar(name)
    if currentValue and currentValue ~= value then
        C_CVar.SetTempCVar(name, value)
        if C_CVar.GetCVar(name) == value then
            activeOverrides[name] = true
        end
    end
end

-- hide names or restore them when the UI is hidden/shown
local function UpdateNames()
    if not enabled or UIParent:IsShown() then
        ClearOverrides()
        return
    end

    for _, setting in ipairs(hiddenValues) do
        ApplyOverride(setting[1], setting[2])
    end

    for _, name in ipairs(playerSettings) do
        if not HideNamesShowPlayerNames then
            ApplyOverride(name, "0")
        elseif activeOverrides[name] then
            ClearOverride(name)
        end
    end
end

-- button tooltips for left and right click
local displayedTooltip
local function ShowMinimapTooltip(tooltip)
    displayedTooltip = tooltip
    local on, off = "|cff33ff66ON|r", "|cffa0a0a0OFF|r"
    local addonState = enabled and on or off
    local playerNameState = HideNamesShowPlayerNames and "|cffe7ff4dSHOW|r" or "|cff46cfffHIDE|r"
    tooltip:SetText(C_AddOns.GetAddOnMetadata(addonName, "Title"), NORMAL_FONT_COLOR:GetRGB())
    tooltip:AddLine("Left-click to toggle addon ( " .. addonState .. " )", 1, 1, 1)
    tooltip:AddLine("Right click to hide/show player names ( " .. playerNameState .. " )", 1, 1, 1)
end

-- register minimap button with lib (used to be custom but that was breaking with leatrix and such)
local function CreateMinimapButton()
    local brokerLib = LibStub and LibStub("LibDataBroker-1.1", true)
    local iconLib = LibStub and LibStub("LibDBIcon-1.0", true)
    if not brokerLib or not iconLib then return end
    if not HideNamesMinimapDB then
        HideNamesMinimapDB = { minimapPos = math.deg(HideNamesMinimapAngle or math.rad(225)) }
    end
    HideNamesMinimapAngle = nil

    local launcher = brokerLib:NewDataObject(addonName, {
        type = "launcher",
        label = C_AddOns.GetAddOnMetadata(addonName, "Title"),
        icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture"),
        OnTooltipShow = ShowMinimapTooltip,
        OnLeave = function()
            displayedTooltip = nil
        end,
        OnClick = function(self, mouseButton)
            if mouseButton == "RightButton" then
                HideNamesShowPlayerNames = not HideNamesShowPlayerNames
            elseif mouseButton == "LeftButton" then
                enabled = not enabled
            end
            UpdateNames()

            if displayedTooltip and displayedTooltip:IsOwned(self) then
                ShowMinimapTooltip(displayedTooltip)
                displayedTooltip:Show()
            end
        end,
    })
    iconLib:Register(addonName, launcher, HideNamesMinimapDB)
end

-- hook into UI on login and clear addon's overrides on logout
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then
        ClearOverrides()
    elseif event == "PLAYER_LOGIN" then
        UIParent:HookScript("OnHide", UpdateNames)
        UIParent:HookScript("OnShow", UpdateNames)
        CreateMinimapButton()
        UpdateNames()
    end
end)
