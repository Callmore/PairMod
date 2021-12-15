--Pairmod
--by Callmore

--## Constants ##--
local STARTTIME = 6*TICRATE + (3*TICRATE/4)

local SYNCBOOST_MAXDIST = 448*FRACUNIT
local SYNCBOOST_MAXBOOST = 3*TICRATE

local INFO_MESSAGE_FADE_TIME = TICRATE*2
local INFO_MESSAGE_START_FADE = TICRATE/2

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

--## Object definition ##--
freeslot(
    "SPR_PAIR", "SPR_SYNC", "SPR_PARL",

    "S_PAIR_POINTER", "MT_PAIR_POINTER"
    "S_PAIR_MARKER", "S_PAIR_MARKER_TRANS", "MT_PAIR_MARKER",
    "S_SYNC_MAXDIST", "MT_SYNC_MAXDIST",
    "S_SNEAKERGATE", "MT_SNEAKERGATE",
    "S_INVINCGATE", "MT_INVINCGATE",
    "S_GROWGATE", "MT_GROWGATE",
    "S_HYUDOROGATE", "MT_HYUDOROGATE"
)


states[S_PAIR_MARKER] = {SPR_PAIR, FF_FULLBRIGHT|A, -1, nil, 0, 0, S_PAIR_MARKER}
states[S_PAIR_MARKER_TRANS] = {SPR_PAIR, FF_FULLBRIGHT|TR_TRANS50|A, -1, nil, 0, 0, S_PAIR_MARKER}
mobjinfo[MT_PAIR_MARKER] = {
    spawnstate = S_PAIR_MARKER
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_PAIR_POINTER] = {SPR_PLAY, FF_FULLBRIGHT|TR_TRANS50|A, -1, nil, 0, 0, S_PAIR_POINTER}
mobjinfo[MT_PAIR_POINTER] = {
    spawnstate = S_PAIR_POINTER,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_SYNC_MAXDIST] = {SPR_PARL, FF_FULLBRIGHT|FF_PAPERSPRITE|A, -1, nil, 0, 0, S_SYNC_MAXDIST}
mobjinfo[MT_SYNC_MAXDIST] = {
    spawnstate = S_SYNC_MAXDIST,
    spawnhealth = 1000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOBLOCKMAP|MF_NOGRAVITY|MF_DONTENCOREMAP,
}

states[S_SNEAKERGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_SNEAKER, -1, nil, 0, 0, S_SNEAKERGATE}
mobjinfo[MT_SNEAKERGATE] = {
    spawnstate = S_SNEAKERGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_DONTENCOREMAP,
}

states[S_INVINCGATE] = {SPR_ITMI, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|FF_ANIMATE|A, -1, nil, 3, 6, S_INVINCGATE}
mobjinfo[MT_INVINCGATE] = {
    spawnstate = S_INVINCGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_DONTENCOREMAP,
}

states[S_GROWGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_GROW, -1, nil, 0, 0, S_GROWGATE}
mobjinfo[MT_GROWGATE] = {
    spawnstate = S_GROWGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_DONTENCOREMAP,
}

states[S_HYUDOROGATE] = {SPR_ITEM, FF_FULLBRIGHT|FF_PAPERSPRITE|TR_TRANS30|KITEM_HYUDORO, -1, nil, 0, 0, S_HYUDOROGATE}
mobjinfo[MT_HYUDOROGATE] = {
    spawnstate = S_HYUDOROGATE,
    spawnhealth = 1000,
    deathsound = sfx_itpick,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_SPECIAL|MF_DONTENCOREMAP,
}

--## Rawsets ##--
rawset(_G, "pairmod", {})
pairmod.running = false

--## Global variables ##--
local pairMarker = nil
local pairmod_stopgamemode = false
local pairmod_ranIntermission = true
local resetcolourcvars = nil

local infoMessage = ""
local infoMessageTimer = 0

local eolScores = nil

local cv_kartelimlast = nil
local kartelimlast = nil

