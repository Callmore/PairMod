--Pairmod
--by Callmore

--## Constants ##--
local STARTTIME = 6*TICRATE + (3*TICRATE/4)

local SYNCBOOST_MAXDIST = 448*FRACUNIT
local SYNCBOOST_MAXBOOST = 3*TICRATE

local SPINOUT_TIMER = (3*TICRATE/2)+2

local RECOVER_RANGE = 192*FRACUNIT

local TEAMCOLOURS = {
    SKINCOLOR_ORANGE,
    SKINCOLOR_BLUE,
    SKINCOLOR_EMERALD,
    SKINCOLOR_PURPLE,
    SKINCOLOR_YELLOW,
    SKINCOLOR_CYAN,
    SKINCOLOR_RED,
    SKINCOLOR_GREY,
}

local RESETCOLOURSSTR = {"color", "color2", "color3", "color4"}

-- Rawset constants
rawset(_G, "PAIRMOD_INFO_MESSAGE_FADE_TIME", TICRATE * 2)
rawset(_G, "PAIRMOD_INFO_MESSAGE_START_FADE", TICRATE / 2)

--## Object definition ##--
freeslot(
    "SPR_PAIR", "SPR_SYNC", "SPR_PARL",

    "S_PAIR_POINTER", "MT_PAIR_POINTER",
    "S_PAIR_MARKER", "S_PAIR_MARKER_TRANS", "MT_PAIR_MARKER",
    "S_SYNC_MAXDIST", "MT_SYNC_MAXDIST",
    "MT_SYNCBOOST_EFFECT",
    "S_SNEAKERGATE", "MT_SNEAKERGATE",
    "S_INVINCGATE", "MT_INVINCGATE",
    "S_GROWGATE", "MT_GROWGATE",
    "S_HYUDOROGATE", "MT_HYUDOROGATE",
    "S_SPBNUMBER_1", "S_SPBNUMBER_2", "S_SPBNUMBER_3", "S_SPBNUMBER_4", "S_SPBNUMBER_5", "MT_PAIRMOD_SPBNUMBERS",

    "S_PAIRMOD_THUNDERSPARK", "MT_PAIRMOD_THUNDERSPARK"
)


states[S_PAIR_MARKER] = {SPR_PAIR, FF_FULLBRIGHT|A, -1, nil, 0, 0, S_PAIR_MARKER}
states[S_PAIR_MARKER_TRANS] = {SPR_PAIR, FF_FULLBRIGHT|TR_TRANS50|A, -1, nil, 0, 0, S_PAIR_MARKER}
mobjinfo[MT_PAIR_MARKER] = {
    spawnstate = S_PAIR_MARKER,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_PAIR_POINTER] = {SPR_PLAY, FF_FULLBRIGHT|A, -1, nil, 0, 0, S_PAIR_POINTER}
mobjinfo[MT_PAIR_POINTER] = {
    spawnstate = S_PAIR_POINTER,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_SYNC_MAXDIST] = {SPR_PARL, FF_FULLBRIGHT|FF_PAPERSPRITE|A, -1, nil, 0, 0, S_SYNC_MAXDIST}
