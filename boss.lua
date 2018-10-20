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
	events = {sgs.GameOverJudge, sgs.BuryVictim},
	priority = 1,
	global = true,
	can_trigger = function(self, player)
	    return player:getGameMode() == "_mini_4"
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameOverJudge then
			if player:getKingdom() == "OMNI" and room:getLieges("OMNI", player):isEmpty() then
				local a, b = room:getAllPlayers(true):at(5), room:getAllPlayers(true):at(6)
				room:revivePlayer(a)
				room:revivePlayer(b)
				if a:objectName() == player:objectName() then
					room:setPlayerFlag(player, "_mini_4_destiny")
					room:changeHero(b, "LEGEND", true, true, false, true)
					b:drawCards(4)
					if not b:faceUp() then
						b:turnOver()
					end
					if b:isChained() then
						room:setPlayerProperty(b, "chained", sgs.QVariant(false))
					end
					return true
				elseif b:objectName() == player:objectName() then
					room:setPlayerFlag(player, "_mini_4_legend")
					room:changeHero(a, "DESTINY", true, true, false, true)
					a:drawCards(4)
					if not a:faceUp() then
						a:turnOver()
					end
					if a:isChained() then
						room:setPlayerProperty(a, "chained", sgs.QVariant(false))
					end
					return true
				else
					room:changeHero(a, "DESTINY", true, true, false, true)
					a:drawCards(4)
					if not a:faceUp() then
						a:turnOver()
					end
					if a:isChained() then
						room:setPlayerProperty(a, "chained", sgs.QVariant(false))
					end
					
					room:changeHero(b, "LEGEND", true, true, false, true)
					b:drawCards(4)
					if not b:faceUp() then
						b:turnOver()
					end
					if b:isChained() then
						room:setPlayerProperty(b, "chained", sgs.QVariant(false))
					end
					return true
				end
			elseif player:getKingdom() == "ZAFT" and room:getLieges("ZAFT", player):isEmpty() then
				for _,p in sgs.qlist(room:getAllPlayers(true)) do
					if p:getState() == "online" then
						gainCoin(p, 10)
					end
				end
			end
		else
			if player:hasFlag("_mini_4_destiny") then
				room:setPlayerFlag(player, "-_mini_4_destiny")
				room:changeHero(player, "DESTINY", true, true, false, true)
				player:throwAllCards()
				player:drawCards(4)
				if not player:faceUp() then
					player:turnOver()
				end
				if player:isChained() then
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
				return true
			elseif player:hasFlag("_mini_4_legend") then
				room:setPlayerFlag(player, "-_mini_4_legend")
				room:changeHero(player, "LEGEND", true, true, false, true)
				player:throwAllCards()
				player:drawCards(4)
				if not player:faceUp() then
					player:turnOver()
				end
				if player:isChained() then
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
				return true
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