--## Console variables ##--
local cv_enabled = CV_RegisterVar{
    name = "pm_enabled",
    defaultvalue = "On",
    flags = CV_NETVAR,
    PossibleValue = CV_OnOff,
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
        syncboostindicator = nil,
        syncboostradiusindicator = nil,
        oldskincolor = SKINCOLOR_BLACK,
        gatechain = 0,
        gatechainreset = 0,
        teamid = nil
    }
end

local function copyLatent(p)
    local pm = p.pairmod
    pm.lastbtn = p.cmd.buttons
    pm.lastitemtype = p.kartstuff[k_itemtype]
    pm.lastitemamount = p.kartstuff[k_itemamount]
    pm.lastsneakertimer = p.kartstuff[k_sneakertimer]
    pm.lastrocketsneakertimer = p.kartstuff[k_rocketsneakertimer]
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
        infoMessage = str
        infoMessageTimer = INFO_MESSAGE_FADE_TIME
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
                    --print(("%s and %s should be skipped"):format(p.name, p.pm_friend.name))
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

        --print(("%s and %s are a pair"):format(p1.name, p2.name))
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
    if pairMarker and pairMarker.valid then
        P_RemoveMobj(pairMarker)
        pairMarker = nil
    end
    for p in players.iterate do
        if p.pairmod then
            if p.pairmod.pairpointer and p.pairmod.pairpointer.valid then
                P_RemoveMobj(p.pairmod.pairpointer)
                p.pairmod.pairpointer = nil
            end
            if p.pairmod.syncboostindicator and p.pairmod.syncboostindicator.valid then
                P_RemoveMobj(p.pairmod.syncboostindicator)
                p.pairmod.syncboostindicator = nil
            end
            if p.pairmod.syncboostradiusindicator and p.pairmod.syncboostradiusindicator.valid then
                P_RemoveMobj(p.pairmod.syncboostradiusindicator)
                p.pairmod.syncboostradiusindicator = nil
            end
        end
    end
end

local function spawnGate(p, gatetype)
    local gate = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, gatetype)
    gate.fuse = TICRATE*15
    gate.targetplayer = p.pairmod.pair
    gate.scale = FixedMul($, FRACUNIT*3)
    gate.angle = p.mo.angle + ANGLE_90
    gate.flags2 = $|MF2_DONTDRAW
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
        chatprintf(p, ("\x84You are now teammates with %s."):format(fr.name), true)
        chatprintf(fr, ("\x84You are now teammates with %s."):format(p.name), true)
    elseif p.pm_friend then
        CONS_Printf(p, 'You already have a teammate! Enter "pm_resetteam" into the console to reset your teammate before attempting to team again.')
    elseif fr.pm_friend then
        -- player already has a friend
        CONS_Printf(p, "That player already has a teammate.")
    else
        p.pm_tryfriend = fr
        fr.pm_askedfriend = p
        CONS_Printf(p, ('A team request has been sent to %s.'):format(fr.name))
        chatprintf(fr, ('\x83%s is requesting to team with you. Enter "pm_acceptteam" into console to accept.'):format(p.name), true)
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
        COM_BufInsertText(consoleplayer, ('%s %d'):format(k, resetcolourcvars[i].value))
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

