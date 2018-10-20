module("extensions.gaodaexcard", package.seeall)
extension = sgs.Package("gaodaexcard", sgs.Package_CardPack)

final_vent = sgs.CreateTrickCard{
	name = "final_vent",
	class_name = "FinalVent",
	suit = 1,
	number = 2,
	target_fixed = false,
	can_recast = false,
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_LuaTrickCard_TypeNormal,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < 1
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		room:getThread():delay(1000)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		--[[if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end]]
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			effect.from:addToPile("#final_vent", self)
			local log = sgs.LogMessage()
			log.type = "$AddToPile"
			log.card_str = self:toString()
			log.arg = "single_target_trick"
			room:sendLog(log)
		end
		
		local x = 1
		for _,card in sgs.qlist(effect.from:getEquips()) do
			if card:isKindOf("Horse") and card:isRed() then
				x = x + 1
				break
			end
		end
		room:damage(sgs.DamageStruct(self, effect.from, effect.to, x, sgs.DamageStruct_Fire))
	end
}

final_vent:clone(2, 13):setParent(extension)

decade = sgs.CreateTrickCard{
	name = "decade",
	class_name = "Decade",
	suit = 0,
	number = 10,
	target_fixed = false,
	can_recast = false,
	subtype = "single_target_trick",
	subclass = sgs.LuaTrickCard_LuaTrickCard_TypeNormal,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < 1
	end,
	feasible = function(self, targets)
		return #targets > 0
	end,
	available = function(self, player)
		return player and player:isAlive() and not player:isCardLimited(self, sgs.Card_MethodUse, true)
	end,
	is_cancelable = function(self, effect)
		return true
	end,
	about_to_use = function(self, room, use)
		self:cardOnUse(room, use)
	end,
	on_use = function(self, room, source, targets)
		room:getThread():delay(1700)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
		--[[if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_DiscardPile, reason, true)
		end]]
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			effect.from:addToPile("#decade", self)
			local log = sgs.LogMessage()
			log.type = "$AddToPile"
			log.card_str = self:toString()
			log.arg = "single_target_trick"
			room:sendLog(log)
		end
		
		local x = 2
		for i = 1, 9, 1 do
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = nil
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, effect.from:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			local card = sgs.Sanguosha:getCard(ids:first())
			if x == 2 and card:getNumber() >= 10 then
				x = 1
			end
			room:throwCard(card, nil)
			room:getThread():delay(0100)
		end
		room:damage(sgs.DamageStruct(self, effect.from, effect.to, x))
	end
}

decade:clone(0, 10):setParent(extension)

sgs.LoadTranslationTable{
	["gaodaexcard"] = "高达杀乱入卡",

	["final_vent"] = "龙骑最终降临",
	["FinalVent"] = "龙骑最终降临",
	[":final_vent"] = "战术牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一名其他角色\
	<b>效果</b>：将此牌移出游戏，对目标角色造成1点火焰伤害，若你的装备区有<b><font color='red'>红色</font></b>坐骑牌，此伤害+1。\
<I>FINAL VENT——《假面骑士龙骑》</I>",

	["decade"] = "必杀卡-DECADE",
	["Decade"] = "必杀卡-DECADE",
	[":decade"] = "战术牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一名其他角色\
	<b>效果</b>：将此牌移出游戏，依次亮出牌堆顶的九张牌，对目标角色造成1点伤害，若亮出的牌点数均小于10，此伤害+1。\
<I>FINAL ATTACKRIDE - D-D-D-DECADE——《假面骑士DECADE》</I>",
}