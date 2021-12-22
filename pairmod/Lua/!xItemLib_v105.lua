--xItemLib
--modular custom item library
--written by minenice, with help from the [REDACTED] (if you know what this is thanks a bunch lmao)
--don't expect this to be compatible with vanilla replays you fuck

--this is expected to be loaded as a packaged library (bundled with mods that need it), not as a dependancy (loaded outside of the mods that need it)
--however this does work as it's own standalone mod, if you just want the enhancements

--current library version (release, major, minor)
local currLibVer = 105

--item flags, people making custom items can copy/paste this over to their lua scripts
local XIF_POWERITEM = 1 --is power item (affects final odds)
local XIF_COOLDOWNONSTART = 2 --can't be obtained on start cooldown
local XIF_UNIQUE = 4 --only one can exist in anyone's slot
local XIF_LOCKONUSE = 8 --locks the item slot when the item is used, slot must be unlocked manually by setting player.xItemData.xItem_itemSlotLocked to false
local XIF_COOLDOWNINDIRECT = 16 --checks if indirectitemcooldown is 0
local XIF_COLPATCH2PLAYER = 32 --map hud patch colour to player prefcolor
local XIF_ICONFORAMT = 64 --item icon and dropped item frame changes depending on the item amount (animation frames become amount frames)


--apparently this makes shit faster? wtf?
local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local MAXSKINCOLORS = MAXSKINCOLORS
local ANG1 = ANG1
local k_sneakertimer = k_sneakertimer
local k_spinouttimer = k_spinouttimer
local k_wipeoutslow = k_wipeoutslow
local k_driftboost = k_driftboost
local k_floorboost = k_floorboost
local k_startboost = k_startboost
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local k_rocketsneakertimer = k_rocketsneakertimer
local k_hyudorotimer = k_hyudorotimer
local k_drift = k_drift
local k_speedboost = k_speedboost
local k_accelboost = k_accelboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_driftcharge = k_driftcharge
local k_position = k_position
local k_roulettetype = k_roulettetype
local k_itemroulette = k_itemroulette
local k_bumper = k_bumper
local k_eggmanheld = k_eggmanheld
local k_itemheld = k_itemheld
local k_squishedtimer = k_squishedtimer
local k_respawn = k_respawn
local k_stolentimer = k_stolentimer
local k_stealingtimer = k_stealingtimer

--desperate times call for desperate measures
local FixedMul = FixedMul
local FixedDiv = FixedDiv
local R_PointToDist2 = R_PointToDist2
local type = type
local table = table
local pcall = pcall
local min = min
local max = max

--"lol," he said. "lmao."
--also rip kartmp dropped item fuse
freeslot(
	"MT_FLOATINGXITEM",
	"MT_XITEMPLAYERARROW"
)

mobjinfo[MT_FLOATINGXITEM] = {
	doomednum = -1,
    spawnstate = S_ITEMICON,
	deathsound = sfx_itpick,
    spawnhealth = 1,
    radius = 24*FRACUNIT,
    height = 32*FRACUNIT,
	mass = 100,
    flags = MF_SLIDEME|MF_SPECIAL|MF_DONTENCOREMAP
}

mobjinfo[MT_XITEMPLAYERARROW] = {
	doomednum = -1,
    spawnstate = S_PLAYERARROW,
    spawnhealth = 1000,
    radius = 36*FRACUNIT,
    height = 37*FRACUNIT,
	mass = 16,
    flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY|MF_DONTENCOREMAP
}

--one (nested) table per splitscreen player
local availableItems = {{}, {}, {}, {}}
--only for player 1
local debuggerDistributions = {it = {}, odds = {}, totalodds = 0}

local function findSplitPlayerNum(p)
	local splitplaynum = 0
	local si = 1
	for dp in displayplayers.iterate do
		if dp and dp == p then
			return si
		end
		si = $+1
	end
	return 0
end

--new solution for vanilla item toggles
--thanks yoshimo
local cvarTbl = {}
local function getCVar(name)
    local cvar = cvarTbl[name]
    if not cvar then
        cvar = CV_FindVar(name)
        cvarTbl[name] = cvar
    end
    return cvar.value
end

local function addItemPatch(item, bigpatch, smallpatch)
	local t = {}
	if type(bigpatch) == "string" then
		t.bigTics = false
		t.bigP = bigpatch
	elseif type(bigpatch) == "table" then
		t.bigTics = bigpatch[1]
		t.bigP = {}
		for i = 2, #bigpatch do
			table.insert(t.bigP, bigpatch[i])
		end
	end
	if type(smallpatch) == "string" then
		t.smallTics = false
		t.smallP = smallpatch
	elseif type(smallpatch) == "table" then
		t.smallTics = smallpatch[1]
		t.smallP = {}
		for i = 2, #smallpatch do
			table.insert(t.smallP, smallpatch[i])
		end
	end
	xItemLib.xItemPatch[item] = t
end

local function addItemDropSprite(item, sprite)
	if not sprite then
		return {tics = 0, pics = {{SPR_ITEM, 0}}}
	end
	local t = {}
	if type(sprite) == "number" then
		t.tics = 0
		t.pics = {{sprite, A}}
	elseif type(sprite) == "table" then	-- format as either {tics between frames, {sprite, frame}, {sprite, frame}, ...} or {0, {sprite, frame}}
		t.tics = sprite[1]
		t.pics = {}
		for i = 2, #sprite do
			table.insert(t.pics, sprite[i])
		end
	end
	return t
end

local function getLoadedItemAmount()
	return table.maxn(xItemLib.xItems)
end

local function getItemPatch(item, small)
	local t = xItemLib.xItemPatch[item]
	if small then
		return (t.smallTics or false), (t.smallP or "K_ISSAD")
	else
		return (t.bigTics or false), (t.bigP or "K_ITSAD")
	end
end

local function getItemPatchSingle(i, small, anime)
	local libdat = xItemLib
	local itflags = libdat.xItemFlags
	local atics, get = libdat.func.getPatch(i, small)
	if atics then
		if itflags[i] and (itflags[i] & XIF_ICONFORAMT) then 
			local idx = max(min(anime, table.maxn(get)), 1)
			return get[idx], table.maxn(get)
		else
			local idx = (leveltime/atics) % table.maxn(get)
			return get[idx + 1], 1
		end
	else
		return get, 1
	end
end