local function toTimeString(tics)
    return ("%d\"%02d'%02d"):format(G_TicsToMinutes(tics, true), G_TicsToSeconds(tics), G_TicsToCentiseconds(tics))
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
            --CONS_Printf(p, ('Found "%s"'):format(players[num].name))
            trySetFriend(p, players[num])
            return
        end
    end

    -- search the player list until we find someone with the same name
    local foundplayers = {}
    for i = 0, #players-1 do
        if players[i] and players[i].valid then
            if players[i].name:lower() == instr:lower() then
                --CONS_Printf(p, ('Found "%s"'):format(players[i].name))
                trySetFriend(p, players[i])
                return
            elseif players[i].name:lower():find(instr:lower(), 0, true) then
                table.insert(foundplayers, players[i])
            end
        end
    end

    -- either set teammate or list all posible teammates
    if #foundplayers == 1 then
        --CONS_Printf(p, ('Found "%s"'):format(foundplayers[1].name))
        trySetFriend(p, foundplayers[1])
    elseif #foundplayers > 0 then
        CONS_Printf(p, "Found muliple players. Did you mean:")
        for i, pl in ipairs(foundplayers) do
            CONS_Printf(p, ('- %s (Node %d)'):format(pl.name, #pl))
        end
    else
        CONS_Printf(p, ('Could not find any players matching the term "%s".'):format(instr))
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
-- Global
local function think()
    if leveltime < 1 then return end
    if leveltime == 1 then
        -- Check if gamemode should be running
        if cv_enabled.value then
            pairmod.running = true
            pairMarker = P_SpawnMobj(0, 0, 0, MT_PAIR_MARKER)
        else
            pairmod.running = false
        end

        for p in players.iterate do
            resetVars(p)
        end

        -- do start of level stuff
        pairmod_stopgamemode = false
        if consoleplayer == server and pairmod_ranIntermission then
            if not cv_kartelimlast then
                cv_kartelimlast = CV_FindVar("karteliminatelast")
            end
            kartelimlast = cv_kartelimlast.string
            COM_BufInsertText(server, "karteliminatelast off")
        end
        pairmod_ranIntermission = false
    end

    --## Info message timer ##--
    if infoMessageTimer then
        infoMessageTimer = $-1
        if not infoMessageTimer then
            infoMessage = ""
        end
    end

    -- KEEP THIS AFTER THE LEVELTIME CHECK OTHERWISE IT WILL BREAK!!!!!!!!!!!!!!
    if pairmod_stopgamemode then
        return
    end

    if not pairmod.running then
        return
    end

    --## Pick teams ##--
    if leveltime == STARTTIME - TICRATE*4 then
        pickPairs()
    end

    --## End gamemode, tally scores ##--
    if allExiting() then
        pairmod_stopgamemode = true
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
        eolScores = processScores(scores)

        -- assign placements to players based on their pos
        for i, k in ipairs(eolScores) do
            for i2, k2 in ipairs(k.players) do
                k2.kartstuff[k_position] = i
            end
        end

        return
    end

    if not (pairMarker and pairMarker.valid) then
        pairMarker = P_SpawnMobj(0, 0, 0, MT_PAIR_MARKER)
    end

    --## Pairmarker teleport ##--
    do
        local dp = displayplayers[0]
        if dp and dp.valid
        and dp.pairmod
        and dp.pairmod.pair and dp.pairmod.pair.valid
        and dp.pairmod.pair.mo and dp.pairmod.pair.mo.valid then
            -- AND NOW TELEPORT!
            local pmo = dp.pairmod.pair.mo
            P_TeleportMove(pairMarker, pmo.x, pmo.y, pmo.z)
            pairMarker.scale = pmo.scale
            pairMarker.flags2 = $&(~MF2_DONTDRAW)

            if dp.mo and dp.mo.valid 
            and R_PointToDist2(dp.mo.x, dp.mo.y, pmo.x, pmo.y) < SYNCBOOST_MAXDIST then
                pairMarker.state = S_PAIR_MARKER_TRANS
            else
                pairMarker.state = S_PAIR_MARKER
            end
        else
            pairMarker.flags2 = $|MF2_DONTDRAW
        end
    end

    --## Main loop ##--
    for p in players.iterate do
        if not p.pairmod then
            resetVars(p)
        end

        local pm = p.pairmod

        --## Pair pointer ##--
        do
            if p.spectator then
                copyLatent(p)
                if pm.pairpointer and pm.pairpointer.valid then
                    P_RemoveMobj(pm.pairpointer)
                    pm.pairpointer = nil
                end
                continue
            end
            if not (pm.pairpointer and pm.pairpointer.valid) then
                pm.pairpointer = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
                pm.pairpointer.scale = FRACUNIT/2
                pm.pairpointer.state = S_PAIR_POINTER
            end
            
            if pm.pairpointer and pm.pairpointer.valid then -- sometimes the spawnmobj fails and everything would die
                if pm.pair and pm.pair.valid and not pm.pair.spectator then
                    local ang = R_PointToAngle2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y)
                    local dist = R_PointToDist2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y)
                    P_TeleportMove(pm.pairpointer, p.mo.x + FixedMul(FixedMul(FixedMul(sin(ang+ANGLE_90), dist), FRACUNIT/64), p.mo.scale),
                                                   p.mo.y + FixedMul(FixedMul(FixedMul(cos(ang+ANGLE_90), -dist), FRACUNIT/64), p.mo.scale),
                                                   p.mo.z + FixedMul(FixedMul(pm.pair.mo.z - p.mo.z, FRACUNIT/64), p.mo.scale))
                    pm.pairpointer.scale = p.mo.scale/2
                    pm.pairpointer.color = pm.pair.mo.color
                    pm.pairpointer.skin = pm.pair.mo.skin
                    pm.pairpointer.angle = pm.pair.frameangle
                    pm.pairpointer.flags2 = $&(~MF2_DONTDRAW)
                else
                    pm.pairpointer.flags2 = $|MF2_DONTDRAW
                end
            end
        end

        -- no teammate? stop here
        if not (pm.pair
        and pm.pair.valid
        and not pm.pair.spectator) then continue end -- STOP USING RETURN ITS CONTINUE
        
        --## Gate spawning ##--
        do
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

        --## Gate chain timer ##--
        if pm.gatechainreset then
            pm.gatechainreset = $-1
            if not pm.gatechainreset then
                pm.gatechain = 0
            end
        end

        --## Syncboosts ##--
        if leveltime > STARTTIME then
            local dist = R_PointToDist2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y)
            if dist <= SYNCBOOST_MAXDIST then
                local lastsync = pm.syncboost
                pm.syncboost = min($+1, SYNCBOOST_MAXBOOST)

                if lastsync == SYNCBOOST_MAXBOOST-1 and pm.syncboost == SYNCBOOST_MAXBOOST then
                    setInfoMessage(p, "Max syncboost!")
                    S_StartSound(p.mo, sfx_s23c)
                end

                if not (pm.syncboostindicator and pm.syncboostindicator.valid) then
                    pm.syncboostindicator = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
                    pm.syncboostindicator.tics = -1
                    pm.syncboostindicator.color = p.skincolor
                    pm.syncboostindicator.scale = p.mo.scale / 2
                    pm.syncboostindicator.sprite = SPR_SYNC
                    if pm.syncboostword then
                        pm.syncboostindicator.frame = 0
                    else
                        pm.syncboostindicator.frame = 1
                    end
                end

                if not (pm.syncboostradiusindicator and pm.syncboostradiusindicator.valid) then
                    pm.syncboostradiusindicator = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
                    pm.syncboostradiusindicator.tics = -1
                    pm.syncboostradiusindicator.color = p.skincolor
                    pm.syncboostradiusindicator.scale = p.mo.scale/2
                    pm.syncboostradiusindicator.state = S_SYNC_MAXDIST
                end
            elseif pm.syncboost then
                pm.syncboost = max($-1, 0)
                if not pm.syncboost then
                    p.mo.colorized = false
                    if pm.syncboostindicator and pm.syncboostindicator.valid then
                        P_RemoveMobj(pm.syncboostindicator)
                        pm.syncboostindicator = nil
                    end
                    if pm.syncboostradiusindicator and pm.syncboostradiusindicator.valid then
                        P_RemoveMobj(pm.syncboostradiusindicator)
                        pm.syncboostradiusindicator = nil
                    end
                end
            end

            p.kartstuff[k_speedboost] = max($, FixedMul(FRACUNIT/7, FixedDiv(pm.syncboost, SYNCBOOST_MAXBOOST)))
            p.kartstuff[k_accelboost] = max($, FixedMul(FRACUNIT/2, FixedDiv(pm.syncboost, SYNCBOOST_MAXBOOST)))

            if pm.syncboostindicator and pm.syncboostindicator.valid then
                local timemul = FixedDiv(pm.syncboost, SYNCBOOST_MAXBOOST)
                local ang = R_PointToAngle2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y)
                P_TeleportMove(pm.syncboostindicator, p.mo.x + FixedMul(FixedMul(FixedMul(sin(ang+ANGLE_90), dist), timemul/2), p.mo.scale),
                                                      p.mo.y + FixedMul(FixedMul(FixedMul(cos(ang+ANGLE_90), -dist), timemul/2), p.mo.scale),
                                                      p.mo.z + FixedMul(FixedMul(pm.pair.mo.z - p.mo.z, timemul/2), p.mo.scale))
                pm.syncboostindicator.scale = p.mo.scale / 2
            end

            if pm.syncboostradiusindicator and pm.syncboostradiusindicator.valid then
                local ang = R_PointToAngle2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y)
                local center_x, center_y, center_z = (p.mo.x + pm.pair.mo.x)/2, (p.mo.y + pm.pair.mo.y)/2, (p.mo.z + pm.pair.mo.z)/2
                P_TeleportMove(pm.syncboostradiusindicator, center_x + FixedMul(FixedMul(sin(ang+ANGLE_90), SYNCBOOST_MAXDIST/2), p.mo.scale),
                                                            center_y + FixedMul(FixedMul(cos(ang+ANGLE_90), -SYNCBOOST_MAXDIST/2), p.mo.scale),
                                                            center_z)
                pm.syncboostradiusindicator.scale = p.mo.scale/2
                pm.syncboostradiusindicator.angle = ang + ANGLE_90
            end

            if pm.syncboost then
                p.mo.colorized = true
                if (pm.syncboost < (SYNCBOOST_MAXBOOST / 2) and not (pm.syncboost % 16))
                or (pm.syncboost > (SYNCBOOST_MAXBOOST / 2) and pm.syncboost < SYNCBOOST_MAXBOOST and not (pm.syncboost % 8))
                or (pm.syncboost == SYNCBOOST_MAXBOOST and not (leveltime % 4)) then
                    P_SpawnGhostMobj(p.mo)
                end
            end
        end

        if (p.kartstuff[k_spinouttimer] or p.kartstuff[k_wipeoutslow]) and p.kartstuff[k_spinouttimer] < SPINOUT_TIMER / 2
        and R_PointToDist2(p.mo.x, p.mo.y, pm.pair.mo.x, pm.pair.mo.y) < RECOVER_RANGE then
            p.kartstuff[k_spinouttimer] = 0
            p.kartstuff[k_wipeoutslow] = 0
            p.powers[pw_flashing] = K_GetKartFlashing(p) / 2
            K_DoSneaker(p)
            setInfoMessage(p, "Recovery!")
            setInfoMessage(pm.pair, "Recovered teammate!")
        end

        --## Team colour forcing ##--
        if pm.teamid and TEAMCOLOURS[pm.teamid] then
            p.skincolor = TEAMCOLOURS[pm.teamid]
        end

        copyLatent(p)
    end
