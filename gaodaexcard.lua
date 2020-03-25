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
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			--移动至隐藏pile，在UI层面上移出游戏，同时防止中途获得此牌（如 “奸雄”）
			source:addToPile("#final_vent", self)
			local log = sgs.LogMessage()
			log.type = "$AddToPile"
			log.card_str = self:toString()
			log.arg = "single_target_trick"
			room:sendLog(log)
			
			--移动至PlaceUnknown，在服务器层面上移出游戏，防止AI把隐形牌用作视为技（如 隐形“武圣”【杀】），但再次获得此牌时会闪退（如 作弊卡牌一览）
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_PlaceUnknown, reason, true)
		end
		
		room:getThread():delay(1000)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()		
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
		if room:getCardPlace(self:getEffectiveId()) == sgs.Player_PlaceTable then
			--移动至隐藏pile，在UI层面上移出游戏，同时防止中途获得此牌（如 “奸雄”）
			source:addToPile("#decade", self)
			local log = sgs.LogMessage()
			log.type = "$AddToPile"
			log.card_str = self:toString()
			log.arg = "single_target_trick"
			room:sendLog(log)
			
			--移动至PlaceUnknown，在服务器层面上移出游戏，防止AI把隐形牌用作视为技（如 隐形“武圣”【杀】），但再次获得此牌时会闪退（如 作弊卡牌一览）
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, source:objectName(), "", self:getSkillName(), "")
			room:moveCardTo(self, source, nil, sgs.Player_PlaceUnknown, reason, true)
		end
		
		room:getThread():delay(1700)
		for _, t in ipairs(targets) do
			room:cardEffect(self, source, t)
		end
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()		
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

--防止作弊卡牌一览获得移出游戏的牌
gaodaexcard_skill = sgs.CreateTriggerSkill{
	name = "gaodaexcard_skill",
	events = {sgs.BeforeCardsMove},
	global = true,
	priority = 3,
	can_trigger = function(self, target)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == player:objectName() then
			for _, id in sgs.qlist(move.card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if table.contains({"final_vent", "decade"}, card:objectName()) and room:getCardPlace(id) == sgs.Player_PlaceUnknown then
					--移出游戏就不能再拿回来，不然会闪退
					move.card_ids:removeOne(id)
				else
					return false
				end
			end
			data:setValue(move)
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("gaodaexcard_skill") then skills:append(gaodaexcard_skill) end
sgs.Sanguosha:addSkills(skills)

sgs.LoadTranslationTable{
	["gaodaexcard"] = "高达杀乱入卡",

	["final_vent"] = "龙骑最终降临",
	["FinalVent"] = "龙骑最终降临",
	[":final_vent"] = "战术牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一名其他角色\
	<b>效果</b>：将此牌移出游戏，对目标角色造成1点火焰伤害，若你的装备区有<b><font color='red'>红色</font></b>坐骑牌，此伤害+1。\
<font color='red'>“戦わなければ生き残れない”<p align='right'>——《假面骑士龙骑》</p></font>",

	["decade"] = "必杀卡-DECADE",
	["Decade"] = "必杀卡-DECADE",
	[":decade"] = "战术牌\
	<b>时机</b>：出牌阶段\
	<b>目标</b>：一名其他角色\
	<b>效果</b>：将此牌移出游戏，依次亮出牌堆顶的九张牌，对目标角色造成1点伤害，若亮出的牌点数均小于10，此伤害+1。\
<font color='magenta'>“通りすがりの仮面ライダーだ、覚えておけ！”<p align='right'>——《假面骑士DECADE》</p></font>",
}