local function getItemDropSprite(item, animate)
	if xItemLib.xItemData[item] then
		local t = xItemLib.xItemData[item].droppedstate
		if animate and t.tics > 0 then
			local anf = 1
			local itf = xItemLib.xItemFlags[item]
			if itf and (itf & XIF_ICONFORAMT) then
				anf = max(min(animate, #t.pics), 1)
			else
				anf = ((animate/t.tics) % #t.pics) + 1
			end
			local pic = t.pics[anf]
			return pic[1], pic[2]
		else
			local pic = t.pics[1]
			return pic[1], pic[2]
		end
	else
		return SPR_ITEM, 0
	end
end

local function addXItemMod(namespace, iName, defDat) --mod namespace, friendly name, default (placeholder) item data
	table.insert(xItemLib.xItemModNamespaces, namespace)
	xItemLib.xItemCrossData.modData[namespace] = {iName = iName or namespace, defDat = defDat or {}}
	print("Added mod "..iName.." ("..namespace..") to xItem mods")
	local t = xItemLib.xItemCrossData.itemData
	for itm = 1, xItemLib.func.countItems() do
		if not t[itm][namespace] then
			t[itm][namespace] = defDat or {}
			print("Added item mod data to item "..itm.." from mod "..iName)
		end
	end
end

local function setXItemModData(namespace, item, data)
	local crossDat = xItemLib.xItemCrossData
	if type(item) == "string" then
		item = xItemLib.func.findItemByNamespace(item, true)
	end
	if crossDat.itemData[item] then
		if crossDat.modData[namespace] then
			crossDat.itemData[item][namespace] = data
			print("Set mod "..namespace.."'s item data for item"..item)
		else
			print("Can't find mod "..namespace.." in xItem mods!")
		end
	else
		print("Can't find item "..item.." in xItems!")
	end
end

local function getXItemModData(namespace, item)
	local crossDat = xItemLib.xItemCrossData
	if type(item) == "string" then
		item = xItemLib.func.findItemByNamespace(item, true)
	end
	if crossDat.modData[namespace] and crossDat.itemData[item] then
		return crossDat.itemData[item][namespace]
	end
	return nil
end

local function addXItem(namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc)
	local item = xItemLib.func.countItems() + 1
	if type(namespace) ~= "table" then
		if type(namespace) ~= "string" then
			error("Tried to add item "..item..", first argument isn't a table or string", 2)
		end
	else
		namespace, iName, bigpatch, smallpatch, flags, raceodds, battleodds, getfunc, usefunc, hudfunc, oddsfunc, resultfunc, droppedstate, showInRoulette, preusefunc, droppedfunc = unpack(namespace, 1, 16)
		if type(namespace) ~= "string" then
			error("Tried to add item "..item..", first element in the passed table isn't a string", 2)
		end
	end
	table.insert(xItemLib.xItems, item)
	xItemLib.xItemNamespaces[namespace] = item
	xItemLib.func.setPatch(item, bigpatch or "K_ITSAD", smallpatch or "K_ISSAD")
	if flags then
		xItemLib.xItemFlags[item] = flags
	end
	--default odds are nothing
	table.insert(xItemLib.xItemOddsRace, raceodds or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
	table.insert(xItemLib.xItemOddsBattle, battleodds or {0, 0})
	xItemLib.xItemData[item] = {
		name = iName, --"friendly" item name that can be used in other mods for display reasons
		defaultRaceOdds = raceodds or {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, --item's default race odds
		defaultBattleOdds = battleodds or {0, 0}, --item's default battle odds
		getfunc = getfunc or nil, --function that fires when the item is first rolled, function(player, itemNum)
		usefunc = usefunc or nil, --function that fires when using the item, function(player, cmd)
		hudfunc = hudfunc or nil, --hud function that runs as long as the item is in the player's item slot, function(v, player, consoleplayer)
		oddsfunc = oddsfunc or nil, --function that runs when finalizing item odds, function(newodds, oddsPos, mashed, spbrush, player, secondist, pingame, pexiting), expected to return a newodds override
		resultfunc = resultfunc or nil, --function that runs when getting the item type, function(player, itemNum), expected to return itemNum and itemAmount overrides
		droppedstate = addItemDropSprite(item, droppedstate), --table of sprites to use when item is dropped
		droppedfunc = droppedfunc or nil, --function that runs when the dropped item first spawns upon a strip, function(droppedMo, item, itemAmount), can return a spriteframe override
		showInRoulette = showInRoulette or nil, --function or boolean that determines wether to show the item in the roulette if function expected to return a boolean
		preusefunc = preusefunc or nil, --function that runs when th player is holding the attack button, before the item is used. the usefunc will run when the button is released instead of when pressed. function(player, cmd, ticsAttackHeld, playerJustPressedAttack?)
	}
	xItemLib.toggles.xItemToggles[item] = true
	xItemLib.xItemCrossData.itemData[item] = {}
	local t = xItemLib.xItemCrossData.itemData[item]
	for i = 1, #xItemLib.xItemModNamespaces do
		local id = xItemLib.xItemModNamespaces[i]
		if not t[id] then
			t[id] = xItemLib.xItemCrossData.modData.defDat
			print("Added item mod data to item "..item.." from mod "..xItemLib.xItemCrossData.modData[id].iName)
		end
	end
	
	print("Added item "..item.." named "..namespace.." to xItems")
	print(xItemLib.func.countItems().." items are loaded ("..table.maxn(xItemLib.xItemPatch).." patch entries)")
end

--must be exact match
local function findItemByNamespace(name, ignoreErrs)
	ignoreErrs = $ or false
	local i = 0
	if type(name) == "string" then --item namespace
		i = xItemLib.xItemNamespaces[name]
		if not i then
			if not ignoreErrs then
				error("can't find item "..name, 2)
			end
			return 0
		end
		return i
	end
	if not ignoreErrs then
		error("passed non-string to xItem findItemByNamespace()", 2)
	end
end

--simple matching, doesn't check for case
local function findItemByFriendlyName(name, ignoreErrs)
	ignoreErrs = $ or false
	local libdat = xItemLib
	local itdat = libdat.xItemData
	local libfn = libdat.func
	name = string.lower(name)
	
	local compName
	local possible = {}
	for i = 1, libfn.countItems() do
		compName = string.lower(itdat[i].name)
		if compName:find(name) then
			table.insert(possible, i)
		end
	end
	if #possible > 0 then
		return possible
	else
		if not ignoreErrs then
			error("can't find item "..name, 2)
		end
		return 0
	end
end

--item ID 0 will fully reset all odds
local function resetOddsForItem(item, p, battle)
	local dat = p.xItemData
	if item == 0 then
		dat.xItem_battleOdds = nil
		dat.xItem_raceOdds = nil
	else
		
		local i = item
		if type(item) == "string" then --item namespace
			i = xItemLib.xItemNamespaces[item]
			if not i then
				print("can't find item "..item)
				return
			end
		end
		
		if battle then
			dat.xItem_battleOdds[i] = xItemLib.xItemData[i].defaultBattleOdds
		else
			dat.xItem_raceOdds[i] = xItemLib.xItemData[i].defaultRaceOdds
		end
	end
end

local function setPlayerOddsForItem(item, p, raceOdds, battleOdds)
	local dat = p.xItemData
	if raceOdds then
		dat.xItem_raceOdds[item] = raceOdds
	end
	if battleOdds then
		dat.xItem_battleOdds[item] = battleOdds
	end
end

local starttime = 6*TICRATE + (3*TICRATE/4)

local function playerScaling(spbrush, playersInGame)
	return (8 - (spbrush and 2 or playersInGame))
end

local function checkStartCooldown()
	if leveltime < 30*TICRATE + starttime then
		return true
	end
	return false
end

local function checkPowerItemOdds(odds, mashed, spbrush, playersInGame)
	if (franticitems) then
		odds = $ * 2
	end
	odds = FixedMul($*FRACUNIT, FRACUNIT + ((xItemLib.func.getPlayerScaling(spbrush, playersInGame)*FRACUNIT) / 25))/FRACUNIT
	if (mashed > 0) then
		odds = FixedDiv(odds*FRACUNIT, FRACUNIT + mashed)/FRACUNIT
	end
	return odds
end

local function floatingItemThinker(mo)
	local f = P_SpawnMobj(mo.x, mo.y, mo.z, MT_FLOATINGXITEM)
	f.momx = mo.momx
	f.momy = mo.momy
	f.momz = mo.momz
	f.scale = mo.scale
	f.destscale = mo.destscale
	f.threshold = mo.threshold
	f.movecount = mo.movecount
	f.flags = mo.flags
	f.flags2 = mo.flags2
	P_SpawnShadowMobj(f)
	P_RemoveMobj(mo)
end

local function floatingItemSpecial(s, t)
	--if t.player and t.player.xItemData and (t.player.xItemData.xItem_roulette or t.player.xItemData.xItem_itemSlotLocked) then
		return true
	--end
end

local function floatingXItemThinker(mo)
	if (mo.flags & MF_NOCLIPTHING) then
		if (P_CheckDeathPitCollide(mo)) then
			P_RemoveMobj(mo)
			return
		elseif (P_IsObjectOnGround(mo)) then
			mo.momx = 1
			mo.momy = 0
			mo.flags = MF_SLIDEME|MF_SPECIAL|MF_DONTENCOREMAP|MF_NOGRAVITY
		end
	else
		mo.angle = $ + 4 * ANG1
		if (mo.flags2 & MF2_NIGHTSPULL) then
			if (not (mo.tracer) or not (mo.tracer.health) or mo.scale <= mapobjectscale >> 4) then
				P_RemoveMobj(mo)
				return
			end
			--fuck
			P_InstaThrust(mo, R_PointToAngle2(mo.x, mo.y, mo.tracer.x, mo.tracer.y), R_PointToDist2(mo.x, mo.y, mo.tracer.x, mo.tracer.y) >> 2)
		else
			local adj = FixedMul(FRACUNIT - cos(mo.angle), (mapobjectscale >> 3))
			if (mo.eflags & MFE_VERTICALFLIP) then
				mo.z = mo.ceilingz - mo.height - adj
			else
				mo.z = mo.floorz + adj
			end
		end
	end
	
	local libdat = xItemLib
	local libfunc = libdat.func
	local idat = libdat.xItemData
	local i = mo.threshold
	local amt = mo.movecount
	local sprite, frame = SPR_ITEM, 0
	--run droppedfunc function if it exists
	
	--set spriteframe here
	--print(i)
	local anim = 0
	local itf = libdat.xItemFlags[i]
	if itf and (itf & XIF_ICONFORAMT) then
		anim = amt
	else
		anim = leveltime
	end
	
	if idat[i].droppedfunc then
		sprite, frame = idat[i].droppedfunc(mo, i, amt)
	else
		sprite, frame = getItemDropSprite(i, anim)
	end
	
	--crossmod "hooks"
	for j = 1, #libdat.xItemModNamespaces do
		local id = libdat.xItemModNamespaces[j]
		local crossMod = libfunc.getXItemModData(id, item)
		if crossMod and type(crossMod) == "table" and crossMod.droppedfunc then
			local status, err = pcall(crossMod.droppedfunc, mo, i, amt)
			if not status then
				error(err, 2)
			end
		end
	end
	
	mo.sprite = sprite
	mo.frame = frame|FF_PAPERSPRITE
end

local function floatingXItemSpecial(s, t)
	if not t.player then
		return
	end
	
	local libdat = xItemLib
	local libfunc = libdat.func
	
	local p = t.player
	local kartstuff = p.kartstuff
	
	--hell
	if p.xItemData and (p.xItemData.xItem_roulette > 0 or p.xItemData.xItem_itemSlotLocked 
		or kartstuff[k_stealingtimer] > 0 or kartstuff[k_stolentimer] > 0 or kartstuff[k_growshrinktimer] > 0 or kartstuff[k_rocketsneakertimer] > 0
		or kartstuff[k_eggmanexplode] > 0 or (kartstuff[k_itemtype] and kartstuff[k_itemtype] ~= s.threshold) or kartstuff[k_itemheld]) then
		return true
	end
	
	if (G_BattleGametype() and kartstuff[k_bumper] <= 0)
		return true
	end
	--print("a")
	kartstuff[k_itemtype] = s.threshold
	kartstuff[k_itemamount] = $ + s.movecount
	
	--crossmod "hooks"
	for j = 1, #libdat.xItemModNamespaces do
		local id = libdat.xItemModNamespaces[j]
		local crossMod = libfunc.getXItemModData(id, s.threshold)
		if crossMod and type(crossMod) == "table" and crossMod.pickupfunc then
			local status, err = pcall(crossMod.pickupfunc, p, s, t)
			if not status then
				error(err, 2)
			end
		end
	end
	
	-- nah
	--if (kartstuff[k_itemamount] > 255) then
	--	kartstuff[k_itemamount] = 255
	--end

	S_StartSound(special, s.info.deathsound)

	s.tracer = t
	s.flags2 = $ | MF2_NIGHTSPULL
	s.destscale = mapobjectscale >> 4
	s.scalespeed = $ << 1

	s.flags = $ & ~MF_SPECIAL
	return true
end

local function itemBoxSpecial(s, t)
	if t.player and t.player.xItemData and (t.player.xItemData.xItem_roulette or t.player.xItemData.xItem_itemSlotLocked) then
		return true
	end
end

local function P_IsLocalPlayer(player)
	local i

	if player == consoleplayer then
		return true
	elseif splitscreen then
		for i = 1, splitscreen do -- Skip P1
			if player == displayplayers[i] then
				return true
            end
		end
	end

	return false
end

--thanks yoshimo for porting all this stuff over
local function playerArrowUnsetPositionThinking(mobj, scale)
	P_TeleportMove(mobj, mobj.target.x, mobj.target.y, mobj.target.z)
	
    mobj.angle = R_PointToAngle(mobj.x, mobj.y) + ANGLE_90 -- literally only happened because i wanted to ^L^R the SPR_ITEM's

    if not splitscreen and displayplayers[0].mo then
        scale = mobj.target.scale + FixedMul(FixedDiv(abs(P_AproxDistance(displayplayers[0].mo.x-mobj.target.x,
            displayplayers[0].mo.y-mobj.target.y)), RING_DIST), mobj.target.scale)
        if scale > 16*mobj.target.scale then
            scale = 16*mobj.target.scale
        end
    end
    mobj.destscale = scale

    if not (mobj.target.eflags & MFE_VERTICALFLIP) then
        mobj.z = mobj.target.z + P_GetPlayerHeight(mobj.target.player) + (mobj.target.scale << 5)
        mobj.eflags = $ & ~MFE_VERTICALFLIP
    else
        mobj.z = mobj.target.z - P_GetPlayerHeight(mobj.target.player) - (mobj.target.scale << 5)
        mobj.eflags = $ | MFE_VERTICALFLIP
    end
    
    return scale
end

local function vanillaArrowThinker(mo)
	local libdat = xItemLib
	local libfunc = libdat.func
	local status
	local err = false
	--crossmod "hooks"
	for i = 1, #libdat.xItemModNamespaces do
		local id = libdat.xItemModNamespaces[i]
		local crossMod = libfunc.getXItemModData(id, 1)
		if crossMod and type(crossMod) == "table" and crossMod.playerArrowSpawn then
			status, err = pcall(crossMod.playerArrowSpawn, mo, mo.target)
			if not status then
				error(err, 2)
			end
		end
		if err then return end
	end
	
	local f = P_SpawnMobj(mo.x, mo.y, mo.z, MT_XITEMPLAYERARROW)
	f.threshold = mo.threshold
	f.movecount = mo.movecount
	f.flags = mo.flags
	f.flags2 = mo.flags2
	f.target = mo.target
	--f.tracer = mo.tracer
	f.scale = mo.scale
	f.destscale = mo.destscale
	mo.state = S_NULL
end

local function playerArrowThinker(mobj)
    if mobj.target and mobj.target.health
        and mobj.target.player and not mobj.target.player.spectator
        and mobj.target.player.health and mobj.target.player.playerstate ~= PST_DEAD
        --[[and displayplayers[0].mo and not displayplayers[0].spectator]]
    then
		local mtrace = mobj.tracer
		local tm = mobj.target
		local tp = mobj.target.player
		local kartstuff = mobj.target.player.kartstuff
		local xitdat = mobj.target.player.xItemData
		
		if not xitdat then return true end
		
        local scale = 3*tm.scale
        mobj.color = tm.color
        K_MatchGenericExtraFlags(mobj, tm)

        if (G_RaceGametype() or kartstuff[k_bumper] <= 0)
--#if 1 -- Set to 0 to test without needing to host
            or ((tp == displayplayers[0]) or P_IsLocalPlayer(tp))
--#endif
        then
            mobj.flags2 = $ | MF2_DONTDRAW
        end

        --P_UnsetThingPosition(mobj)
        if mobj.flags & MF_NOCLIP then
            scale = playerArrowUnsetPositionThinking(mobj, scale)
        else
            mobj.flags = $ | MF_NOCLIP
            scale = playerArrowUnsetPositionThinking(mobj, scale)
            mobj.flags = $ & ~MF_NOCLIP
        end
        --P_SetThingPosition(mobj)

        if not mtrace then
            local overlay = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)
            mobj.tracer = overlay
            overlay.target = mobj
            overlay.state = S_PLAYERARROW_ITEM
            --P_SetScale(mtrace, (mtrace.destscale = mobj.scale))
            overlay.destscale = mobj.scale
            P_SetScale(overlay, (overlay.destscale))
			mtrace = mobj.tracer
        end

        -- Do this in an easy way
        if xitdat.xItem_roulette then
            mtrace.color = tp.skincolor
            mtrace.colorized = true
        else
            mtrace.color = SKINCOLOR_NONE
            mtrace.colorized = false
        end

        if not (mobj.flags2 & MF2_DONTDRAW) then
			local idat = xItemLib.xItemData
            local numberdisplaymin = 2
			local i = kartstuff[k_itemtype]
			local itf = xItemLib.xItemFlags[i]
			if itf and (itf & XIF_ICONFORAMT) then
				numberdisplaymin = idat[i].droppedstate.tics + 1
			end
			
            -- Set it to use the correct states for its condition
            if xitdat.xItem_roulette then
				i = ((xitdat.xItem_roulette % (xItemLib.func.countItems() * 3)) / 3) + 1
				local itdat = idat[i]
				local sprs = itdat.droppedstate
				local sprite, frame = getItemDropSprite(i, 0)
				
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = sprite
                mtrace.frame = FF_FULLBRIGHT|frame
                mtrace.flags2 = $ & ~MF2_DONTDRAW
				
            elseif kartstuff[k_stolentimer] > 0 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_HYUDORO
                if leveltime & 2 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif (kartstuff[k_stealingtimer] > 0) and (leveltime & 2) then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_HYUDORO
                mtrace.flags2 = $ & ~MF2_DONTDRAW
            elseif kartstuff[k_eggmanexplode] > 1 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_EGGMAN
                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_rocketsneakertimer] > 1 then
                --itembar = kartstuff[k_rocketsneakertimer] -- not today satan
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_ROCKETSNEAKER
                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_growshrinktimer] > 0 then
                mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = SPR_ITEM
                mtrace.frame = FF_FULLBRIGHT|KITEM_GROW

                if leveltime & 1 then
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                else
                    mtrace.flags2 = $ | MF2_DONTDRAW
                end
            elseif kartstuff[k_itemtype] and kartstuff[k_itemamount] > 0 then
                mobj.state = S_PLAYERARROW_BOX
				
				--find sprite to use
				local sprite, frame
				if itf and (itf & XIF_ICONFORAMT) then
					sprite, frame = getItemDropSprite(i, kartstuff[k_itemamount])
				else
					sprite, frame = getItemDropSprite(i, leveltime)
				end
				
				--set correct sprite BEFORE THE GAME DOES IT FFS
				mobj.state = S_PLAYERARROW_BOX
                mtrace.sprite = sprite
                mtrace.frame = FF_FULLBRIGHT|frame

                if kartstuff[k_itemheld] then
                    if leveltime & 1 then
                        mtrace.flags2 = $ & ~MF2_DONTDRAW
                    else
                        mtrace.flags2 = $ | MF2_DONTDRAW
                    end
                else
                    mtrace.flags2 = $ & ~MF2_DONTDRAW
                end
            else
                mobj.state = S_PLAYERARROW
                mtrace.state = S_PLAYERARROW_ITEM
            end

            mtrace.destscale = scale
			
            if kartstuff[k_itemamount] >= numberdisplaymin
                and kartstuff[k_itemamount] <= 10 -- Meh, too difficult to support greater than this; convert this to a decent HUD object and then maybe :V
            then
                local number = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)
                local numx = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_OVERLAY)

                number.target = mtrace
                number.state = S_PLAYERARROW_NUMBER
                P_SetScale(number, mtrace.scale)
                number.destscale = scale
                number.frame = FF_FULLBRIGHT|(kartstuff[k_itemamount])

                numx.target = mtrace
                numx.state = S_PLAYERARROW_X
                P_SetScale(numx, mtrace.scale)
                numx.destscale = scale
            end

            if K_IsPlayerWanted(tp) and mobj.movecount ~= 1 then
                local wanted = P_SpawnMobj(mobj.x, mobj.y, mobj.z, MT_PLAYERWANTED)
                wanted.target = tm
                wanted.tracer = mobj
                P_SetScale(wanted, mobj.scale)
                wanted.destscale = scale
                mobj.movecount = 1
            elseif not K_IsPlayerWanted(tp) then
                mobj.movecount = 0
            end
        else
            mtrace.flags2 = $ | MF2_DONTDRAW
        end
    elseif mobj.health > 0 then
        P_KillMobj(mobj, nil, nil)
        --return
        return true
    end