end
addHook("ThinkFrame", think)

local function intThink()
    if pairmod_ranIntermission then return end
    pairmod_ranIntermission = true
    if not pairmod.running then return end
    resetColours()
    if kartelimlast ~= nil then
        COM_BufInsertText(server, ('karteliminatelast "%s"'):format(kartelimlast))
    end
end
addHook("IntermissionThinker", intThink)

-- Gates
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

local function sneakergateSpecial(mo, toucher)
    if toucher and toucher.valid and toucher.player and toucher.player.valid
    and toucher.player == mo.targetplayer then
        K_DoSneaker(toucher.player)
        doGateChain(toucher.player)
        setInfoMessage(toucher.player.pairmod.pair, "Teammate used your sneaker gate!")
        P_RemoveMobj(mo)
    end
    return true
end
addHook("TouchSpecial", sneakergateSpecial, MT_SNEAKERGATE)

local function invincgateSpecial(mo, toucher)
    if toucher and toucher.valid and toucher.player and toucher.player.valid
    and toucher.player == mo.targetplayer then
        if not toucher.player.kartstuff[k_invincibilitytimer] then
            local overlay = P_SpawnMobj(toucher.x, toucher.y, toucher.z, MT_INVULNFLASH)
            overlay.target = toucher
            overlay.destscale = toucher.scale
            overlay.scale = toucher.scale
        end
        toucher.player.kartstuff[k_invincibilitytimer] = 10*TICRATE
        P_RestoreMusic(toucher.player)
        if not isLocalPlayer(toucher.player) then
            S_StartSound(toucher, (CV_FindVar("kartinvinsfx").value and sfx_alarmi or sfx_kinvnc))
        end
        K_PlayPowerGloatSound(toucher)
        doGateChain(toucher.player)
        setInfoMessage(toucher.player.pairmod.pair, "Teammate used your invincibility gate!")
        P_RemoveMobj(mo)
    end
    return true
