--[[高达杀兵包   
   编写者：某个什么都不会的杂兵指挥官
   鸣谢：高达杀制作组QQ群里的大佬们
   高达杀制作组QQ群：565837324
   PS：准备好氪金验欧非吧
]]

module("extensions.zabing", package.seeall)
extension = sgs.Package("zabing")

ZAKU = sgs.General(extension, "ZAKU", "", 0, true, true)
ZAKU:setGender(sgs.General_Neuter)

dangqiang = sgs.CreateTriggerSkill
{
	name = "dangqiang",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:changeHero(player, "", false, false, true, false)
			room:setEmotion(player, "skill_nullify")
			return true
		end
	end
}

ZAKU:addSkill(dangqiang)

GM = sgs.General(extension, "GM", "", 0, true, true)
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

JEGAN = sgs.General(extension, "JEGAN", "", 0, true, true)
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

BUCUE = sgs.General(extension, "BUCUE", "", 0, true, true)
BUCUE:setGender(sgs.General_Neuter)

M1ASTRAY = sgs.General(extension, "M1ASTRAY", "", 0, true, true)
M1ASTRAY:setGender(sgs.General_Neuter)

FLAG = sgs.General(extension, "FLAG", "", 0, true, true)
FLAG:setGender(sgs.General_Neuter)

TIEREN = sgs.General(extension, "TIEREN", "", 0, true, true)
TIEREN:setGender(sgs.General_Neuter)

GENOACE = sgs.General(extension, "GENOACE", "", 0, true, true)
GENOACE:setGender(sgs.General_Neuter)

GAFRAN = sgs.General(extension, "GAFRAN", "", 0, true, true)
GAFRAN:setGender(sgs.General_Neuter)

sgs.LoadTranslationTable{
	["zabing"] = "支援机",
	["ZAKU"] = "渣古ⅡF",
	["#ZAKU"] = "自护的先锋",
	["dangqiang"] = "挡枪",
	[":dangqiang"] = "当你受到伤害时，你可以防止之并移除此武将牌。",
	["GM"] = "吉姆",
	["#GM"] = "联邦的先锋",
	["liangchan"] = "量产",
	[":liangchan"] = "你使用【杀】时可额外指定一个目标。",
	["JEGAN"] = "积根",
	["#JEGAN"] = "联邦之杰",
	["lianxie"] = "连携",
	[":lianxie"] = "出牌阶段限一次，你可以将一张锦囊牌当【战术连携】使用。",
	["BUCUE"] = "巴库",
	["#BUCUE"] = "沙漠猛犬",
	["M1ASTRAY"] = "M1迷惘",
	["#M1ASTRAY"] = "奥布主力",
	["FLAG"] = "旗帜式",
	["#FLAG"] = "翱翔的战士",
	["kongxi"] = "空袭",
	[":kongxi"] = "<b><font color='blue'>锁定技，</font></b>你的黑色【杀】无视目标角色的防具。",
	["TIEREN"] = "铁人",
	["#TIEREN"] = "疆土的守卫者",
	["GENOACE"] = "杰诺亚斯",
	["#GENOACE"] = "UE的对立者",
	["GAFRAN"] = "格夫兰",
	["#GAFRAN"] = "未知的敌人",
	--["LuaDiyu"] = "抵御",
	--[":LuaDiyu"] = "你的体力值减少后，你可以摸一张牌。 ",
}