end

--odds functions start
local function xItem_GetItemResult(p, getitem)
	local libdat = xItemLib
	local itdat = libdat.xItemData
	local libfn = libdat.func
	local it = itdat[getitem]
	local itflags = libdat.xItemFlags[getitem]
	local kartstuff = p.kartstuff
	
	if it and it.resultfunc then
		kartstuff[k_itemtype], kartstuff[k_itemamount] = it.resultfunc(p, getitem)
	else
		if (getitem <= 0 or getitem > libfn.countItems()) then -- Sad (Fallback)
			if (getitem ~= 0) then
				print("ERROR: xItem_GetItemResult - Item roulette gave bad item "..getitem.." :(")
			end
			kartstuff[k_itemtype] = 0
		else
			kartstuff[k_itemtype] = getitem
		end
		kartstuff[k_itemamount] = 1
	end
	--custom on get functions
	if it and it.getfunc then
		--print("running getfunc")
		local status, err = pcall(it.getfunc, p, getitem)
		if not status then
			error(err, 2)
		end
		--crossmod "hooks"
		for i = 1, #libdat.xItemModNamespaces do
			local id = libdat.xItemModNamespaces[i]
			local crossMod = libfn.getXItemModData(id, getitem)
			if crossMod and type(crossMod) == "table" and crossMod.getfunc then
				local status, err = pcall(crossMod.getfunc, p, i)
				if not status then
					error(err, 2)
				end
			end
		end
	end
end

local function xItem_GetOdds(pos, item, mashed, spbrush, p)
	local distvar = 64*14
	local newodds
	local pingame = 0
	local pexiting = 0
	local first
	local second
	local secondist = 0
	
	local libdat = xItemLib
	local libfn = libdat.func
	local itdat = libdat.xItemData[item]
	local itflags = libdat.xItemFlags[item]
	local kartstuff = p.kartstuff
	local pdat = p.xItemData
	
	
	local itemenabled = {
		libfn.getCVar("sneaker"),
		libfn.getCVar("rocketsneaker"),
		libfn.getCVar("invincibility"),
		libfn.getCVar("banana"),
		libfn.getCVar("eggmanmonitor"),
		libfn.getCVar("orbinaut"),
		libfn.getCVar("jawz"),
		libfn.getCVar("mine"),
		libfn.getCVar("ballhog"),
		libfn.getCVar("selfpropelledbomb"),
		libfn.getCVar("grow"),
		libfn.getCVar("shrink"), 
		libfn.getCVar("thundershield"),
		libfn.getCVar("hyudoro"),
		libfn.getCVar("pogospring"),
		libfn.getCVar("kitchensink"),
		libfn.getCVar("triplesneaker"),
		libfn.getCVar("triplebanana"),
		libfn.getCVar("decabanana"),
		libfn.getCVar("tripleorbinaut"),
		libfn.getCVar("quadorbinaut"),
		libfn.getCVar("dualjawz")
	}
	
	if item <= 0 then return 0 end
	
	if (G_BattleGametype()) then
		if pdat.xItem_battleOdds and pdat.xItem_battleOdds[item] then
			newodds = pdat.xItem_battleOdds[item][pos]
		else
			newodds = libdat.xItemOddsBattle[item][pos]
		end
	else
		if pdat.xItem_battleOdds and pdat.xItem_battleOdds[item] then
			newodds = pdat.xItem_battleOdds[item][pos]
		else
			newodds = libdat.xItemOddsRace[item][pos]
		end
	end
	
	newodds = $ << 2
	
	--print("got odds "..newodds)
	
	if item <= table.maxn(itemenabled) and not itemenabled[item] then newodds = 0 end
	if not xItemLib.toggles.xItemToggles[item] then
		newodds = 0
	end
	
	if newodds then
		for pi in players.iterate do
			local piks = pi.kartstuff
			--print("checking player " + pi.name)
			if pi.spectator then continue end
			if (not G_BattleGametype()) or piks[k_bumper] then pingame = $+1 end
			if pi.exiting or (pi.pflags & PF_TIMEOVER == PF_TIMEOVER) then pexiting = $+1 end
			if pi.mo then
				local checkItem = piks[k_itemtype]
				if itflags and (itflags & XIF_UNIQUE == XIF_UNIQUE) and checkItem == item then
					newodds = 0
				end
				if (not G_BattleGametype()) then
					if (piks[k_position] == 1 and (first == nil))
						first = pi.mo
						--print("got first")
					end
					if (piks[k_position] == 2 and (second == nil))
						second = pi.mo
						--print("got second")
					end
				end
			end
		end
		if (first and second) then
			--print("getting secondist")
			local p1 = first
			local p2 = second
			secondist = R_PointToDist2(0, p1.x, R_PointToDist2(p1.y, p1.z, p2.y, p2.z), p2.x) / mapobjectscale
			if (franticitems) then
				secondist = (15 * $) / 14
			end
			secondist = ((28 + (8-pingame)) * $) / 28
			--print("secondist = " + secondist)
		end
		
		--replaces the switch-case with a table of flags, for modularity
		if itflags then
			if (itflags & XIF_POWERITEM == XIF_POWERITEM) then
				--print("item " + item + " is power item")
				newodds = libfn.getPowerOdds($, mashed, spbrush, pingame)
			end
			if (itflags & XIF_COOLDOWNINDIRECT == XIF_COOLDOWNINDIRECT) then
				--print("item " + item + " is timed item")
				if (indirectitemcooldown > 0) then newodds = 0 end
			end
			if (itflags & XIF_COOLDOWNONSTART == XIF_COOLDOWNONSTART) then
				--print("item " + item + " is psuedo-timed item")
				if libfn.getStartCountdown() then newodds = 0 end
			end
		end
	end
	
	local status = true
	--special cases, custom items
	if itdat and itdat.oddsfunc then
		status, newodds = pcall(itdat.oddsfunc, $2, pos, mashed, spbrush, p, secondist, pingame, pexiting)
		if not status then
			error(newodds, 2)
			return 0
		end
	end
	newodds = tonumber($) or 0
	--print("got final odds "..newodds)
	
	distvar = nil
	pingame = nil
	pexiting = nil
	first = nil
	second = nil
	secondist = nil
	return newodds