end
addHook("TouchSpecial", invincgateSpecial, MT_INVINCGATE)

local function growgateSpecial(mo, toucher)
    if toucher and toucher.valid and toucher.player and toucher.player.valid
    and toucher.player == mo.targetplayer then
        if toucher.player.kartstuff[k_growshrinktimer] < 0 then -- If you're shrunk, then "grow" will just make you normal again.
            removeGrowShrink(toucher.player)
        else
            K_PlayPowerGloatSound(toucher)
            toucher.scalespeed = mapobjectscale/TICRATE
            toucher.destscale = (3*mapobjectscale)/2
            if CV_FindVar("kartdebugshrink").value then
                toucher.destscale = (6*toucher.destscale)/8
            end
            toucher.player.kartstuff[k_growshrinktimer] = 12*TICRATE
            P_RestoreMusic(toucher.player)
            if not isLocalPlayer(toucher.player) then
                S_StartSound(toucher, (CV_FindVar("kartinvinsfx").value and sfx_alarmg or sfx_kgrow))
            end
            S_StartSound(toucher, sfx_kc5a)
        end
        doGateChain(toucher.player)
        setInfoMessage(toucher.player.pairmod.pair, "Teammate used your grow gate!")
        P_RemoveMobj(mo)
    end
    return true
end
addHook("TouchSpecial", growgateSpecial, MT_GROWGATE)