mobjinfo[MT_SYNC_MAXDIST] = {
    spawnstate = S_SYNC_MAXDIST,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

mobjinfo[MT_SYNCBOOST_EFFECT] = {
    spawnstate = S_KARMAFIREWORK1,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_SNEAKERGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_SNEAKER, -1, nil, 0, 0, S_SNEAKERGATE}
mobjinfo[MT_SNEAKERGATE] = {
    spawnstate = S_SNEAKERGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_INVINCGATE] = {SPR_ITMI, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|FF_ANIMATE|A, -1, nil, 3, 6, S_INVINCGATE}
mobjinfo[MT_INVINCGATE] = {
    spawnstate = S_INVINCGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_GROWGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_GROW, -1, nil, 0, 0, S_GROWGATE}
mobjinfo[MT_GROWGATE] = {
    spawnstate = S_GROWGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_HYUDOROGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_HYUDORO, -1, nil, 0, 0, S_HYUDOROGATE}
mobjinfo[MT_HYUDOROGATE] = {
    spawnstate = S_HYUDOROGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_SPBNUMBER_1] = {SPR_DRWN, 1|TR_TRANS30, TICRATE, nil, 0, 0, S_NULL}
states[S_SPBNUMBER_2] = {SPR_DRWN, 2|TR_TRANS30, TICRATE, nil, 0, 0, S_NULL}
states[S_SPBNUMBER_3] = {SPR_DRWN, 3|TR_TRANS30, TICRATE, nil, 0, 0, S_NULL}
states[S_SPBNUMBER_4] = {SPR_DRWN, 4|TR_TRANS30, TICRATE, nil, 0, 0, S_NULL}
states[S_SPBNUMBER_5] = {SPR_DRWN, 5|TR_TRANS30, TICRATE, nil, 0, 0, S_NULL}
mobjinfo[MT_PAIRMOD_SPBNUMBERS] = {
    spawnstate = S_SPBNUMBER_1,
    spawnhealth = 1000,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_PAIRMOD_THUNDERSPARK] = {SPR_KSPK, A|FF_ANIMATE, -1, nil, 3, 6, S_PAIRMOD_THUNDERSPARK}
mobjinfo[MT_PAIRMOD_THUNDERSPARK] = {
    spawnstate = S_PAIRMOD_THUNDERSPARK,
    spawnhealth = 1000,
    radius = 4*FRACUNIT,
    height = 8*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

--## Rawsets ##--
rawset(_G, "pairmod", {})

--## Global variables ##--
pairmod.running = false

pairmod.stopgamemode = false
pairmod.ranIntermission = true

pairmod.infoMessage = ""
pairmod.infoMessageTimer = 0

pairmod.eolScores = nil

-- Local globals
local resetcolourcvars = nil
local cv_kartelimlast = nil
local kartelimlast = nil

--## Console variables ##--
local cv_enabled = CV_RegisterVar{
    name = "pm_enabled",
    defaultvalue = "On",
    flags = CV_NETVAR,
    PossibleValue = CV_OnOff,
}

local cv_showRangeFrom = CV_RegisterVar{
    name = "pm_showsyncboostrangefrom",
    defaultvalue = "Teammate",
    flags = CV_NETVAR,
    PossibleValue = {Off = 0, Center = 1, Teammate = 2},
}

--## Functions ##--
local function resetVars(p)
    p.pairmod = {
        pair = nil,
        pairpointer = nil,
        lastbtn = nil,
        lastitemtype = nil,
        lastitemamount = nil,
        lastsneakertimer = nil,
        lastrocketsneakertimer = nil,
        syncboost = 0,
        syncboostindicator = {},
        syncboostradiusindicator = nil,
        gatechain = 0,
        gatechainreset = 0,
        teamid = nil,
        alreadyDidExit = false,
        thundershieldInvul = 0,
    }
    p.pm_itemoddsset = false
end

local function copyLatent(p)
    local pm = p.pairmod
    pm.lastbtn = p.cmd.buttons
    pm.lastitemtype = p.kartstuff[k_itemtype]
    pm.lastitemamount = p.kartstuff[k_itemamount]
    pm.lastsneakertimer = p.kartstuff[k_sneakertimer]
    pm.lastrocketsneakertimer = p.kartstuff[k_rocketsneakertimer]
end

local function mosFix(x)
    return FixedMul(x, mapobjectscale)
end

local function isLocalPlayer(p)
    for dp in displayplayers.iterate do
        if dp == p then 
            return true
        end
    end
    return false
end

local function setInfoMessage(p, str)
    if p == displayplayers[0] then
        pairmod.infoMessage = str
        pairmod.infoMessageTimer = PAIRMOD_INFO_MESSAGE_FADE_TIME
    end
end

local function removeGrowShrink(p)
    if p.mo and p.mo.valid then
        if p.kartstuff[k_growshrinktimer] > 0 then -- Play Shrink noise
            S_StartSound(p.mo, sfx_kc59)
        elseif p.kartstuff[k_growshrinktimer] < 0 then -- Play Grow noise
            S_StartSound(p.mo, sfx_kc5a)
        end

        if p.kartstuff[k_invincibilitytimer] == 0 then
            p.mo.color = p.skincolor
        end

        p.mo.scalespeed = mapobjectscale/TICRATE
        p.mo.destscale = mapobjectscale
        if CV_FindVar("kartdebugshrink").value then
            p.mo.destscale = (6*p.mo.destscale)/8
        end
    end

    p.kartstuff[k_growshrinktimer] = 0
    p.kartstuff[k_growcancel] = -1

    P_RestoreMusic(p)
end

local function playersInGame()
    local ingame = {}
    for p in players.iterate do
        if not p.spectator then
            table.insert(ingame, p)
        end
    end
    return ingame
end

local function pickPairs()
    local pairers = playersInGame()
    local pairerstoremove = {}
    local teamid = 1

    for i, p in ipairs(pairers) do
        if p and p.valid and p.pairmod then
            local pm = p.pairmod
            if p.pairmod.pair then continue end
            if p.pm_friend and p.pm_friend.valid then
                if p.pm_friend.pairmod and not p.pm_friend.spectator then
                    local p2 = p.pm_friend

                    --search for second player
                    local p2i = nil
                    for i, ps in ipairs(pairers) do
                        if ps == p2 then
                            p2i = i
                            break
                        end
                    end
                    assert(p2i ~= nil)

                    if not p.pairmod then
                        resetVars(p1)
                    end
                    if not p2.pairmod then
                        resetVars(p2)
                    end

                    pm.pair = p.pm_friend
                    pm.syncboostword = false
                    pm.teamid = teamid
                    p2.pairmod.pair = p
                    p2.pairmod.syncboostword = true
                    p2.pairmod.teamid = teamid
                    table.insert(pairerstoremove, i)
                    table.insert(pairerstoremove, p2i)

                    p.skincolor = TEAMCOLOURS[teamid]
                    p2.skincolor = TEAMCOLOURS[teamid]

                    p.mo.color = TEAMCOLOURS[teamid]
                    p2.mo.color = TEAMCOLOURS[teamid]

                    teamid = $+1

                    S_StartSound(nil, sfx_strpst, p)
                    S_StartSound(nil, sfx_strpst, p2)

                    setInfoMessage(p, "Teammate is " .. p2.name)
                    setInfoMessage(p2, "Teammate is " .. p.name)
                end
            else
                p.pm_friend = nil
            end
        end
    end
    if #pairerstoremove then
        table.sort(pairerstoremove)
        for i = #pairerstoremove, 1, -1 do
            table.remove(pairers, pairerstoremove[i])
        end
    end

    -- while there are at least two players left in the table, make a pair
    while #pairers >= 2 do
        local p1 = table.remove(pairers, P_RandomKey(#pairers)+1)
        local p2 = table.remove(pairers, P_RandomKey(#pairers)+1)

        if not p1.pairmod then
            resetVars(p1)
        end
        if not p2.pairmod then
            resetVars(p2)
        end

        p1.pairmod.pair = p2
        p1.pairmod.syncboostword = false
        p1.pairmod.teamid = teamid
        p2.pairmod.pair = p1
        p2.pairmod.syncboostword = true
        p1.pairmod.teamid = teamid

        p1.skincolor = TEAMCOLOURS[teamid]
        p2.skincolor = TEAMCOLOURS[teamid]

        p1.mo.color = TEAMCOLOURS[teamid]
        p2.mo.color = TEAMCOLOURS[teamid]
        teamid = $+1

        S_StartSound(nil, sfx_strpst, p1)
        S_StartSound(nil, sfx_strpst, p2)

        setInfoMessage(p1, "Teammate is " .. p2.name)
        setInfoMessage(p2, "Teammate is " .. p1.name)
    end
end

local function allExiting()
    local valid_exit = false
    for p in players.iterate do
        if p.spectator then continue end
        if p.exiting 
        or (p.pflags & PF_TIMEOVER)
        or p.lives == 0 then
            valid_exit = true
            continue
        end
        return false
    end
    if valid_exit then
        return true
    else
        return false
    end
end

local function cleanUpObjects()
    for p in players.iterate do
        if p.pairmod then
            if p.pairmod.pairpointer and p.pairmod.pairpointer.valid then
                P_RemoveMobj(p.pairmod.pairpointer)
                p.pairmod.pairpointer = nil
            end
            if p.pairmod.syncboostradiusindicator and p.pairmod.syncboostradiusindicator.valid then
                P_RemoveMobj(p.pairmod.syncboostradiusindicator)
                p.pairmod.syncboostradiusindicator = nil
            end
        end
    end
end

local function isInSyncboostRange(p, other)
    return R_PointToDist2(p.mo.x, p.mo.y, p.pairmod.pair.mo.x, p.pairmod.pair.mo.y) <= mosFix(SYNCBOOST_MAXDIST)
end

-- Object spawning functions

local function spawnGate(p, gatetype)
    if isInSyncboostRange(p, p.pairmod.pair) then
        pairmodGateFunctions[gatetype](p.pairmod.pair.mo, false)
    else
        local gate = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, gatetype)
        gate.fuse = TICRATE*15
        gate.targetplayer = p.pairmod.pair
        gate.scale = FixedMul($, FRACUNIT*3)
        gate.angle = p.mo.angle + ANGLE_90
        gate.flags2 = $|MF2_DONTDRAW
        return gate
    end
end

-- doThunderShield is not exposed to lua so ima have to expose it myself...
-- https://git.do.srb2.org/KartKrew/Kart-Public/-/blob/master/src/k_kart.c#L3415
local THUNDERRADIUS = 320
local function doTeamThunderShield(otherp)
    local p = otherp.pairmod.pair

	S_StartSound(p.mo, sfx_zio3)
	P_NukeEnemies(p.mo, p.mo, RING_DIST/4)

	-- spawn vertical bolt
	local mobolt1 = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
	mobolt1.target = p.mo
	mobolt1.state = S_LZIO11
	mobolt1.color = SKINCOLOR_TEAL
	mobolt1.scale = p.mo.scale*3 + (p.mo.scale/2)

	local mobolt2 = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
	mobolt2.target = p.mo
	mobolt2.state = S_LZIO21
	mobolt2.color = SKINCOLOR_CYAN
	mobolt2.scale = p.mo.scale*3 + (p.mo.scale/2)

	-- spawn horizontal bolts
	for i = 0, 6 do
		local mo = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
		mo.angle = P_RandomRange(0, 359)*ANG1
		mo.fuse = P_RandomRange(20, 50)
		mo.target = p.mo
		mo.state = S_KLIT1
    end

	-- spawn the radius thing:
	local an = ANGLE_22h
	for i = 0, 14 do
		local sx = p.mo.x + FixedMul(p.mo.scale * THUNDERRADIUS, cos(an * i))
		local sy = p.mo.y + FixedMul(p.mo.scale * THUNDERRADIUS, sin(an * i))
		local mo = P_SpawnMobj(sx, sy, p.mo.z, MT_THOK)
		mo.angle = an * i
		mo.extravalue1 = THUNDERRADIUS -- Used to know whether we should teleport by radius or something.
		mo.scale = p.mo.scale * 3
		mo.target = p.mo
		mo.state = S_KSPARK1
    end

end

local function spawnMaxRangeIndicator(p, i)
    local mo = P_SpawnMobj(p.pairmod.pair.mo.x, p.pairmod.pair.mo.y, p.pairmod.pair.mo.z, MT_SYNCBOOST_EFFECT)
    mo.color = p.pairmod.pair.skincolor
    mo.pairmod_syncboostId = i
    mo.target = p.mo
    return mo
end

local function spawnPairMarker(dpIndex)
    local mo = P_SpawnMobj(0, 0, 0, MT_PAIR_MARKER)
    mo.pm_indexwatch = dpIndex
    mo.eflags = $ | (MFE_DRAWONLYFORP1 << (dpIndex - 1))
    return mo
end

local function spawnPairPointer(dpIndex)
    local mo = P_SpawnMobj(0, 0, 0, MT_PAIR_POINTER)
    mo.scale = $/2
    mo.pm_indexwatch = dpIndex
    mo.eflags = $ | (MFE_DRAWONLYFORP1 << (dpIndex - 1))
    return mo
end

local function spawnSyncboostMaxDistanceIndicatior(dpIndex, side)
    local mo = P_SpawnMobj(0, 0, 0, MT_SYNC_MAXDIST)
    mo.pm_indexwatch = dpIndex
    mo.pm_side = side
    mo.scale = $/2
    mo.eflags = $ | (MFE_DRAWONLYFORP1 << (dpIndex - 1))
    return mo
end

local function trySetFriend(p, fr)
    if p == fr then
        CONS_Printf(p, "You cannot team with yourself!")
    elseif fr.pm_tryfriend == p then
        -- players have become friends
        p.pm_friend = fr
        p.pm_tryfriend = nil
        p.pm_askedfriend = nil
        fr.pm_friend = p
        fr.pm_tryfriend = nil
        fr.pm_askedfriend = nil
        chatprintf(p, string.format("\x84You are now teammates with %s.", fr.name), true)
        chatprintf(fr, string.format("\x84You are now teammates with %s.", p.name), true)
    elseif p.pm_friend then
        CONS_Printf(p, 'You already have a teammate! Enter "pm_resetteam" into the console to reset your teammate before attempting to team again.')
    elseif fr.pm_friend then
        -- player already has a friend
        CONS_Printf(p, "That player already has a teammate.")
    else
        p.pm_tryfriend = fr
        fr.pm_askedfriend = p
        CONS_Printf(p, string.format('A team request has been sent to %s.', fr.name))
        chatprintf(fr, string.format('\x83%s is requesting to team with you. Enter "pm_acceptteam" into console to accept.', p.name), true)
    end
end

local function clearFriend(p)
    if p and p.valid and p.pm_friend then
        if p.pm_friend.valid and p.pm_friend.pairmod then
            p.pm_friend.pm_friend = nil
            p.pm_friend.pm_tryfriend = nil
            p.pm_friend.pm_askedfriend = nil
        end
        p.pm_friend = nil
        p.pm_tryfriend = nil
        p.pm_askedfriend = nil
        CONS_Printf(p, "Reset teammate.")
    end
end

local function resetColours()
    if not resetcolourcvars then
        resetcolourcvars = {}
        for i, k in ipairs(RESETCOLOURSSTR) do
            resetcolourcvars[i] = CV_FindVar(k)
        end
    end

    for i, k in ipairs(RESETCOLOURSSTR) do
        COM_BufInsertText(consoleplayer, string.format('%s %d', k, resetcolourcvars[i].value))
    end
end

local function doGateChain(p)
    if p and p.valid and p.pairmod then
        p.pairmod.gatechain = $+1
        p.pairmod.gatechainreset = TICRATE*5

        local snd = sfx_hoop1 + min((p.pairmod.gatechain-1)/3, 2)
        if p.mo and p.mo.valid then
            S_StartSound(p.mo, snd)
        end
        if p.pairmod.pair and p.pairmod.pair.valid then
            S_StartSoundAtVolume(nil, snd, 127, p.pairmod.pair)
        end
    end
end

local function scoreSortFunction(a, b)
    return a.time < b.time
end

local function processScores(scores)
    for i, k in ipairs(scores) do
        k.playernames = {}
        for i2, k2 in ipairs(k.players) do
            k.playernames[i2] = k2.name
        end
    end
    return scores
end

--## Commands ## --
local function com_setFriend(p, ...)
    local instr = table.concat({...}, " ")
    if instr == "" then
        CONS_Printf(p, "Enter the name of whoever you want to team with (Either in-game name or node number).")
        CONS_Printf(p, "The person you specify will be sent a request and can accept by teaming you back.")
        return
    end
    if tonumber(instr) ~= nil then
        -- they entered a number maybe? look for a node that is that number
        local num = tonumber(instr)
        if num >= 0 and num < #players
        and players[num] then
            trySetFriend(p, players[num])
            return
        end
    end

    -- search the player list until we find someone with the same name
    local foundplayers = {}
    for i = 0, #players-1 do
        if players[i] and players[i].valid then
            if players[i].name:lower() == instr:lower() then
                trySetFriend(p, players[i])
                return
            elseif players[i].name:lower():find(instr:lower(), 0, true) then
                table.insert(foundplayers, players[i])
            end
        end
    end

    -- either set teammate or list all posible teammates
    if #foundplayers == 1 then
        trySetFriend(p, foundplayers[1])
    elseif #foundplayers > 0 then
        CONS_Printf(p, "Found muliple players. Did you mean:")
        for i, pl in ipairs(foundplayers) do
            CONS_Printf(p, string.format('- %s (Node %d)', pl.name, #pl))
        end
    else
        CONS_Printf(p, string.format('Could not find any players matching the term "%s".', instr))
    end
end
COM_AddCommand("pm_team", com_setFriend)

local function com_resetFriend(p)
    clearFriend(p)
end
COM_AddCommand("pm_resetteam", com_resetFriend)

local function com_acceptFriend(p)
    if p and p.valid and p.pm_askedfriend and p.pm_askedfriend.valid then
        trySetFriend(p, p.pm_askedfriend)
    else
        CONS_Printf(p, "You don't have any team requests to accept.")
    end
end
COM_AddCommand("pm_acceptteam", com_acceptFriend)

--## Hook functions ##--

local function levelInit()
    -- Check if gamemode should be running
    if cv_enabled.value then
        pairmod.running = true
        for i = 1, 4 do
            spawnPairMarker(i)

            spawnPairPointer(i)

            for i2 = 1, 2 do
                spawnSyncboostMaxDistanceIndicatior(i, i2)
            end
        end
    else
        pairmod.running = false
    end

    for p in players.iterate do
        resetVars(p)
    end

    -- do start of level stuff
    pairmod.stopgamemode = false
    if consoleplayer == server and pairmod.ranIntermission then
        if not cv_kartelimlast then
            cv_kartelimlast = CV_FindVar("karteliminatelast")
        end
        kartelimlast = cv_kartelimlast.string
        COM_BufInsertText(server, "karteliminatelast off")
    end
    pairmod.ranIntermission = false
end

local function runInfoMessageTimer()
    --## Info message timer ##--
    if pairmod.infoMessageTimer then
        pairmod.infoMessageTimer = $-1
        if not pairmod.infoMessageTimer then
            pairmod.infoMessage = ""
        end
    end
end

local function doGamemodeExit()
    pairmod.stopgamemode = true
    cleanUpObjects()
    local pingame = playersInGame()
    local scores = {}
    while #pingame do
        local p = pingame[1]
        local scoreadd = {players={}, time=0}
        local dontadd = false
        if p.pairmod and p.pairmod.pair and p.pairmod.pair.valid then
            for i = 2, #pingame do
                if pingame[i] == p.pairmod.pair then
                    table.remove(pingame, i)
                    break
                end
            end
            if (p.pflags & PF_TIMEOVER) or (p.pairmod.pair.pflags & PF_TIMEOVER) then
                p.realtime = -1
                p.pairmod.pair.realtime = -1

                dontadd = true
            else
                local totaltime = p.realtime + p.pairmod.pair.realtime
                p.realtime = totaltime
                p.pairmod.pair.realtime = totaltime

                scoreadd.time = totaltime
                scoreadd.players[1] = p
                scoreadd.players[2] = p.pairmod.pair
            end
        else
            p.realtime = $*2

            scoreadd.time = p.realtime
            scoreadd.players[1] = p
        end
        table.remove(pingame, 1)
        if not dontadd then
            table.insert(scores, scoreadd)
        end
    end
    table.sort(scores, scoreSortFunction)
    local eolScores = processScores(scores)

    -- assign placements to players based on their pos
    for i, k in ipairs(eolScores) do
        for i2, k2 in ipairs(k.players) do
            k2.kartstuff[k_position] = i
        end
    end
end

local function checkAndDoPlayerFinish(p)
    local pm = p.pairmod

    if not p.exiting and p.pflags & PF_TIMEOVER == 0 then return false end
    if pm.alreadyDidExit then return true end
    
    pm.alreadyDidExit = true
    return true
end

local function checkForValidTeammate(p)
    if p.pairmod.pair and p.pairmod.pair.valid and p.pairmod.pair.pairmod then
        if p.pairmod.pair.pairmod.pair ~= p then
            p.pairmod.pair = nil -- Remove pair
        end
    end
end

local function doShrinkMod(p)
    local pm = p.pairmod
    
    -- Shrink
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_SHRINK
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer] then
        if pm.pair and pm.pair.valid and pm.pair.kartstuff[k_growshrinktimer] < 0 then
            pm.pair.kartstuff[k_growshrinktimer] = $ / 4
        end
        for ip in players.iterate do
            if ip and ip.valid and ip.mo and ip.mo.valid and ip ~= p and ip ~= pm.pair and ip.kartstuff[k_position] < p.kartstuff[k_position] then
                -- Someone is going to complain about this but it's to make shrink less bad...
                K_SpinPlayer(ip, p.mo, 1)
            end
        end
    end
end

local function doGateSpawning(p)
    local pm = p.pairmod

    --sneaker
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_SNEAKER
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer]
    and p.kartstuff[k_sneakertimer] >= (TICRATE + (TICRATE/3))-1 then
        spawnGate(p, MT_SNEAKERGATE)
    end

    --rocket sneaker
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and (pm.lastrocketsneakertimer >= p.kartstuff[k_rocketsneakertimer]+(2*TICRATE)
    or (pm.lastrocketsneakertimer and not p.kartstuff[k_rocketsneakertimer]))
    and p.kartstuff[k_sneakertimer] >= (TICRATE + (TICRATE/3))-1 then
        spawnGate(p, MT_SNEAKERGATE)
    end

    --invince
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_INVINCIBILITY
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer]
    and p.kartstuff[k_invincibilitytimer] >= (10*TICRATE)-1 then
        spawnGate(p, MT_INVINCGATE)
    end

    --grow
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_GROW
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer]
    and p.kartstuff[k_growshrinktimer] >= (12*TICRATE)-1 then
        spawnGate(p, MT_GROWGATE)
    end

    --hyudoro
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_HYUDORO
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer]
    and p.kartstuff[k_hyudorotimer] >= (7*TICRATE)-1 then
        spawnGate(p, MT_HYUDOROGATE)
    end
end

local function doThunderShieldCheck(p)
    local pm = p.pairmod

    -- Thunder shield
    if p.cmd.buttons & BT_ATTACK and not (pm.lastbtn & BT_ATTACK)
    and pm.lastitemtype == KITEM_THUNDERSHIELD
    and pm.lastitemamount == p.kartstuff[k_itemamount] + 1
    and not p.kartstuff[k_stolentimer] then
        p.pairmod.thundershieldInvul = 1
        p.pairmod.pair.pairmod.thundershieldInvul = 1
        doTeamThunderShield(p)
    end

    if p.kartstuff[k_itemtype] == KITEM_THUNDERSHIELD and p.kartstuff[k_itemamount] > 0 then
        local pair = p.pairmod.pair
        local spark = P_SpawnMobj(pair.mo.x, pair.mo.y, pair.mo.z, MT_SUPERSPARK)

        local ang = FixedAngle(P_RandomRange(0, 359) * FRACUNIT)

        spark.scale = $ / 2
        spark.momx = cos(ang) * 4
        spark.momy = sin(ang) * 4
        spark.momz = 3 * P_RandomFixed()
    end

    p.pairmod.thundershieldInvul = max($ - 1, 0)
end

local function doGateChainTimer(p)
    local pm = p.pairmod

    if pm.gatechainreset then
        pm.gatechainreset = $-1
        if not pm.gatechainreset then
            pm.gatechain = 0
        end
    end
end

local function doSyncboost(p)
    local pm = p.pairmod

    if leveltime > STARTTIME + (TICRATE * 5) then
        if isInSyncboostRange(p, pm.pair) then
            local lastsync = pm.syncboost
            pm.syncboost = min($+1, SYNCBOOST_MAXBOOST)

            if lastsync == SYNCBOOST_MAXBOOST-1 and pm.syncboost == SYNCBOOST_MAXBOOST then
                setInfoMessage(p, "Max syncboost!")
                S_StartSound(p.mo, sfx_s23c)
            end

            for i = 1, pm.syncboost / TICRATE do
                if not (pm.syncboostindicator[i] and pm.syncboostindicator[i].valid) then
                    pm.syncboostindicator[i] = spawnMaxRangeIndicator(p, i)
                end
            end
        elseif pm.syncboost then
            pm.syncboost = max($-1, 0)
            if not pm.syncboost then
                p.mo.colorized = false
            end
        end

        p.kartstuff[k_speedboost] = max($, FixedMul(FRACUNIT/7, FixedDiv(pm.syncboost, SYNCBOOST_MAXBOOST)))
        p.kartstuff[k_accelboost] = max($, FixedMul(FRACUNIT/2, FixedDiv(pm.syncboost, SYNCBOOST_MAXBOOST)))

        if pm.syncboost then
            p.mo.colorized = true
            if (pm.syncboost < (SYNCBOOST_MAXBOOST / 2) and not (pm.syncboost % 16))
            or (pm.syncboost > (SYNCBOOST_MAXBOOST / 2) and pm.syncboost < SYNCBOOST_MAXBOOST and not (pm.syncboost % 8))
            or (pm.syncboost == SYNCBOOST_MAXBOOST and not (leveltime % 4)) then
                P_SpawnGhostMobj(p.mo)
            end
        end
    end
end

local function doRecovery(p)
    local pm = p.pairmod

    if (p.kartstuff[k_spinouttimer] or p.kartstuff[k_wipeoutslow]) and p.kartstuff[k_spinouttimer] < SPINOUT_TIMER / 2
    and R_PointToDist2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y) < RECOVER_RANGE then
        p.kartstuff[k_spinouttimer] = 0
        p.kartstuff[k_wipeoutslow] = 0
        p.powers[pw_flashing] = K_GetKartFlashing(p) / 2
        K_DoSneaker(p)
        setInfoMessage(p, "Recovery!")
        setInfoMessage(pm.pair, "Recovered teammate!")
    end
end

local function forceTeamColour(p)
    local pm = p.pairmod

    if pm.teamid and TEAMCOLOURS[pm.teamid] then
        p.skincolor = TEAMCOLOURS[pm.teamid]
    end
end

local function setItemOddsForPlayer(p)
    for item, odds in pairs(PAIRMOD_CUSTOM_ITEM_ODDS) do
        xItemLib.func.setPlayerOddsForItem(item, p, odds)
    end
    p.pm_itemoddsset = true
end

local function removeItemOdds()
    for p in players.iterate do
        -- p should always be valid here if it's not then thats mega dumb...
        if p.pm_itemoddsset then
            xItemLib.func.resetItemOdds(0, p)
            p.pm_itemoddsset = false
        end
    end
end

local function playerThinker(p)
    if not p.pairmod then
        resetVars(p)
    end

    local pm = p.pairmod

    if p.spectator then
        return
    end

    if not p.pm_itemoddsset then
        setItemOddsForPlayer(p)
    end

    if checkAndDoPlayerFinish(p) then return end

    checkForValidTeammate(p)

    doShrinkMod(p)

    -- no teammate? stop here
    if not (pm.pair
    and pm.pair.valid
    and not pm.pair.spectator) then return end

    doGateSpawning(p)

    doThunderShieldCheck(p)

    doGateChainTimer(p)

    doSyncboost(p)

    doRecovery(p)

    forceTeamColour(p)
end

-- Global
local function think()
    if leveltime < 1 then return end
    if leveltime == 1 then
        levelInit()
    end

    runInfoMessageTimer()

    -- KEEP THIS AFTER THE LEVELTIME CHECK OTHERWISE IT WILL BREAK!!!!!!!!!!!!!!
    if pairmod.stopgamemode then
        return
    end

    if not pairmod.running then
        removeItemOdds()
        return
    end

    --## Pick teams ##--
    if leveltime == STARTTIME - TICRATE*4 then
        pickPairs()
    end

    --## End gamemode, tally scores ##--
    if allExiting() then
        doGamemodeExit()
        return
    end

    --## Main loop ##--
    for p in players.iterate do
        playerThinker(p)
        copyLatent(p)
    end
end
addHook("ThinkFrame", think)

local function intThink()
    if pairmod.ranIntermission then return end
    pairmod.ranIntermission = true
    if not pairmod.running then return end
    resetColours()
    if kartelimlast ~= nil then
        COM_BufInsertText(server, string.format('karteliminatelast "%s"', kartelimlast))
    end
end
addHook("IntermissionThinker", intThink)

local function onRespawn(pmo)
    if pmo and pmo.valid and pmo.player and pmo.player.valid then
        setItemOddsForPlayer(pmo.player)
    end
end
addHook("MobjSpawn", onRespawn, MT_PLAYER)

-- Object thinkers

local function pairIndicatorThink(mo)
    if pairmod.stopgamemode then
        P_RemoveMobj(mo)
        return
    end

    local dp = displayplayers[mo.pm_indexwatch - 1]
    if dp and dp.valid
    and dp.mo and dp.mo.valid
    and dp.pairmod
    and dp.pairmod.pair and dp.pairmod.pair.valid
    and dp.pairmod.pair.mo and dp.pairmod.pair.mo.valid then
        -- AND NOW TELEPORT!
        local pmo = dp.pairmod.pair.mo

        mo.eflags = (mo.eflags & ~MFE_VERTICALFLIP) | (pmo.eflags & MFE_VERTICALFLIP)
        mo.flags2 = (mo.flags2 & ~MF2_OBJECTFLIP) | (pmo.flags2 & MF2_OBJECTFLIP)


        P_TeleportMove(mo, pmo.x, pmo.y, pmo.z)
        mo.flags2 = $&(~MF2_DONTDRAW)
        mo.color = pmo.color

        if R_PointToDist2(dp.mo.x, dp.mo.y, pmo.x, pmo.y) < mosFix(SYNCBOOST_MAXDIST) then
            mo.state = S_PAIR_MARKER_TRANS
        else
            mo.state = S_PAIR_MARKER
        end
    else
        mo.flags2 = $|MF2_DONTDRAW
    end
end
addHook("MobjThinker", pairIndicatorThink, MT_PAIR_MARKER)

local function pairPointerThink(mo)
    if pairmod.stopgamemode then
        P_RemoveMobj(mo)
        return
    end

    local dp = displayplayers[mo.pm_indexwatch - 1]
    if dp and dp.valid
    and dp.mo and dp.mo.valid
    and dp.pairmod
    and dp.pairmod.pair and dp.pairmod.pair.valid
    and dp.pairmod.pair.mo and dp.pairmod.pair.mo.valid then
        P_TeleportMove(mo, dp.mo.x + mosFix(FixedMul(dp.pairmod.pair.mo.x - dp.mo.x, FRACUNIT/64)),
                           dp.mo.y + mosFix(FixedMul(dp.pairmod.pair.mo.y - dp.mo.y, FRACUNIT/64)),
                           dp.mo.z + mosFix(FixedMul(dp.pairmod.pair.mo.z - dp.mo.z, FRACUNIT/64)))
        mo.scale = dp.pairmod.pair.mo.scale/2
        mo.color = dp.pairmod.pair.mo.color
        mo.skin = dp.pairmod.pair.mo.skin
        mo.angle = dp.pairmod.pair.frameangle
        mo.colorized = dp.pairmod.pair.mo.colorized
        mo.frame = dp.pairmod.pair.mo.frame
        mo.flags2 = $&(~MF2_DONTDRAW)

        -- Get transparency
        mo.frame = $ & ~FF_TRANSMASK
        local dist = R_PointToDist2(dp.mo.x, dp.mo.y, dp.pairmod.pair.mo.x, dp.pairmod.pair.mo.y)
        local new_trans_level = (7 - min(max(abs(FixedInt(FixedDiv(max(mosFix(dist) - (mosFix(SYNCBOOST_MAXDIST) / 2), 0), mosFix(SYNCBOOST_MAXDIST) / 16))), 0), 7)) + 2
        mo.frame = $ | (new_trans_level << 16)
    else
        mo.flags2 = $|MF2_DONTDRAW
    end
end
addHook("MobjThinker", pairPointerThink, MT_PAIR_POINTER)

local function syncBoostRadiusIndicatorThinker(mo)
    local dp = displayplayers[mo.pm_indexwatch - 1]
    if cv_showRangeFrom.value ~= 0
    and leveltime > STARTTIME + (5 * TICRATE)
    and dp and dp.valid
    and dp.mo and dp.mo.valid
    and dp.pairmod
    and dp.pairmod.pair and dp.pairmod.pair.valid
    and dp.pairmod.pair.mo and dp.pairmod.pair.mo.valid then
        local ang = R_PointToAngle2(dp.pairmod.pair.mo.x, dp.pairmod.pair.mo.y, dp.mo.x, dp.mo.y)
        local center_x, center_y, center_z = 0, 0, 0
        if cv_showRangeFrom.value == 1 then -- Center
            center_x, center_y, center_z = (dp.mo.x + dp.pairmod.pair.mo.x)/2, (dp.mo.y + dp.pairmod.pair.mo.y)/2, (dp.mo.z + dp.pairmod.pair.mo.z)/2
        elseif cv_showRangeFrom.value == 2 then -- Teammate
            center_x = dp.pairmod.pair.mo.x + mosFix(FixedMul(cos(ang), SYNCBOOST_MAXDIST / 2))
            center_y = dp.pairmod.pair.mo.y + mosFix(FixedMul(sin(ang), SYNCBOOST_MAXDIST / 2))
            center_z = (dp.mo.z + dp.pairmod.pair.mo.z)/2
        end
        if mo.pm_side == 1 then
            ang = $ + ANGLE_180
        end
        P_TeleportMove(mo, center_x + mosFix(FixedMul(sin(ang+ANGLE_90), SYNCBOOST_MAXDIST/2)),
                           center_y + mosFix(FixedMul(cos(ang+ANGLE_90), -SYNCBOOST_MAXDIST/2)),
                           center_z)
        mo.angle = ang + ANGLE_90
        mo.color = dp.skincolor
        mo.flags2 = $&(~MF2_DONTDRAW)

        -- Get transparency
        mo.frame = $ & ~FF_TRANSMASK
        local dist = R_PointToDist2(dp.mo.x, dp.mo.y, dp.pairmod.pair.mo.x, dp.pairmod.pair.mo.y)
        local new_trans_level = min(max(abs(FixedInt(FixedDiv(mosFix(dist) - mosFix(SYNCBOOST_MAXDIST), (mosFix(SYNCBOOST_MAXDIST) * 2) / 9)) + 1), 0), 9)
        mo.frame = $ | (new_trans_level << 16)
    else
        mo.flags2 = $|MF2_DONTDRAW
    end
end
addHook("MobjThinker", syncBoostRadiusIndicatorThinker, MT_SYNC_MAXDIST)

local function syncBoostEffectThinker(mo)
    local pmo = mo.target
    if pmo and pmo.valid and pmo.player and pmo.player.valid and pmo.player.pairmod and (pmo.player.pairmod.syncboost / TICRATE) >= mo.pairmod_syncboostId then
        local trail = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
        trail.state = S_KARMAFIREWORKTRAIL
        trail.scale = mo.scale
        trail.destscale = 1
        trail.scalespeed = mo.scale/12
        trail.color = mo.color

        -- Figure out tp point
        local rot = (leveltime * ANG2) + FixedAngle(mo.pairmod_syncboostId * (360 / (pmo.player.pairmod.syncboost / TICRATE)) * FRACUNIT)
        local new_x = pmo.x + FixedMul(cos(rot) * 48, mapobjectscale)
        local new_y = pmo.y + FixedMul(sin(rot) * 48, mapobjectscale)
        local new_z = pmo.z

        -- Teleport!
        local dist_x = new_x - mo.x
        local dist_y = new_y - mo.y
        local dist_z = new_z - mo.z

        mo.momx = FixedMul(FixedMul(dist_x, mapobjectscale), 4*FRACUNIT/10)
        mo.momy = FixedMul(FixedMul(dist_y, mapobjectscale), 4*FRACUNIT/10)
        mo.momz = FixedMul(FixedMul(dist_z, mapobjectscale), 4*FRACUNIT/10)
    else
        P_RemoveMobj(mo)
    end
end
addHook("MobjThinker", syncBoostEffectThinker, MT_SYNCBOOST_EFFECT)

-- Gates

-- Gate functions
rawset(_G, "pairmodGateFunctions", {
    [MT_SNEAKERGATE] = function (pmo, gate)
        K_DoSneaker(pmo.player)
        if gate then
            doGateChain(pmo.player)
            setInfoMessage(pmo.player.pairmod.pair, "Teammate used your sneaker gate!")
        end
    end,
    [MT_INVINCGATE] = function (pmo, gate)
        if not pmo.player.kartstuff[k_invincibilitytimer] then
            local overlay = P_SpawnMobj(pmo.x, pmo.y, pmo.z, MT_INVULNFLASH)
            overlay.target = pmo
            overlay.destscale = pmo.scale
            overlay.scale = pmo.scale
        end
        pmo.player.kartstuff[k_invincibilitytimer] = 10*TICRATE
        P_RestoreMusic(pmo.player)
        if not isLocalPlayer(pmo.player) then
            S_StartSound(pmo, (CV_FindVar("kartinvinsfx").value and sfx_alarmi or sfx_kinvnc))
        end
        K_PlayPowerGloatSound(pmo)
        if gate then
            doGateChain(pmo.player)
            setInfoMessage(pmo.player.pairmod.pair, "Teammate used your invincibility gate!")
        end
    end,
    [MT_GROWGATE] = function (pmo, gate)
        if pmo.player.kartstuff[k_growshrinktimer] < 0 then -- If you're shrunk, then "grow" will just make you normal again.
            removeGrowShrink(pmo.player)
        else
            K_PlayPowerGloatSound(pmo)
            pmo.scalespeed = mapobjectscale/TICRATE
            pmo.destscale = (3*mapobjectscale)/2
            if CV_FindVar("kartdebugshrink").value then
                pmo.destscale = (6*pmo.destscale)/8
            end
            pmo.player.kartstuff[k_growshrinktimer] = 12*TICRATE
            P_RestoreMusic(pmo.player)
            if not isLocalPlayer(pmo.player) then
                S_StartSound(pmo, (CV_FindVar("kartinvinsfx").value and sfx_alarmg or sfx_kgrow))
            end
            S_StartSound(pmo, sfx_kc5a)
        end
        if gate then
            doGateChain(pmo.player)
            setInfoMessage(pmo.player.pairmod.pair, "Teammate used your grow gate!")
        end
    end,
    [MT_HYUDOROGATE] = function (pmo, gate)
        pmo.player.kartstuff[k_hyudorotimer] = 7*TICRATE
        S_StartSound(pmo, sfx_s3k92)
        if gate then
            doGateChain(pmo.player)
            setInfoMessage(pmo.player.pairmod.pair, "Teammate used your hyudoro gate!")
        end
    end,
})

local function gateThink(mo)
    local dp = displayplayers[0]
    if mo.targetplayer == dp
    or (mo.targetplayer and mo.targetplayer.valid
    and mo.targetplayer.pairmod and mo.targetplayer.pairmod.pair == dp
    and mo.fuse > TICRATE*10) then
        mo.flags2 = $&(~MF2_DONTDRAW)
    else
        mo.flags2 = $|MF2_DONTDRAW
    end
end
addHook("MobjThinker", gateThink, MT_SNEAKERGATE)
addHook("MobjThinker", gateThink, MT_INVINCGATE)
addHook("MobjThinker", gateThink, MT_GROWGATE)
addHook("MobjThinker", gateThink, MT_HYUDOROGATE)

local function gateTouchSpecial(mo, toucher)
    if toucher and toucher.valid and toucher.player and toucher.player.valid
    and toucher.player == mo.targetplayer then
        pairmodGateFunctions[mo.type](toucher, true)
        P_RemoveMobj(mo)
    end
    return true
end
addHook("TouchSpecial", gateTouchSpecial, MT_SNEAKERGATE)
addHook("TouchSpecial", gateTouchSpecial, MT_INVINCGATE)
addHook("TouchSpecial", gateTouchSpecial, MT_GROWGATE)
addHook("TouchSpecial", gateTouchSpecial, MT_HYUDOROGATE)

-- Items
local ITEM_DONT_COLLIDE = {
    [MT_ORBINAUT_SHIELD] = true,
    [MT_JAWZ_SHIELD] = true,
    [MT_MINE] = true,
    [MT_BANANA_SHIELD] = true,
    [MT_EGGMANITEM_SHIELD] = true,
}

local function checkHeight(mo, other)
    return ((mo.z >= other.z and mo.z < other.z + other.height)
        or (other.z >= mo.z and other.z < mo.z + mo.height))
end

local function playerItemCollide(pmo, mo)
    if pmo and pmo.valid and mo and mo.valid then
        if ITEM_DONT_COLLIDE[mo.type]
        and pmo.player and pmo.player.valid
        and pmo.player.pairmod and pmo.player.pairmod.pair
        and mo.target and mo.target.valid
        and pmo.player.pairmod.pair == mo.target.player
        and checkHeight(pmo, mo) then
            return true
        end
    end
end

local function itemCollide(mo, other)
    if mo and mo.valid and other and other.valid then
        if ITEM_DONT_COLLIDE[other.type] 
        and mo.target and mo.target.valid
        and mo.target.player and mo.target.player.valid
        and mo.target.player.pairmod and mo.target.player.pairmod.pair
        and other.target and other.target.valid
        and other.target.player
        and mo.target.player.pairmod.pair == other.target.player
        and checkHeight(mo, other) then
            return false
        end
    end
end

local function itemTouchSpecial(pmo, mo)
    if ITEM_DONT_COLLIDE[mo.type] and pmo and pmo.valid and pmo.player and pmo.player.valid
    and pmo.player.pairmod and pmo.player.pairmod.pair
    and mo and mo.valid and mo.target and mo.target.valid
    and pmo.player.pairmod.pair == mo.target.player then
        return true
    end
end

local function itemShouldDamange(pmo, mo)
    if mo and mo.valid and ITEM_DONT_COLLIDE[mo.type]
    and pmo and pmo.valid and pmo.player and pmo.player.valid
    and pmo.player.pairmod and pmo.player.pairmod.pair
    and mo.target and mo.target.valid
    and pmo.player.pairmod.pair == mo.target.player then
        return false
    end
end

local ITEM_DONT_COLLIDE_APPLIED = {
    MT_ORBINAUT_SHIELD,
    MT_JAWZ_SHIELD,
    MT_MINE,
    MT_BANANA_SHIELD,
    MT_EGGMANITEM_SHIELD,
}
addHook("MobjCollide", playerItemCollide, MT_PLAYER)
for _, k in ipairs(ITEM_DONT_COLLIDE_APPLIED) do
    addHook("MobjCollide", itemCollide, k)
    addHook("TouchSpecial", itemTouchSpecial, k)
end
addHook("ShouldDamage", itemShouldDamange, MT_PLAYER)

-- This is an extremely dirty hack and I expect this to eventually break somewhere
-- but it makes thunder shields not do team damage so yay.
addHook("PlayerSpin", function (p, inf, src)
    if inf.valid and inf.type == MT_PLAYER and p.valid and p.pairmod.pair == inf.player and inf == src then
        return true
    end
end)

-- SPB Modifications
local function SPBMod(mo)
    if not pairmod.running then
        return
    end

    -- It's a blue shell make it blue ffs
    mo.color = SKINCOLOR_BLUE
    mo.colorized = true

    if mo.extravalue1 == 1 then
        mo.pairmod_spbTimer = ($ + 1) or 0

        if mo.pairmod_spbTimer >= 3*TICRATE and mo.pairmod_spbTimer % TICRATE == 0 and mo.pairmod_spbTimer < 8*TICRATE then
            local n = 7 - (mo.pairmod_spbTimer / TICRATE)

            local numbermobj = P_SpawnMobj(mo.x, mo.y, mo.z + (32 * mapobjectscale * P_MobjFlip(mo)), MT_PAIRMOD_SPBNUMBERS)
            numbermobj.state = S_SPBNUMBER_1 + n
            numbermobj.target = mo
            numbermobj.scale = $ * 2

            S_StartSound(mo, sfx_buzz3)
        end

        if mo.pairmod_spbTimer >= 8*TICRATE then
            mo.momx = FixedMul($, 3*FRACUNIT/2)
            mo.momy = FixedMul($, 3*FRACUNIT/2)
            mo.momz = FixedMul($, 3*FRACUNIT/2)
        end
    else
        mo.pairmod_spbTimer = 0
    end
end
addHook("MobjThinker", SPBMod, MT_SPB)

local function SPBNumberThinker(mo)
    if not (mo.target and mo.target.valid) then
        P_RemoveMobj(mo)
        return
    end

    K_MatchGenericExtraFlags(mo, mo.target)

    P_TeleportMove(mo, mo.target.x, mo.target.y, mo.target.z + (72 * mapobjectscale * P_MobjFlip(mo)))
end
addHook("MobjThinker", SPBNumberThinker, MT_PAIRMOD_SPBNUMBERS)

-- NetVars
local function netVars(net)
    pairmod = net($)
end
addHook("NetVars", netVars)