end

local function setupDistTable(odds, num, disttable, distlen)
	local a = 0
	for i = num, 1, -1 do
		a = $+1
		disttable[distlen + a] = odds
	end
	return a
end

local function xItem_FindUseOdds(p, mashed, pingame, spbrush, dontforcespb)
	local distvar = 64*14
	local i
	local pdis = 0
	local useodds = 1
	local oddsvalid = {}
	local disttable = {}
	local distlen = 0
	--local debug_useoddsstopcode = 0
	
	local FAUXPOS = G_BattleGametype() and 2 or 10
	
	local libdat = xItemLib
	local libfn = libdat.func
	
	local pks = p.kartstuff
	
	--make faux positions valid or not
	for i = 1, FAUXPOS do
		local available = false
		for j = 1, libfn.countItems() do
			--print("checking itemodds for item "..j.." at pos "..i)
			if libfn.getOdds(i, j, mashed, spbrush, p) > 0 then
				available = true
				--if j > 22 then
					--print("item "..j.." is available for pos "..i)
				--end
				break
			end
		end
		oddsvalid[i] = available
	end
	
	--calc distances (honestly kinda weiiiirdddd)
	for p2 in players.iterate do
		if p.mo and p2 and (not p2.spectator) and p2.mo and (p2.kartstuff[k_position] ~= 0) and p2.kartstuff[k_position] < pks[k_position] then
			pdis = $ + R_PointToDist2(0, p.mo.x, R_PointToDist2(p.mo.y, p.mo.z, p2.mo.y, p2.mo.z), p2.mo.x) / mapobjectscale * (pingame - p2.kartstuff[k_position]) / max(1, ((pingame - 1) * (pingame + 1) / 3))
		end
	end
	
	--set up distributions
	if (G_BattleGametype()) then
		if (pks[k_roulettetype] == 1 and oddsvalid[2])
			-- 1 is the extreme odds of player-controlled "Karma" items
			useodds = 2
			--debug_useoddsstopcode = 8
		else
			useodds = 1
			--debug_useoddsstopcode = 9
			if (oddsvalid[1] == false and oddsvalid[2])
				-- try to use karma odds as a fallback
				useodds = 2
				--debug_useoddsstopcode = 10
			end
		end
	else
		if oddsvalid[2] then distlen = $ + libfn.setupDist(2, 1, disttable, distlen) end
		if oddsvalid[3] then distlen = $ + libfn.setupDist(3, 1, disttable, distlen) end
		if oddsvalid[4] then distlen = $ + libfn.setupDist(4, 1, disttable, distlen) end
		if oddsvalid[5] then distlen = $ + libfn.setupDist(5, 2, disttable, distlen) end
		if oddsvalid[6] then distlen = $ + libfn.setupDist(6, 2, disttable, distlen) end
		if oddsvalid[7] then distlen = $ + libfn.setupDist(7, 3, disttable, distlen) end
		if oddsvalid[8] then distlen = $ + libfn.setupDist(8, 3, disttable, distlen) end
		if oddsvalid[9] then distlen = $ + libfn.setupDist(9, 1, disttable, distlen) end
		
		if (franticitems) then -- Frantic items make the distances between everyone artifically higher, for crazier items
			pdis = (15 * $) / 14
		end
		
		if (spbrush) then -- SPB Rush Mode: It's 2nd place's job to catch-up items and make 1st place's job hell
			pdis = (3 * $) >> 1
		end
		
		pdis = ((28 + (8-pingame)) * $) / 28
		
		if pingame == 1 and oddsvalid[1] then					-- Record Attack, or just alone
			useodds = 1
			--debug_useoddsstopcode = 0
			--print("in RA")
		elseif pdis <= 0 then									-- (64*14) *  0 =     0
			--print(disttable[1])
			useodds = disttable[1]
			--debug_useoddsstopcode = 1
		elseif pks[k_position] == 2 and oddsvalid[10] and spbplace == -1 and (indirectitemcooldown == 0) and (not dontforcespb) and pdis > distvar*6 then -- Force SPB in 2nd
			useodds = 10
			--debug_useoddsstopcode = 7
		elseif pdis > distvar * ((12 * distlen) / 14) then -- (64*14) * 12 = 10752
			useodds = disttable[distlen]
			p.playerbot = nil
			--debug_useoddsstopcode = 2
		else
			for i = 1, 12 do
				if pdis <= distvar * ((i * distlen) / 14) then
					--print(((i * distlen) / 14))
					useodds = disttable[((i * distlen) / 14)] + 1
					--debug_useoddsstopcode = 3
					break
				end
			end
		end
	end
	--print(useodds)
	--print("Got useodds "..useodds.." (kart useodds "..(useodds - 1).."). (position: "..p.kartstuff[k_position]..", distance: "..pdis..", stopcode: "..debug_useoddsstopcode..")") 
	--debug_useoddsstopcode = nil
	
	distvar = nil
	i = nil
	pdis = nil
	distlen = nil
	
	return useodds
end

local function xItem_ItemRoulette(p, cmd)
	local i
	local pingame = 0
	local roulettestop
	local useodds = 0
	local spawnchance = {}
	local totalspawnchance = 0
	local bestbumper = 0
	local mashed = 0
	local dontforcespb = false
	local spbrush = false
	
	local kartstuff = p.kartstuff
	local pdat = p.xItemData
	local libdat = xItemLib
	local libfn = libdat.func
	
	if leveltime == 0 then
		pdat.xItem_roulette = 0
		libfn.resetItemOdds(0, p)
	end
	if kartstuff[k_itemroulette] and pdat.xItem_roulette == 0 then
		pdat.xItem_roulette = kartstuff[k_itemroulette]
		kartstuff[k_itemroulette] = 4
		if pdat.xItem_resetOddsNextRoll == -1 then
			libfn.resetItemOdds(0, p)
			pdat.xItem_resetOddsNextRoll = 0
		end
	end
	if kartstuff[k_itemroulette] and kartstuff[k_itemroulette] < 4 and (kartstuff[k_roulettetype] == 2) then
		pdat.xItem_roulette = kartstuff[k_itemroulette]
		kartstuff[k_itemroulette] = 4
		kartstuff[k_roulettetype] = 2
		if pdat.xItem_resetOddsNextRoll == -1 then
			libfn.resetItemOdds(0, p)
			pdat.xItem_resetOddsNextRoll = 0
		end
	end
	
	if pdat.xItem_roulette then
		kartstuff[k_itemroulette] = 4
		pdat.xItem_roulette = $+1
		--print(p.name.."'s roulette type is "..kartstuff[k_roulettetype])
	else
		return
	end
	
	-- Gotta check how many players are active at this moment.
	for p in players.iterate do
		if p.spectator then continue end
		pingame = $+1
		p.spawntowaypoint = true
		if (p.exiting) then
			dontforcespb = true
		end
		if (kartstuff[k_bumper] > bestbumper)
			bestbumper = kartstuff[k_bumper]
		end
	end
	if (pingame <= 2)
		dontforcespb = true
	end

	
	-- This makes the roulette produce the random noises.
	if P_IsLocalPlayer(p) and pdat.xItem_roulette % 3 == 1 then
		S_StartSound(nil, sfx_itrol1 + ((pdat.xItem_roulette / 3) % 8), p)
	end
	
	roulettestop = TICRATE + (3*(pingame - kartstuff[k_position]))
	if (G_RaceGametype())
		spbrush = (spbplace ~= -1 and kartstuff[k_position] == spbplace+1)
	end
	
	local splitplaynum = p.splitscreenindex + 1
	if P_IsLocalPlayer(p) and ((pdat.xItem_roulette < 4) or (pdat.xItem_roulette % 3 == 0)) then
		useodds = libfn.findUseOdds(p, 0, pingame, spbrush, dontforcespb)
		availableItems[splitplaynum] = libfn.hudFindRouletteItems(p, useodds, 0, spbrush)
		--print("dynroulette for player "..p.name)
	end
	--print("roulette tic "..pdat.xItem_roulette)
	
	if ((cmd.buttons & BT_ATTACK) and not (kartstuff[k_eggmanheld] or kartstuff[k_itemheld]) and pdat.xItem_roulette >= roulettestop and not modeattacking) then
		-- Mashing reduces your chances for the good items
		mashed = FixedDiv(pdat.xItem_roulette*FRACUNIT, ((TICRATE*3)+roulettestop)*FRACUNIT) - FRACUNIT
	elseif (not(pdat.xItem_roulette >= (TICRATE*3))) then
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil
		return
	end
	
	useodds = libfn.findUseOdds(p, mashed, pingame, spbrush, dontforcespb)
	
	if (kartstuff[k_roulettetype] == 2) then -- Fake items
		kartstuff[k_eggmanexplode] = max($, 4*TICRATE) --in case this runs after stuff like egg panic
		kartstuff[k_itemroulette] = 0
		pdat.xItem_roulette = 0
		kartstuff[k_roulettetype] = 0
		S_StartSound(nil, sfx_itrole, p)
		pdat.xItem_itemSlotLocked = false --just in case
		if pdat.xItem_resetOddsNextRoll == 1 then
			libfn.resetItemOdds(0, p)
			pdat.xItem_resetOddsNextRoll = 0
		end
		
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil
		return
	end
	
	--debugitem
	if (libdat.toggles.debugItem ~= 0 and not modeattacking) then
		local di = min(libdat.toggles.debugItem, libfn.countItems())
		libfn.getItemResult(p, di)
		kartstuff[k_itemamount] = libdat.cvars.dItemDebugAmt.value
		kartstuff[k_itemblink] = TICRATE
		kartstuff[k_itemblinkmode] = 2
		kartstuff[k_itemroulette] = 0
		pdat.xItem_roulette = 0
		kartstuff[k_roulettetype] = 0
		S_StartSound(nil, sfx_dbgsal, p)
		if pdat.xItem_resetOddsNextRoll == 1 then
			libfn.resetItemOdds(0, p)
			pdat.xItem_resetOddsNextRoll = 0
		end
		
		di = nil
		i = nil
		pingame = nil
		roulettestop = nil
		useodds = nil
		totalspawnchance = nil
		bestbumper = nil
		mashed = nil
		dontforcespb = nil
		spbrush = nil
		return
	end
	
	for i = 1, libfn.countItems() do
		local o = libfn.getOdds(useodds, i, mashed, spbrush, p)
		if o > 0 then
			totalspawnchance = $ + o
		end
		spawnchance[i] = totalspawnchance
	end
	
	-- Award the player whatever power is rolled
	if (totalspawnchance > 0) then
		local spawnidx = P_RandomKey(totalspawnchance)
		for i = 1, libfn.countItems() do
			if spawnchance[i] > spawnidx then 
				--print("GOT ITEM "..i)
				libfn.getItemResult(p, i)
				break 
			end
		end
		spawnidx = nil
	else
		kartstuff[k_itemtype] = -1
		kartstuff[k_itemamount] = 1
	end
	
	if pdat.xItem_resetOddsNextRoll == 1 then
		libfn.resetItemOdds(0, p)
		pdat.xItem_resetOddsNextRoll = 0
	end
	
	S_StartSound(nil, ((kartstuff[k_roulettetype] == 1) and sfx_itrolk or (mashed and sfx_itrolm or sfx_itrolf)), p)
	
	kartstuff[k_itemblink] = TICRATE
	kartstuff[k_itemblinkmode] = ((kartstuff[k_roulettetype] == 1) and 2 or (mashed and 1 or 0))
	
	kartstuff[k_itemroulette] = 0
	pdat.xItem_roulette = 0  --Since we're done, clear the roulette number
	kartstuff[k_roulettetype] = 0 --This too
	
	i = nil
	pingame = nil
	roulettestop = nil
	useodds = nil
	totalspawnchance = nil
	bestbumper = nil
	mashed = nil
	dontforcespb = nil
	spbrush = nil
