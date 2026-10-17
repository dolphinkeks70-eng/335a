local frame = CreateFrame("Frame")

local MIN_LEVEL = 10
local MAX_LEVEL = 18
local REPORT_INTERVAL = 30
local ANNOUNCE_INTERVAL = 30
local MAX_CHAT_LENGTH = 255

-- Split in two: one chat message is limited to 255 characters.
local WHISPER_LINES = {
    "please leave, this is bg for 19 twinks. you can create a twink 19 lvl instantly and buy all gear for free from vendor on blackrock-realm.",
    "you're welcome to come back as proper twink and play with us. currently you only block other twinks from coming and joining the bg. ty!",
}

local nextReportAt = {}
local whispered = {}
local lastAnnounced = ""
local nextAnnounceAt = 0
local elapsed = 0

local function IsInBattleground()
    local _, instanceType = IsInInstance()
    return instanceType == "pvp"
end

local function ResetState()
    wipe(nextReportAt)
    wipe(whispered)
    lastAnnounced = ""
    nextAnnounceAt = 0
end

local function IsLowLevelMember(unit)
    if not UnitExists(unit) or not UnitIsPlayer(unit) or UnitIsUnit(unit, "player") then
        return false
    end
    local level = UnitLevel(unit)
    return level >= MIN_LEVEL and level <= MAX_LEVEL
end

local function WhisperTarget(unit)
    local name, realm = UnitName(unit)
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

local function Announce(entries)
    local prefix = "help report low level players: "
    local line = prefix
    for i = 1, #entries do
        local entry = entries[i]
        local separator = (line == prefix) and "" or ", "
        if #line + #separator + #entry > MAX_CHAT_LENGTH then
            SendChatMessage(line, "BATTLEGROUND")
            line = prefix .. entry
        else
            line = line .. separator .. entry
        end
    end
    SendChatMessage(line, "BATTLEGROUND")
end

local function Tick()
    if not IsInBattleground() then
        ResetState()
        return
    end

    local now = GetTime()
    local entries = {}
    local raidCount = GetNumRaidMembers()
    local prefix = raidCount > 0 and "raid" or "party"
    local count = raidCount > 0 and raidCount or GetNumPartyMembers()

    for i = 1, count do
        local unit = prefix .. i
        if IsLowLevelMember(unit) then
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            entries[#entries + 1] = name .. "(" .. UnitLevel(unit) .. ")"

            if not UnitAffectingCombat(unit) and now >= (nextReportAt[guid] or 0) then
                ReportPlayerIsPVPAFK(unit)
                nextReportAt[guid] = now + REPORT_INTERVAL
            end

            if not whispered[guid] then
                whispered[guid] = true
                local target = WhisperTarget(unit)
                for j = 1, #WHISPER_LINES do
                    SendChatMessage(WHISPER_LINES[j], "WHISPER", nil, target)
                end
            end
        end
    end

    table.sort(entries)
    local list = table.concat(entries, ", ")
    if #entries > 0 and list ~= lastAnnounced and now >= nextAnnounceAt then
        Announce(entries)
        lastAnnounced = list
        nextAnnounceAt = now + ANNOUNCE_INTERVAL
    end
end

frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        Tick()
    end
end)
