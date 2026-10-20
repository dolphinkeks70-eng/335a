local frame = CreateFrame("Frame")

local MIN_LEVEL = 10
local MAX_LEVEL = 18
local REPORT_INTERVAL = 30

local nextReportAt = {}
local elapsed = 0

local function IsInBattleground()
    local _, instanceType = IsInInstance()
    return instanceType == "pvp"
end

local function ResetState()
    wipe(nextReportAt)
end

local function IsLowLevelMember(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return false
    end
    local level = UnitLevel(unit)
    return level >= MIN_LEVEL and level <= MAX_LEVEL
end

local function Tick()
    if not IsInBattleground() then
        ResetState()
        return
    end

    local now = GetTime()
    local raidCount = GetNumRaidMembers()
    local prefix = raidCount > 0 and "raid" or "party"
    local count = raidCount > 0 and raidCount or GetNumPartyMembers()

    for i = 1, count do
        local unit = prefix .. i
        if IsLowLevelMember(unit) then
            local guid = UnitGUID(unit)

            if not UnitAffectingCombat(unit) and now >= (nextReportAt[guid] or 0) then
                ReportPlayerIsPVPAFK(unit)
                nextReportAt[guid] = now + REPORT_INTERVAL
            end
        end
    end
end

frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        Tick()
    end
end)