end

local function xItem_handleDistributionDebugger(pa)
	local libdat = xItemLib
	local libfn = libdat.func
	if libdat.cvars.bItemDebugDistrib.value and P_IsLocalPlayer(pa) and (pa == consoleplayer) then
		local pingame = 0
		local dontforcespb = false
		local spbrush = false
		local kartstuff = pa.kartstuff
		local bestbumper = 0

		for p in players.iterate do
			if p.spectator then continue end
			pingame = $+1
			p.spawntowaypoint = true
			if (p.exiting) then
				dontforcespb = true
			end
			if (kartstuff[k_bumper] > bestbumper)
				bestbumper = kartstuff[k_bumper]
			end
		end
		if (pingame <= 2)
			dontforcespb = true
		end
		if (G_RaceGametype())
			spbrush = (spbplace ~= -1 and kartstuff[k_position] == spbplace+1)
		end

		local useodds = libfn.findUseOdds(pa, 0, pingame, spbrush, dontforcespb)
		debuggerDistributions = libfn.findItemDistributions(pa, useodds, 0, spbrush)
	end
end

local function canUseItem(p)
	return (p and p.mo and p.mo.health > 0 and (not p.spectator) and (not p.exiting)
		and p.kartstuff[k_spinouttimer] == 0 and p.kartstuff[k_squishedtimer] == 0 and p.kartstuff[k_respawn] == 0
		and (not p.xItemData.xItem_attackedDuringRoll))
end

local function xItem_BasicItemHandler(p, cmd)
	local pdat = p.xItemData
	local kartstuff = p.kartstuff
	
	local libdat = xItemLib
	local libfunc = libdat.func
	
	local item = kartstuff[k_itemtype]
	local itdat = libdat.xItemData[item]
	local itflags = libdat.xItemFlags[item]
	local canUseItem = libfunc.canUseItem
	
	local attackJustDown = ((cmd.buttons & BT_ATTACK) and pdat.xItem_pressedUse == 0)
	local attackDown = (cmd.buttons & BT_ATTACK)
	local attackReleased = ((pdat.xItem_pressedUse) and not (cmd.buttons & BT_ATTACK))
	local noHyudoro = (p.kartstuff[k_stolentimer] == 0 and p.kartstuff[k_stealingtimer] == 0)
	
	local status, err
	if itdat and itdat.preusefunc then
		if canUseItem(p) and noHyudoro then
			if attackDown then
				status, err = pcall(itdat.preusefunc, p, cmd, pdat.xItem_pressedUse, attackJustDown)
				if not status then
					error(err, 2)
				end
				--crossmod "hooks"
				for i = 1, #libdat.xItemModNamespaces do
					local id = libdat.xItemModNamespaces[i]
					local crossMod = libfunc.getXItemModData(id, item)
					if crossMod and type(crossMod) == "table" and crossMod.preusefunc then
						status, err = pcall(crossMod.preusefunc, p, cmd, pdat.xItem_pressedUse, attackJustDown)
						if not status then
							error(err, 2)
						end
					end
				end
			elseif attackReleased then
				if itdat and itdat.usefunc then
					status, err = pcall(itdat.usefunc, p, cmd)
					if not status then
						error(err, 2)
					end
				end
				if itflags and (itflags & XIF_LOCKONUSE == XIF_LOCKONUSE) then
					pdat.xItem_itemSlotLocked = true
				end
				--crossmod "hooks"
				for i = 1, #libdat.xItemModNamespaces do
					local id = libdat.xItemModNamespaces[i]
					local crossMod = libfunc.getXItemModData(id, item)
					if crossMod and type(crossMod) == "table" and crossMod.usefunc then
						status, err = pcall(crossMod.usefunc, p, cmd)
						if not status then
							error(err, 2)
						end
					end
				end
			end
		end
	else
		if canUseItem(p) and attackJustDown and noHyudoro then
			--print("using item "..item)
			if itflags and (itflags & XIF_LOCKONUSE == XIF_LOCKONUSE) then
				pdat.xItem_itemSlotLocked = true
			end
			if itdat and itdat.usefunc then
				--print("has a function")
				status, err = pcall(itdat.usefunc, p, cmd)
				if not status then
					error(err, 2)
				end
			end
			--crossmod "hooks"
			for i = 1, #libdat.xItemModNamespaces do
				local id = libdat.xItemModNamespaces[i]
				local crossMod = libfunc.getXItemModData(id, item)
				if crossMod and type(crossMod) == "table" and crossMod.usefunc then
					status, err = pcall(crossMod.usefunc, p, cmd)
					if not status then
						error(err, 2)
					end
				end
			end
		end
	end
	
	if attackDown and (pdat.xItem_roulette > 0 or p.kartstuff[k_respawn] ~= 0) then
		pdat.xItem_attackedDuringRoll = true
	end
	if (not attackDown) and pdat.xItem_roulette == 0 and p.kartstuff[k_respawn] == 0 and pdat.xItem_attackedDuringRoll then
		pdat.xItem_attackedDuringRoll = false
	end
	p.findwaypoint, p.racebot = nil, nil

	if ((pdat.xItem_pressedUse) and not attackDown) then
		pdat.xItem_pressedUse = 0
	elseif attackDown then
		pdat.xItem_pressedUse = $+1
	end
end

--port of item hud to lua
--now even more modular and extensible, and specifically made for xItemLib

local splitplayers = {}
local function splitnum(p)
	for i = 1, #splitplayers do
		if splitplayers[i] == p
			return i-1
		end
	end
end

local BASEVIDWIDTH  = 320
local BASEVIDHEIGHT = 200

local ITEM_X = 5
local ITEM_Y = 5

local ITEM1_X = -9
local ITEM1_Y = -8

local ITEM2_X = BASEVIDWIDTH-39
local ITEM2_Y = -8
local colormode = TC_RAINBOW
local localcolor = SKINCOLOR_NONE