local function hyudorogateSpecial(mo, toucher)
    if toucher and toucher.valid and toucher.player and toucher.player.valid
    and toucher.player == mo.targetplayer then
        toucher.player.kartstuff[k_hyudorotimer] = 7*TICRATE
        S_StartSound(toucher, sfx_s3k92)
        doGateChain(toucher.player)
        setInfoMessage(toucher.player.pairmod.pair, "Teammate used your hyudoro gate!")
        P_RemoveMobj(mo)
    end
    return true
end
addHook("TouchSpecial", hyudorogateSpecial, MT_HYUDOROGATE)

-- NetVars
local function netVars(net)
    pairmod = net($)
    pairmod_stopgamemode = net($)
    pairmod_ranIntermission = net($)
end
addHook("NetVars", netVars)

--## Hud ##--
-- Constants
local ITEMX = 160
local ITEMY = 163
local ITEMTEXTX = 36
local ITEMTEXTY = 26

local ITEMMINI = {
    "K_ISSHOE",
    "K_ISRSHE",
    "K_ISINV1",
    "K_ISBANA",
    "K_ISEGGM",
    "K_ISORBN",
    "K_ISJAWZ",
    "K_ISMINE",
    "K_ISBHOG",
    "K_ISSPB",
    "K_ISGROW",
    "K_ISSHRK",
    "K_ISTHNS",
    "K_ISHYUD",
    "K_ISPOGO",
    "K_ISSINK"
}

-- Variables
local playerfacesgfx = {}
local miniitemgfx
local miniiteminvulgfx
local sadgfx

