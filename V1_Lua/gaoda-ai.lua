function bindSkills(room)
	--local skillsOnline={"aitarget"}
	local skillsOnline={}	
	local skillsAll={"#jianwuskill","#jianwuinvoke","#liurenskill","#liuren2skill"}
	local all = room:getAlivePlayers()
	for _, p in sgs.qlist(all) do
		for _, itemAll in ipairs(skillsAll) do
			room:acquireSkill(p,itemAll)
		end
		for _, itemOnline in ipairs(skillsOnline) do
			if p:getState() ~= "robot" then room:acquireSkill(p,itemOnline) end
		end
	end	
end

sgs.ai_skill_invoke["#jianwuskill"] = function(self, data)
	local dying = data:toDying()
	return self:isEnemy(dying.who)
end

local jianwuskillvs_skill={}
jianwuskillvs_skill.name="jianwuskillvs"
table.insert(sgs.ai_skills, jianwuskillvs_skill)
jianwuskillvs_skill.getTurnUseCard = function(self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:objectName() == "jianwu_sword" then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end

	local card_str = ("#jianwuskillcard:%d:")
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func.jianwuskillcard = function(card, use, self)
	local equips = {}
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:objectName() == "jianwu_sword" then
			if not self:getSameEquip(card) then
			else
				table.insert(equips, card)
			end
		end
	end

	if #equips == 0 then return end

	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			if not self:getSameEquip(equip, friend) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end

	if not target then return end
	if use.to then
		use.to:append(target)
	end
	local jianwuskillvs = sgs.Card_Parse("#jianwuskillcard:%d:" .. select_equip:getId())
	use.card = jianwuskillvs
end

sgs.ai_card_intention.jianwuskillcard = -80

sgs.ai_cardneed.jianwuskillvs = sgs.ai_cardneed.equip

function sgs.ai_weapon_value.jianwu_sword()
	return 3.8
end

function sgs.ai_armor_value.liuren_shield()
	return 3.8
end

sgs.ai_skill_invoke["#liurenskill"] = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["#liurenskill"] = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
end

sgs.ai_skill_choice.xiaohao = function(self, choice)
    if self.player:getHandcardNum() >= 3 then
	    return "xhdis"
	else
	    if self.player:isWounded() then
		    return "xhmaxhp"
		else
		    return "xhhp"
	    end
	end
end

sgs.ai_skill_invoke.chunzhong = function(self, data)
	return true
end

sgs.ai_skill_invoke.sanhua = function(self, data)
	return true
end

sgs.ai_skill_invoke.yuanjian = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_invoke.yazhi = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_invoke.sushe = function(self, data)
	return true
end

sgs.ai_view_as.shuangjia = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:getSuit() == sgs.Card_Heart then
		return ("jink:shuangjia[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.baofeng = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.to)
end

sgs.ai_skill_invoke.canyingmopai = function(self, data)
	return true
end

sgs.ai_skill_invoke.luaqianggong = function(self, data)
	return true
end

sgs.ai_skill_invoke.fanqin = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.from)
end

local jianwu_skill={}
jianwu_skill.name="jianwu"
table.insert(sgs.ai_skills,jianwu_skill)
jianwu_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local anal_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:inherits("Weapon") then
			anal_card = card
			break
		end
	end

	if anal_card then
		local suit = anal_card:getSuitString()
		local number = anal_card:getNumberString()
		local card_id = anal_card:getEffectiveId()
		local card_str = ("slash:jianwu[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		return slash
	end
end

sgs.ai_filterskill_filter.jianwu = function(card, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Weapon") then return ("slash:jianwu[%s:%s]=%d"):format(suit, number, card_id) end
end

sgs.ai_skill_invoke.liuren = function(self, data)
	return true
end

sgs.ai_skill_invoke.baofa = function(self, data)
	return self.player:getHp() < 4
end

sgs.ai_skill_choice.lijietarget = function(self, choice)
    local who = self.room:getCurrent()
	if self:isFriend(who) then return "agree" end
	return "disagree"
end

sgs.harute_suit_value = 
{
	heart = 6
}

sgs.harute_keep_value = 
{
	Peach = 6,
	Jink = 5.1,
	Crossbow = 5,
	Blade = 5,
	Spear = 5,
	DoubleSword =5,
	QinggangSword=5,
	Axe=5,
	KylinBow=5,
	Halberd=5,
	IceSword=5,
	Fan=5,
	MoonSpear=5,
	GudingBlade=5,
	DefensiveHorse = 5,
	OffensiveHorse = 5
}

sgs.harute6_keep_value = 
{
	Peach = 6,
	Jink = 5.1,
	Crossbow = 5,
	Blade = 5,
	Spear = 5,
	DoubleSword =5,
	QinggangSword=5,
	Axe=5,
	KylinBow=5,
	Halberd=5,
	IceSword=5,
	Fan=5,
	MoonSpear=5,
	GudingBlade=5,
	DefensiveHorse = 5,
	OffensiveHorse = 5
}

sgs.ai_view_as.liepao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Slash") and card:isBlack() then return ("thunder_slash:liepao[%s:%s]=%d"):format(suit, number, card_id) end
end

local liepao_skill={}
liepao_skill.name="liepao"
table.insert(sgs.ai_skills,liepao_skill)
liepao_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local black_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:inherits("Slash") and card:isBlack() then
			black_card = card
			break
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("thunder_slash:liepao[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_view_as.liepao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Slash") and card:isRed() then return ("fire_slash:liepao[%s:%s]=%d"):format(suit, number, card_id) end
end

local liepao_skill={}
liepao_skill.name="liepao"
table.insert(sgs.ai_skills,liepao_skill)
liepao_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local red_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:inherits("Slash") and card:isRed() then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("fire_slash:liepao[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_skill_invoke.ronghe = function(self, data)
	return true
end

sgs.ai_view_as.qunxi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Slash") then
		return ("archery_attack:qunxi[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local qunxi_skill={}
qunxi_skill.name="qunxi"
table.insert(sgs.ai_skills,qunxi_skill)
qunxi_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local black_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:inherits("Slash") then
			black_card = card
			break
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("archery_attack:qunxi[%s:%s]=%d"):format(suit, number, card_id)
		local archery_attack = sgs.Card_Parse(card_str)

		assert(archery_attack)

		return archery_attack
	end
end

sgs.ai_skill_invoke.qinshi = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.to)
end

sgs.ai_skill_invoke.jiansi = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end

sgs.ai_skill_invoke.quanren = function(self, data)
	local judge = data:toJudge()
	return judge:isBad()
end

sgs.ai_skill_invoke.yuanzu = function(self, data)
	return true
end

sgs.ai_skill_invoke.feiti = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_invoke.sanbei = function(self, data)
	return true
end

sgs.ai_view_as.xiaya = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isRed() then
		return ("jink:xiaya[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.zaishi = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.from)
end

sgs.sazabi_suit_value = 
{
	diamond = 4.1,
	heart = 4.2
}

sgs.sinanju_suit_value = 
{
	diamond = 4.1,
	heart = 4.2
}

sgs.ai_skill_invoke.chihun = function(self, data)
	local damage = data:toDamage()
	return self:isFriend(damage.to) and not self:isFriend(damage.from)
end

sgs.ai_skill_invoke.sidao = function(self, data)
    local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Weapon") then
			n = n + 1
		end
	end
	local target = data:toPlayer()
	return n > 0 and not self:isFriend(target)
end

sgs.ai_skill_invoke.bati = function(self, data)
    local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") then
			n = n + 1
		end
	end
	local damage = data:toDamage()
	return n > 0 and not self:isFriend(damage.from)
end

local dianbo_skill={}
dianbo_skill.name="dianbo"
table.insert(sgs.ai_skills,dianbo_skill)
dianbo_skill.getTurnUseCard=function(self,inclusive)
	if self.player:getMark("@dianbo") == 0 then return nil end

	local card_str = ("#dianbo:%d:")
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#dianbo"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["#dianbo"] = 100
sgs.ai_use_value["#dianbo"] = 100

sgs.tho_keep_value = 
{
	Peach = 6,
	Jink = 5.1,
	Slash = 5,
	Crossbow = 5,
	Blade = 5,
	Spear = 5,
	DoubleSword =5,
	QinggangSword=5,
	Axe=5,
	KylinBow=5,
	Halberd=5,
	IceSword=5,
	Fan=5,
	MoonSpear=5,
	GudingBlade=5,
}

sgs.ai_skill_invoke.jvpao = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.to)
end

sgs.ai_view_as.feidanvs = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:inherits("Jink") then
		return ("archery_attack:feidan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local feidan_skill={}
feidan_skill.name="feidan"
table.insert(sgs.ai_skills,feidan_skill)
feidan_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local black_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:inherits("Jink") then
			black_card = card
			break
		end
	end

	if black_card and self.player:getMark("@xiejia") == 0 and (self.player:getMark("feidanused") < self.player:getLostHp()) then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("archery_attack:feidan[%s:%s]=%d"):format(suit, number, card_id)
		local archery_attack = sgs.Card_Parse(card_str)

		assert(archery_attack)

		return archery_attack
	end
end

sgs.ai_skill_playerchosen.xiejia = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.zihun = function(self, data)
    local damage = data:toDamage()
	return damage.damage >= self.player:getHp() or self.player:getPile("fuyou"):length() == 0
end

sgs.ai_view_as.abao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() then
		return ("thunder_slash:abao[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local abao_skill={}
abao_skill.name="abao"
table.insert(sgs.ai_skills,abao_skill)
abao_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local black_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card)<sgs.ai_use_value.Slash) or inclusive) then
			black_card = card
			break
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("thunder_slash:abao[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_skill_invoke.ganying = function(self, data)
	return true
end

sgs.ai_skill_invoke.jingshen = function(self, data)
	return true
end

sgs.ai_skill_invoke.guangdun = function(self, data)
	return true
end

local shenzhang_skill={}
shenzhang_skill.name="shenzhang"
table.insert(sgs.ai_skills,shenzhang_skill)
shenzhang_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasFlag("shenzhangused") then return false end
	return sgs.Card_Parse("#shenzhang:.:")
end

sgs.ai_skill_use_func["#shenzhang"]=function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)

	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 2 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 then
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart or card:getNumber() == 13 then
				    if card:getSuit() == sgs.Card_Heart and card:getNumber() == 13 then
					    use.card = sgs.Card_Parse("#shenzhang_big:"..card:getId()..":")
					else
					    use.card = sgs.Card_Parse("#shenzhang:"..card:getId()..":")
					end
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["#shenzhang"] = 10
sgs.ai_use_value["#shenzhang"] = 10

sgs.ai_skill_choice.shenzhang = function(self, choice)
	return "damage*3"
end

sgs.ai_skill_playerchosen.shijiang = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

local shuangpao_skill={}
shuangpao_skill.name="shuangpao"
table.insert(sgs.ai_skills,shuangpao_skill)
shuangpao_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasFlag("shuangpaoused") then return nil end
	
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") and self.player:getHp() > 1 and ((self.player:canSlashWithoutCrossbow()) or (self.player:getWeapon() and self.player:getWeapon():className() == "Crossbow")) then
			for _,enemy in ipairs(self.enemies) do
			    if self:slashIsEffective(card, enemy) then
					local card_str = ("#shuangpao:%d:")
					return sgs.Card_Parse(card_str)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#shuangpao"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["#shuangpao"] = 5
sgs.ai_use_value["#shuangpao"] = 9

sgs.ai_skill_invoke.lingshi = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()

	local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Peach") or card:inherits("Analeptic") then
			n = n + 1
		end
	end

	return n < peaches
end

sgs.ai_skill_invoke.yinxing = function(self, data)
	return true
end

sgs.ai_skill_invoke.ansha = function(self, data)
	local player = self.room:getCurrent()
	return not self:isFriend(player)
end

sgs.ai_skill_invoke.zaji = function(self, data)
	return true
end

sgs.ai_skill_invoke.shuanglian = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.shuanglian = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.liekong = function(self, data)
	return true
end

sgs.ai_skill_invoke.laobing = function(self, data)
	return true
end

sgs.ai_skill_invoke.baopo = function(self, data)
    local damage = data:toDamage()
	return self:isEnemy(damage.to) and not damage.to:hasSkill("xiaoji")
end

sgs.ai_skill_invoke.qunshou = function(self, data)
    local effect = data:toCardEffect()
	return not self:isFriend(effect.from)
end

sgs.ai_skill_playerchosen.shuizhan = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.qianfu = function(self, data)
	return self.player:getHandcardNum() > self.player:getMaxCards()
end

sgs.ai_skill_invoke.huanzhuang = function(self, data)
    if self.player:getPhase() == sgs.Player_Start then
		local cards = self.player:getHandcards()
		local n = 0
		for _, card in sgs.qlist(cards) do
			if card:inherits("Slash") then
				n = n + 1
			end
		end
	    return n > 0 and self.player:getHandcardNum() > 1
	else
	    return true
	end
end

sgs.ai_skill_invoke.xiangzhuan = function(self, data)
	return true
end

sgs.ai_skill_invoke.pojia = function(self, data)
	return self.player:getEquips():length() < 3 or (self.player:isWounded() and self.player:hasArmorEffect("silver_lion")) or self.player:getHp() < 2 or data:toDamage().from:getHp() < 3
end

sgs.ai_skill_invoke.shenlou = function(self, data)
	return true
end

sgs.ai_skill_invoke.zhuanjin = function(self, data)
	return self:isFirend(data:toDying().who)
end

sgs.ai_skill_invoke.zhuangjia = function(self, data)
    local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Peach") then
			n = n + 1
		end
	end
	return n == 0 or self.player:getHp() < 2
end

sgs.ai_skill_invoke.jiandao = function(self, data)
	return self:isEnemy(data:toDamage().to)
end

sgs.ai_skill_invoke.helie = function(self, data)
	local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Peach") or card:inherits("Jink") or card:inherits("ExNihilo") then
			n = n + 1
		end
	end
	return n == 0 or self.player:getHandcardNum() < 2
end

sgs.ai_skill_invoke.jiaoxie = function(self, data)
	return true
end

sgs.ai_skill_invoke.huixuan = function(self, data)
	return true
end

sgs.ai_skill_choice.huixuan = function(self, choice)
    local x = math.random(1, 2)
	if x == 1 then return "hxthrow" end
	return "hxreturn"
end

sgs.ai_skill_invoke.jinduan = function(self, data)
	return not data:toCardEffect().card:isKindOf("GodSalvation") and not data:toCardEffect().card:isKindOf("AmazingGrace") and not data:toCardEffect().card:isKindOf("Peach")
end

sgs.ai_skill_playerchosen.jinduan = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.liesha = function(self, data)
	return true
end

sgs.ai_skill_invoke.longqi = function(self, data)
    local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") then
			n = n + 1
		end
	end
	return n > 0
end

sgs.ai_skill_playerchosen.longqi = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.zhongcheng = function(self, data)
    local damage = data:toDamage()
	return self:isEnemy(damage.from)
end

sgs.ai_skill_invoke.daohe = function(self, data)
	return true
end

sgs.ai_skill_invoke["#meiying"] = function(self, data)
	return true
end

sgs.ai_skill_invoke["#jianying"] = function(self, data)
	return true
end

sgs.ai_skill_invoke["#jiying"] = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end

sgs.ai_skill_invoke.chaoqi = function(self, data)
	return true
end

sgs.ai_skill_invoke.huanyi = function(self, data)
	return true
end

sgs.ai_skill_invoke.feiniao = function(self, data)
	return data:toSlashEffect().from:getHp() > self.player:getHp()
end

sgs.ai_skill_invoke.jiqi = function(self, data)
	local cards = self.player:getHandcards()
	local n = 0
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") then
			n = n + 1
		end
	end
	return n > 0
end

sgs.ai_skill_invoke.kelong = function(self, data)
	return self:isEnemy(data:toDying().damage.from)
end

sgs.ai_view_as.jianmie = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:objectName() == "slash" then
		return ("fire_slash:jianmie[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local jianmie_skill={}
jianmie_skill.name="jianmie"
table.insert(sgs.ai_skills,jianmie_skill)
jianmie_skill.getTurnUseCard=function(self,inclusive)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	local n_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards) do
		if card:objectName() == "slash" then
			n_card = card
			break
		end
	end

	if n_card then
		local suit = n_card:getSuitString()
		local number = n_card:getNumberString()
		local card_id = n_card:getEffectiveId()
		local card_str = ("fire_slash:jianmie[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end

sgs.ai_skill_invoke.jianmie = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.jianmie = function(self, targets)
	for _, target in sgs.qlist(targets) do
		if not self:isFriend(target) then
			return target
		end
	end
end

sgs.ai_skill_invoke.shenshou = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

local paojicard_skill={}
paojicard_skill.name="paojicard"
table.insert(sgs.ai_skills,paojicard_skill)
paojicard_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasFlag("shuangpaoused") or self.player:getMark("@ex") == 0 then return nil end
	
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:inherits("Slash") and self.player:getHp() > 1 and ((self.player:canSlashWithoutCrossbow()) or (self.player:getWeapon() and self.player:getWeapon():className() == "Crossbow")) then
			for _,enemy in ipairs(self.enemies) do
			    if self:slashIsEffective(card, enemy) then
					local card_str = ("#paojicard:%d:")
					return sgs.Card_Parse(card_str)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#paojicard"]=function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["#paojicard"] = 5
sgs.ai_use_value["#paojicard"] = 9