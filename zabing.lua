--[[高达杀兵包   
   编写者：某个什么都不会的杂兵指挥官
   鸣谢：高达杀制作组QQ群里的大佬们
   高达杀制作组QQ群：565837324
   PS：准备好氪金验欧非吧
]]

--[[设定
	支援机体力 = 耐久度
	第二回合起，出牌阶段，点击“支援”按钮，召唤你喜欢的支援机，以副将的形式出击。
	出牌阶段开始时、当你造成或受到1点伤害后，支援机耐久度-1，若为0则消失，X回合后才可再次召唤支援机出击。（X为其原耐久度）
	各类支援机的使用权从“扭蛋”获得，每次抽到便令该支援机的可使用次数+1/+3。
	一场游戏中，第一次召唤支援机需消耗1次该支援机的使用次数，之后再召唤支援机时不消耗次数，但只能召唤第一次的支援机。
]]

module("extensions.zabing", package.seeall)
extension = sgs.Package("zabing")

ZAKU = sgs.General(extension, "ZAKU", "", 5, true, true)
ZAKU:setGender(sgs.General_Neuter)

dangqiang = sgs.CreateTriggerSkill
{
	name = "dangqiang",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			local marks = player:getMarkNames()
			for _,mark in pairs(marks) do
				if mark:startsWith("@zb_") and player:getMark(mark) > 0 then
					room:setPlayerMark(player, mark, 0)
					break
				end
			end
			room:setPlayerMark(player, "@zb_full5_re0", 1)
			room:changeHero(player, "", false, false, true, false)
			room:setEmotion(player, "skill_nullify")
			return true
		end
	end
}

ZAKU:addSkill(dangqiang)

GM = sgs.General(extension, "GM", "", 3, true, true)
GM:setGender(sgs.General_Neuter)

liangchan = sgs.CreateTargetModSkill{
	name = "liangchan",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player and player:hasSkill(self:objectName()) then
			return 1
		end
	end
}

GM:addSkill(liangchan)

JEGAN = sgs.General(extension, "JEGAN", "", 3, true, true)
JEGAN:setGender(sgs.General_Neuter)

lianxievs = sgs.CreateOneCardViewAsSkill{
	name = "lianxie",
	filter_pattern = "TrickCard",
	response_or_use = true,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("tactical_combo", card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("lianxie")
	end
}

lianxie = sgs.CreateTriggerSkill
{
	name = "lianxie",
	events = {sgs.CardUsed},
	view_as_skill = lianxievs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "lianxie" then
			room:addPlayerHistory(player, self:objectName())
		end
	end
}

JEGAN:addSkill(lianxie)

BUCUE = sgs.General(extension, "BUCUE", "", 4, true, true)
BUCUE:setGender(sgs.General_Neuter)

dizhan = sgs.CreateTriggerSkill{
	name = "dizhan",
	events = {sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and player:isKongcheng() and room:askForSkillInvoke(player, self:objectName(), data) then
			local card = sgs.Sanguosha:cloneCard("savage_assault")
			card:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
			use.card = card
			use.from = player
			room:useCard(use)
		end
	end
}

BUCUE:addSkill(dizhan)

M1_ASTRAY = sgs.General(extension, "M1_ASTRAY", "", 4, true, true)
M1_ASTRAY:setGender(sgs.General_Neuter)

zhongli = sgs.CreateTriggerSkill{
	name = "zhongli",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:getMark("damage_point_round") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			player:drawCards(1, self:objectName())
		end
	end
}

M1_ASTRAY:addSkill(zhongli)

FLAG = sgs.General(extension, "FLAG", "", 3, true, true)
FLAG:setGender(sgs.General_Neuter)

kongxi = sgs.CreateTriggerSkill{
	name = "kongxi",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#IgnoreArmor"
			log.from = player
			log.card_str = use.card:toString()
			room:sendLog(log)
			for _,p in sgs.qlist(use.to) do
				if p:getMark("Equips_of_Others_Nullified_to_You") == 0 then
					p:addQinggangTag(use.card)
				end
			end
		end
	end
}

FLAG:addSkill(kongxi)

TIEREN = sgs.General(extension, "TIEREN", "", 4, true, true)
TIEREN:setGender(sgs.General_Neuter)

diyu = sgs.CreateTriggerSkill{
	name = "diyu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.HpLost, sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		room:sendCompulsoryTriggerLog(player, self:objectName())
		player:drawCards(1, self:objectName())
	end
}

TIEREN:addSkill(diyu)

GENOACE = sgs.General(extension, "GENOACE", "", 4, true, true)
GENOACE:setGender(sgs.General_Neuter)

huanji = sgs.CreateTriggerSkill{
	name = "huanji",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    local damage = data:toDamage()
		if damage.from and damage.from:objectName() ~= player:objectName() then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			slash:setSkillName(self:objectName())
			if not damage.from:isProhibited(damage.from, slash) and room:askForCard(player, ".|red", "@@huanji", data,  sgs.Card_MethodDiscard, nil, false, self:objectName(), false) then
				local use = sgs.CardUseStruct()
				use.card = slash
				use.from = player
				use.to:append(damage.from)
				room:useCard(use)
			end
		end
	end
}

GENOACE:addSkill(huanji)

GAFRAN = sgs.General(extension, "GAFRAN", "", 5, true, true)
GAFRAN:setGender(sgs.General_Neuter)

fuxicard = sgs.CreateSkillCard
{
	name = "fuxi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	about_to_use = function(self, room, use)
		room:throwCard(self, use.from)
		local log = sgs.LogMessage()
		log.type = "#fuxi"
		log.from = use.from
		log.arg = self:objectName()
		room:sendLog(log)
		local marks = use.from:getMarkNames()
		for _,mark in pairs(marks) do
			if mark:startsWith("@zb_") and use.from:getMark(mark) > 0 then
				room:setPlayerMark(use.from, mark, 0)
				break
			end
		end
		room:setPlayerMark(use.from, "@zb_full5_re0", 1)
		room:changeHero(use.from, "", false, false, true, false)
		room:addPlayerMark(use.to:first(), "fuxi")
	end
}

fuxi = sgs.CreateViewAsSkill
{
	name = "fuxi",
	n = 2,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local acard = fuxicard:clone()
			acard:addSubcard(cards[1])
			acard:addSubcard(cards[2])
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return true
	end
}

fuxieffect = sgs.CreateTriggerSkill
{
	name = "#fuxieffect",
	events = {sgs.TurnStart},
	global = true,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getMark("fuxi") > 0 then
			room:removePlayerMark(player, "fuxi")
			local log = sgs.LogMessage()
			log.type = "#fuxie"
			log.from = player
			log.arg = "fuxi"
			room:sendLog(log)
		    room:loseHp(player, 1)
		end
	end
}

GAFRAN:addSkill(fuxi)
GAFRAN:addSkill(fuxieffect)

--请在gaoda.lua的“杂兵”处进行翻译