--## Hud ##--
-- Constants
local ITEMX = 160
local ITEMY = 157
local ITEMTEXTX = 36
local ITEMTEXTY = 26

local TEAMMATE_VFLAGS = V_SNAPTOBOTTOM|V_HUDTRANS

-- Variables
local playerfacesgfx = {}
local miniitemgfx
local miniiteminvulgfx
local sadgfx

-- Functions
local function getItemPatchName(itemId)
    if xItemLib then
        return xItemLib.func.getSinglePatch(itemId, true, true)
    end
    if itemId == KITEM_INVINCIBILITY then
        --inv is shiny
        return string.format("K_ISINV%d", ((leveltime%(6*3))/3) + 1)
    end
    return K_GetItemPatch(itemId, true)
end

local function toTimeString(tics)
    return string.format("%d'%02d\"%02d", G_TicsToMinutes(tics, true), G_TicsToSeconds(tics), G_TicsToCentiseconds(tics))
end

local function pairHud(v, p)
    --## Face ##--
    if p and p.valid and p.pairmod
    and p.pairmod.pair and p.pairmod.pair.valid and not p.pairmod.pair.spectator then
        local skinused = p.pairmod.pair.mo.skin
        if p.pairmod.pair.mo.colorized then
            skinused = TC_RAINBOW
        end
        v.draw(152, 171, v.cachePatch(skins[p.pairmod.pair.mo.skin].facerank), TEAMMATE_VFLAGS, v.getColormap(skinused, p.pairmod.pair.mo.color))
        
        local s = tostring(p.pairmod.pair.name)
        v.drawString(160 - (v.stringWidth(s, V_6WIDTHSPACE, "thin") / 2), 190, s, V_ALLOWLOWERCASE|V_6WIDTHSPACE|TEAMMATE_VFLAGS, "thin")
        
        --## Items ##--
        local pair_p = p.pairmod.pair

        local itemcount = pair_p.kartstuff[k_itemamount]

        if pair_p.kartstuff[k_rocketsneakertimer] then
            if not (leveltime&1) then
                v.draw(ITEMX, ITEMY, v.cachePatch(getItemPatchName(KITEM_ROCKETSNEAKER)), TEAMMATE_VFLAGS)				
            end
        elseif pair_p.kartstuff[k_eggmanexplode] then
            local flashtime = 4<<(pair_p.kartstuff[k_eggmanexplode]/TICRATE)
            local cmap = nil
            if not (pair_p.kartstuff[k_eggmanexplode] == 1
            or (pair_p.kartstuff[k_eggmanexplode] % (flashtime/2) ~= 0)) then
                cmap = v.getColormap(TC_BLINK, SKINCOLOR_CRIMSON)
            end				
            v.draw(ITEMX, ITEMY, v.cachePatch(getItemPatchName(KITEM_EGGMAN)), TEAMMATE_VFLAGS, cmap)				
        elseif pair_p.kartstuff[k_itemtype] then
            local itemp = v.cachePatch(getItemPatchName(pair_p.kartstuff[k_itemtype]))
            --draw amount as a number
            if not (pair_p.kartstuff[k_itemheld] and not (leveltime&1)) then
                v.draw(ITEMX, ITEMY, itemp, TEAMMATE_VFLAGS)
                if itemcount > 1 then
                    v.drawString(ITEMX+ITEMTEXTX, ITEMY+ITEMTEXTY, itemcount, TEAMMATE_VFLAGS, "right")
                end
            end
        end

        -- Rank icons
        local patch_to_draw = v.cachePatch(string.format("OPPRNK%02d", pair_p.kartstuff[k_position]))
        v.draw(148, 182, patch_to_draw, TEAMMATE_VFLAGS)
    end

    --## Info messages ##--
    if pairmod.infoMessageTimer then
        local fadeLevel = (10 - FixedInt(FixedDiv(min(pairmod.infoMessageTimer, PAIRMOD_INFO_MESSAGE_START_FADE), PAIRMOD_INFO_MESSAGE_START_FADE)*10)) * V_10TRANS
        v.drawString(160, 161, pairmod.infoMessage, fadeLevel|V_ALLOWLOWERCASE|V_SNAPTOBOTTOM, "center")
    end

    --## Post race message ##--
    if p.exiting and not pairmod.stopgamemode then
        local str = "Your final time will be doubled to keep rankings fair"
        if p.pairmod and p.pairmod.pair then
            str = "Your final time is the sum of both player's time"
        end
        local strwidth = v.stringWidth(str, V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin")
        v.drawString(160 - (strwidth / 2), 70, str, V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "thin")
    end

    --## Post race scoreboard ##--
    if pairmod.stopgamemode then
        v.drawString(160, 30, "Final ranking", V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "center")

        if pairmod.eolScores ~= nil then
            for i, k in ipairs(pairmod.eolScores) do
                v.drawString(80, 33+(i*10), table.concat(k.playernames, " & "), V_ALLOWLOWERCASE|V_6WIDTHSPACE|V_HUDTRANS, "thin")
                v.drawString(260, 33+(i*10), toTimeString(k.time), V_ALLOWLOWERCASE|V_HUDTRANS, "thin-right")
            end
        else
            v.drawString(160, 60, "None!", V_ALLOWLOWERCASE|V_SNAPTOTOP|V_HUDTRANS, "center")
        end
    end
end
hud.add(pairHud, "game")
