module("extensions.boss", package.seeall)
extension = sgs.Package("boss", sgs.Package_GeneralPack)

--获得G币
gainCoin = function(player, n)
	if n < 1 then return false end

	local room = player:getRoom()
	
	local json = require("json")
	local jsonValue = {
	player:objectName(),
	"yomeng"
	}
	local wholist = sgs.SPlayerList()
	wholist:append(player)
	room:doBroadcastNotify(wholist, sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))

	local log = sgs.LogMessage()
	log.type = "#coin"
	log.from = player
	log.arg = n
	room:sendLog(log)
	if n == 1 then
		room:broadcastSkillInvoke("gdsbgm", 7)
	else
		room:broadcastSkillInvoke("gdsbgm", 8)
	end
	
	local ip = room:getOwner():getIp()
	if player:getState() == "online" then
		room:setPlayerMark(player, "add_coin", n)
		room:askForUseCard(player, "@@luckyrecord!", "@luckyrecord")
		room:setPlayerMark(player, "add_coin", 0)
		room:setPlayerFlag(player, "-g2data_saved")
	end
end

_mini_3_skill = sgs.CreateTriggerSkill{
	name = "_mini_3_skill",
	events = {sgs.GameOverJudge, sgs.BuryVictim},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_3"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:isLord() then
			if event == sgs.GameOverJudge then
				if player:getGeneralName() == "BARBATOS" then
					room:revivePlayer(player)
					return true
				elseif player:getGeneralName() == "LUPUS" then
					room:revivePlayer(player)
					return true
				else
					for _,p in sgs.qlist(room:getAllPlayers(true)) do
						if p:getState() == "online" then
							gainCoin(p, 10)
						end
					end
				end
			else
				if player:getGeneralName() == "BARBATOS" then
					room:changeHero(player, "LUPUS", true, true, false, true)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(8))
					room:setPlayerProperty(player, "hp", sgs.QVariant(8))
					player:throwAllCards()
					player:drawCards(8)
					if not player:faceUp() then
						player:turnOver()
					end
					if player:isChained() then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
					room:acquireSkill(player, "kuanggu")
					return true
				elseif player:getGeneralName() == "LUPUS" then
					room:changeHero(player, "REX", true, true, false, true)
					room:setPlayerProperty(player, "maxhp", sgs.QVariant(12))
					room:setPlayerProperty(player, "hp", sgs.QVariant(12))
					player:throwAllCards()
					player:drawCards(12)
					if not player:faceUp() then
						player:turnOver()
					end
					if player:isChained() then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
					room:acquireSkill(player, "xueji")
					return true
				end
			end
		end
	end
}

_mini_4_skill = sgs.CreateTriggerSkill{
	name = "_mini_4_skill",
	events = {sgs.GameOverJudge},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_4"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getKingdom() == "OMNI" and room:getLieges("OMNI", player):isEmpty() then
			for i,p in sgs.qlist(room:getAllPlayers(true)) do
				if i == 5 then
					room:revivePlayer(p)
					room:changeHero(p, "DESTINY", true, true, false, true)
					p:drawCards(4)
				elseif i == 6 then
					room:revivePlayer(p)
					room:changeHero(p, "LEGEND", true, true, false, true)
					p:drawCards(4)
				end
			end
		elseif player:getKingdom() == "ZAFT" and room:getLieges("ZAFT", player):isEmpty() then
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				if p:getState() == "online" then
					gainCoin(p, 10)
				end
			end
		end
	end
}

SHAMBLO = sgs.General(extension, "SHAMBLO", "ZEON", 8, false, true, true)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("_mini_3_skill") then skills:append(_mini_3_skill) end
if not sgs.Sanguosha:getSkill("_mini_4_skill") then skills:append(_mini_4_skill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["boss"] = "BOSS",
	["SHAMBLO"] = "尚布罗",
	["#SHAMBLO"] = "重力的井底",
	["~SHAMBLO"] = "",
	["designer:SHAMBLO"] = "高达杀制作组",
	["cv:SHAMBLO"] = "罗妮·贾维",
	["illustrator:SHAMBLO"] = "wch5621628",
}