local function xItem_FindHudFlags(v, p, c)
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		if c.pnum == 1 then
			return ITEM_X, ITEM_Y, V_SNAPTOTOP|V_SNAPTOLEFT, false
		else
			return ITEM_X, ITEM_Y, V_SNAPTOLEFT|V_SPLITSCREEN, false
		end
	else -- now we're having a fun game.
		if c.pnum == 1 or c.pnum == 3 then -- If we are P1 or P3...
			return ITEM1_X, ITEM1_Y, (c.pnum == 3 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTOLEFT, false	-- flip P3 to the bottom.	
		else -- else, that means we're P2 or P4.
			return ITEM2_X, ITEM2_Y, (c.pnum == 4 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTORIGHT, true
		end
	end
end

local function xItem_DrawItemBox(v, p, c)
	local fx, fy, fflags = xItemLib.func.hudFindFlags(v, p, c)
	local localbg = {v.cachePatch("K_ITBG"), v.cachePatch("K_ISBG")}
	
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		v.draw(fx, fy, localbg[1], V_HUDTRANS|fflags)
	else -- now we're having a fun game.
		v.draw(fx, fy, localbg[2], V_HUDTRANS|fflags)
	end
end

local function xItem_DrawItem(v, p, c, i, blink, disableBox)
	disableBox = $ or false
	local fx, fy, fflags, flipamount = xItemLib.func.hudFindFlags(v, p, c)
	local itTflags = V_HUDTRANS
	local offset = ((splitscreen > 1) and 2 or 1)
	local get
	
	local kp_itemx = v.cachePatch("K_ITX")
	local localmul = {v.cachePatch("K_ITMUL"), v.cachePatch("K_ISMUL")}
	local kp_itemtimer = {v.cachePatch("K_ITIMER"), v.cachePatch("K_ISIMER")}
	
	local rouletteAnim = false
	local libdat = xItemLib
	local itflags = libdat.xItemFlags
	
	local kartstuff = p.kartstuff
	
	if i == nil then
		i = kartstuff[k_itemtype]
	end
	
	local colour = v.getColormap(TC_DEFAULT, SKINCOLOR_NONE)
	if i and p and itflags[i] and (itflags[i] & XIF_COLPATCH2PLAYER == XIF_COLPATCH2PLAYER) then 
		--print("item "..i.." has XIF_COLPATCH2PLAYER")
		colour = v.getColormap(TC_DEFAULT, p.skincolor)
	end
	
	local s, icn
	if i > 0 then
		local idx = 0
		if itflags[i] and (itflags[i] & XIF_ICONFORAMT) then 
			idx = kartstuff[k_itemamount]
		else
			idx = leveltime
		end
		s, get = libdat.func.getSinglePatch(i, splitscreen >= 2, idx)
		icn = v.cachePatch(s)
	end
	if icn == nil then icn = v.cachePatch("K_ITSAD") end
	if p.xItemData.xItem_roulette then
		--print("spinning, drawing item "..i)
		colormode = TC_RAINBOW
		localcolor = p.skincolor or SKINCOLOR_GREY
		colour = v.getColormap(colormode, localcolor)
		if libdat.cvars.bRouletteAnim.value then
			rouletteAnim = true
		end
	end
	
	if kartstuff[k_itemblink] and leveltime%2 == 1 then
		colormode = TC_BLINK
		if kartstuff[k_itemblinkmode] == 2 then
			localcolor = 1 + (leveltime % (MAXSKINCOLORS-1))
		elseif kartstuff[k_itemblinkmode] == 1 then
			localcolor = SKINCOLOR_RED
		else
			localcolor = SKINCOLOR_WHITE
		end
		colour = v.getColormap(colormode, localcolor)
	end
	
	if not disableBox then
		libdat.func.hudDrawItemBox(v, p, c)
	end
	
	local yShift = ((leveltime%3)-1)
	if splitscreen < 2 then 
		if rouletteAnim then
			fy = $ + 10*yShift
			if yShift then itTflags = V_HUDTRANSHALF end
		end
	else 
		if rouletteAnim then
			fy = $ + 4*yShift
			if yShift then itTflags = V_HUDTRANSHALF end
		end
	end
	
	--fuck me
	if kartstuff[k_itemamount] > 1 then
		v.draw(fx + (flipamount and 48 or 0), fy, localmul[offset], V_HUDTRANS|fflags|(flipamount and V_FLIP or 0))
		if (blink and leveltime % blink == 0) or (not blink) and blink ~= -1 then
			v.draw(fx, fy, icn, itTflags|fflags, colour)
		end
		if offset == 2 then
			if flipamount then	-- reminder that this is for 3/4p's right end of the screen.
				v.drawString(fx+2, fy+31, "x" + kartstuff[k_itemamount], V_ALLOWLOWERCASE|V_HUDTRANS|fflags)
			else
				v.drawString(fx+24, fy+31, "x" + kartstuff[k_itemamount], V_ALLOWLOWERCASE|V_HUDTRANS|fflags)
			end
		else
			if (not (itflags[i] and (itflags[i] & XIF_ICONFORAMT))) or (itflags[i] and (itflags[i] & XIF_ICONFORAMT) and kartstuff[k_itemamount] > get) then
				v.draw(fy+28, fy+41, kp_itemx, V_HUDTRANS|fflags)
				v.drawKartString(fx+38, fy+36, kartstuff[k_itemamount], V_HUDTRANS|fflags)
			end
		end
	else
		if (blink and leveltime % blink == 0) or (not blink) and blink ~= -1 then
			v.draw(fx, fy, icn, itTflags|fflags, colour)
		end
	end
	
	--timer bar
	local offset = 1
	local barlength = 26
	local height = 2
	local x = 11
	local y = 35
	if splitscreen > 1 then
		offset = 2
		barlength = 12
		height = 1
		x = 17
		y = 27
	end
	
	local itembar = p.xItemData.xItem_timerBar
	local maxitembar = p.xItemData.xItem_maxTimerBar
	
	if itembar > 0 then
		local fill = ((itembar*barlength)/maxitembar)
		local length = min(barlength, fill)
		
		v.draw(fx+x, fy+y, kp_itemtimer[offset], V_HUDTRANS|fflags)
		-- The left dark "AA" edge
		if length == 2 then
			v.drawFill(fx+x+1, fy+y+1, 2, height, 12|fflags)
		else
			v.drawFill(fx+x+1, fy+y+1, 1, height, 12|fflags)
		end
		-- The bar itself
		if (length > 2) then
			v.drawFill(fx+x+length, fy+y+1, 1, height, 12|fflags) -- the right one
			if (height == 2) then
				v.drawFill(fx+x+2, fy+y+2, length-2, 1, 8|fflags) -- the dulled underside
			end
			v.drawFill(fx+x+2, fy+y+1, length-2, 1, 120|fflags) -- the shine
		end
	end
	p.xItemData.xItem_timerBar = 0
	p.xItemData.xItem_maxTimerBar = 0
end

--had a look at eggpanic to make sure this works clean with that too out of the box
local function xItem_drawEggTimer(v, p, c)
	local fx, fy, fflags, flipamount = xItemLib.func.hudFindFlags(v, p, c)
	
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		v.draw(fx+17, fy+13, v.cachePatch("K_EGGN" .. min(G_TicsToSeconds(p.kartstuff[k_eggmanexplode]), 5)), fflags|V_HUDTRANS)
	else -- now we're having a fun game.
		v.draw(fx+17, fy+13, v.cachePatch("K_EGGN" .. min(G_TicsToSeconds(p.kartstuff[k_eggmanexplode]), 5) ), fflags|V_HUDTRANS)
	end
end

local function xItem_drawSad(v, p, c)
	local fx, fy, fflags, flipamount = xItemLib.func.hudFindFlags(v, p, c)
	
	if splitscreen < 2 then
		v.draw(fx, fy, v.cachePatch("K_ITSAD"), fflags|V_HUDTRANS)
	else
		v.draw(fx, fy+13, v.cachePatch("K_ISSAD"), fflags|V_HUDTRANS)
	end
end

local function findItemDistributions(p, useodds, spbrush)
	local distributions = {
		totalodds = 0,
		it = {},
		odds = {}
	}
	local libdat = xItemLib
	local libfn = xItemLib.func
	local itdat = libdat.xItemData
	local cv = libdat.cvars
	local tg = libdat.toggles
	
	if tg.debugItem then
		local di = min(tg.debugItem, libfn.countItems())
		distributions.it = {di}
		distributions.odds = {1}
		distributions.totalodds = 1
		return distributions
	end

	for i = 1, libfn.countItems() do
		local odds = libfn.getOdds(useodds, i, 0, spbrush, p)
		if odds > 0 then
			table.insert(distributions.it, i)
			table.insert(distributions.odds, odds)
			distributions.totalodds = $ + odds
		end
	end

	return distributions
end

local function xItem_drawDistributions(v, p, c)
	if not xItemLib.cvars.bItemDebugDistrib.value then return end
	if p ~= consoleplayer then return end
	local libdat = xItemLib
	local libfn = xItemLib.func
	local itdat = libdat.xItemData

	local fx = 40
	local fy = -10
	local totalodds = debuggerDistributions.totalodds
	for i = 1, #(debuggerDistributions.it) do
		local it = debuggerDistributions.it[i]
		local odds = debuggerDistributions.odds[i]
		local perc = FixedMul(10000*FRACUNIT, FixedDiv(odds, totalodds)) >> FRACBITS

		local s, get = libfn.getSinglePatch(it, true, 1)
		local icn = v.cachePatch(s)
		v.draw(fx + 28 * ((i-1) % 10), fy + 30 * ((i-1) / 10), icn, V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS)
		v.drawString(fx + 28 * ((i-1) % 10) + 38, fy + 30 * ((i-1) / 10) + 26, (perc/100) + "." + (perc%100) + "%", V_SNAPTOTOP|V_SNAPTOLEFT|V_50TRANS, "small-right")
	end
end

local function findAvailableRoulettePatches(p, useodds, spbrush)
	local available = {}
	local libdat = xItemLib
	local libfn = xItemLib.func
	local itdat = libdat.xItemData
	local cv = libdat.cvars
	local tg = libdat.toggles
	
	if cv.bEnhancedRoulette.value and tg.debugItem then
		local di = min(tg.debugItem, libfn.countItems())
		available = {di}
		return available
	end
	
	for i = 1, libfn.countItems() do
		local dat = itdat[i].showInRoulette
		if not dat then continue end
		if type(dat) == "function" then
			if dat(p) then
				table.insert(available, i)
				continue
			end
		else
			table.insert(available, i)
			continue
		end
	end
	
	--CTGP-7 roulette
	if cv.bEnhancedRoulette.value and useodds then
		local eav = {}
		for j = 1, #available do
			if libfn.getOdds(useodds, available[j], 0, spbrush, p) > 0 then
				table.insert(eav, available[j])
				continue
			end
		end
		available = eav
	end
	return available
end

local function xItem_hudMain(v, p, c)
	local libdat = xItemLib
	local libfn = libdat.func
	local playerdat = p.xItemData
	
	hud.disable("item")
	local status
	local err = false
	for i = 1, #libdat.xItemModNamespaces do
		local id = libdat.xItemModNamespaces[i]
		local crossMod = libfn.getXItemModData(id, 1)
		if crossMod and type(crossMod) == "table" and crossMod.hudoverride then
			status, err = pcall(crossMod.hudoverride, v, p, c)
			if not status then
				error(err, 2)
			end
		end
		if err then return end
	end
	if p.xItemData.enableHud then
		splitplayers[#splitplayers+1] = p
		local kartstuff = p.kartstuff
		if playerdat then
			--handle vanilla special cases first
			if kartstuff[k_stolentimer] > 0 then
				libfn.hudDrawItem(v, p, c, 14, 2)
			elseif kartstuff[k_stealingtimer] > 0 and leveltime % 2 then
				libfn.hudDrawItem(v, p, c, 14)
			elseif kartstuff[k_eggmanexplode] then
				libfn.hudDrawItem(v, p, c, 5, 2)
				libfn.hudDrawEgg(v, p, c)
			elseif kartstuff[k_rocketsneakertimer] then
				libfn.hudDrawItem(v, p, c, 2, 2)
				playerdat.xItem_timerBar = kartstuff[k_rocketsneakertimer]
				playerdat.xItem_maxTimerBar = 8*3*TICRATE
			elseif kartstuff[k_growshrinktimer] > 0 then
				libfn.hudDrawItem(v, p, c, 11, 2)
				if kartstuff[k_growcancel] > 0 then
					playerdat.xItem_timerBar = kartstuff[k_growcancel]
					playerdat.xItem_maxTimerBar = 26
				end
			elseif kartstuff[k_sadtimer] or kartstuff[k_itemtype] == -1 then
				libfn.hudDrawItem(v, p, c, 0, -1)
				if leveltime % 2 then
					libfn.hudDrawSad(v, p, c)
				end
			--custom item hud drawer here (this only runs when the item is still in the slot, if special timers are involved like above the mod should handle that by itself)
			elseif libdat.xItemData[kartstuff[k_itemtype]] and libdat.xItemData[kartstuff[k_itemtype]].hudfunc then
				pcall(libdat.xItemData[kartstuff[k_itemtype]].hudfunc, v, p, c)
			--draw the roulette
			elseif playerdat.xItem_roulette then
				local av = availableItems[p.splitscreenindex + 1]
				--print(splitnum(p))
				if av and table.maxn(av) then
					libfn.hudDrawItem(v, p, c, av[((leveltime/3) % table.maxn(av)) + 1])
				end
			--draw the held item
			elseif kartstuff[k_itemtype] then
				if kartstuff[k_itemheld] then
					libfn.hudDrawItem(v, p, c, kartstuff[k_itemtype], 2)
				else
					libfn.hudDrawItem(v, p, c, kartstuff[k_itemtype])
				end
			end
			--crossmod "hooks"
			if kartstuff[k_itemtype] then
				for i = 1, #libdat.xItemModNamespaces do
					local id = libdat.xItemModNamespaces[i]
					local crossMod = libfn.getXItemModData(id, kartstuff[k_itemtype])
					if crossMod and type(crossMod) == "table" and crossMod.hudfunc then
						status, err = pcall(crossMod.hudfunc, v, p, c)
						if not status then
							error(err, 2)
						end
					end
				end
			end
		end
	end
	--debugger goes last
	libfn.xItem_drawDistributions(v, p, c)
end

local function playerThinkFrame(p)
	local libfn = xItemLib.func
	if not p.xItemData then
		p.xItemData = {
			xItem_roulette = 0,
			xItem_rouletteType = 0,
			xItem_attackedDuringRoll = false,
			
			xItem_raceOdds = nil,
			xItem_battleOdds = nil,
			xItem_resetOddsNextRoll = 0, --0 = no, -1 = before rolling for an item, 1 = after rolling for an item
			
			xItem_blink = 0,
			xItem_blinkMode = 0,
			xItem_timerBar = 0,
			xItem_maxTimerBar = 0,
			
			xItem_pressedUse = 0,
			
			xItem_itemSlotLocked = false,
			
			xItem_Hud_availableItems = {},
			
			enableHud = true, --enables / disables the xItemLib item hud, as a replacement for hud.disable("item") and hud.enable("item")
		}

		--quick init step even though this may not do much
		libfn.getCVar("sneaker")
		libfn.getCVar("rocketsneaker")
		libfn.getCVar("invincibility")
		libfn.getCVar("banana")
		libfn.getCVar("eggmanmonitor")
		libfn.getCVar("orbinaut")
		libfn.getCVar("jawz")
		libfn.getCVar("mine")
		libfn.getCVar("ballhog")
		libfn.getCVar("selfpropelledbomb")
		libfn.getCVar("grow")
		libfn.getCVar("shrink")
		libfn.getCVar("thundershield")
		libfn.getCVar("hyudoro")
		libfn.getCVar("pogospring")
		libfn.getCVar("kitchensink")
		libfn.getCVar("triplesneaker")
		libfn.getCVar("triplebanana")
		libfn.getCVar("decabanana")
		libfn.getCVar("tripleorbinaut")
		libfn.getCVar("quadorbinaut")
		libfn.getCVar("dualjawz")
	end
	libfn.xItem_handleDistributionDebugger(p)
	libfn.attackHandler(p, p.cmd)
	libfn.doRoulette(p, p.cmd)
end

if not xItemLib then
	print("\3\135xItemLib\n\128by \130minenice\128")
	print("Initial xItemLib loading...")
	print("Library version \130"..currLibVer)
	
	rawset(_G, "xItemLib", {
		gLibVersion = currLibVer,
		func = {},
		xItems = {},
		xItemNamespaces = {},
		xItemData = {}, --holds an item name, functions (on get (when rolled), on use, hud function), default raceodds, default battleodds
		xItemPatch = {}, --format is {{tics, bigpatch1, bigpatch2, ...}, {tics, smallpatch1, smallpatch2, ...}}
		xItemFlags = {},
		
		--extra item data
		xItemModNamespaces = {},
		xItemCrossData = {
			modData = {},
			itemData = {},
		}, 
		
		xItemOddsRace = {},
		xItemOddsBattle = {},
		cvars = {},
		toggles = {
			debugItem = 0,
			xItemToggles = {},
		}
	})
	
	xItemLib.func.countItems = getLoadedItemAmount
	xItemLib.func.setPatch = addItemPatch
	xItemLib.func.getPatch = getItemPatch
	xItemLib.func.getSinglePatch = getItemPatchSingle
	xItemLib.func.addItem = addXItem
	xItemLib.func.resetItemOdds = resetOddsForItem
	xItemLib.func.setPlayerOddsForItem = setPlayerOddsForItem
	xItemLib.func.getPlayerScaling = playerScaling
	xItemLib.func.getStartCountdown = checkStartCooldown
	xItemLib.func.getPowerOdds = checkPowerItemOdds
	xItemLib.func.floatingItemThinker = floatingItemThinker
	xItemLib.func.floatingItemSpecial = floatingItemSpecial
	xItemLib.func.itemBoxSpecial = itemBoxSpecial
	xItemLib.func.getItemResult = xItem_GetItemResult
	xItemLib.func.getOdds = xItem_GetOdds
	xItemLib.func.setupDist = setupDistTable
	xItemLib.func.findUseOdds = xItem_FindUseOdds
	xItemLib.func.doRoulette = xItem_ItemRoulette
	xItemLib.func.attackHandler = xItem_BasicItemHandler
	xItemLib.func.hudFindFlags = xItem_FindHudFlags
	xItemLib.func.hudDrawItemBox = xItem_DrawItemBox
	xItemLib.func.hudDrawItem = xItem_DrawItem
	xItemLib.func.hudDrawEgg = xItem_drawEggTimer
	xItemLib.func.hudDrawSad = xItem_drawSad
	xItemLib.func.hudMain = xItem_hudMain
	xItemLib.func.playerThinker = playerThinkFrame
	xItemLib.func.hudFindRouletteItems = findAvailableRoulettePatches
	xItemLib.func.findItemByNamespace = findItemByNamespace
	xItemLib.func.findItemByFriendlyName = findItemByFriendlyName
	xItemLib.func.getCVar = getCVar
	xItemLib.func.findItemDistributions = findItemDistributions
	xItemLib.func.xItem_drawDistributions = xItem_drawDistributions
	xItemLib.func.xItem_handleDistributionDebugger = xItem_handleDistributionDebugger
	--here you go yoshimo lmao
	xItemLib.func.canUseItem = canUseItem
	--a
	xItemLib.func.floatingXItemThinker = floatingXItemThinker
	xItemLib.func.floatingXItemSpecial = floatingXItemSpecial
	xItemLib.func.playerArrowThinker = playerArrowThinker
	xItemLib.func.vanillaArrowThinker = vanillaArrowThinker
	--crossmod support
	xItemLib.func.addXItemMod = addXItemMod
	xItemLib.func.setXItemModData = setXItemModData
	xItemLib.func.getXItemModData = getXItemModData
	
	local function setDebugItem(p, cv)
		local i = tonumber(cv)
		local t
		if not i then
			i = tostring(cv)
			--print(i)
			--for all the calls here we're ignoring errors
			--first search by friendly name
			t = xItemLib.func.findItemByFriendlyName(i, true)
			if t then
				if #t == 1 then
					xItemLib.toggles.debugItem = t[1]
					print("Set debugitem to \x82"..xItemLib.xItemData[t[1]].name.."\x80")
					return
				else
					table.sort(t)
					local s = ""
					CONS_Printf(p, "Found too many items! Did you mean:")
					for x, it in ipairs(t) do
						s = $..(xItemLib.xItemData[it].name.." (ID \x82".. it.."\x80)")
						if x ~= #t then
							s = $..", \n"
						end
					end
					CONS_Printf(p, s)
					
					s = nil
					return
				end
			end
			--then by internal
			t = xItemLib.func.findItemByNamespace(i, true)
			if t > 0 then
				xItemLib.toggles.debugItem = t
				print("Set debugitem to \x82"..xItemLib.xItemData[t].name.."\x80")
				return
			end
		end
		--then just vanilla kart behaviour
		i = max(min(tonumber(i) or 0, xItemLib.func.countItems()), 0)
		xItemLib.toggles.debugItem = i
		if i > 0 then
			print("Set debugitem to \x82"..xItemLib.xItemData[i].name.."\x80")
		else
			print("Disabled debugitem")
		end
		
		t = nil
		i = nil
	end
	COM_AddCommand("xitemdebugitem", setDebugItem, 1) --equivalent to kartdebugitem, can also take item names
	
	local function toggleItem(p, cv)
		local i = tonumber(cv)
		local t
		if not i then
			i = tostring(cv)
			t = xItemLib.func.findItemByFriendlyName(i, true)
			if t then
				if #t == 1 then
					xItemLib.toggles.xItemToggles[t[1]] = (not $)
					print("\x82"..xItemLib.xItemData[t[1]].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t[1]] and "enabled" or "disabled"))
					return
				else
					table.sort(t)
					local s = ""
					CONS_Printf(p, "Found too many items! Did you mean:")
					for x, it in ipairs(t) do
						s = $..(xItemLib.xItemData[it].name.." (ID \x82".. it.."\x80)")
						if x ~= #t then
							s = $..", \n"
						end
					end
					CONS_Printf(p, s)
					
					s = nil
					return
				end
			end
			--then by internal
			t = xItemLib.func.findItemByNamespace(i, true)
			if t > 0 then
				xItemLib.toggles.xItemToggles[t] = (not $)
				print("\x82"..xItemLib.xItemData[y].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t] and "enabled" or "disabled"))
				return
			end
		end
		--then just vanilla kart behaviour
		i = max(min(tonumber(i) or 0, xItemLib.func.countItems()), 0)
		xItemLib.toggles.xItemToggles[i] = (not $)
		if i > 0 then
			print("\x82"..xItemLib.xItemData[i].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[i] and "enabled" or "disabled"))
		end
		
		t = nil
		i = nil
	end
	COM_AddCommand("togglexitem", toggleItem, 1) --equivalent to kartdebugitem, can also take item names
	
	
	local function listItem(p)
		CONS_Printf(p, "\n\3\135xItemLib\n\128by \130minenice\128")
		CONS_Printf(p, "Library version \130"..currLibVer)
		
		CONS_Printf(p, "\nNow listing all loaded xItems:\n----------------")
		local ndat = xItemLib.xItemNamespaces
		local itdat = xItemLib.xItemData
		local idat
		local nsp = ""
		for i = 1, xItemLib.func.countItems() do
			idat = itdat[i]
			for k, v in pairs(ndat) do
				if i == v then
					nsp = k
				end
			end
			CONS_Printf(p, "\x82"..idat.name.."\x80 (Item ID \x82"..i.."\x80, namespaced \134"..nsp.."\x80)")
		end
	end
	COM_AddCommand("listxitem", listItem, 4) --prints all item names to the console
	
	xItemLib.cvars.dItemDebugAmt = CV_RegisterVar({ --equivalent to kartdebugamount
		name = "xitemdebugamount",
		defaultvalue = "1",
		flags = CV_NETVAR,
		possiblevalue = CV_Natural
	})
	xItemLib.cvars.bEnhancedRoulette = CV_RegisterVar({ --enables the CTGP-7 style enhanced roulette
		name = "xitemroulette",
		defaultvalue = "No",
		possiblevalue = CV_YesNo
	})
	xItemLib.cvars.bRouletteAnim = CV_RegisterVar({ --enables the fancy roulette animation
		name = "xitemrouletteanim",
		defaultvalue = "No",
		possiblevalue = CV_YesNo
	})
	xItemLib.cvars.bItemDebugDistrib = CV_RegisterVar({ --distribution debugger
		name = "xitemdebugdistributions",
		defaultvalue = "No",
		flags = CV_NETVAR,
		possiblevalue = CV_YesNo
	})
	
	local function spbOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		local distvar = 64*14
		if ((indirectitemcooldown > 0) or (pexiting > 0) or (secondist/distvar < 3)) and (pos ~= 10) then -- Force SPB
			nod = 0
			--print("disabled SPB (indirectitemcooldown = " + indirectitemcooldown + ", secondist/distvar = " + secondist/distvar +", pexiting = " + pexiting + ")")
		else
			nod = $ * min((secondist/distvar)-4, 3)
		end
		--print("spb odds is "..nod)
		return nod
	end
	
	local function hyuuOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		if (hyubgone > 0) or (pingame-1 <= pexiting) then
			nod = 0
			--print("disabled hyuu (hyubgone = " + hyubgone + ", pingame = " + pingame +", pexiting = " + pexiting + ")")
		end
		--print("hyuu odds is "..nod)
		return nod
	end
	
	local function shrinkOdds(newodds, pos, mashed, rush, p, secondist, pingame, pexiting)
		local nod = newodds
		if (indirectitemcooldown > 0) or (pingame-1 <= pexiting) then
			nod = 0
			--print("disabled shrink (indirectitemcooldown = " + indirectitemcooldown + ", pingame = " + pingame +", pexiting = " + pexiting + ")")
		end
		--print("shrink odds is "..nod)
		return nod
	end
	
	local function getSpb(p, i)
		K_SetIndirectItemCooldown(20*TICRATE)
	end
	
	local function getHyuu(p, i)
		K_SetHyudoroCooldown(5*TICRATE)
	end
	
	local function getTripleShoe(p, i)
		return xItemLib.xItemNamespaces["KITEM_SNEAKER"], 3
	end
	
	local function getTripleBanana(p, i)
		return xItemLib.xItemNamespaces["KITEM_BANANA"], 3
	end
	
	local function getDecaBanana(p, i)
		return xItemLib.xItemNamespaces["KITEM_BANANA"], 10
	end
	
	local function getTripleOrbi(p, i)
		return xItemLib.xItemNamespaces["KITEM_ORBINAUT"], 3
	end
	
	local function getQuadOrbi(p, i)
		return xItemLib.xItemNamespaces["KITEM_ORBINAUT"], 4
	end
	
	local function getDualJawz(p, i)
		return xItemLib.xItemNamespaces["KITEM_JAWZ"], 2
	end
	
	local function showPogo(p)
		if (G_BattleGametype()) then
			return true
		else
			return false
		end
	end

	hud.add(function(v, p, c)
		xItemLib.func.hudMain(v, p, c)
	end, "game")
	
	addHook("ThinkFrame", do
		for i = 0, #players-1 do
			if players[i] then
				xItemLib.func.playerThinker(players[i])
			end
		end
	end)

	--dropped item behaviour
	addHook("MobjThinker", xItemLib.func.floatingItemThinker, MT_FLOATINGITEM)

	addHook("TouchSpecial", xItemLib.func.floatingItemSpecial, MT_FLOATINGITEM)

	addHook("TouchSpecial", xItemLib.func.itemBoxSpecial, MT_RANDOMITEM)
	
	addHook("MobjThinker", xItemLib.func.floatingXItemThinker, MT_FLOATINGXITEM)

	addHook("TouchSpecial", xItemLib.func.floatingXItemSpecial, MT_FLOATINGXITEM)
	
	addHook("MobjThinker", xItemLib.func.playerArrowThinker, MT_XITEMPLAYERARROW)
	
	addHook("MobjThinker", xItemLib.func.vanillaArrowThinker, MT_PLAYERARROW)
	
	xItemLib.func.addItem{"KITEM_SNEAKER", "Sneaker", "K_ITSHOE", "K_ISSHOE", 0, {20, 0, 0, 4, 6, 7, 0, 0, 0, 0 }, { 2, 1 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 1}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_ROCKETSNEAKER", "Rocket Sneaker", "K_ITRSHE", "K_ISRSHE", 0, { 0, 0, 0, 0, 0, 1, 4, 5, 3, 0 }, { 0, 0 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 2}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_INVINCIBILITY", "Invincibility", {3, "K_ITINV1", "K_ITINV2", "K_ITINV3", "K_ITINV4", "K_ITINV5", "K_ITINV6", "K_ITINV7"}, {3, "K_ISINV1", "K_ISINV2", "K_ISINV3", "K_ISINV4", "K_ISINV5", "K_ISINV6"}, 0, { 0, 0, 0, 0, 0, 1, 4, 6,10, 0 }, { 2, 1 }, nil, nil, nil, nil, nil, {3, {SPR_ITMI, A}, {SPR_ITMI, B}, {SPR_ITMI, C}, {SPR_ITMI, D}, {SPR_ITMI, E}, {SPR_ITMI, F}, {SPR_ITMI, G}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_BANANA", "Banana", "K_ITBANA", "K_ISBANA", 0, { 0, 9, 4, 2, 1, 0, 0, 0, 0, 0 }, { 1, 0 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 4}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_EGGMAN", "Eggman Monitor", "K_ITEGGM", "K_ISEGGM", 0, { 0, 3, 2, 1, 0, 0, 0, 0, 0, 0 }, { 1, 0 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 5}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_ORBINAUT", "Orbinaut", {35, "K_ITORB1", "K_ITORB2", "K_ITORB3", "K_ITORB4"}, "K_ISORBN", XIF_ICONFORAMT, { 0, 7, 6, 4, 2, 0, 0, 0, 0, 0 }, { 8, 0 }, nil, nil, nil, nil, nil, {4, {SPR_ITMO, A}, {SPR_ITMO, B}, {SPR_ITMO, C}, {SPR_ITMO, D}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_JAWZ", "Jawz", "K_ITJAWZ", "K_ISJAWZ", 0, { 0, 0, 3, 2, 1, 1, 0, 0, 0, 0 }, { 8, 1 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 7}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_MINE", "Mine", "K_ITMINE", "K_ISMINE", 0, { 0, 0, 2, 2, 1, 0, 0, 0, 0, 0 }, { 4, 1 }, nil, nil, nil, nil, nil, {0, {SPR_ITEM, 8}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_BALLHOG", "Ballhog", "K_ITBHOG", "K_ISBHOG", 0, { 0, 0, 0, 2, 1, 0, 0, 0, 0, 0 }, { 2, 1 }, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 9}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_SPB", "Self-Propelled Bomb", "K_ITSPB", "K_ISSPB", XIF_COOLDOWNINDIRECT, { 0, 0, 1, 2, 3, 4, 2, 2, 0, 20 }, { 0, 0 }, getSpb, nil, nil, spbOdds, nil,  {0, {SPR_ITEM, 10}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_GROW", "Grow", "K_ITGROW", "K_ISGROW", XIF_POWERITEM|XIF_COOLDOWNONSTART, { 0, 0, 0, 0, 0, 0, 2, 5, 7, 0 }, { 2, 1 }, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 11}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_SHRINK", "Shrink", "K_ITSHRK", "K_ISSHRK", XIF_POWERITEM|XIF_COOLDOWNONSTART|XIF_COOLDOWNINDIRECT, { 0, 0, 0, 0, 0, 0, 0, 2, 0, 0 }, { 0, 0 }, getSpb, nil, nil, shrinkOdds, nil,  {0, {SPR_ITEM, 12}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_THUNDERSHIELD", "Thunder Shield", "K_ITTHNS", "K_ISTHNS", XIF_POWERITEM|XIF_COOLDOWNONSTART|XIF_UNIQUE, { 0, 1, 2, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0 }, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 13}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_HYUDORO", "Hyudoro", "K_ITHYUD", "K_ISHYUD", XIF_COOLDOWNONSTART|XIF_UNIQUE, { 0, 0, 0, 0, 1, 2, 1, 0, 0, 0 }, { 2, 0 }, getHyuu, nil, nil, hyuuOdds, nil,  {0, {SPR_ITEM, 14}}, true, nil, nil}
	xItemLib.func.addItem{"KITEM_POGOSPRING", "Pogo Spring", "K_ITPOGO", "K_ISPOGO", 0, { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 2, 0 }, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 15}}, showPogo, nil, nil} --what if I throw in a sneaky pogo lmao
	xItemLib.func.addItem{"KITEM_KITCHENSINK", "Kitchen Sink", "K_ITSINK", "K_ISSINK", 0, { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 }, { 0, 0 }, nil, nil, nil, nil, nil,  {0, {SPR_ITEM, 16}}, false, nil, nil}
	
	xItemLib.func.addItem{"KRITEM_TRIPLESNEAKER", "Triple Sneaker", "K_ITSHOE", "K_ISSHOE", 0, { 0, 0, 0, 0, 3, 7, 9, 2, 0, 0 }, { 0, 1 }, nil, nil, nil, nil, getTripleShoe,  {0, {SPR_ITEM, 1}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TRIPLEBANANA", "Triple Banana", "K_ITBANA", "K_ISBANA", 0, { 0, 0, 1, 1, 0, 0, 0, 0, 0, 0 }, { 1, 0 }, nil, nil, nil, nil, getTripleBanana, {0, {SPR_ITEM, 4}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TENFOLDBANANA", "Deca Banana", "K_ITBANA", "K_ISBANA", 0, { 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 }, { 0, 1 }, nil, nil, nil, nil, getDecaBanana, {0, {SPR_ITEM, 5}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_TRIPLEORBINAUT", "Triple Orbinaut", "K_ITORB3", "K_ISORBN", 0, { 0, 0, 0, 1, 0, 0, 0, 0, 0, 0 }, { 2, 0 }, nil, nil, nil, nil, getTripleOrbi, {0, {SPR_ITMO, C}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_QUADORBINAUT", "Quad Orbinaut", "K_ITORB4", "K_ISORBN", 0, { 0, 0, 0, 0, 1, 1, 0, 0, 0, 0 }, { 1, 1 }, nil, nil, nil, nil, getQuadOrbi, {0, {SPR_ITMO, D}}, false, nil, nil}
	xItemLib.func.addItem{"KRITEM_DUALJAWZ", "Dual Jawz", "K_ITJAWZ", "K_ISJAWZ", XIF_POWERITEM, { 0, 0, 0, 1, 2, 0, 0, 0, 0, 0 }, { 2, 1 }, nil, nil, nil, nil, getDualJawz, {0, {SPR_ITEM, 7}}, false, nil, nil}
	
	xItemLib.func.addXItemMod("XITEM_BASE", "xItemLib", {lib = "by minenice"})
	
	addHook("NetVars", function(net)
		xItemLib.toggles = net(xItemLib.toggles)
	end)
end

if xItemLib.gLibVersion < currLibVer then
	print("\3\135xItemLib\n\128by \130minenice\128")
	print("Updating xItemLib to library version \130"..currLibVer)
	xItemLib.func = {}
	xItemLib.func.countItems = getLoadedItemAmount
	xItemLib.func.setPatch = addItemPatch
	xItemLib.func.getPatch = getItemPatch
	xItemLib.func.getSinglePatch = getItemPatchSingle
	xItemLib.func.addItem = addXItem
	xItemLib.func.resetItemOdds = resetOddsForItem
	xItemLib.func.setPlayerOddsForItem = setPlayerOddsForItem
	xItemLib.func.getPlayerScaling = playerScaling
	xItemLib.func.getStartCountdown = checkStartCooldown
	xItemLib.func.getPowerOdds = checkPowerItemOdds
	xItemLib.func.floatingItemThinker = floatingItemThinker
	xItemLib.func.floatingItemSpecial = floatingItemSpecial
	xItemLib.func.itemBoxSpecial = itemBoxSpecial
	xItemLib.func.getItemResult = xItem_GetItemResult
	xItemLib.func.getOdds = xItem_GetOdds
	xItemLib.func.setupDist = setupDistTable
	xItemLib.func.findUseOdds = xItem_FindUseOdds
	xItemLib.func.doRoulette = xItem_ItemRoulette
	xItemLib.func.attackHandler = xItem_BasicItemHandler
	xItemLib.func.hudFindFlags = xItem_FindHudFlags
	xItemLib.func.hudDrawItemBox = xItem_DrawItemBox
	xItemLib.func.hudDrawItem = xItem_DrawItem
	xItemLib.func.hudDrawEgg = xItem_drawEggTimer
	xItemLib.func.hudDrawSad = xItem_drawSad
	xItemLib.func.hudMain = xItem_hudMain
	xItemLib.func.playerThinker = playerThinkFrame
	xItemLib.func.hudFindRouletteItems = findAvailableRoulettePatches
	xItemLib.func.findItemByNamespace = findItemByNamespace
	xItemLib.func.findItemByFriendlyName = findItemByFriendlyName
	xItemLib.func.canUseItem = canUseItem
	xItemLib.func.floatingXItemThinker = floatingXItemThinker
	xItemLib.func.floatingXItemSpecial = floatingXItemSpecial
	xItemLib.func.playerArrowThinker = playerArrowThinker
	xItemLib.func.vanillaArrowThinker = vanillaArrowThinker
	xItemLib.func.addXItemMod = addXItemMod
	xItemLib.func.setXItemModData = setXItemModData
	xItemLib.func.getXItemModData = getXItemModData
	xItemLib.func.getCVar = getCVar
	xItemLib.func.findItemDistributions = findItemDistributions
	xItemLib.func.xItem_drawDistributions = xItem_drawDistributions
	xItemLib.func.xItem_handleDistributionDebugger = xItem_handleDistributionDebugger
else
	print("xItemLib is to date")
end