-- Functions
local function pairHud(v, p)
    do
        --Rank faces
        for i = 0, #skins-1 do
            if not playerfacesgfx[skins[i].name] then
                playerfacesgfx[skins[i].name] = v.cachePatch(skins[i].facerank)
            end
        end

        --Mini items
        if not miniitemgfx then
            miniitemgfx = {}
            for i, k in ipairs(ITEMMINI) do
                --print("Caching " .. k .. " into " .. i)
                miniitemgfx[i] = v.cachePatch(k)
            end
        end

        --Mini invul
        if not miniiteminvulgfx then
            miniiteminvulgfx = {}
            for i = 1, 6 do
                --print("Caching K_ISINV" .. i .. " into " .. i)
                miniiteminvulgfx[i-1] = v.cachePatch("K_ISINV" .. i)
            end
        end

        --Sad face (for yes)
        if not sadgfx then
            sadgfx = v.cachePatch("K_ITSAD")
        end
    end

    --## Face ##--
    if p and p.valid and p.pairmod
    and p.pairmod.pair and p.pairmod.pair.valid and not p.pairmod.pair.spectator then
        local skinused = p.pairmod.pair.mo.skin
        if p.pairmod.pair.mo.colorized then
            skinused = TC_RAINBOW
        end
        v.draw(152, 171, playerfacesgfx[p.pairmod.pair.mo.skin], V_SNAPTOBOTTOM|V_HUDTRANS, v.getColormap(skinused, p.pairmod.pair.mo.color))
        v.drawString(160, 190, "Team: " .. p.pairmod.pair.name, V_ALLOWLOWERCASE|V_SNAPTOBOTTOM|V_HUDTRANS, "center")
        
        --## Items ##--
        do
            local p = p.pairmod.pair

            local itemcount = p.kartstuff[k_itemamount]

            if p.kartstuff[k_rocketsneakertimer] then
                if not (leveltime&1) then
                    v.draw(ITEMX, ITEMY, miniitemgfx[2], vflags)				
                end
            elseif p.kartstuff[k_eggmanexplode] then
                local flashtime = 4<<(p.kartstuff[k_eggmanexplode]/TICRATE)
                local cmap = nil
                if not (p.kartstuff[k_eggmanexplode] == 1
                or (p.kartstuff[k_eggmanexplode] % (flashtime/2) ~= 0)) then
                    cmap = v.getColormap(TC_BLINK, SKINCOLOR_CRIMSON)
                end				
                v.draw(ITEMX, ITEMY, miniitemgfx[5], vflags, cmap)				
            elseif p.kartstuff[k_itemtype] then
                local itemp = miniitemgfx[p.kartstuff[k_itemtype]] or sadgfx
                --inv is shiny
                if p.kartstuff[k_itemtype] == KITEM_INVINCIBILITY then
                    itemp = miniiteminvulgfx[((leveltime%(6*3))/3)]
                end
                --draw amount as a number
                if not (p.kartstuff[k_itemheld] and not (leveltime&1)) then
                    v.draw(ITEMX, ITEMY, itemp, vflags)
                    if itemcount > 1 then
                        v.drawString(ITEMX+ITEMTEXTX, ITEMY+ITEMTEXTY, itemcount, vflags, "right")
                    end
                end
            end
        end
    end

    --## Info messages ##--
    if infoMessageTimer then
        local fadeLevel = (10 - FixedInt(FixedDiv(min(infoMessageTimer, INFO_MESSAGE_START_FADE), INFO_MESSAGE_START_FADE)*10)) * V_10TRANS
        v.drawString(160, 161, infoMessage, fadeLevel|V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "center")
    end

    --## Post race message ##--
    if p.exiting and not pairmod_stopgamemode then
        local str = "Your final time will be doubled to keep rankings fair"
        if p.pairmod and p.pairmod.pair then
            str = "Your final time is the sum of both player's time"
        end
        local strwidth = v.stringWidth(str, V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin")
        v.drawString(160 - (strwidth / 2), 70, str, V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin")
    end

    --## Post race scoreboard ##--
    if pairmod_stopgamemode then
        v.drawString(160, 30, "Final ranking", V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "center")

        if eolScores ~= nil then
            for i, k in ipairs(eolScores) do
                v.drawString(80, 33+(i*10), table.concat(k.playernames, " & "), V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin")
                v.drawString(260, 33+(i*10), toTimeString(k.time), V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin-right")
            end
        else
            v.drawString(160, 60, "None!", V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "center")
        end
    end
end
hud.add(pairHud, "game")
