module("extensions.gaoda",package.seeall)--游戏包
extension=sgs.Package("gaoda")--增加拓展包

equipmaker = sgs.General(extension, "equipmaker", "qun", 3, true, true,true)

jianwu_sword=sgs.Weapon(sgs.Card_Spade,5,5)
jianwu_sword:setObjectName("jianwu_sword")
jianwu_sword:setParent(extension)

liuren_shield=sgs.Armor(sgs.Card_Spade,6)
liuren_shield:setObjectName("liuren_shield")
liuren_shield:setParent(extension)

--[[okk=sgs.DefensiveHorse(sgs.Card_Spade,7,2)
okk:setObjectName("okk")
okk:setParent(extension)]]

--[[wch=sgs.OffensiveHorse(sgs.Card_Spade,8,-2)
wch:setObjectName("wch")
wch:setParent(extension)]]

--[[local myslash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_Diamond, 1)
myslash:setParent(extension)]]

local function causeDamage(from, to, num, nature, card)
	local damage = sgs.DamageStruct()
	damage.from = from
	damage.to = to
	if num then
		damage.damage = num
	else
		damage.damage = 1
	end
	if nature then
		if nature == "normal" then
			damage.nature = sgs.DamageStruct_Normal
		elseif nature == "fire" then
			damage.nature = sgs.DamageStruct_Fire
		elseif nature == "thunder" then
			damage.nature = sgs.DamageStruct_Thunder
		end
	else
		damage.nature = sgs.DamageStruct_Normal
	end
	if card then
		damage.card = card
	end
	local room = from:getRoom()
	room:damage(damage)
end

jianwuskillcard = sgs.CreateSkillCard{
        name = "jianwuskillcard",
        will_throw = false,
        target_fixed = false,
        filter = function(self, targets, to_select)
                if #targets>0 then return false end
                if to_select:objectName()==sgs.Self:objectName() then return false end
                        return to_select:getWeapon() == nil
        end,
        on_use = function(self, room, source, targets)
                room:moveCardTo(self, targets[1], sgs.Player_Equip, true)
                source:drawCards(1)
        end,
}

jianwuskillvs = sgs.CreateViewAsSkill{
        name = "jianwuskillvs",
        n = 1,
        view_filter = function(self, selected, to_select)
                return to_select:objectName() == "jianwu_sword"
        end,
        view_as = function(self, cards)
                if #cards ~= 1 then return nil end
                local acard = jianwuskillcard:clone()
                for _,card in ipairs(cards) do
                        acard:addSubcard(card:getId())
                end
                return acard
        end,
        enabled_at_play = function()
                return true
        end,
        enabled_at_response = function(self, player, pattern)
                return false
        end,
}

jianwuskill=sgs.CreateTriggerSkill
{
	name = "#jianwuskill",
	events = {sgs.Dying,sgs.AskForPeachesDone},
	priority = 11,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		local current = room:getCurrent()
		if event == sgs.Dying and dying.damage.from:objectName() == current:objectName() and ((not dying.damage.card) or (dying.damage.card and not dying.damage.card:inherits("Slash") and not dying.damage.card:inherits("Duel"))) and current:getWeapon():objectName()=="jianwu_sword" and not current:hasSkill("wansha") and not current:hasSkill("LUAWanSha") and room:askForSkillInvoke(current, self:objectName(), data) then
		   room:acquireSkill(current,"LUAWanSha")
		elseif event == sgs.AskForPeachesDone and current:getGeneralName() ~= "jiaxu" and current:getGeneralName() ~= "sp_jiaxu" then
		   room:detachSkillFromPlayer(current,"LUAWanSha")
		end
	end,
}

LUAWanSha=sgs.CreateTriggerSkill{
	name="LUAWanSha",
	events=sgs.AskForPeaches,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local current=room:getCurrent()
		if current:isAlive() and current:hasSkill("LUAWanSha") then
			local dying=data:toDying()
			local who=dying.who
			return not (player:getSeat()==current:getSeat() or player:getSeat()==who:getSeat())
		end
	end,
	can_trigger=function(self,player)
		return player and player:isAlive()
	end,
}

jianwuinvoke=sgs.CreateTriggerSkill
{
	name = "#jianwuinvoke",
	events = {sgs.GameStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		room:attachSkillToPlayer(player,"jianwuskillvs")
	end,
}

liurenskill = sgs.CreateTriggerSkill{
	name = "#liurenskill",
	events = {sgs.CardLost},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toCardMove()
		local cd = sgs.Sanguosha:getCard(move.card_id)
		if move.from_place == sgs.Player_Equip and cd:objectName() == "liuren_shield" and room:askForSkillInvoke(player, self:objectName(), data) then
		    local tos = sgs.SPlayerList()
			local list = room:getOtherPlayers(player)
			for _,p in sgs.qlist(list) do
			if not p:isProhibited(p, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
			tos:append(p)
			end
			end
			local target = room:askForPlayerChosen(player, tos, self:objectName())
			if target then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                slash:setSkillName(self:objectName())
                local use = sgs.CardUseStruct()
                use.from = player

                use.to:append(target)
                                                         
                use.card = slash
                room:useCard(use,false)
			end
		end
	end,
}

liuren2skill = sgs.CreateTriggerSkill{
	name = "#liuren2skill",
	events = sgs.SlashEffected,
	frequency = sgs.Skill_Compulsory,	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()	
		local effect = data:toSlashEffect()
		if (effect.slash:inherits("FireSlash") or effect.slash:inherits("ThunderSlash")) and effect.to:objectName()==player:objectName() and player:hasArmorEffect("liuren_shield") then
			local log = sgs.LogMessage()
			log.type = "#liuren_shield_msg"
			log.from = player
			log.arg  = "liuren_shield"
			room:sendLog(log)
			room:playSkillEffect("liuren_shield")
			return true
		end
		return false		
	end,
}

seshia = sgs.CreateTriggerSkill{
	name = "#seshia",
	events = sgs.PhaseChange,	
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if player:getPhase() == sgs.Player_Start and player:getState() ~= "robot" then
	    player:speak("来！开始吧！<font color='red'>♥</font>")
		room:setEmotion(player,"seshia")
    end			
	end,
}

equipmaker:addSkill(jianwuskill)
equipmaker:addSkill(jianwuskillvs)
equipmaker:addSkill(jianwuinvoke)
equipmaker:addSkill(liurenskill)
equipmaker:addSkill(liuren2skill)
equipmaker:addSkill(LUAWanSha)
equipmaker:addSkill(seshia)

local generalnames=sgs.Sanguosha:getLimitedGeneralNames()
local hidden={"sp_diaochan","sp_sunshangxiang","sp_pangde","sp_caiwenji","sp_machao","sp_jiaxu","anjiang","shenlvbu1","shenlvbu2","sujiang","sujiangf","ECLIPSE","XENON","AIOS","ooqb","harute6","00-RAISER2","Hyper_GOD","transam_exia"}
table.insertTable(generalnames,hidden)
for _, generalname in ipairs(generalnames) do
	local general = sgs.Sanguosha:getGeneral(generalname)
	if general then
		general:addSkill("#liurenskill")
		general:addSkill("#liuren2skill")
		general:addSkill("#jianwuinvoke")
		general:addSkill("#jianwuskill")
		general:addSkill("#yinxingp")
		general:addSkill("#shuanglongp")
		general:addSkill("#aobup")
		general:addSkill("#seshia")
		--[[general:addSkill("sjiao")]]
	end
end

--EXIA

exia = sgs.General(extension, "exia", "god", 5,true,false)--增加武将

-- 原剑

yuanjian=sgs.CreateTriggerSkill{
        name="yuanjian",
        events={sgs.CardUsed,sgs.Predamage,sgs.CardFinished},
        priority=2,
        frequency=sgs.Skill_NotFrequent,
        on_trigger=function(self,event,player,data)
        local room=player:getRoom()
        local use=data:toCardUse()
        local card = use.card        
        local log=sgs.LogMessage()
        log.type = "#yuanjian"
        log.from=player
        if event==sgs.CardUsed and card:inherits("Slash") and card:getSuit() == sgs.Card_Spade and not player:hasFlag("yuanjian_used") and room:askForSkillInvoke(player, self:objectName()) then
                                room:playSkillEffect("yuanjian")
                                room:sendLog(log)
                                for _,p in sgs.qlist(use.to) do
								local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if(judge:isGood()) then
			room:setEmotion(player,"yuanjian")
                                        p:addMark("qinggang")                                
                                end
								end
                                room:setPlayerFlag(player,"yuanjian_used")
                                room:useCard(use,false)
                                for _,p in sgs.qlist(use.to) do
                                        p:removeMark("qinggang")                                
                                end        
                                room:setPlayerFlag(player,"-yuanjian_used")
                                return true
        elseif event==sgs.CardUsed and card:inherits("Slash") and card:getSuit() == sgs.Card_Heart and room:askForSkillInvoke(player, self:objectName()) then
		    local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if(judge:isGood()) then
			room:setEmotion(player,"yuanjian")
			player:addMark("yuanjian2")
			end
		elseif event == sgs.CardFinished and card:inherits("Slash") and card:getSuit() == sgs.Card_Heart then
		    player:removeMark("yuanjian2")
		elseif event==sgs.Predamage then
		    local damage = data:toDamage()
			local cd = damage.card
		    if cd:inherits("Slash") and cd:getSuit() == sgs.Card_Heart and player:getMark("yuanjian2") > 0 then
		       room:playSkillEffect("yuanjian")
		       local x = damage.damage
			   local log = sgs.LogMessage()
	            log.type = "#yuanjian"
	            log.from = player
	            room:sendLog(log)
			    room:loseHp(damage.to,x)
				return true
			end
		elseif event==sgs.CardUsed and card:inherits("Slash") and card:getSuit() == sgs.Card_Club then
		    for _,p in sgs.qlist(use.to) do
			if p:isKongcheng() then return end
			room:askForSkillInvoke(player, self:objectName())
			room:playSkillEffect("yuanjian")
			local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if(judge:isGood()) then
			room:setEmotion(player,"yuanjian")
			room:throwCard(room:askForCardChosen(player, p ,"h",self:objectName()))
			end
			end
		elseif event==sgs.CardUsed and card:inherits("Slash") and card:getSuit() == sgs.Card_Diamond and room:askForSkillInvoke(player, self:objectName()) then
		    room:playSkillEffect("yuanjian")
			local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(heart):(.*)")
			judge.good = false
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if(judge:isGood()) then
			room:setEmotion(player,"yuanjian")
			room:acquireSkill(player,"wushuang")
			end
		elseif event == sgs.CardFinished and card:inherits("Slash") and card:getSuit() == sgs.Card_Diamond and player:hasSkill("wushuang") then
			room:detachSkillFromPlayer(player,"wushuang")
        end
	end
}

lingmin = sgs.CreateDistanceSkill{
--灵敏
   name = "lingmin",
   correct_func = function(self, from, to)
       if from:hasSkill("lingmin") and to:getHandcardNum() <= from:getHp() then
       return -1
    end
end,
}


exia:addSkill(yuanjian)
exia:addSkill(lingmin)

dynames = sgs.General(extension, "dynames$", "god", 5,true,false)

yazhi=sgs.CreateTriggerSkill{
        name="yazhi",
        events={sgs.SlashProceed},
		priority=2,
        frequency=sgs.Skill_NotFrequent,
    on_trigger=function(self,event,player,data)
        local room=player:getRoom()
		local effect = data:toSlashEffect()
    if event == sgs.SlashProceed and room:askForSkillInvoke(player, self:objectName()) then
	    room:playSkillEffect(self:objectName())
		if room:askForCard(effect.to,"Slash,EquipCard,TrickCard|.|.|hand|.","@yazhi",data) then
		    return true
		else
			room:slashResult(effect, nil)
			return true
		end
	end
    end
}

jingzhun=sgs.CreateTriggerSkill{
        name="jingzhun",
        events=sgs.CardUsed,
        priority=2,
        frequency=sgs.Skill_Compulsory,
        on_trigger=function(self,event,player,data)
        local room=player:getRoom()
        local use=data:toCardUse()
        local card = use.card        
        local log=sgs.LogMessage()
        log.type = "#jingzhun"
        log.from=player
        if event==sgs.CardUsed and card:inherits("Slash") and not player:hasFlag("jingzhun_used") then
                                room:playSkillEffect("jingzhun")                                
                                room:sendLog(log)
                                for _,p in sgs.qlist(use.to) do
                                        p:addMark("qinggang")                                
                                end                                    
                                room:setPlayerFlag(player,"jingzhun_used")
                                room:useCard(use,false)
                                for _,p in sgs.qlist(use.to) do
                                        p:removeMark("qinggang")                                
                                end        
                                room:setPlayerFlag(player,"-jingzhun_used")
                                return true
        end
        end,
}

jingzhundistance = sgs.CreateSlashSkill
{
	name = "jingzhundistance",
    can_trigger = function(self, player)
                return player:hasSkill("jingzhun")
        end,
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("jingzhun") and to and to:getDefensiveHorse()~=nil) then
			return -2
		end
	end,
}

dynames:addSkill(yazhi)
dynames:addSkill(jingzhun)

kyrios = sgs.General(extension, "kyrios", "god", 5,true,false)

sushe=sgs.CreateTriggerSkill{
        name="sushe",
        events=sgs.CardUsed,
		priority=1,
        frequency=sgs.Skill_NotFrequent,
        on_trigger=function(self,event,player,data)
        local room=player:getRoom()
		local use=data:toCardUse()
        local cd = use.card
        if event==sgs.CardUsed and cd:inherits("Slash") and room:askForSkillInvoke(player, self:objectName()) then
		        local card_id = room:drawCard() --取一张牌
				local card=sgs.Sanguosha:getCard(card_id)
                room:moveCardTo(card,nil,sgs.Player_Special,true)
                room:getThread():delay()
				if(card:inherits("Slash") or card:inherits("EquipCard") or card:inherits("Collateral"))then
				room:obtainCard(player,card_id)
                else
                    room:throwCard(card_id)
					end
					end
					end
}

hongzhacard=sgs.CreateSkillCard{
name="hongzhacard",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets > 0 then return false end
          return to_select:objectName() ~= player:objectName()
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
		room:throwCard(self)
        local damage=sgs.DamageStruct()
        damage.damage=(self:subcardsLength())
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
		damage.from=effect.from
        damage.to=effect.to
		room:askForDiscard(effect.from,"hongzhacard",self:subcardsLength()-1,self:subcardsLength()-1,false,false)
		effect.from:loseMark("@hongzha")
		room:playSkillEffect("hongzhaTS")
        local log=sgs.LogMessage()
        log.type = "#hongzha"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
end                
}

hongzha=sgs.CreateViewAsSkill{
name="hongzha",
n=998,
view_filter=function(self, selected, to_select)
        return to_select:isEquipped()
end,
view_as = function(self, cards)
		if ((sgs.Self:getEquips():length()-1) > (sgs.Self:getHandcardNum())) then return end
		if #cards > 0 then
			local new_card = hongzhacard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("hongzha")
			return new_card
		else return nil
		end
	end,
	enabled_at_play=function(self,player) 
        return player:getMark("@hongzha") > 0
    end,
}

hongzhaTS=sgs.CreateTriggerSkill
{
	name="hongzhaTS",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = hongzha,
	
	on_trigger=function(self,event,player,data)
		player:gainMark("@hongzha")
	end,
}


kyrios:addSkill(hongzhaTS)
kyrios:addSkill(sushe)

throne1 = sgs.General(extension, "throne1", "god", 4,true,false)

hongguangcard = sgs.CreateSkillCard
{--流离技能卡 by hypercross
	name = "hongguangcard",
	target_fixed = false,
	will_throw = true,

	filter = function(self, targets, to_select, player)
		if #targets > 1 then return false end
		if to_select:hasFlag("slash_source") then return false end
		if (to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_Heart, 0))) then return false end

		local card_id = self:getSubcards()[1]
		if sgs.Self:getWeapon() and sgs.Self:getWeapon():getId() == card_id then 
			return sgs.Self:distanceTo(to_select) <= 1	--如果拿来流离的牌正好是自己的武器，则只能对距离1以内的使用
		end

		return sgs.Self:canSlash(to_select, true) or not sgs.Self:inMyAttackRange(to_select)	--其他情况：自己的攻击范围
	end,

	on_effect = function(self, effect)
		effect.to:getRoom():setPlayerFlag(effect.to, "hongguangtarget")
	end
}

hongguangVS = sgs.CreateViewAsSkill
{--流离视为技 by hypercross
	name = "hongguangVS",
	n = 1,

	view_filter = function(self, selected, to_select)
		return true
	end,

	view_as = function(self, cards)
		if #cards == 0 then return nil end
		local ahongguangcard = hongguangcard:clone()	--使用之前创建的skillCard的clone方法来创建新的skillCard
		ahongguangcard:addSubcard(cards[1])

		return ahongguangcard
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern) 
		return pattern == "#hongguangcard"
	end
}

hongguang = sgs.CreateTriggerSkill
{--流离触发技 by hypercross
	name = "hongguang",
	view_as_skill = hongguangVS,
	events = {sgs.CardEffected},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local players = room:getOtherPlayers(player)
		local effect = data:toCardEffect()

		if (effect.card:inherits("Slash") and effect.card:isRed()) and (not player:isNude()) and room:alivePlayerCount() > 2 then
			local canInvoke

			for _,aplayer in sgs.qlist(players) do
				if player:canSlash(aplayer) or (not player:inMyAttackRange(aplayer))then 
					canInvoke = true
				end
			end

			if not canInvoke then return end

			local prompt = "#hongguangcard:" .. effect.from:objectName()
			room:setPlayerFlag(effect.from, "slash_source")
			if room:askForUseCard(player, "#hongguangcard", prompt) then 
				room:output("ha?")
				for _,aplayer in sgs.qlist(players) do
					if aplayer:hasFlag("hongguangtarget") then 
						room:setPlayerFlag(effect.from,"-slash_source")
						room:setPlayerFlag(aplayer,"-hongguangtarget")
						effect.to=aplayer

						room:cardEffect(effect)
						if player:isAlive() then
						if player and room:askForChoice(player, self:objectName(), "2targets+1target") == "1target" then
                        return true end
				for _,aplayer in sgs.qlist(players) do
                    if aplayer:hasFlag("hongguangtarget") then 
                       room:setPlayerFlag(effect.from,"-slash_source")
                       room:setPlayerFlag(aplayer,"-hongguangtarget")
                       effect.to=aplayer
                       room:cardEffect(effect)
                       return true end end  end  end end end end end
}

weilu = sgs.CreateTriggerSkill{
 name="weilu",
 events={sgs.PhaseChange ,sgs.HpRecover},
 frequency = sgs.Skill_Compulsory,
 can_trigger = function(self, player)
			return true
	end,
 on_trigger=function(self,event,player,data)
  local room = player:getRoom()
  local selfplayer = room:findPlayerBySkillName(self:objectName())
  if (event==sgs.HpRecover) then
  if not selfplayer:isAlive() then return end
  if(player:getPhase()== sgs.Player_NotActive) then return end
  if player:hasSkill("sanbuFS") then return end
  local recover = data:toRecover()
    for var=1,recover.recover,1 do
    player:gainMark("@weilu",1)
    end
    end
  if (event==sgs.PhaseChange) and (player:getPhase()== sgs.Player_Discard) and (player:getMark("@weilu") >= 1) then
  if not selfplayer:isAlive() then return end
  local x=player:getHp()
  local y=player:getMark("@weilu")
   local z = player:getHandcardNum()
   if z <= (x-y) then
   return true
   else
       local e = z-(x-y)
	  if e > z then
	  room:askForDiscard(player,"weilu",z,z,false,false) 
      else room:askForDiscard(player,"weilu",e,e,false,false)
	  return true
  end
  end
  end
  if (event==sgs.PhaseChange) and (player:getPhase()== sgs.Player_Finish) and (player:getMark("@weilu") >= 1) then
  local y=player:getMark("@weilu")
  player:loseMark("@weilu",y)
  end
  end,
  }

xianzhi = sgs.CreateFilterSkill{
    name = "xianzhi",
	
    view_filter = function(self, card)
        return card:inherits("ExNihilo")
    end,
	
    view_as = function(self, card)
        local acard = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        return acard
    end
}

xianzhislash = sgs.CreateViewAsSkill
{--武圣 by 【群】皇叔
	name = "xianzhislash",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("IronChain")
	end,

	view_as = function(self, cards)
		if #cards == 0 then return nil end
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

throne1:addSkill(hongguang)
throne1:addSkill(weilu)
throne1:addSkill(xianzhi)
throne1:addSkill(xianzhislash)

throne2 = sgs.General(extension, "throne2", "god", 4,true,false)

jvren = sgs.CreateTriggerSkill
{
	name = "jvren",
	events = {sgs.CardUsed},
	priority=2,
	frequency = sgs.Skill_Compulsory,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

		if event==sgs.CardUsed then
        local effect=data:toCardUse()
        local card=data:toCardUse().card
		if player:isNude() then return end
        if card:inherits("Slash") and card:getSkillName() ~= "jianya" then
            room:playSkillEffect("jvren")
			room:askForDiscard(effect.from,"jvren",1,1, false,true)
    end        
    end
	end,
}

jianyavs = sgs.CreateViewAsSkill
{
	name = "jianya",
	n = 0,

	view_filter = function(self, selected, to_select)
		return true
	end,

	view_as = function(self, cards)
	    if sgs.Self:getMark("@jianya") < 1 then return nil end
		if #cards <= 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0) 
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player) and player:getMark("@jianya") > 0
	end,

	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

jianya = sgs.CreateTriggerSkill
{
	name = "jianya",
	events = {sgs.GameStart,sgs.CardUsed},
	view_as_skill = jianyavs,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
		    player:gainMark("@jianya",6)
			end
        if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName() == "jianya" then
				player:loseMark("@jianya",1)
			end
			end
	end,
}

lua_fanji = sgs.CreateTriggerSkill
{
	name = "lua_fanji",
	events = {sgs.CardLost ,sgs.PhaseChange},
	frequency = sgs.Skill_Frequent,

	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local move = data:toCardMove()          
      local card = sgs.Sanguosha:getCard(move.card_id)
	  if player:getPhase() ~= sgs.Player_NotActive then return end
      if card:inherits("Jink") then
            room:playSkillEffect("lua_fanji")
	        player:drawCards(1)
	  elseif not card:inherits("Jink") then
	        room:playSkillEffect("lua_fanji")
	        player:gainMark("@jianya",1)
		end
	end,
}

weigongcard=sgs.CreateSkillCard{  --强袭EX卡片
name="weigongcard",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets == 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
        local damage=sgs.DamageStruct()
        damage.damage=3
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
        local log=sgs.LogMessage()
        log.type = "#weigong"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
		room:playSkillEffect("weigong")
		damage.from:loseMark("@jianya",8)
		damage.from:loseMark("@weigong",1)
end                
}

weigongvs=sgs.CreateViewAsSkill{
name="weigong",
n=0,
view_filter=function(self, selected, to_select)
        return true
end,
view_as=function(self, cards)
        if #cards==0 then  
        local acard=weigongcard:clone()
            return acard
        end
end,
enabled_at_play=function(self,player) 
        return player:getMark("@jianya") >= 8 and player:getMark("@weigong") > 0
end,
enabled_at_response=function(self,player,pattern) 
        return false 
end
}

weigong=sgs.CreateTriggerSkill
{
	name="weigong",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = weigongvs,
	
	on_trigger=function(self,event,player,data)
		player:gainMark("@weigong",1)
	end,
}

throne2:addSkill(jvren)
throne2:addSkill(jianya)
throne2:addSkill(lua_fanji)
throne2:addSkill(weigong)

throne3 = sgs.General(extension, "throne3", "god", 3,false,false)

lua_zhiyuan = sgs.CreateTriggerSkill
{--遗计 by roxiel, ibicdlcod修复两张牌不能分给两名其他角色的BUG
	name = "lua_zhiyuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	priority=2,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use=data:toCardUse()
		local card = use.card
		if event == sgs.CardUsed and card:inherits("Peach") then
		if(not room:askForSkillInvoke(player, "lua_zhiyuan")) then return false end

		room:playSkillEffect("lua_zhiyuan")  --音效（音效和LOG属于非核心的内容，建议上下空白一行）

			player:drawCards(2)   --先摸（典藏版描述改了，估计以后也得改）
			local hnum = player:getHandcardNum() --手牌数
			local cdlist = sgs.IntList()   --Int类型的list
			cdlist:append(player:handCards():at(hnum-1))   --插入刚摸的
			cdlist:append(player:handCards():at(hnum-2))   --还是插入刚摸的
			room:askForYiji(player, cdlist)   --这个。。内核自带的一个函数，想必实现遗计神哥花了不少功夫，观星同样
			if(player:getHandcardNum() == hnum-1) then
				celist = sgs.IntList()
				celist:append(player:handCards():at(hnum-2))
				room:askForYiji(player, celist)
		    end
				return true
		end        
	end
}

jiahai = sgs.CreateTriggerSkill
{
	name = "jiahai",
	events = {sgs.Damage ,sgs.SlashProceed ,sgs.CardFinished ,sgs.Predamage},
	priority=2,
	frequency = sgs.Skill_NotFrequent, 
	
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		local use = data:toCardUse()
		local cd = use.card
		if(event == sgs.Damage and card:inherits("Slash")) then
		  
		  room:playSkillEffect("jiahai")
		  
		  if damage.damage >= 2 and room:askForSkillInvoke(player, self:objectName()) then
          room:drawCards(damage.from, 1)

		  elseif damage.damage == 1 then
		  room:setPlayerMark(damage.from, "jiahai", damage.from:getMark("jiahai")+1)
		      if player:getMark("jiahai") >= 2 and room:askForSkillInvoke(player, self:objectName()) then
		      room:drawCards(damage.from, 1)
		  end
		  end
		elseif event == sgs.CardFinished and cd:inherits("Slash") and player:getMark("jiahai") >= 1 then
		  room:setPlayerMark(player, "jiahai", 0)
		elseif event == sgs.Predamage and damage.to:getHp() == 1 then
		if (not room:askForSkillInvoke(player, self:objectName())) then return end
		  room:playSkillEffect("jiahai")
		   damage.damage = damage.damage+1
				data:setValue(damage)
	end
end,
}

sanbu=sgs.CreateTriggerSkill{
    name="#sanbu",
    events=sgs.CardEffected,
    frequency = sgs.Skill_Compulsory,	
on_trigger=function(self,event,player,data)	
    local effect=data:toCardEffect()
    local room=player:getRoom()	
    if (effect.card:inherits("SavageAssault") or effect.card:inherits("ArcheryAttack") or effect.card:inherits("Duel")) and effect.to:hasSkill(self:objectName()) then
    return true 
    end	
end
}

sanbuFS = sgs.CreateFilterSkill{
    name = "sanbuFS",
	
    view_filter = function(self, card)
        return card:inherits("Duel")
    end,
	
    view_as = function(self, card)
        local acard = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        return acard
    end
}

throne3:addSkill(lua_zhiyuan)
throne3:addSkill(jiahai)
throne3:addSkill(sanbu)
throne3:addSkill(sanbuFS)

sp_exia = sgs.General(extension, "sp_exia", "god", 5, true,false)

yuanlu = sgs.CreateMaxCardsSkill{
	name = "yuanlu" ,
	extra_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:isWounded() then
			return 1
		else
			return 0
		end
	end
}

jianyi = sgs.CreateTriggerSkill
{
	name = "jianyi",
	events = {sgs.CardResponsed ,sgs.CardLost ,sgs.PhaseChange},
	frequency = sgs.Skill_Frequent,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()

        if event == sgs.CardResponsed and player:getPhase() ~= sgs.Player_NotActive then
			local cd=data:toCard()
			if cd:inherits("Slash") and room:askForSkillInvoke(player, "jianyi") then
			    room:playSkillEffect("jianyi")
                player:drawCards(1)
			end
	    elseif event == sgs.CardLost and player:getPhase() == sgs.Player_NotActive then
	  		local move = data:toCardMove()          
            local card = sgs.Sanguosha:getCard(move.card_id)
            if card:inherits("Slash") and room:askForSkillInvoke(player, "jianyi") then
	        room:playSkillEffect("jianyi")
			player:drawCards(1)
			end
	end
	end,
}

sp_exia_sanhong = sgs.CreateTriggerSkill
{--突袭 by ibicdlcod
	name = "sp_exia_sanhong",
	events = sgs.Predamaged,
	priority = -1,
	frequency=sgs.Skill_Wake,
	
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	local damage = data:toDamage()
	if damage.damage < player:getHp()-1 then return end
	room:setEmotion(player, "sanhong")
	room:playSkillEffect("sp_exia_sanhong")
	room:transfigure(player, "transam_exia", false, true)
			if player:isChained() then 
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
	return true
end
}

sp_exia:addSkill(yuanlu)
sp_exia:addSkill(jianyi)
sp_exia:addSkill(sp_exia_sanhong)

transam_exia = sgs.General(extension, "transam_exia", "god", 4, true,true,true)

pohuaicard=sgs.CreateSkillCard{  --强袭EX卡片
name="pohuaicard",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets == 1 then return false end
          return to_select:objectName()~=player:objectName() --否则要在攻击范围内
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
        local damage=sgs.DamageStruct() --伤害结构体 这里赘述了一些
        damage.damage=1
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
		room:playSkillEffect("pohuai")
        room:loseMaxHp(effect.from)
        local log=sgs.LogMessage() --广播一下
        log.type = "#pohuai"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
        --effect.from:addHistory("QiangxiCard",1) --用这个方法貌似无效
        room:setPlayerFlag(effect.from,"pohuaiused") --这个方法可以限制每回合一次
end                
}

pohuai=sgs.CreateViewAsSkill{ --强袭EX视为技能
name="pohuai",
n=1,
view_filter=function(self, selected, to_select)
        return not to_select:isEquipped() --已经选择了0张 ，目标是武器
end,
view_as=function(self, cards)
        local acard=pohuaicard:clone() 
        if #cards==1 then --有武器牌就加入子卡
                acard:addSubcard(cards[1])
            acard:setSkillName(self:objectName())     
                return acard
        end
end,
enabled_at_play=function(self,player) 
    if  player:getPhase()==sgs.Player_Finish then player:setFlags("-pohuaiused") end --回合结束取消标记 限制每回合一次
        return not player:hasFlag("pohuaiused") 
        --return not player:hasUsed("QiangxiCard") --这种限制方式无效
end,
enabled_at_response=function(self,player,pattern) 
        return false 
end
}

niuqvcard=sgs.CreateSkillCard{  --急速卡片
	name="niuqvcard",
	once=true,
	will_throw=false,
	filter = function(self, targets, to_select, player)
		if #targets >= 1 then return false end
		if (to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then return false end
		return to_select:objectName()~=player:objectName()
	end,
	on_effect=function(self,effect)                   
		local room = effect.from:getRoom()
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("niuqv")
		local use = sgs.CardUseStruct()
		use.from = effect.from
		use.to:append(effect.to)
		use.card = slash
		room:playSkillEffect("niuqv")
		room:useCard(use,false)
		room:setPlayerFlag(effect.from, "niuqv_used")
	end
}

niuqvVS=sgs.CreateViewAsSkill{
	name="niuqv",
	n=0,
	view_as=function(self, cards)
			if #cards==0 then
				local acard=niuqvcard:clone()         
				acard:setSkillName(self:objectName())     
				return acard
			end
	end,
	enabled_at_play=function(self,player)
			return false
	end,
	enabled_at_response=function(self,player,pattern) 
			return pattern == "@@niuqv"
	end
}

niuqv = sgs.CreateTriggerSkill{
	name="niuqv",
	events=sgs.PhaseChange,
	view_as_skill=niuqvVS,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()==sgs.Player_Finish and player:isKongcheng() then
			if(room:askForSkillInvoke(player,self:objectName()) ~= true) then
			end
			room:askForUseCard(player, "@@niuqv", "@niuqv")
			room:setPlayerFlag(player, "-niuqv_used")
	end
	end
}

qijiandrawvs = sgs.CreateViewAsSkill
{--苦肉 by ibicdlcod
	name = "qijiandraw",
	n = 0,

	view_as = function(self, cards)
	if #cards == 0 then
		local card = qijiandrawcard:clone()		
		card:setSkillName(self:objectName())
		return card
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@qijiandraw") > 0
	end
}

qijiandrawcard = sgs.CreateSkillCard
{--苦肉技能卡 by ibicdlcod
	name = "qijiandraw",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		    source:loseMark("@qijiandraw")
			room:playSkillEffect("qijiandraw")
			room:drawCards(source, 2)
			local choice=room:askForChoice(source, self:objectName(), "qijianTS+qijianTS2+qijianTS3")
			if choice == "qijianTS3" then
			room:askForUseCard(source, "@@qijianTS3", "@qijianTS3")
			elseif choice == "qijianTS2" then
			room:askForUseCard(source, "@@qijianTS2", "@qijianTS2")
			else
			room:askForUseCard(source, "@@qijianTS", "@qijianTS")
			end
	end,
}

qijiandraw = sgs.CreateTriggerSkill{
	name="qijiandraw",
	events=sgs.PhaseChange,
	frequency = sgs.Skill_Limited,
	view_as_skill=qijiandrawvs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
	end
}

qijiancard=sgs.CreateSkillCard{  --强袭EX卡片
name="qijiancard",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets == 1 then return false end
          return to_select:objectName()~=player:objectName() --否则要在攻击范围内
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
		room:throwCard(self)
        local damage=sgs.DamageStruct() --伤害结构体 这里赘述了一些
        damage.damage=(self:subcardsLength())/2
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
		damage.from=effect.from
        damage.to=effect.to
		effect.from:loseMark("@qijian")
		room:playSkillEffect("qijianTS")
        local log=sgs.LogMessage() --广播一下
        log.type = "#qijian"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
        --effect.from:addHistory("QiangxiCard",1) --用这个方法貌似无效
end                
}

qijian=sgs.CreateViewAsSkill{ --强袭EX视为技能
name="qijian",
n=998,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards >= 0 then
			local new_card = qijiancard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("qijian")
			return new_card
		else return nil
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@qijiandraw") == 0 and player:getMark("@qijian") > 0
	end,
	enabled_at_response = function(self,player,pattern) 
        return pattern == "@@qijianTS3" and player:getMark("@qijian") > 0
    end,
}

qijianTS=sgs.CreateTriggerSkill
{
	name="qijianTS",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = qijian,
	
	on_trigger=function(self,event,player,data)
		player:gainMark("@qijiandraw")
		player:gainMark("@qijian")
	end,
}

qijiancard2=sgs.CreateSkillCard{  --强袭EX卡片
name="qijiancard2",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets == 1 then return false end
          return to_select:objectName()~=player:objectName() --否则要在攻击范围内
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
		room:throwCard(self)
        local damage=sgs.DamageStruct() --伤害结构体 这里赘述了一些
        damage.damage=((self:subcardsLength())+1)/2
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
		damage.from=effect.from
        damage.to=effect.to
		effect.from:loseMark("@qijian")
		room:playSkillEffect("qijianTS")
		room:loseHp(effect.from)
        local log=sgs.LogMessage() --广播一下
        log.type = "#qijian2"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
        --effect.from:addHistory("QiangxiCard",1) --用这个方法貌似无效
end                
}

qijian2=sgs.CreateViewAsSkill{ --强袭EX视为技能
name="qijian2",
n=998,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards >= 0 then
			local new_card = qijiancard2:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("qijian2")
			return new_card
		else return nil
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@qijiandraw") == 0 and player:getMark("@qijian") > 0
	end,
	enabled_at_response = function(self,player,pattern) 
        return pattern == "@@qijianTS3" and player:getMark("@qijian") > 0
    end,
}

qijianTS2=sgs.CreateTriggerSkill
{
	name="qijianTS2",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = qijian2,
	
	on_trigger=function(self,event,player,data)
	end,
}

qijiancard3=sgs.CreateSkillCard{  --强袭EX卡片
name="qijiancard3",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets == 1 then return false end
          return to_select:objectName()~=player:objectName() --否则要在攻击范围内
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
		room:throwCard(self)
        local damage=sgs.DamageStruct() --伤害结构体 这里赘述了一些
        damage.damage=((self:subcardsLength())+2)/2
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false 
		damage.from=effect.from
        damage.to=effect.to
		effect.from:loseMark("@qijian")
		room:playSkillEffect("qijianTS")
		room:loseHp(effect.from,2)
        local log=sgs.LogMessage() --广播一下
        log.type = "#qijian3"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
        damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
        --effect.from:addHistory("QiangxiCard",1) --用这个方法貌似无效
end                
}

qijian3=sgs.CreateViewAsSkill{ --强袭EX视为技能
name="qijian3",
n=998,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards >= 0 then
			local new_card = qijiancard3:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("qijian3")
			return new_card
		else return nil
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@qijiandraw") == 0 and player:getMark("@qijian") > 0
	end,
	enabled_at_response = function(self,player,pattern) 
        return pattern == "@@qijianTS3" and player:getMark("@qijian") > 0
    end,
}

qijianTS3=sgs.CreateTriggerSkill
{
	name="qijianTS3",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = qijian3,
	
	on_trigger=function(self,event,player,data)
	end,
}

transam_exia:addSkill(pohuai)
transam_exia:addSkill(niuqv)
transam_exia:addSkill(qijiandraw)
transam_exia:addSkill(qijianTS)
transam_exia:addSkill(qijianTS2)
transam_exia:addSkill(qijianTS3)

CHERUDIM = sgs.General(extension, "CHERUDIM", "god", 3, true,false)

jvji = sgs.CreateTriggerSkill
{
	name = "jvji",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.SlashProceed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
	if event == sgs.SlashProceed and effect.slash:isBlack() and not effect.slash:inherits("FireSlash") and not effect.slash:inherits("ThunderSlash") then
		if effect.slash:getNumber() == 13 then
			room:slashResult(effect, nil)      
			return true
	    else
			local pattern = "Jink|.|"..(effect.slash:getNumber()+1).."~|.|."--感谢冰羽妹
			if room:askForCard(effect.to,pattern,"@jvji",data) then
			    return true
			else
			    room:slashResult(effect, nil)      
			    return true
			    end
			end
		end
	end
}

dunqiangvs = sgs.CreateViewAsSkill
{
	name = "dunqiang",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isRed()
    end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

dunqiang = sgs.CreateTriggerSkill
{
	name = "dunqiang",
	events = {sgs.CardAsked},
    view_as_skill = dunqiangvs,
	priority = 1,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
        local selfplayer = room:findPlayerBySkillName(self:objectName())
	if data:toString() == "jink" and player:objectName() ~= selfplayer:objectName() and selfplayer:inMyAttackRange(player) and room:askForSkillInvoke(selfplayer, self:objectName(),data) then
		local jink_card = room:askForCard(selfplayer, "jink", "@dunqiang", data)
		if jink_card then
		    room:provide(jink_card)
		    return true
		end
	end
	end,
}

haro = sgs.CreateTriggerSkill{
        name = "haro",
        events = {sgs.CardEffected},	
    on_trigger = function(self,event,player,data)	
        local room = player:getRoom()
    	local effect = data:toCardEffect()	
    if (effect.card:inherits("SavageAssault") or effect.card:inherits("ArcheryAttack")) and room:askForSkillInvoke(player, self:objectName(),data) then
        player:drawCards(1)
	    return true 
    end
end
}

chsanhong = sgs.CreateTriggerSkill{
        name = "chsanhong",
        events = {sgs.GameStart,sgs.Predamaged},
		frequency = sgs.Skill_Limited,
    on_trigger = function(self,event,player,data)	
        local room = player:getRoom()
    	local damage = data:toDamage()
    if event == sgs.GameStart then
	    player:gainMark("@chsanhong")
	end
	if event == sgs.Predamaged and player:getMark("@chsanhong") > 0 and room:askForSkillInvoke(player, self:objectName(),data) then
        player:loseMark("@chsanhong")
		damage.to = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName())
		damage.transfer = true
		room:damage(damage)
		
		player:throwAllCards()
		player:turnOver()
		return true
	end
	end
}

CHERUDIM:addSkill(jvji)
CHERUDIM:addSkill(dunqiang)
CHERUDIM:addSkill(haro)
CHERUDIM:addSkill(chsanhong)

arios = sgs.General(extension, "arios", "god", 4, true,true,true)

shuangjia = sgs.CreateViewAsSkill
{--倾国 by ibicdlcod, 【群】皇叔修复response无效的BUG
	name = "shuangjia",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:getSuit() == sgs.Card_Heart
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

lueduo = sgs.CreateViewAsSkill
{
    name = "lueduo",
    n = 1,

    view_filter = function(self, selected, to_select)
        return to_select:isBlack() and not to_select:isEquipped()
    end,

    view_as = function(self, cards)
        if #cards == 1 then
            local card = cards[1]
            local new_card =sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
            new_card:addSubcard(card:getId())
            new_card:setSkillName(self:objectName())
            return new_card
        end
    end,
}

arios:addSkill(shuangjia)
arios:addSkill(lueduo)

sinanju = sgs.General(extension, "sinanju", "god", 4, true,false)
xiaya = sgs.CreateViewAsSkill
{--倾国 by ibicdlcod, 【群】皇叔修复response无效的BUG
	name = "xiaya",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isRed()
    end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

zaishi_Card = sgs.CreateSkillCard {  --野心技能卡
	name = "zaishi",
	target_fixed = true,
	will_throw = false,
	once = true,
	on_use = function(self, room, source, targets)
		local n = 0
		local quans = source:getPile("su")
		if quans:length() > 0 then
			room:fillAG(quans, source)
		end
        while(quans:length() > 0) do
            local card_id = room:askForAG(source, quans, true, "zaishi")
            if card_id == -1 then
                break
			end
            quans:removeOne(card_id)
            n = n + 1
			source:obtainCard(sgs.Sanguosha:getCard(card_id))
        end
		source:invoke("clearAG")
		if n > 0 then
			local ex_cards = room:askForExchange(source, "zaishi", n)
			for _,id in sgs.qlist(ex_cards:getSubcards()) do
				source:addToPile("su", id)
			end
		end
	end
}

zaishi_Vskill = sgs.CreateViewAsSkill{  --野心视为技
	name = "zaishi",
	n = 0,
	enabled_at_play = function(self,player)
		return player:getPile("su"):length() > 0
	end,
	view_as = function(self, cards)
		local new_card = zaishi_Card:clone()
		new_card:setSkillName("zaishi")
		return new_card
	end
}

zaishi = sgs.CreateTriggerSkill
{
	frequency = sgs.Skill_NotFrequent,
	name = "zaishi",
	events = {sgs.Damaged,sgs.PhaseChange,sgs.Predamaged},
	view_as_skill=zaishi_Vskill,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Predamaged and damage.from then
		    local tos = sgs.SPlayerList()
			if not damage.from:isProhibited(damage.from, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
			tos:append(damage.from)
			end
			local target = room:askForPlayerChosen(player, tos, self:objectName())
			local su = player:getPile("su")
            if su:length()==0 then return end
		if target and room:askForSkillInvoke(player, self:objectName(), data) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local su = player:getPile("su")
                                room:fillAG(su,player)
                                        local id_t=room:askForAG(player,su,false,self:objectName())
                                        room:throwCard(id_t)
                                player:invoke("clearAG")
                              slash:setSkillName("zaishi")
                              local use = sgs.CardUseStruct()
                              use.from = player
                                                          
                              use.to:append(target)
                                                         
                              use.card = slash
                              room:useCard(use,false) 
			end
			elseif event == sgs.Damaged then
		    local x = damage.damage
		    for i=1, x, 1 do
				room:playSkillEffect(self:objectName())
				local cards = sgs.QList2Table(room:getNCards(1))
				player:addToPile("su", cards[1])
		    end
			return false
		end
	end
}


huixing = sgs.CreateDistanceSkill{

   name = "huixing",
   correct_func = function(self, from, to)
       if from:hasSkill("huixing") then
	   local x = from:getHp()
	   return -x
    end
end,
}

wangling_vs = sgs.CreateViewAsSkill
{
	name = "wangling",
	n = 0,

	view_filter = function(self, selected, to_select)
		return true
	end,

	view_as = function(self, cards)
	if #cards <= 1 then
		local card = cards[1]
		local acard = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
		acard:setSkillName(self:objectName())
		return acard
		end
	end,
	
	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return (sgs.Self:hasSkill("xiaya") or sgs.Self:hasSkill("zaishi") or sgs.Self:hasSkill("huixing")) and string.find(pattern, "analeptic")
	end,
}

wangling=sgs.CreateTriggerSkill
{
	name="wangling",
	events={sgs.GameStart,sgs.Predamage,sgs.Predamaged,sgs.CardUsed,sgs.CardFinished},
	priority = 2,
	view_as_skill = wangling_vs,
	
	on_trigger=function(self,event,player,data)
	local room = player:getRoom()
	if event == sgs.GameStart then
	    room:playSkillEffect("wangling")
	    room:acquireSkill(player,"xiaya")
		room:acquireSkill(player,"zaishi")
		room:acquireSkill(player,"huixing")
	end
	if event == sgs.Predamaged then
	if (not player:hasSkill("xiaya")) and (not player:hasSkill("zaishi")) and (not player:hasSkill("huixing")) then return end
		if not room:askForSkillInvoke(player, self:objectName(), data) then return false end
		room:playSkillEffect("wangling")
	    if player:hasSkill("xiaya") and player:hasSkill("zaishi") and player:hasSkill("huixing") then
	        local choice=room:askForChoice(player, self:objectName(), "xiaya+zaishi+huixing+cancel")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya") player:gainMark("@wangling")
			elseif choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi") player:gainMark("@wangling")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing") player:gainMark("@wangling")
			elseif choice == "cancel" then return false
			end
			end
		if (not player:hasSkill("xiaya")) and player:hasSkill("zaishi") and player:hasSkill("huixing") then
		    local choice=room:askForChoice(player, self:objectName(), "zaishi+huixing+cancel")
			if choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi") player:gainMark("@wangling")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing") player:gainMark("@wangling")
			elseif choice == "cancel" then return false
			end
			end
		if player:hasSkill("xiaya") and (not player:hasSkill("zaishi")) and player:hasSkill("huixing") then
		    local choice=room:askForChoice(player, self:objectName(), "xiaya+huixing+cancel")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya") player:gainMark("@wangling")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing") player:gainMark("@wangling")
			elseif choice == "cancel" then return false
			end
			end
		if player:hasSkill("xiaya") and player:hasSkill("zaishi") and (not player:hasSkill("huixing")) then
		    local choice=room:askForChoice(player, self:objectName(), "xiaya+zaishi+cancel")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya") player:gainMark("@wangling")
			elseif choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi") player:gainMark("@wangling")
			elseif choice == "cancel" then return false
			end
			end
		if (not player:hasSkill("xiaya")) and (not player:hasSkill("zaishi")) and player:hasSkill("huixing") then
		    local choice=room:askForChoice(player, self:objectName(), "huixing+cancel")
			    if choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing") player:gainMark("@wangling")
				elseif choice == "cancel" then return false
			end
			end
		if (not player:hasSkill("xiaya")) and player:hasSkill("zaishi") and (not player:hasSkill("huixing")) then
		    local choice=room:askForChoice(player, self:objectName(), "zaishi+cancel")
			    if choice == "zaishi" then
		        for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi") player:gainMark("@wangling")
			    elseif choice == "cancel" then return false
			end
			end
	    if player:hasSkill("xiaya") and (not player:hasSkill("zaishi")) and (not player:hasSkill("huixing")) then
		    local choice=room:askForChoice(player, self:objectName(), "xiaya+cancel")
			    if choice == "xiaya" then
		        room:detachSkillFromPlayer(player,"xiaya") player:gainMark("@wangling")
				elseif choice == "cancel" then return false
			end
		end
		end
	if event == sgs.Predamage then
	local damage = data:toDamage()
	if damage.from:getMark("@wangling") == 0 then return end
		   damage.damage = damage.damage+(damage.from:getMark("@wangling"))
				data:setValue(damage)
				room:playSkillEffect("wangling")
				damage.from:loseAllMarks("@wangling")
		end
	if event == sgs.CardUsed then
	local use = data:toCardUse()
	local card = use.card
	if card:getSkillName() == "wangling" then
	    if (not player:hasSkill("xiaya")) and (not player:hasSkill("zaishi")) and (not player:hasSkill("huixing")) then return end
	    if player:hasSkill("xiaya") and player:hasSkill("zaishi") and player:hasSkill("huixing") then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
	        local choice=room:askForChoice(player, self:objectName(), "xiaya+zaishi+huixing")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya")
			elseif choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing")
			end
			end
		if (not player:hasSkill("xiaya")) and player:hasSkill("zaishi") and player:hasSkill("huixing") then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
		    local choice=room:askForChoice(player, self:objectName(), "zaishi+huixing")
			if choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing")
			end
			end
		if player:hasSkill("xiaya") and (not player:hasSkill("zaishi")) and player:hasSkill("huixing") then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
		    local choice=room:askForChoice(player, self:objectName(), "xiaya+huixing")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya")
			elseif choice == "huixing" then
			    room:detachSkillFromPlayer(player,"huixing")
			end
			end
		if player:hasSkill("xiaya") and player:hasSkill("zaishi") and (not player:hasSkill("huixing")) then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
		    local choice=room:askForChoice(player, self:objectName(), "xiaya+zaishi")
		    if choice == "xiaya" then
			    room:detachSkillFromPlayer(player,"xiaya")
			elseif choice == "zaishi" then
			    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi")
			end
			end
		if (not player:hasSkill("xiaya")) and (not player:hasSkill("zaishi")) and player:hasSkill("huixing") then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
			    room:detachSkillFromPlayer(player,"huixing")
			end
		if (not player:hasSkill("xiaya")) and player:hasSkill("zaishi") and (not player:hasSkill("huixing")) then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
		    for _,id in sgs.qlist(player:getPile("su")) do
					player:obtainCard(sgs.Sanguosha:getCard(id)) 
			    end
			    room:detachSkillFromPlayer(player,"zaishi")
			end
	    if player:hasSkill("xiaya") and (not player:hasSkill("zaishi")) and (not player:hasSkill("huixing")) then
		if player:getMark("wling") > 0 then return end
		player:addMark("wling")
		    room:detachSkillFromPlayer(player,"xiaya")
			end
		end
		end
		if event == sgs.CardFinished then
		local use = data:toCardUse()
	    local card = use.card
		    if card:getSkillName() == "wangling" then
			player:loseAllMarks("wling")
			end
		end
	end,
}

sinanju:addSkill(wangling)


tallgeese = sgs.General(extension, "tallgeese", "god", 4, true,false)

lua_jisu = sgs.CreateDistanceSkill{

   name = "lua_jisu",
   correct_func = function(self, from, to)
       if from:hasSkill("lua_jisu") and to:getHandcardNum() >= from:getHandcardNum() then
	   return -998
    end
	   if to:hasSkill("lua_jisu") and to:getHandcardNum() <= from:getHandcardNum() then
	   return 1
	end
end,
}

baofeng = sgs.CreateTriggerSkill
{
	name = "baofeng",
	events = {sgs.Predamage},
	frequency = sgs.Skill_NotFrequent,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if(event == sgs.Predamage and card:inherits("Slash")) then
		  if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
		  room:playSkillEffect("baofeng")
		   damage.damage = damage.damage+(damage.to:getEquips():length())
				data:setValue(damage)
				return false
	end
end,
}


tallgeese:addSkill(lua_jisu)
tallgeese:addSkill(baofeng)

f91 = sgs.General(extension, "f91", "god", 3, true,false)

function getDiamonds(card)
-- 本函数用于获取落英的梅花，因为有些梅花是在技能卡的子卡列表里，不能直接获得
        local diamonds = {}
        if not card:isVirtualCard() then
                if card:getSuit() == sgs.Card_Diamond or card:getNumber() == 1 or card:getNumber() == 9 then
                        table.insert(diamonds, card)
                end
                return diamonds
        end
        for _, card_id in sgs.qlist(card:getSubcards()) do
                local c = sgs.Sanguosha:getCard(card_id)
                if c:getSuit() == sgs.Card_Diamond or c:getNumber() == 1 or c:getNumber() == 9 then
                        table.insert(diamonds, c)
                end
        end
        return diamonds
end

fangcheng=sgs.CreateTriggerSkill{
-- 落英主代码
        name="fangcheng",
        frequency = sgs.Skill_Frequent,
        default_choice = "no",
        priority = -1,
        events={sgs.CardDiscarded,sgs.CardUsed,sgs.FinishJudge},

        can_trigger = function(self, player)
                return not player:hasSkill(self:objectName())
        end,

        on_trigger = function(self,event,player,data)
                local room = player:getRoom()
                local diamonds = {}
                if event == sgs.CardUsed then
                        local use = data:toCardUse()
                        if use.card and use.card:subcardsLength() > 0 and
                                use.card:willThrow() and not use.card:isOwnerDiscarded() and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardedPile then
                                diamonds = getDiamonds(use.card)
                        end
                elseif event == sgs.CardDiscarded then
                        local card = data:toCard()
						if room:getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardedPile then
                        diamonds = getDiamonds(card)
						end
                elseif event == sgs.FinishJudge then
                        local judge = data:toJudge()
                        if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_DiscardedPile
                           and judge.card:getSuit() == sgs.Card_Diamond or judge.card:getNumber() == 1 or judge.card:getNumber() == 9 then
                           table.insert(diamonds, judge.card)
                        end
                end

                local f91 = room:findPlayerBySkillName(self:objectName())
                for _, card in ipairs(diamonds) do
                        if card:objectName() == "shit" then
-- 拿不拿屎的温馨提示，想坑人就删掉这部分~ 呵呵
                                if f91 and room:askForChoice(f91, self:objectName(), "yes+no") == "no" then
                                        for i = #diamonds, 1, -1 do
                                                if diamonds[i]:objectName() == card:objectName() then
                                                        table.remove(diamonds, i)
                                                end
                                        end
                                end
                        end
                end

                if #diamonds == 0 then return false end
                if f91 and f91:askForSkillInvoke(self:objectName(), data) then
                                room:playSkillEffect("fangcheng",math.random(1, 2))
                        end
                        for _, diamond in ipairs(diamonds) do
                                f91:obtainCard(diamond)
                        end
                end
}



canying=sgs.CreateTriggerSkill
{
	name="canying",
	frequency = sgs.Skill_Frequent,
	events={sgs.Damaged},
	priority = -1,
	--view_as_skill=view_as_skill,

	on_trigger=function(self,event,f91,data)
		local room = f91:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
		for i=1, x, 1 do
			if not f91:askForSkillInvoke(self:objectName()) then return end

			room:playSkillEffect("canying",math.random(1, 2))

			f91:gainMark("@formula",1)
		end
	end,

	-- can_trigger=function(self,target)
		-- return true
	-- end,
}

canyingdistance = sgs.CreateDistanceSkill{

   name = "#canyingdistance",
   correct_func = function(self, from, to)
       if to:hasSkill("#canyingdistance") and to:getMark("@formula") < 6 then
	   local x = to:getMark("@formula")
	   return x
	end
	   if to:hasSkill("#canyingdistance") and to:getMark("@formula") > 5 then
	   return 5
    end
end,
}

canyingkill=sgs.CreateTriggerSkill{
	name="#canyingkill",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.TurnStart},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local splayer=room:findPlayerBySkillName(self:objectName())
		if not splayer then return end
		if splayer:isKongcheng() then return end
		if player:objectName()==splayer:objectName() then return end
		if splayer:getMark("@formula") > 0 then
		if (player:isProhibited(player, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then return end
		if not splayer:askForSkillInvoke(self:objectName()) then return end
		if not room:askForCard(splayer,"Jink","@canyingkill",data) then return end
			splayer:loseMark("@formula")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                              slash:setSkillName("#canyingkill")
                              local use = sgs.CardUseStruct()
                              use.from = splayer
                                                          
                              use.to:append(player)
                                                         
                              use.card = slash
                              room:useCard(use,false)
		end
	end,
	can_trigger=function(self,target)
		return true
	end,
}

canyingkill2=sgs.CreateTriggerSkill{
	name="#canyingkill2",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.PhaseChange},
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		if player:getPhase()~=sgs.Player_Finish then return end
		local splayer=room:findPlayerBySkillName(self:objectName())
		if not splayer then return end
		if splayer:isKongcheng() then return end
		if player:objectName()==splayer:objectName() then return end
		if splayer:getMark("@formula") > 0 then
		if (player:isProhibited(player, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then return end
		if not splayer:askForSkillInvoke(self:objectName()) then return end
		if not room:askForCard(splayer,"Jink","@canyingkill",data) then return end
			splayer:loseMark("@formula")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                              slash:setSkillName("#canyingkill2")
                              local use = sgs.CardUseStruct()
                              use.from = splayer
                                                          
                              use.to:append(player)
                                                         
                              use.card = slash
                              room:useCard(use,false)
		end
	end,
	can_trigger=function(self,target)
		return true
	end,
}

canyingmopai = sgs.CreateTriggerSkill
{
	name = "#canyingmopai",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.PhaseChange},
	
	on_trigger = function(self, event, player, data)
	    if player:getMark("@formula") <= 2 then return end
		if(player:getPhase() == sgs.Player_Draw and player:getMark("@formula") < 6 and player:askForSkillInvoke("canyingmopai")) then
			local x = player:getMark("@formula")
			player:drawCards(x-2)
		end
		if(player:getPhase() == sgs.Player_Draw and player:getMark("@formula") > 5 and player:askForSkillInvoke("canyingmopai")) then
			player:drawCards(3)
		end
		return false
	end
}

f91:addSkill(fangcheng)
f91:addSkill(canying)
f91:addSkill(canyingdistance)
f91:addSkill(canyingkill)
f91:addSkill(canyingkill2)
f91:addSkill(canyingmopai)

susanowo = sgs.General(extension, "susanowo", "god", 4, true,false)

ruhun=sgs.CreateTriggerSkill{
	name="ruhun",
	frequency=sgs.Skill_Frequent,
	events=sgs.TurnStart,
	can_trigger=function(self,player)
		return not player:hasSkill(self:objectName())
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
		room:askForSkillInvoke(selfplayer,"ruhun")
		selfplayer:drawCards(1)
	end,
}

erdao = sgs.CreateTriggerSkill
{
	name = "erdao",
	events = {sgs.DamageCaused,sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
	return true
 end,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if(event == sgs.DamageCaused and card:inherits("Slash")) then
		if not room:askForCard(player,"Slash","@erdao",data) then
		       return true end
				else return false
	end
end,
}

erdao2 = sgs.CreateSlashSkill
{
	name = "#erdao2",
	s_residue_func = function(self, from)
		if from:hasSkill("erdao") then
            local init =  1 - from:getSlashCount()
            return init + 998
        else
            return 0
		end
	end,
}

susanowo:addSkill(ruhun)
susanowo:addSkill(erdao)
susanowo:addSkill(erdao2)

ARCHE = sgs.General(extension, "ARCHE", "god", 2, true,false)

luaqianggong_vs=sgs.CreateViewAsSkill{
name="luaqianggong",
n=1,
view_filter=function(self,selected,to_select)
    if not sgs.Slash_IsAvailable(sgs.Self) then
	return to_select:inherits("Duel") or to_select:inherits("SavageAssault") or to_select:inherits("ArcheryAttack") end
    return to_select:inherits("Slash") or to_select:inherits("Duel") or to_select:inherits("SavageAssault") or to_select:inherits("ArcheryAttack")
end,
view_as = function(self, cards)
    local card = cards[1]
	if #cards==1 then
        if card:inherits("Slash") then
			local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		elseif card:inherits("Duel") then
		    local acard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		elseif card:inherits("SavageAssault") then
		    local acard = sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		elseif card:inherits("ArcheryAttack") then
		    local acard = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end
end,

enabled_at_play = function()
		return true
	end,
enabled_at_response=function(self,player,pattern)
 return false
end,
}

luaqianggong=sgs.CreateTriggerSkill
{
	name="luaqianggong",
	events={sgs.Predamage,sgs.DrawNCards},
	priority = 9,
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = luaqianggong_vs,
	
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	    local damage = data:toDamage()
		if event == sgs.Predamage and damage.card:getSkillName() == "luaqianggong" then
		    damage.nature = sgs.DamageStruct_Fire
			data:setValue(damage)
			return false
		elseif event == sgs.DrawNCards and room:askForSkillInvoke(player, self:objectName()) then
		    data:setValue(data:toInt()+1)
		end
	end,
}

fanqin = sgs.CreateTriggerSkill
{
	frequency = sgs.Skill_NotFrequent,
	name = "fanqin",
	events = {sgs.PhaseChange,sgs.Predamaged},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamaged and player:getPhase() == sgs.Player_NotActive and room:askForSkillInvoke(player, self:objectName()) then
		for var = 1, 2, 1 do
				if damage.from:isNude() then break end
				room:throwCard(room:askForCardChosen(player, damage.from ,"he",self:objectName()))
			end
		end
	end
}

yongbing=sgs.CreateTriggerSkill
{
	name="yongbing",
	events={sgs.Predamage},
	priority = 8,
	frequency = sgs.Skill_NotFrequent,
	
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	    local damage = data:toDamage()
		if event == sgs.Predamage and room:askForSkillInvoke(player, self:objectName()) then
		    damage.from = room:askForPlayerChosen(player, room:getOtherPlayers(player), "yongbing")
			data:setValue(damage)
			return false
		end
	end,
}

weijiao_vs = sgs.CreateViewAsSkill
{
	name = "weijiao",
	n = 1,
	view_filter = function(self,selected,to_select)
		if sgs.Self:getMark("@weijiao") == 0 then
		return not to_select:isEquipped() end
		return false
	end,
	view_as = function(self, cards)
	local card = cards[1]
	if #cards == 0 then
	    if sgs.Self:getMark("@weijiao") == 0 then return nil end
		local acard = weijiao_card:clone()		
		acard:setSkillName(self:objectName())
		return acard
	elseif #cards == 1 then
	    local acard = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
		acard:addSubcard(card:getId())
        acard:setSkillName(self:objectName())
		return acard
	end
	end,
	enabled_at_play = function(self,player)
		return (sgs.Self:getMark("@weijiao") > 0) or (sgs.Self:getMark("@weijiao") == 0 and not sgs.Self:hasUsed("Analeptic"))
	end,
	enabled_at_response = function(self,player,pattern)        
        return string.find(pattern, "analeptic") and sgs.Self:getMark("@weijiao") == 0
    end,
}

weijiao_card = sgs.CreateSkillCard
{
	name = "weijiao",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        local room=effect.from:getRoom()
		effect.from:loseMark("@weijiao")
		room:loseMaxHp(effect.from)
        local damage=sgs.DamageStruct()
		damage.damage=2
        damage.nature=sgs.DamageStruct_Normal
		damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
end                
}

weijiao=sgs.CreateTriggerSkill
{
	name="weijiao",
	events={sgs.GameStart,sgs.PhaseChange},
	frequency = sgs.Skill_Limited,
	view_as_skill = weijiao_vs,
	
	on_trigger=function(self,event,player,data)
	local room = player:getRoom()
  if event == sgs.GameStart then
      player:gainMark("@weijiao")
      end
  if event == sgs.PhaseChange and player:getPhase()== sgs.Player_Discard and player:getMark("@weijiao") == 0 then
  local x=player:getHp()
   local z = player:getHandcardNum()
   local w = player:getMark("@weilu")
   if z <= (2+x-w) then
   return true
   else
       local e = z-(2+x-w)
      room:askForDiscard(player,"weijiao",e,e,false,false)
	  return true
  end
  end
  end,
}

ARCHE:addSkill(luaqianggong)
ARCHE:addSkill(fanqin)
ARCHE:addSkill(yongbing)
ARCHE:addSkill(weijiao)

reborns = sgs.General(extension, "reborns", "god", 4, true,false)

jianong=sgs.CreateTriggerSkill{
name="jianong",
events={sgs.GameStart,sgs.TurnStart},
on_trigger=function(self,event,player,data)
local room=player:getRoom()
local selfplayer=room:findPlayerBySkillName(self:objectName())
local otherplayers=room:getOtherPlayers(selfplayer)
if event==sgs.GameStart then 
if player:hasSkill("jianong") then
room:acquireSkill(selfplayer,"fengong")
room:acquireSkill(selfplayer,"liansuo")
  player:gainMark("@jn",1)
  end
elseif event==sgs.TurnStart and (not selfplayer:isNude()) and room:askForSkillInvoke(selfplayer,"jianong") then
if(room:askForDiscard(selfplayer,self:objectName(),1,1,false,true)) then
if selfplayer:getMark("@jn") > 0 then
room:playSkillEffect("jianong",1)
room:acquireSkill(selfplayer,"jidong")
if not selfplayer:faceUp() then selfplayer:turnOver() end
room:acquireSkill(selfplayer,"zaisheng")
room:detachSkillFromPlayer(selfplayer,"fengong")
room:detachSkillFromPlayer(selfplayer,"liansuo") 
selfplayer:gainMark("@gd")
selfplayer:loseMark("@jn")
elseif selfplayer:getMark("@gd") > 0 then
room:playSkillEffect("jianong",2)
room:acquireSkill(selfplayer,"fengong")
room:acquireSkill(selfplayer,"liansuo")
room:detachSkillFromPlayer(selfplayer,"jidong")
room:detachSkillFromPlayer(selfplayer,"zaisheng")
selfplayer:gainMark("@jn")
selfplayer:loseMark("@gd")
end
end
end
end,
can_trigger=function(self,player)
local room=player:getRoom()
local selfplayer=room:findPlayerBySkillName(self:objectName())
if selfplayer==nil then return false end
return selfplayer:isAlive()

end,
}

rbsanhong_vs = sgs.CreateViewAsSkill
{
	name = "rbsanhong_vs",
	n = 0,

	view_as = function(self, cards)
	if #cards == 0 then
		local card = rbsanhong_card:clone()		
		card:setSkillName(self:objectName())
		return card
    end
	end,
	enabled_at_play = function()
		return sgs.Self:getMark("@rbsanhong") > 0
	end,
}

rbsanhong_card = sgs.CreateSkillCard
{
	name = "rbsanhong",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
	if source:getMark("rbsanhongused") == 0 then
	source:addMark("rbsanhongused")
	end
	room:playSkillEffect("rbsanhong")
if source:getMark("@jn") > 0 then
room:acquireSkill(source,"jidong")
if not source:faceUp() then source:turnOver() end
room:acquireSkill(source,"zaisheng")
room:detachSkillFromPlayer(source,"fengong")
room:detachSkillFromPlayer(source,"liansuo") 
source:gainMark("@gd")
source:loseMark("@jn")
elseif source:getMark("@gd") > 0 then
room:acquireSkill(source,"fengong")
room:acquireSkill(source,"liansuo")
room:detachSkillFromPlayer(source,"jidong")
room:detachSkillFromPlayer(source,"zaisheng")
source:gainMark("@jn")
source:loseMark("@gd")
end
	end,

	enabled_at_play = function()
		return true
	end
}

rbsanhong=sgs.CreateTriggerSkill
{
	name="rbsanhong",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart,sgs.PhaseChange},
	view_as_skill = rbsanhong_vs,
	
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	if event == sgs.GameStart then
		player:gainMark("@rbsanhong",1)
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:getMark("@rbsanhong")>0 and player:getMark("rbsanhongused")>0 then
	    player:loseMark("@rbsanhong")
		room:setPlayerMark(player, "rbsanhongused", 0)
	end
	end,
}

fengong = sgs.CreateViewAsSkill
{
	name = "fengong",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("ThunderSlash") or to_select:inherits("FireSlash")
	end,

	view_as = function(self, cards)
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,

	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

liansuo = sgs.CreateViewAsSkill
{
	name = "liansuo",
	n = 0,

	view_as = function(self, cards)
	if #cards == 0 then
		local card = liansuo_card:clone()		
		card:setSkillName(self:objectName())
		return card
	end
	end,
	enabled_at_play = function(self,player)
		return true
	end,
}

liansuo_card = sgs.CreateSkillCard
{
	name = "liansuo",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
	    room:playSkillEffect("liansuo")
		if source:faceUp() then
		source:turnOver()
        end
		room:setPlayerFlag(source,"liansuoslash")
	end,
}

jidong = sgs.CreateTriggerSkill
{
	name = "jidong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TurnedOver},
    on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnedOver then
		if player:faceUp() then return end
		player:turnOver()
		end
	end
}

zaisheng_card = sgs.CreateSkillCard
{
	name = "zaisheng",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
			room:setPlayerFlag(source, "zaisheng_used")
			
				room:playSkillEffect("zaisheng")
                
				while source:getMark("zaishengget") < self:subcardsLength() do
				local card_id = room:drawCard()
				local card=sgs.Sanguosha:getCard(card_id)
                room:moveCardTo(card,nil,sgs.Player_Special,true)
                room:getThread():delay()
				if card:inherits("BasicCard") then
				room:obtainCard(source,card_id)
				source:addMark("zaishengget")
				else room:throwCard(card_id)
                end
                end
	end,
}

zaisheng = sgs.CreateViewAsSkill
{
	name = "zaisheng",
	n = 998,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,

	view_as = function(self, cards)
		if #cards > 0 then
			local new_card = zaisheng_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("zaisheng")
			return new_card
		else return nil
		end
	end,

	enabled_at_play = function(self,player)
		return not player:hasFlag("zaisheng_used")
	end
}

zaishengb=sgs.CreateTriggerSkill
{
	name="#zaishengb",
	events={sgs.PhaseChange},
	can_trigger=function(self,player)
	    return true
	end,	
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish and player:getMark("zaishengget") > 0 then
		room:setPlayerMark(player, "zaishengget", 0)
		end
	end,
}

rebornslash = sgs.CreateSlashSkill
{
	name = "#rebornslash",
	s_residue_func = function(self, from)
		if (from:hasSkill("liansuo") and from:hasFlag("liansuoslash")) then
            local init =  1 - from:getSlashCount()
            return 998
        else
            return 0
		end
	end,
	s_extra_func = function(self, from, to, slash)
		if (from:hasSkill("fengong") and slash and slash:getSkillName() == "fengong") then
			return 1
		end
	end,
}

reborns:addSkill(jianong)
reborns:addSkill(rbsanhong)
reborns:addSkill(zaishengb)
reborns:addSkill(rebornslash)

ooq = sgs.General(extension, "ooq", "god", 4, true,false)

jianwu = sgs.CreateFilterSkill{
    name = "jianwu",
	
    view_filter = function(self, card)
        return card:inherits("Weapon") and not card:isEquipped()
    end,
	
    view_as = function(self, card)
        local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        return acard
    end
}

jianwu2 = sgs.CreateSlashSkill
{
	name = "jianwu2",
	can_trigger = function(self, player)
                return player:hasSkill("jianwu")
        end,
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("jianwu") and not from:getWeapon()) then
			return -5
		end
	end,
}

liurencard=sgs.CreateSkillCard{  --强袭EX卡片
name="liuren",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return end
          return player:inMyAttackRange(to_select) --否则要在攻击范围内
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom() 
        local damage=sgs.DamageStruct() --伤害结构体 这里赘述了一些
        damage.damage=1
        damage.nature=sgs.DamageStruct_Normal 
        damage.chain=false
		damage.from=effect.from
        damage.to=effect.to
		effect.from:loseMark("@ooqren",6)
        local log=sgs.LogMessage()
		log.from = player
        log.type = "#liuren"
        log.arg = effect.to:getGeneralName()
        room:sendLog(log)
		damage.from=effect.from
        damage.to=effect.to
        room:damage(damage)
end                
}

liurenvs=sgs.CreateViewAsSkill{ --强袭EX视为技能
name="liuren",
n=0,
view_filter=function(self, selected, to_select)
        return true
end,
view_as=function(self, cards)
        local acard=liurencard:clone() 
        if #cards==0 then         --如果没有选择武器直接返回
                return acard 
        elseif #cards==1 then --有武器牌就加入子卡
                acard:addSubcard(cards[1])
            acard:setSkillName(self:objectName())     
                return acard
        end
end,
enabled_at_play=function(self,player) 
        return player:getMark("@ooqren") >= 6
end,
enabled_at_response=function(self,player,pattern) 
        return false 
end
}

liuren = sgs.CreateTriggerSkill
{
	name = "liuren",
	events = {sgs.CardUsed, sgs.CardResponsed,sgs.Predamaged},
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = liurenvs,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:inherits("Slash") and room:askForSkillInvoke(player, self:objectName()) then
				room:playSkillEffect("liuren")
                player:gainMark("@ooqren",1)
			end
		elseif event == sgs.CardResponsed then
			local cd=data:toCard()
			if cd:inherits("Slash") and room:askForSkillInvoke(player, self:objectName()) then
				room:playSkillEffect("liuren")
                player:gainMark("@ooqren",1)
			end
		elseif event == sgs.Predamaged and player:getMark("@ooqren") >= 6 then
		    local damage = data:toDamage()
		    local card = damage.card
			if (not room:askForSkillInvoke(player, self:objectName())) then return false end
			room:playSkillEffect("liuren")
		    player:loseMark("@ooqren",6)
		    return true
	end
	end,
}

ooqsanhong_vs = sgs.CreateViewAsSkill
{
	name = "ooqsanhong",
	n = 0,

	view_as = function(self, cards)
	if #cards == 0 then
		local card = ooqsanhong_card:clone()		
		card:setSkillName(self:objectName())
		return card
	end
	end,
	
	enabled_at_play = function(self,player)
		return not player:hasFlag("ooqsanhongused") and player:getMark("@ooqsanhong") > 0
	end
}

ooqsanhong_card = sgs.CreateSkillCard
{
	name = "ooqsanhong",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
			room:drawCards(source, 3)
			source:turnOver()
			source:addMark("ooqturnover")
			room:setPlayerFlag(source, "ooqsanhongused")
	end,
}

ooqsanhong = sgs.CreateTriggerSkill
{
	name = "ooqsanhong",
	frequency = sgs.Skill_Limited,
	view_as_skill = ooqsanhong_vs,
	events = {sgs.GameStart,sgs.PhaseChange,sgs.TurnedOver,sgs.Damaged},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
		player:gainMark("@ooqsanhong")
		end
		if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:hasFlag("ooqsanhongused") then
		player:loseMark("@ooqsanhong")
		end
		if event == sgs.TurnedOver and player:getMark("ooqturnover") > 0 then
		player:removeMark("ooqturnover")
		end
		if event == sgs.Damaged and not player:faceUp() and player:getMark("ooqturnover") > 0 then
		player:removeMark("ooqturnover")
		room:playSkillEffect("ooqsanhong")
		player:turnOver()
		end
end,
}

liangzi = sgs.CreateTriggerSkill
{--突袭 by ibicdlcod
	name = "liangzi",
	events = sgs.TurnStart,
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	if player:getHp() == 1 then
  for _, p in sgs.qlist(room:getPlayers()) do
    p:unicast("animate lightbox:$liangzianimate:3000")

  end

	room:transfigure(player, "ooqb", false, true)
	    for _,id in sgs.qlist(player:getJudgingArea()) do
            room:throwCard(id) end
		local recover = sgs.RecoverStruct()   --回复结构体
			recover.recover = 1  --回复点数
			recover.who = player   --回复来源
			room:recover(player,recover)
			player:loseAllMarks("@ooqren")
			player:loseAllMarks("@ooqsanhong")
			if player:isChained() then 
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
end
end
}

ooq:addSkill(jianwu)
ooq:addSkill(liuren)
ooq:addSkill(ooqsanhong)
ooq:addSkill(liangzi)

ooqb = sgs.General(extension, "ooqb", "god", 3, true,true,true)

tuojia = sgs.CreateTriggerSkill
{
	name = "tuojia",
	events = {sgs.Predamaged,sgs.SlashProceed},
	frequency = sgs.Skill_Compulsory,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		local card = damage.card
		if(event == sgs.Predamaged and card:inherits("FireSlash") or card:inherits("ThunderSlash")) then
		  room:playSkillEffect("tuojia")
		   damage.damage = damage.damage+1
				data:setValue(damage)
				return false
	end
end,
}

lijie_card = sgs.CreateSkillCard
{
	name = "lijie",
	target_fixed = false,
	will_throw = true,
	once = true,

	filter = function(self, targets, to_select, player)
		if(#targets >= 1) then return false end
		
		if to_select:objectName() == player:objectName() then return false end
		
		return not to_select:isKongcheng()
	end,

	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		if effect.from:getHandcardNum() > 0 then
        local choice=room:askForChoice(effect.from, self:objectName(), "watch+recover")
		if choice == "watch" then
		local handcards = effect.to:handCards()
		room:showAllCards(effect.to,effect.from)
		effect.from:invoke("clearAG")
		room:fillAG(handcards,effect.from)
		room:playSkillEffect("lijie")
		room:getThread():delay(2500)
		effect.from:invoke("clearAG")
		room:setPlayerFlag(effect.from, "lijieused")
		elseif choice == "recover" then
		local choicee=room:askForChoice(effect.to, "lijietarget", "agree+disagree")
		if choicee == "agree" then
		room:askForDiscard(effect.from,"lijie",1,1, false,false)
		room:askForDiscard(effect.to,"lijie",1,1, false,false)
		local recov = sgs.RecoverStruct()
		recov.recover = 1
		recov.card = self
		recov.who = effect.from

		room:recover(effect.from, recov)
		room:recover(effect.to, recov)

		room:playSkillEffect("lijie")
		room:setPlayerFlag(effect.from, "lijieused")
		elseif choicee == "disagree" then
		room:setPlayerFlag(effect.from, "lijieused")
	end
	end
	elseif effect.from:getHandcardNum() < 1 then
	    local handcards = effect.to:handCards()
		room:showAllCards(effect.to,effect.from)
		effect.from:invoke("clearAG")
		room:fillAG(handcards,effect.from)
		room:playSkillEffect("lijie")
		room:getThread():delay(2500)
		effect.from:invoke("clearAG")
		room:setPlayerFlag(effect.from, "lijieused")
	end
	end
}

lijie = sgs.CreateViewAsSkill
{
	name = "lijie",
	n = 1,

	enabled_at_play = function(self,player)
		return not player:hasFlag("lijieused")
	end,

	view_filter = function(self, selected, to_select)
		return true
	end,

	view_as = function(self, cards)
		if #cards == 1 then
		local new_card = lijie_card:clone()
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end
	end
}

baofa = sgs.CreateTriggerSkill
{
	name = "baofa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if room:askForSkillInvoke(player,"baofa",data) then
			data:setValue(5-player:getHp())
		end
	end
}

ooqb:addSkill(tuojia)
ooqb:addSkill(lijie)
ooqb:addSkill(baofa)

new_ooq = sgs.General(extension, "new_ooq", "god", 4, true,false)

new_jianwu = sgs.CreateViewAsSkill
{
	name = "new_jianwu",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("Weapon") and not to_select:isEquipped()
	end,

	view_as = function(self, cards)
		if #cards == 0 then return nil end
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function()
		return sgs.Self:getWeapon()
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

new_jianwu2 = sgs.CreateSlashSkill
{
	name = "#new_jianwu2",
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("new_jianwu") and not from:getWeapon()) then
			return -5
		end
	end,
}

new_ooq:addSkill(new_jianwu)
new_ooq:addSkill(new_jianwu2)
new_ooq:addSkill("liuren")
new_ooq:addSkill("ooqsanhong")
new_ooq:addSkill("liangzi")

--[[ZABANYA = sgs.General(extension, "ZABANYA", "god", 4, true,false)

danmu = sgs.CreateTriggerSkill
{
	frequency = sgs.Skill_NotFrequent,
	name = "danmu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected,sgs.CardFinished},
    can_trigger = function(self, player)
                return true
    end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
		local use = data:toCardUse()
		local selfplayer=room:findPlayerBySkillName(self:objectName())
		if event == sgs.CardEffected and effect.card:inherits("ArcheryAttack") and effect.to:objectName() == selfplayer:objectName() then
		    return true
		end
		if event == sgs.CardFinished and use.card:inherits("ArcheryAttack") and use.from:objectName() ~= selfplayer:objectName() and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardedPile then
		    selfplayer:obtainCard(use.card)
		end
	end
}

sanshecard=sgs.CreateSkillCard{
name="sanshe",
target_fixed=false,
will_throw=true,
filter=function(self,targets,to_select,player)
          return player:inMyAttackRange(to_select) and player:distanceTo(to_select) == 1
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom()
		if not effect.from:hasFlag("sansheusing") then
		room:setPlayerFlag(effect.from,"sansheusing")
		end
		room:setPlayerFlag(effect.to,"sanshetarget")
end                
}

sanshevs=sgs.CreateViewAsSkill{
	name="sanshe",
	n=1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as=function(self, cards)
			if #cards==1 then
				local acard=sanshecard:clone()
				acard:addSubcard(cards[1])
				acard:setSkillName(self:objectName())     
				return acard
			end
	end,
	enabled_at_play=function(self,player)
			return not player:hasFlag("sansheusing")
	end,
	enabled_at_response=function(self,player,pattern) 
			return false
	end,
}

sanshe = sgs.CreateTriggerSkill
{
	name = "sanshe",
	events = {sgs.SlashEffect,sgs.PhaseChange},
	view_as_skill = sanshevs,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
        if event == sgs.SlashEffect then
		    if player:hasFlag("sansheusing") then
		    room:setPlayerFlag(player,"-sansheusing")
			end
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:hasFlag("sanshetarget") then
		    room:setPlayerFlag(p,"-sanshetarget")
			end
			end
		elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:hasFlag("sansheusing") then
		    room:setPlayerFlag(player,"-sansheusing")
			for _,q in sgs.qlist(room:getOtherPlayers(player)) do
		    if q:hasFlag("sanshetarget") then
		    room:setPlayerFlag(q,"-sanshetarget")
			end
			end
		end
	end,
}

sansheslash = sgs.CreateSlashSkill
{
	name = "#sansheslash",
    can_trigger = function(self, player)
                return player:hasSkill(self:objectName())
    end,
	s_extra_func = function(self, from, to, slash)
		if (from:hasSkill("sanshe") and from:hasFlag("sansheusing") and to and to:hasFlag("sanshetarget")) then
			return 998
		elseif (from:hasSkill("sanshe") and from:hasFlag("sansheusing") and to and not to:hasFlag("sanshetarget")) then
			return -998
		end
	end,
}

zbsanhongcard=sgs.CreateSkillCard{
name="zbsanhong",
target_fixed=true,
will_throw=false,
on_use=function(self, room, source, targets)
        source:loseMark("@zbsanhong",1)
		for _,aplayer in sgs.qlist(room:getOtherPlayers(source)) do
		    local damage=sgs.DamageStruct()
		    damage.damage=1
            damage.nature=sgs.DamageStruct_Normal
		    damage.from=source
            damage.to=aplayer
            room:damage(damage)
		end
		source:turnOver()
end                
}

zbsanhongvs=sgs.CreateViewAsSkill{
name="zbsanhong",
n=0,

view_as=function(self, cards)
        local acard=zbsanhongcard:clone()
		acard:addSubcard(cards[1])
        acard:setSkillName(self:objectName())
		return acard
end,
enabled_at_play=function(self,player)
        return player:getMark("@zbsanhong")>0
end,
enabled_at_response=function(self,player,pattern) 
        return false 
end
}

zbsanhong=sgs.CreateTriggerSkill
{
	name="zbsanhong",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = zbsanhongvs,
	
	on_trigger=function(self,event,player,data)
		player:gainMark("@zbsanhong",1)
	end,
}

ZABANYA:addSkill(danmu)
ZABANYA:addSkill(sanshe)
ZABANYA:addSkill(zbsanhong)
ZABANYA:addSkill(sansheslash)]]

harute = sgs.General(extension, "harute", "god", 4, true,false)

bianxing=sgs.CreateTriggerSkill{
    name="bianxing",
	frequency = sgs.Skill_Compulsory,
    events=sgs.CardEffected,	
on_trigger=function(self,event,player,data)	
    local effect=data:toCardEffect()
    local room=player:getRoom()	
    if effect.card:inherits("Collateral") and effect.to:hasSkill(self:objectName()) then
    return true 
    end	
end
}

bianxingdistance = sgs.CreateDistanceSkill{

   name = "bianxingdistance",
   correct_func = function(self, from, to)
       if to:hasSkill("bianxing") then
	   return 1
    end
end,
}

liuyan = sgs.CreateTriggerSkill
{--突袭 by ibicdlcod
	name = "liuyan",
	events = {sgs.HpChanged,sgs.CardLost,sgs.CardGot,sgs.CardLostDone,sgs.CardGotDone},
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	if (event == sgs.HpChanged or event == sgs.CardLost or event == sgs.CardGot or event == sgs.CardLostDone or event == sgs.CardGotDone) and player:getHp() <= 2 and player:getEquips():length() >= 2 then
		for _, p in sgs.qlist(room:getPlayers()) do
    p:unicast("animate lightbox:$liuyananimate:3000")
  end

	room:transfigure(player, "harute6", false, true)
	    for _,id in sgs.qlist(player:getJudgingArea()) do
            room:throwCard(id) end
			room:drawCards(player, 3)
			player:addMark("jiefangdraw")
			if player:isChained() then 
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
end
end
}

harute:addSkill(bianxing)
harute:addSkill("shuangjia")
harute:addSkill(liuyan)

harute6 = sgs.General(extension, "harute6", "god", 3, true,true,true)

jiefangd=sgs.CreateTriggerSkill{
    name="#jiefangd",
	frequency = sgs.Skill_Compulsory,
    events=sgs.DrawNCards,	
on_trigger=function(self,event,player,data)	
    local room=player:getRoom()
    if event == sgs.DrawNCards and player:getMark("jiefangdraw") > 0 then
	data:setValue(0)
	player:loseAllMarks("jiefangdraw")
    return true 
    end	
end
}

jiefang = sgs.CreateDistanceSkill
{--马术 by 【群】皇叔
	name = "jiefang",
	correct_func = function(self, from, to)
		if from:hasSkill("jiefang") then
			return -1
		end
	end,
}

weishan_vs = sgs.CreateViewAsSkill
{--急救 by ibicdlcod and William915
	name = "weishan",
	n = 1,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@weishan"
	end,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("EquipCard")
	end,

	view_as = function(self, cards)
		if(#cards ~= 1) then return nil end
		local card = cards[1]
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		peach:addSubcard(card)
		peach:setSkillName(self:objectName())
		return peach
	end
}

weishan=sgs.CreateTriggerSkill
{
	name="weishan",
	events={sgs.AskForPeaches},
	view_as_skill = weishan_vs,
	on_trigger=function(self,event,player,data)
	local room = player:getRoom()
    room:askForUseCard(player, "@@weishan", "@weishan")
	end,
}

harute6sanhong_card=sgs.CreateSkillCard{
name="harute6sanhong",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
          if(#targets >= 1) then return end

		  if(to_select == self) then return end
          return not (to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)))
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom()
		effect.from:turnOver()
		effect.from:loseMark("@harute6sanhong")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("harute6sanhong")
        local use = sgs.CardUseStruct()
        use.from = effect.from
                                                          
        use.to:append(effect.to)
                                                         
        use.card = slash
        room:useCard(use,false)
		room:useCard(use,false)
		room:useCard(use,false)
end                
}

harute6sanhong_vs=sgs.CreateViewAsSkill{
name="harute6sanhong",
n=1,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards == 1 then
			local new_card = harute6sanhong_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("harute6sanhong")
			return new_card
		else return nil
		end
	end,
	enabled_at_play=function(self,player)
        return player:getMark("@harute6sanhong") > 0
    end,
}

harute6sanhong=sgs.CreateTriggerSkill
{
	name="harute6sanhong",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = harute6sanhong_vs,
	on_trigger=function(self,event,player,data)
	local room = player:getRoom()
	if event == sgs.GameStart then
	    player:gainMark("@harute6sanhong")
		end
	end,
}

harute6sanhong2_card=sgs.CreateSkillCard{
name="harute6sanhong2",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
          if(#targets >= 3) then return end

		  if(to_select == self) then return end
          return not (to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)))
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom()
		effect.from:turnOver()
		effect.from:loseMark("@harute6sanhong")
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("harute6sanhong")
        local use = sgs.CardUseStruct()
        use.from = effect.from
                                                          
        use.to:append(effect.to)
                                                         
        use.card = slash
        room:useCard(use,false)
end                
}

harute6sanhong2_vs=sgs.CreateViewAsSkill{
name="harute6sanhong2",
n=1,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards == 1 then
			local new_card = harute6sanhong2_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("harute6sanhong")
			return new_card
		else return nil
		end
	end,
	enabled_at_play=function(self,player)
        return player:getMark("@harute6sanhong") > 0
    end,
}

harute6sanhong2=sgs.CreateTriggerSkill
{
	name="harute6sanhong2",
	frequency = sgs.Skill_Limited,
	view_as_skill = harute6sanhong2_vs,
	on_trigger=function(self,event,player,data)
	end,
}

harute6:addSkill(jiefang)
harute6:addSkill(jiefangd)
harute6:addSkill(weishan)
harute6:addSkill(harute6sanhong)
harute6:addSkill(harute6sanhong2)

RAPHAEL = sgs.General(extension, "RAPHAEL", "god", 3,true,false)

liepao = sgs.CreateFilterSkill{
    name = "liepao",
	
    view_filter = function(self, card)
        return card:inherits("Slash")
    end,
	
    view_as = function(self, card)
	if card:isBlack() then
        local acard = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        return acard
	elseif card:isRed() then
	    local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
        return acard
		end
    end,
}

rpsanhongcard=sgs.CreateSkillCard{
	name="rpsanhong",
	once=true,
	will_throw=false,
	filter = function(self, targets, to_select, player)
		return not to_select:isChained()
	end,
	on_effect=function(self,effect)                   
		local room = effect.from:getRoom()
		if effect.from:getMark("@rpsanhong") > 0 then
		effect.from:loseMark("@rpsanhong")
		room:setPlayerFlag(effect.from,"rpslash")
		effect.from:turnOver()
		end
		room:setPlayerProperty(effect.to, "chained", sgs.QVariant(true))
	end
}

rpsanhongvs=sgs.CreateViewAsSkill{
	name="rpsanhong",
	n=0,
	view_as=function(self, cards)
			if #cards==0 then
				local acard=rpsanhongcard:clone()         
				acard:setSkillName(self:objectName())     
				return acard
			end
	end,
	enabled_at_play=function(self,player)
			return player:getMark("@rpsanhong") > 0
	end,
	enabled_at_response=function(self,player,pattern) 
			return false
	end
}

rpsanhong = sgs.CreateTriggerSkill{
	name="rpsanhong",
	events=sgs.GameStart,
	frequency = sgs.Skill_Limited,
	view_as_skill=rpsanhongvs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
        player:gainMark("@rpsanhong")
	end
}

rpslash = sgs.CreateSlashSkill
{
	name = "#rpslash",
	can_trigger=function(self,player)
	    return true
	end,
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("rpsanhong") and from:hasFlag("rpslash")) or (from:hasSkill("solsanhong") and from:getMark("solling") > 0) then
			return -998
		end
	end,
	s_residue_func = function(self, from)
		if (from:hasSkill("rpsanhong") and from:hasFlag("rpslash")) then
            local init =  1 - from:getSlashCount()
            return init + 1
        else
            return 0
		end
	end,
}

weidacard = sgs.CreateSkillCard
{
	name = "weida",	
	target_fixed = true,	
	will_throw = false,

	on_use=function(self, room, source, targets)
	    for _,cd in sgs.qlist(self:getSubcards()) do
		source:addToPile("fenshen", cd)
		end
	end,
}

weidavs = sgs.CreateViewAsSkill
{
	name = "weida",	
	n = 998,

	view_filter=function(self,selected,to_select)
        return to_select:inherits("EquipCard")
    end,
	
	view_as = function(self, cards)
		if #cards >= 0 then
			local new_card = weidacard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("fenli")
			return new_card
		else return nil
		end
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@weida"
	end
}

weida = sgs.CreateTriggerSkill
{
	name = "weida",
	view_as_skill = weidavs,
	events = {sgs.PhaseChange},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
			 local room = player:getRoom()
		     local log=sgs.LogMessage()
             log.type = "#weida"
             room:sendLog(log)
	end,
}

fenlicard = sgs.CreateSkillCard
{
	name = "fenli",	
	target_fixed = false,	
	will_throw = false,

	filter = function(self, targets, to_select, player)
	if #targets >= 2 then return false end
		return to_select:getEquips():length() > 0
	end,

	on_use = function(self, room, source, targets)
		source:gainMark("@fenli")
		room:loseMaxHp(source)
		if targets[1]~=nil then
		for _,id in sgs.qlist(targets[1]:getEquips()) do
		room:moveCardTo(id, source, sgs.Player_Hand, true)
		end
		end
		if targets[2]~=nil then
		for _,id in sgs.qlist(targets[2]:getEquips()) do
		room:moveCardTo(id, source, sgs.Player_Hand, true)
		end
		end
		room:askForUseCard(source, "@@weida", "##fenli")
	end,
}

fenlivs = sgs.CreateViewAsSkill
{
	name = "fenli",	
	n = 0,

	view_as=function(self, cards)
			if #cards==0 then
				local acard=fenlicard:clone()
				acard:setSkillName(self:objectName())     
				return acard
			end
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@fenli"
	end
}

fenli = sgs.CreateTriggerSkill
{
	name = "fenli",
	view_as_skill = fenlivs,
	priority = 2,
	events = {sgs.HpChanged,sgs.CardGot,sgs.PhaseChange,sgs.Predamaged},
	frequency = sgs.Skill_Wake,
    can_trigger=function(self,player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local selfplayer = room:findPlayerBySkillName(self:objectName())
	if (event == sgs.HpChanged or event == sgs.CardGot) and player:getHp() == 1 and selfplayer:getMark("@fenli") == 0 then
			local can_invoke = false
			for _,aplayer in sgs.qlist(room:getAlivePlayers()) do
				if (aplayer:getEquips():length() > 0) then
					can_invoke = true
					break
				end
			end
			if can_invoke then
			room:askForUseCard(selfplayer, "@@fenli", "#fenli")
			end
		end
	if event == sgs.PhaseChange and selfplayer:getPhase()== sgs.Player_Discard and selfplayer:getPile("fenshen"):length() > 0 then
        local x=selfplayer:getHp()
	    local z = selfplayer:getHandcardNum()
	    local w = selfplayer:getMark("@weilu")
	    if z <= (selfplayer:getPile("fenshen"):length()+x-w) then
	    return true
	    else
        local e = z-(selfplayer:getPile("fenshen"):length()+x-w)
        room:askForDiscard(selfplayer,"fenli",e,e,false,false)
	    return true
        end
	end
	if event == sgs.Predamaged then
	    local damage = data:toDamage()
	    if selfplayer:getPile("fenshen"):length() >= damage.damage and room:askForSkillInvoke(selfplayer,self:objectName()) then
	        for i=1, damage.damage, 1 do
			local fenshen = selfplayer:getPile("fenshen")
            room:fillAG(fenshen,selfplayer)
            local id_t=room:askForAG(selfplayer,fenshen,false,self:objectName())
            room:throwCard(id_t)
            selfplayer:invoke("clearAG")
			end
		return true
		end
	end
end,
}

zibao = sgs.CreateTriggerSkill{
	name = "zibao",
	events={sgs.Death},
	frequency = sgs.Skill_Compulsory,
	can_trigger=function(self, player)
	    return true
    end,
    on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		if not player:hasSkill(self:objectName()) then return false end
		local damage = data:toDamageStar()
		if damage.from and damage.from:isAlive() then
		    local from = damage.from
		    room:loseMaxHp(from)
		end
	end,
}

RAPHAEL:addSkill(liepao)
RAPHAEL:addSkill(rpsanhong)
RAPHAEL:addSkill(rpslash)
RAPHAEL:addSkill(fenli)
RAPHAEL:addSkill(zibao)
RAPHAEL:addSkill(weida)

SOLBRAVES = sgs.General(extension, "SOLBRAVES", "god", 4,true,false)

duixing=sgs.CreateTriggerSkill{
    name="duixing",
    events=sgs.CardEffected,
	frequency = sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data)	
    local effect=data:toCardEffect()
    local room=player:getRoom()	
    if (effect.card:inherits("Snatch") or effect.card:inherits("Dismantlement")) and effect.to:hasSkill(self:objectName()) and effect.to:getHandcardNum() >= effect.to:getHp() then
    return true 
    end	
end
}

solsanhong=sgs.CreateTriggerSkill{
    name="solsanhong",
    events={sgs.GameStart,sgs.Damaged,sgs.PhaseChange,sgs.DrawNCards},
	frequency = sgs.Skill_Limited,
on_trigger=function(self,event,player,data)	
    local room = player:getRoom()
	local damage = data:toDamage()
	if event == sgs.GameStart then
	    player:gainMark("@solsanhong")
	end
    if event == sgs.Damaged and player:getMark("@solsanhong") > 0 and room:askForSkillInvoke(player, self:objectName()) then
	    player:loseMark("@solsanhong")
		room:setPlayerMark(player,"solling",1)
		player:gainAnExtraTurn(player)
	end
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start and player:getMark("solling") > 0 then
	    player:turnOver()
	    player:skip(sgs.Player_Judge)
    end
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:getMark("solling") > 0 then
		room:setPlayerMark(player,"solling",0)
    end
	if event == sgs.DrawNCards and player:getMark("solling") > 0 then
	    data:setValue(data:toInt()+1)
	end
end
}

kaituocard = sgs.CreateSkillCard{
	name = "kaituo", 
	target_fixed = false, 
	will_throw = false,
	filter = function(self, targets, to_select)
        return #targets < 3
    end,
	on_use = function(self, room, source, targets)
		local damage = sgs.DamageStruct()
		damage.from = nil
		if targets[1]~=nil then
		    damage.to = targets[1]
			room:damage(damage)
		end
		if targets[2]~=nil then
		    damage.to = targets[2]
			room:damage(damage)
		end
		if targets[3]~=nil then
		    damage.to = targets[3]
			room:damage(damage)
		end
		local target = room:askForPlayerChosen(source,room:getOtherPlayers(source),self:objectName())
		target:drawCards(source:getHandcardNum())
		room:killPlayer(source,nil)
		target:gainAnExtraTurn(source)
	end,
}

kaituo = sgs.CreateViewAsSkill{
	name = "kaituo", 
	n = 0,
	view_as = function(self, cards) 
		if #cards == 0 then
			local card = kaituocard:clone()
			card:setSkillName(self:objectName())
			return card
		end
	end, 
	enabled_at_play = function(self, player)
		return true
	end,
}

SOLBRAVES:addSkill(duixing)
SOLBRAVES:addSkill(solsanhong)
SOLBRAVES:addSkill(kaituo)

OORAISER = sgs.General(extension, "00-RAISER", "god", 5, true,false)

jian3 = sgs.CreateSlashSkill
{
	name = "jian3",
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("jian3") and slash and slash:isRed()) then
			return -3
		end
	end,
}

kuairen = sgs.CreateTriggerSkill
{
    name = "kuairen",
    events = {sgs.SlashMissed},
	priority = 2,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local effect = data:toSlashEffect()
    if effect.slash:isBlack() and not (effect.to:isProhibited(effect.to, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then
	    local tslash = room:askForCard(player,"Slash","kuairen",data)
	if tslash then
	    local use = sgs.CardUseStruct()
        use.card = tslash
		use.from = player
 
		use.to:append(effect.to)
		
		room:useCard(use)
	end
	end
end,	
}

shuangyi = sgs.CreateTriggerSkill
{
	name = "shuangyi",
	events = {sgs.Predamaged},
	frequency = sgs.Skill_Compulsory,
on_trigger = function(self, event, player, data)
        local room=player:getRoom()
		local damage = data:toDamage()
    if damage.from:getPhase() ~= sgs.Player_NotActive and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() then
    if not damage.from:hasFlag("shuangyip") then
        room:setPlayerFlag(damage.from,"shuangyip")
		if damage.damage > 1 then
		    damage.damage = 1
		    data:setValue(damage)
		    return false
		end
	elseif damage.from:hasFlag("shuangyip") then
	    return true
	end
	end
end,
}

oorsanhong = sgs.CreateTriggerSkill
{
	name = "oorsanhong",
	events = sgs.HpChanged,
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	    local room=player:getRoom()
	if player:getHp() <= 3 then
	
        for _, p in sgs.qlist(room:getPlayers()) do
            p:unicast("animate lightbox:$oorsanhong:2000")
        end

	room:transfigure(player, "00-RAISER2", false, true)
	if player:isChained() then 
	    room:setPlayerProperty(player, "chained", sgs.QVariant(false))
	end
end
end
}

OORAISER:addSkill(jian3)
OORAISER:addSkill(kuairen)
OORAISER:addSkill(shuangyi)
OORAISER:addSkill(oorsanhong)

OORAISER2 = sgs.General(extension, "00-RAISER2", "god", 4, true,true,true)

xiaohao = sgs.CreateTriggerSkill
{
	name = "xiaohao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PhaseChange},

	on_trigger = function(self, event, player, data)
		    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			if player:getHandcardNum() >= 3 then
			    local choice = room:askForChoice(player, self:objectName(), "xhhp+xhmaxhp+xhdis")
			    if choice == "xhhp" then
				    room:loseHp(player)
				elseif choice == "xhmaxhp" then
				    room:loseMaxHp(player)
			    elseif choice == "xhdis" then
				    room:askForDiscard(player,"xiaohao",3,3,false,false)
				end
			elseif player:getHandcardNum() < 3 then
			    local choice = room:askForChoice(player, self:objectName(), "xhhp+xhmaxhp")
			    if choice == "xhhp" then
				    room:loseHp(player)
				elseif choice == "xhmaxhp" then
				    room:loseMaxHp(player)
				end
			end
		end
	end,
}

chunzhongcard = sgs.CreateSkillCard
{
	name = "chunzhong",	
	target_fixed = false,	
	will_throw = false,

	filter = function(self, targets, to_select, player)
		return #targets < 3
	end,

	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		effect.to:gainMark("@chunzhong")
		room:attachSkillToPlayer(effect.to,"chunzhongv")
	end,
}

chunzhongvs = sgs.CreateViewAsSkill
{
	name = "chunzhong",	
	n = 0,

	view_as = function(self, cards)
		local card = chunzhongcard:clone()
		card:setSkillName(self:objectName())
		return card
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@chunzhong"
	end
}

chunzhong = sgs.CreateTriggerSkill
{
	name = "chunzhong",
	view_as_skill = chunzhongvs,
	events = {sgs.PhaseChange,sgs.CardAsked,sgs.Death},
    can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
			local room = player:getRoom()
			local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.PhaseChange and selfplayer:getPhase() == sgs.Player_Discard then
			local can_invoke = false
			for _,aplayer in sgs.qlist(room:getAlivePlayers()) do
				if (aplayer:isAlive()) then
					can_invoke = true
					break
				end
			end
			if(not room:askForSkillInvoke(selfplayer, "chunzhong")) then return false end
			if can_invoke and room:askForUseCard(selfplayer, "@@chunzhong", "@chunzhongcard") then
			local x=selfplayer:getHp()
			local z = selfplayer:getHandcardNum()
			local w = selfplayer:getMark("@weilu")
			if z <= (2+x-w) then
			return true
			else
			local e = z-(2+x-w)
			room:askForDiscard(selfplayer,"chunzhong",e,e,false,false)
			return true
			end
			end
		return false
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Discard and selfplayer:isAlive() and player:getMark("@chunzhong") > 0 then
	    local x=player:getHp()
        local z = player:getHandcardNum()
        local w = player:getMark("@weilu")
        if z <= (2+x-w) then
        return true
        else
        local e = z-(2+x-w)
        room:askForDiscard(player,"chunzhong",e,e,false,false)
	    return true
		end
	elseif event == sgs.CardAsked and data:toString() == "jink" and selfplayer:isAlive() and player:getMark("@chunzhong") > 0 and not player:getArmor() and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and room:askForSkillInvoke(player, self:objectName()) then
		    local judge=sgs.JudgeStruct()
			judge.pattern=sgs.QRegExp("(.*):(heart|diamond):(.*)")
			judge.good=true
			judge.reason=self:objectName()
			judge.who=player
			room:judge(judge)
			if (judge:isGood()) then
				local jink_card = sgs.Sanguosha:cloneCard ("jink",sgs.Card_NoSuit,0)
				jink_card:setSkillName(self:objectName())
				room:provide(jink_card)
				room:setEmotion(player, "good")
				return true
			else room:setEmotion(player, "bad")
			end
	elseif (event == sgs.PhaseChange and selfplayer:getPhase() == sgs.Player_Start) then
	    for _,p in sgs.qlist(room:getAlivePlayers()) do
		    if p:getMark("@chunzhong") > 0 then
			p:loseMark("@chunzhong")
			room:detachSkillFromPlayer(p,"chunzhongv")
			end
			end
		end
	end
}

chunzhongvcard = sgs.CreateSkillCard{
        name = "chunzhongv",
        will_throw = false,
        target_fixed = false,
        filter = function(self, targets, to_select)
        if #targets>0 then return false end
            return to_select:hasSkill("chunzhong")
        end,
        on_use = function(self, room, source, targets)
		        room:setPlayerFlag(source,"chunzhongvused")
                room:moveCardTo(self, targets[1], sgs.Player_Hand, false)
        end,
}

chunzhongv = sgs.CreateViewAsSkill{
        name = "chunzhongv",
        n = 1,
        view_filter = function(self, selected, to_select)
                return not to_select:isEquipped()
        end,
        view_as = function(self, cards)
                if #cards ~= 1 then return nil end
                local acard = chunzhongvcard:clone()
                for _,card in ipairs(cards) do
                        acard:addSubcard(card:getId())
                end
                return acard
        end,
        enabled_at_play = function(self,player)
                return player:getMark("@chunzhong") > 0 and not player:hasFlag("chunzhongvused")
        end,
        enabled_at_response = function(self, player, pattern)
                return false
        end,
}

sanhua = sgs.CreateTriggerSkill{
	name = "sanhua",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Predamaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local x = damage.damage
	if player:faceUp() and player:getHandcardNum() >= x and room:askForSkillInvoke(player, self:objectName()) then
	    room:askForDiscard(player,"sanhua",x,x,false,false)
		player:turnOver()
		return true
		end
	end
}

OORAISER2:addSkill(xiaohao)
OORAISER2:addSkill(chunzhong)
OORAISER2:addSkill(sanhua)

GADELAZA = sgs.General(extension, "GADELAZA", "god", 5,true,false)

renpo_card=sgs.CreateSkillCard{
        name = "renpo",
        will_throw = false,
        once = true,
        filter = function(self,targets,to_select,player)
        if (#targets>0) then return false end
        return not to_select:isKongcheng()
        end,
        on_effect=function(self,effect)          
                local room = effect.from:getRoom()
                room:setPlayerFlag(effect.from, "renpo_used")
                if (effect.from:pindian(effect.to,"renpo",self)) then
					    for i=1,effect.to:getHp(),1 do
						if effect.to:isNude() then break end
						room:moveCardTo(sgs.Sanguosha:getCard(room:askForCardChosen(effect.from, effect.to, "he", "renpo")), effect.from, sgs.Player_Hand, false)
		                end
                else
                    local current=room:getCurrent()
                    local thread=room:getThread()
                    current:play(current:getPhases())
                    while true do
                    current=current:getNextAlive()
                    current:gainAnExtraTurn(current)
                    end
                end
        end,
}

renpo=sgs.CreateViewAsSkill{
        name = "renpo",
        n = 1,
        view_filter = function(self, selected, to_select)
                return not to_select:isEquipped()
        end,
        view_as=function(self, cards)
                if #cards == 1 then 
                        local acard = renpo_card:clone()
                        acard:addSubcard(cards[1])                
                        acard:setSkillName("renpo")
                        return acard end
        end,
        enabled_at_play = function(self,player)
                return not player:hasFlag("renpo_used")
        end,
        enabled_at_response = function(self,player,pattern) 
                return false 
        end
}

ganrao = sgs.CreateTriggerSkill
{
	name = "ganrao",
	events = {sgs.CardUsed},
	priority=2,
	frequency = sgs.Skill_Compulsory,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if player:getMark("@glsanhong") > 0 then return false end
		if event==sgs.CardUsed then
        local effect=data:toCardUse()
        local card=data:toCardUse().card
        if card:inherits("Slash") and player:isNude() then
		local log=sgs.LogMessage()
        log.from =player
		log.arg = self:objectName()
        log.type ="#ganrao"
        room:sendLog(log)
            room:playSkillEffect("ganrao")
			room:loseHp(player,1)
		elseif card:inherits("Slash") and (not player:isNude()) then
		local log=sgs.LogMessage()
        log.from =player
		log.arg = self:objectName()
        log.type ="#ganrao"
        room:sendLog(log)
            local choice=room:askForChoice(player, self:objectName(), "ganraohp+ganraodis")
		    if choice == "ganraohp" then
			room:playSkillEffect("ganrao")
			room:loseHp(player,1)
			elseif choice == "ganraodis" then
			room:askForDiscard(player,"ganrao",1,1, false,true)
			end
    end        
    end
	end,
}

glsanhong=sgs.CreateTriggerSkill{
        name="glsanhong",
		frequency = sgs.Skill_Wake,
        events=sgs.HpChanged,
		can_trigger = function(self, player)
                return true
        end,
        on_trigger=function(self,event,player,data)
        local room=player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
        if  selfplayer:getMark("@glsanhong") > 0 then return false end
        local x=selfplayer:getHp()
        local m={} 
        for _,p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
                        table.insert(m,p:getHp())                        
        end
        if x>math.min(unpack(m)) then m=nil return end
        local log=sgs.LogMessage()
        log.from =selfplayer
		log.arg = self:objectName()
        log.type ="#glsanhong"
        room:sendLog(log)
        selfplayer:gainMark("@glsanhong")
        room:loseMaxHp(selfplayer)
		room:detachSkillFromPlayer(selfplayer,"ganrao")
		room:acquireSkill(selfplayer,"benchi")
    end
}

benchicard=sgs.CreateSkillCard{
	name="benchi",
	once=true,
	will_throw=false,
	filter = function(self, targets, to_select, player)
		if #targets >= 1 then return false end
		if (to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0))) then return false end
		return sgs.Self:canSlash(to_select, true)
	end,
	on_effect=function(self,effect)                   
		local room = effect.from:getRoom()
		room:loseHp(effect.from)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName("benchi")
		local use = sgs.CardUseStruct()
		use.from = effect.from
		use.to:append(effect.to)
		use.card = slash
		room:useCard(use,false)
	end
}

benchi=sgs.CreateViewAsSkill{
	name="benchi",
	n=0,
	view_as=function(self, cards)
			if #cards==0 then
				local acard=benchicard:clone()         
				acard:setSkillName(self:objectName())     
				return acard
			end
	end,
	enabled_at_play=function(self,player)
			return true
	end,
	enabled_at_response=function(self,player,pattern) 
			return false
	end
}

GADELAZA:addSkill(renpo)
GADELAZA:addSkill(ganrao)
GADELAZA:addSkill(glsanhong)

znh = sgs.General(extension, "znh", "god", 5, true,true,true)

shouhu = sgs.CreateTriggerSkill{
        frequency = sgs.Skill_Compulsory,
        name = "shouhu",
        events = sgs.PhaseChange,        
        on_trigger = function(self,event,player,data)
		if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start then
        local room = player:getRoom()
        room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHp()+1))
		local recover=sgs.RecoverStruct()
        recover.who=player
        recover.recover=1
        room:recover(player,recover)
    end
	end
}

znh_sanhong = sgs.CreateTriggerSkill
{--突袭 by ibicdlcod
	name = "znh_sanhong",
	events = {sgs.PhaseChange ,sgs.Death},
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	local players = room:getOtherPlayers(player)
	if player:getHandcardNum() > 10 then
	if player:getPhase() ~= sgs.Player_Play then return end
    
	for _, p in sgs.qlist(room:getPlayers()) do
    p:unicast("animate lightbox:Trans-AM:2000")
	end

	room:transfigure(player, "transam_znh", false, true)
	        local x = player:getHandcardNum()
			room:askForDiscard(player,"weilu",x/2,x/2,false,false)
			if player:isChained() then 
					room:setPlayerProperty(player, "chained", sgs.QVariant(false))
				end
end
end
}

znh_sanhong2 = sgs.CreateTriggerSkill{
        name = "#znh_sanhong2",
        frequency = sgs.Skill_Wake,
        events = {sgs.Death},
        can_trigger = function(self, player)
                return not player:hasSkill(self:objectName())
        end,
        on_trigger = function(self, event, player, data)
                local room = player:getRoom()
                local selfplayer = room:findPlayerBySkillName(self:objectName())
    for _, p in sgs.qlist(room:getPlayers()) do
    p:unicast("animate lightbox:Trans-AM:2000")
	end

	room:transfigure(selfplayer, "transam_znh", false, true)
            selfplayer:throwAllCards()
			selfplayer:drawCards(3)
			if selfplayer:isChained() then 
					room:setPlayerProperty(selfplayer, "chained", sgs.QVariant(false))
				end
        end
}

znh:addSkill(shouhu)
znh:addSkill(znh_sanhong)
znh:addSkill(znh_sanhong2)

transam_znh = sgs.General(extension, "transam_znh", "god", 4, true,true,true)

-- 隐藏人物（用于觉醒技）
yincangzhe = sgs.General(extension, "yincangzhe", "qun", 4, true, true, true)

saochang = sgs.CreateViewAsSkill
{--苦肉 by ibicdlcod
	name = "saochang",
	n = 0,

	view_as = function(self, cards)
	if sgs.Self:getMark("saochangused") > 0 then return nil end
		local card = saochangcard:clone()		
		card:setSkillName(self:objectName())
		return card
	end
}

saochangcard = sgs.CreateSkillCard
{--苦肉技能卡 by ibicdlcod
	name = "saochang",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, player, targets)
		room:loseHp(player)
		room:loseMaxHp(player)
		if(player:isAlive()) then
			room:acquireSkill(player,"saochang_a")
			room:acquireSkill(player,"saochang_b")
			player:gainMark("saochangused")
		end
		if player:getPhase()==sgs.Player_Finish then
	        room:detachSkillFromPlayer(player,"saochang_a")	
			room:detachSkillFromPlayer(player,"saochang_b")
			player:loseMark("saochangused")
		end
	end,

	enabled_at_play = function()
		return true
	end
}

saochang_a = sgs.CreateViewAsSkill
{--奇袭 by ibicdlcod
	name = "saochang_a",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card =sgs.Sanguosha:cloneCard("savage_assault", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end
}

saochang_b = sgs.CreateViewAsSkill
{--奇袭 by ibicdlcod
	name = "saochang_b",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card =sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end
}

tianren = sgs.CreateTriggerSkill{
frequency = sgs.Skill_NotFrequent,
name = "tianren",
events={sgs.Death}, 
can_trigger=function(self,player)
	return player:hasSkill("tianren") end,
on_trigger=function(self,event,player,data)
	local room = player:getRoom()
	if event == sgs.Death then
	if room:askForSkillInvoke(player,"tianren") then
	    local target=room:askForPlayerChosen(player,room:getOtherPlayers(player),"tianren")
	    target:turnOver()
    end
	end
end
}

transam_znh:addSkill(saochang)
transam_znh:addSkill(tianren)
yincangzhe:addSkill(saochang_a)
yincangzhe:addSkill(saochang_b)
yincangzhe:addSkill(bianxingdistance)
yincangzhe:addSkill(jingzhundistance)

hinu = sgs.General(extension, "hinu", "god", 3, true,false)

abao = sgs.CreateViewAsSkill
{
	name = "abao",
	n = 1,

	view_filter = function(self, selected, to_select)
	if sgs.Self:getSlashCount() > 0 and sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Crossbow" then
	    return to_select:isBlack() and not(to_select:isEquipped() and to_select:inherits("Weapon"))
		else
		return to_select:isBlack()
		end
	end,

	view_as = function(self, cards)
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("thunder_slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "slash"
	end,
}

abaoslash = sgs.CreateSlashSkill
{
	name = "#abaoslash",
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("abao") and slash and slash:getSkillName() == "abao") then
			return -998
		end
	end,
}

ganyingskill={}
ganying=sgs.CreateTriggerSkill{
	name="ganying",
	frequency=sgs.Skill_NotFrequent,
	priority = 10,
	events={sgs.TurnStart,sgs.CardUsed},
	on_trigger=function(self,event,player,data)
	    local room=player:getRoom()
	if event == sgs.TurnStart then
		if #ganyingskill~=0 then
			room:detachSkillFromPlayer(player,ganyingskill[1])
			table.remove(ganyingskill)
		end
		end
	if event == sgs.CardUsed then
        local use=data:toCardUse()
        local card = use.card
		if card:inherits("ThunderSlash") or card:inherits("FireSlash") then
		if player:hasFlag("ganyingused") then return end
		if player:getPhase() ~= sgs.Player_Play then return end
		local skilllist={}
		for _,p in sgs.qlist(use.to) do
			for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				local name=skill:objectName()
				if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake)  then
					table.insert(skilllist,name)
				end
			end
		end
		if #skilllist~=0 then
			if not player:askForSkillInvoke(self:objectName()) then return end
			local skill=room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
			table.insert(ganyingskill,skill)
			room:acquireSkill(player,skill)
			room:playSkillEffect("ganying")
			room:setPlayerFlag(player,"ganyingused")
		end
		end
		end
	end,
}

gujia=sgs.CreateTriggerSkill
{--涅槃 by 【群】皇叔
	name = "gujia",
	frequency = sgs.Skill_Wake,
	events = {sgs.Dying},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying=data:toDying()
		    if dying.who:hasSkill("gujia") and dying.who:getMark("@gujia")==0 then
			room:playSkillEffect(self:objectName())
			player:gainMark("@gujia")
			local getKingdoms=function() --可以在函数中定义函数
			local kingdoms={}
			local kingdom_number=0
			local players=room:getAlivePlayers()
			for _,aplayer in sgs.qlist(players) do
				if not kingdoms[aplayer:getKingdom()] then
					kingdoms[aplayer:getKingdom()]=true
					kingdom_number=kingdom_number+1
				end
			end
			return kingdom_number
		end
        local x=getKingdoms()
		    player:throwAllCards()
			player:drawCards(x)
			local recover = sgs.RecoverStruct()   --回复结构体
			                recover.recover = x  --回复点数
			                recover.who = player   --回复来源
			                room:recover(player,recover)
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			room:acquireSkill(p,"nihong")
			p:gainMark("nihong")
			end
			end
	end,
}

nihong = sgs.CreateProhibitSkill
{--空城 by 【群】皇叔
	name = "nihong",
	is_prohibited = function(self, from, to, card)
		if to:hasSkill("nihong") and to:getMark("nihong") > 0 then
			return (card:inherits("Slash") and card:isRed()) or card:inherits("Duel")
		end
	end,
}

nihongL=sgs.CreateTriggerSkill
{--涅槃 by 【群】皇叔
	name = "#nihongL",
	events = {sgs.Death},
	 can_trigger = function(self, player)
                return player:hasSkill("#nihongL")
        end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			p:loseMark("nihong")
			end
	end,
}

hinu:addSkill(abao)
hinu:addSkill(abaoslash)
hinu:addSkill(ganying)
hinu:addSkill(gujia)
hinu:addSkill(nihongL)

starooq = sgs.General(extension, "starooq$", "god", 4, true,false)

jiansi = sgs.CreateTriggerSkill
{
	name = "jiansi",
	events = {sgs.Predamage},
	frequency = sgs.Skill_NotFrequent,
on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	local damage = data:toDamage()
	if(event == sgs.Predamage) then
	if damage.to:getHp() < 4 then return false end
	    if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
	    room:playSkillEffect("jiansi")
	    damage.damage = damage.damage+1
	    data:setValue(damage)
	    return false
	end
end,
}

quanren=sgs.CreateTriggerSkill{
        name="quanren",
        events={sgs.AskForRetrial,sgs.FinishJudge},
        frequency = sgs.Skill_NotFrequent,
        on_trigger=function(self,event,player,data)
                local room=player:getRoom()
                local selfplayer=room:findPlayerBySkillName(self:objectName())
				if event == sgs.AskForRetrial then
                local judge = data:toJudge()
				if judge.who:objectName() ~= selfplayer:objectName() then return false end
				selfplayer:setTag("Judge",data)
				if (room:askForSkillInvoke(selfplayer,self:objectName(),data)~=true) then return false end
                      room:setPlayerFlag(judge.who, "qr")
			    if not selfplayer:hasFlag("qr") then return false end
				selfplayer:addToPile("quanren",judge.card)
                local idlist=room:getNCards(1)
				for _,id in sgs.qlist(idlist) do
				    card = sgs.Sanguosha:getCard(id)
			    end
                judge.card = sgs.Sanguosha:getCard(card:getEffectiveId())
                room:moveCardTo(judge.card, nil, sgs.Player_Special)
				local log=sgs.LogMessage()
               log.type = "$ChangedJudge"
               log.from = selfplayer
               log.to:append(judge.who)
               log.card_str = card:getEffectIdString()
               room:sendLog(log)
               room:sendJudgeResult(judge)
			   end
			   if(event == sgs.FinishJudge and data:toJudge().who:hasFlag("qr")) then
			    local judge = data:toJudge()
				room:setPlayerFlag(judge.who, "-qr")
				selfplayer:addToPile("quanren",judge.card)
				local q = selfplayer:getPile("quanren")
				if ((sgs.Sanguosha:getCard(q:at(0)):isBlack() and sgs.Sanguosha:getCard(q:at(1)):isRed()) or (sgs.Sanguosha:getCard(q:at(0)):isRed() and sgs.Sanguosha:getCard(q:at(1)):isBlack())) then
                room:fillAG(q,selfplayer)
				local id_t=room:askForAG(selfplayer,q,false,self:objectName())
				room:obtainCard(player, id_t)
				q:removeOne(id_t)
				for _,qq in sgs.qlist(q) do
				    room:throwCard(qq)
				end
				selfplayer:invoke("clearAG")
				else
				for _,qq in sgs.qlist(q) do
				    room:throwCard(qq)
				end
				end
				return true
				else
				return false
				end
                return false
        end,        
}

starsanhongvs = sgs.CreateViewAsSkill
{
	name = "starsanhong",
	n = 1,

    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
	view_as = function(self, cards)
		if #cards == 1 then
        local acard = starsanhongcard:clone()
        acard:addSubcard(cards[1])                
        acard:setSkillName(self:objectName())
        return acard
		end
        end,
	enabled_at_play = function(self,player)
		return player:getMark("@starsanhong") > 0
	end,
}

starsanhongcard = sgs.CreateSkillCard
{
	name = "starsanhong",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
	    source:loseMark("@starsanhong")
		while true do
				local judge = sgs.JudgeStruct()
				judge.pattern = sgs.QRegExp("(.*):(spade|club):(.*)")
				judge.good = true
				judge.reason = "starsanhong"
				judge.who = source
				room:judge(judge)
				if judge:isGood() then
				source:obtainCard(judge.card)
				elseif(judge:isBad()) then break end
		end
		source:turnOver()
	end,
}

starsanhong=sgs.CreateTriggerSkill
{
	name="starsanhong",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = starsanhongvs,
	on_trigger=function(self,event,player,data)
		player:gainMark("@starsanhong")
	end,
}

starooq:addSkill(jiansi)
starooq:addSkill(quanren)
starooq:addSkill(starsanhong)

els = sgs.General(extension, "els", "god", 9, true,true)

rongheskill={}
ronghe=sgs.CreateTriggerSkill{
	name="ronghe",
	frequency=sgs.Skill_NotFrequent,
	priority = 10,
	events={sgs.Death},
	can_trigger = function(self, player)
        return true
    end,
	on_trigger=function(self,event,player,data)
	    local room=player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if player:getGeneralName() == "elssmall" then return false end
	if player:objectName() == selfplayer:objectName() then return false end
	if room:askForSkillInvoke(selfplayer,self:objectName(),data) then
		local skilllist={}
			for _,skill in sgs.qlist(player:getVisibleSkillList()) do
				local name=skill:objectName()
				if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Wake)  then
					table.insert(skilllist,name)
				end
			end
		if #skilllist~=0 then
			local skill=room:askForChoice(selfplayer,self:objectName(),table.concat(skilllist,"+"))
			table.insert(rongheskill,skill)
			room:acquireSkill(selfplayer,skill)
			room:transfigure(selfplayer, "els", false, true)
			room:playSkillEffect("ronghe")
		end
		end
	end,
}

qunxi = sgs.CreateViewAsSkill
{--奇袭 by ibicdlcod
	name = "qunxi",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("Slash")
	end,

	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card =sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end
}

qinshi = sgs.CreateTriggerSkill
{
	name = "qinshi",
	events = {sgs.Damage},
	frequency = sgs.Skill_NotFrequent,
    can_trigger=function(self, player)
	    return player:hasSkill(self:objectName()) or player:hasSkill("tongzhong")
    end,
    on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		local to = damage.to
		if event == sgs.Damage then
		if player:hasSkill(self:objectName()) then
		  if (not room:askForSkillInvoke(player, self:objectName(),data)) then return false end

			local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(spade|club):(.*)")
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if(judge:isGood()) then
			if to:isNude() or not to:isAlive() then return end
				local card_id = room:askForCardChosen(player, to, "he", "qinshi")
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), player, sgs.Player_Hand, false)
	end
	    else
		    local selfplayer = room:findPlayerBySkillName(self:objectName())
		    if (not room:askForSkillInvoke(selfplayer, self:objectName(),data)) then return false end

			local judge = sgs.JudgeStruct()
			judge.pattern = sgs.QRegExp("(.*):(spade|club):(.*)")
			judge.good = true
			judge.reason = self:objectName()
			judge.who = selfplayer
			room:judge(judge)
			if(judge:isGood()) then
			if to:isNude() or not to:isAlive() then return end
				local card_id = room:askForCardChosen(selfplayer, to, "he", "qinshi")
				room:moveCardTo(sgs.Sanguosha:getCard(card_id), selfplayer, sgs.Player_Hand, false)
	end
	end
	end
end,
}

elsmode=sgs.CreateTriggerSkill{
	name="#elsmode",
	priority = 2,
	events={sgs.CardEffected},
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	    local effect = data:toCardEffect()
	if effect.card:getSkillName() == "lijie" and player:getMark("@lijie") > 0 then
	    if player:getMark("@lijie") > 1 then
		    room:setPlayerMark(player,"@lijie",player:getMark("@lijie")-1)
		else
		    room:killPlayer(player)
		end
	end
	end,
}

els:addSkill(ronghe)
els:addSkill(qunxi)
els:addSkill(qinshi)
els:addSkill(elsmode)

elssmall = sgs.General(extension, "elssmall", "god", 2, true,true,true)

tongzhong=sgs.CreateTriggerSkill{
	name="tongzhong",
	frequency=sgs.Skill_Compulsory,
	events={sgs.Predamaged,sgs.Predamage},
	priority = 2,
	on_trigger=function(self,event,player,data)
		    local room = player:getRoom()
		    local damage = data:toDamage()
	    if event == sgs.Predamaged and damage.from:getGeneralName() == "els" then
	        return true
	    elseif event == sgs.Predamage then
		    local froms = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getGeneralName() == "els" then
				froms:append(p)
				end
			end
			local from = room:askForPlayerChosen(player, froms, "tongzhong")
			damage.from = from
			data:setValue(damage)
			return false
		end
    end
}

zailin=sgs.CreateTriggerSkill{
	name="zailin",
	events={sgs.GameStart,sgs.Death},
	priority = 2,
	can_trigger=function(self, player)
	    return player:hasSkill(self:objectName())
    end,
	on_trigger=function(self,event,player,data)
		    local room = player:getRoom()
	    if event == sgs.GameStart then
		    for _,p in sgs.qlist(room:getAlivePlayers()) do
			    if p:getGeneralName() == "els" and not p:hasSkill("zailinv") then
			        room:attachSkillToPlayer(p,"zailinv")
				end
			end
		elseif event == sgs.Death then
		    for _,q in sgs.qlist(room:getAlivePlayers()) do
			    if q:getGeneralName() == "els" then
				    room:setPlayerMark(q,"canzailin",q:getMark("canzailin")+1)
				end
			end
		end
    end
}

zailinvcard = sgs.CreateSkillCard{
        name = "zailinv",
        will_throw = true,
        target_fixed = true,
        on_use = function(self, room, source, targets)
		    for _,p in sgs.qlist(room:getPlayers()) do
			    if p:isDead() and p:hasSkill("zailin") then
			        room:revivePlayer(p)
			        room:setPlayerProperty(p, "maxhp", sgs.QVariant(2))
			        room:setPlayerProperty(p,"hp",sgs.QVariant(2))
			        room:setPlayerMark(source,"canzailin",0)
				end
			end
        end,
}

zailinv = sgs.CreateViewAsSkill{
        name = "zailinv",
        n = 2,
        view_filter=function(self, selected, to_select)
        if #selected ==0 then return not to_select:isEquipped() end
        if #selected == 1 then
                        local cc = selected[1]:getSuit()
						local dd = selected[1]:getNumber()
                        return (not to_select:isEquipped()) and (to_select:getSuit() == cc or to_select:getNumber() == dd)
        else return false
        end
        end,
        view_as = function(self, cards)
		if #cards == 2 then
			local new_card = zailinvcard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("zailinv")
			return new_card
		else return nil
		end
	    end,
        enabled_at_play = function(self,player)
                return player:getMark("canzailin") > 0
        end,
        enabled_at_response = function(self, player, pattern)
                return false
        end,
}

elssmall:addSkill(tongzhong)
elssmall:addSkill(zailin)

gundam = sgs.General(extension, "gundam", "god", 4,true,false)

yuanzuskill={}
yuanzu=sgs.CreateTriggerSkill{
	name="yuanzu",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.GameStarted,sgs.TurnStart,sgs.PhaseEnd},
	on_trigger=function(self,event,player,data)
		if event==sgs.GameStarted or event == sgs.TurnStart or (event == sgs.PhaseEnd and player:getPhase() == sgs.Player_Finish) then
		local room=player:getRoom()
		if #yuanzuskill~=0 then
			room:detachSkillFromPlayer(player,yuanzuskill[1])
			table.remove(yuanzuskill)
		end
		local skilllist={}
		local all=room:getOtherPlayers(player)
		for _,p in sgs.qlist(all) do
			for _,skill in sgs.qlist(p:getVisibleSkillList()) do
				local name=skill:objectName()
				if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake)  then
					table.insert(skilllist,name)
				end
			end
		end
		if #skilllist~=0 then
			if not player:askForSkillInvoke(self:objectName()) then return end
			room:playSkillEffect("yuanzu")
			local skill=room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
			table.insert(yuanzuskill,skill)
			local target=room:findPlayerBySkillName(skill)
			room:setEmotion(target,"judgegood")
			room:acquireSkill(player,skill)
		end
	end
end
}

gundam:addSkill(yuanzu)

zaku2 = sgs.General(extension, "zaku2", "god", 4,true,false)

sanbei=sgs.CreateTriggerSkill{
frequency = sgs.Skill_NotFrequent,
name = "sanbei",
events={sgs.DrawNCards},
on_trigger=function(self,event,player,data)
  local room=player:getRoom()
  if event==sgs.DrawNCards then
  if (not room:askForSkillInvoke(player, self:objectName())) then return end
   room:playSkillEffect("sanbei")
   room:drawCards(player,1)
   data:setValue(0)
   for i=1,3,1 do --1到X循环
				local card_id = room:drawCard() --取一张牌
				local card=sgs.Sanguosha:getCard(card_id)
                room:moveCardTo(card,nil,sgs.Player_Special,true)
                room:getThread():delay()
				if(card:isRed())then
				room:obtainCard(player,card_id)
                elseif not(card:isRed())then --否则玩家获得该牌
                    room:throwCard(card_id)
				end	
			end
		end
	end
}

feiti = sgs.CreateTriggerSkill
{
	name = "feiti",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashProceed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		if event == sgs.SlashProceed and effect.slash:isRed() then
			if (not room:askForSkillInvoke(player, self:objectName())) then return false end
				room:playSkillEffect("feiti")
				room:slashResult(effect, nil)      
				return true
		end
	end
}

zaku2:addSkill(sanbei)
zaku2:addSkill(feiti)

zeta = sgs.General(extension, "zeta", "god", 4,true,false)

chihun = sgs.CreateTriggerSkill{
        name = "chihun",
        frequency = sgs.Skill_NotFrequent,
        events = {sgs.Damaged},
        can_trigger = function(self, player)
                return true
        end,
        on_trigger = function(self, event, player, data)
                local room = player:getRoom()
				local damage = data:toDamage()
                local selfplayer = room:findPlayerBySkillName(self:objectName())
				if selfplayer:isKongcheng() then return end
				if not selfplayer:inMyAttackRange(damage.to) then return end
                if not room:askForSkillInvoke(selfplayer, self:objectName(), data) then return end
				    room:playSkillEffect("chihun")
				    room:askForDiscard(selfplayer,"chihun",1,1,false,false)
				    local judge = sgs.JudgeStruct()
			        judge.pattern = sgs.QRegExp("(.*):(spade|heart|club|diamond):(.*)")
			        judge.good = true
			        judge.reason = self:objectName()
			        judge.who = selfplayer
			        room:judge(judge)
			            if(judge.card:isBlack()) then
						    selfplayer:obtainCard(judge.card)
						elseif(judge.card:getSuit() == sgs.Card_Heart) then
						    if not damage.from:isAlive() then return end
							room:loseHp(damage.from,1)
						elseif(judge.card:getSuit() == sgs.Card_Diamond) then
						    if not damage.to:isAlive() then return end
							local recover = sgs.RecoverStruct()   --回复结构体
			                recover.recover = 1  --回复点数
			                recover.who = damage.to   --回复来源
			                room:recover(damage.to,recover)
						end
        end
}

tucicard=sgs.CreateSkillCard{  --??EX卡片
name="tucicard",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
          if(#targets > 0) then return end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)                
        local room=effect.from:getRoom()
		local x = effect.from:getMark("@tuci")
		room:loseHp(effect.from,x)
		effect.from:loseMark("@tuci",x)
		effect.from:loseMark("@tucimain")
		room:playSkillEffect("tuciTS",math.random(1,2))
        room:setPlayerProperty(effect.to,"maxhp",sgs.QVariant(effect.to:getMaxHp()-x))
		if effect.to:getMaxHp() <= 0 then
		room:killPlayer(effect.to)
		end
end                
}

tuci=sgs.CreateViewAsSkill{ --??EX??技能
name="tuci",
n=0,
view_filter=function(self, selected, to_select)
        return true
end,
view_as = function(self, cards)
		if #cards == 0 then
			local new_card = tucicard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("tuci")
			return new_card
		else return nil
		end
	end,
	enabled_at_play=function(self,player)
        return player:getMark("@tuci") > 0 and player:getMark("@tucimain") > 0
    end,
    enabled_at_response=function(self,player,pattern) 
        return false 
    end,
}

tuciTS=sgs.CreateTriggerSkill
{
	name="tuciTS",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart,sgs.Death},
	view_as_skill = tuci,
	can_trigger = function(self, player)
                return true
        end,
	on_trigger=function(self,event,player,data)
	local room = player:getRoom()
	local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.GameStart then
	if selfplayer:getMark("@tucimain") > 0 then return end
	    selfplayer:gainMark("@tucimain")
	elseif event == sgs.Death then
	if selfplayer:getMark("@tucimain") == 0 then return end
	    room:playSkillEffect("tuciTS",3)
		selfplayer:gainMark("@tuci")
		end
	end,
}

zeta:addSkill("bianxing")
zeta:addSkill(chihun)
zeta:addSkill(tuciTS)

tho = sgs.General(extension, "tho", "god", 4,true,false)

sidao = sgs.CreateTriggerSkill
{
	name = "sidao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashProceed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		if event == sgs.SlashProceed then
		if (room:askForSkillInvoke(player, self:objectName()) ~= true) then return false end
        if room:askForCard(player,"Weapon","@sidao",data) then
		room:playSkillEffect(self:objectName())
			room:slashResult(effect, nil) 
			return true
		end
		end
	end
}

bati = sgs.CreateTriggerSkill
{
	name = "bati",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Predamaged},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Predamaged and damage.card:inherits("Slash") and damage.from:isAlive() and room:askForSkillInvoke(player, self:objectName()) then
        if room:askForCard(damage.to,"Slash","@bati",data) then
		room:playSkillEffect(self:objectName())
		    if damage.to:hasSkill("sidao") and room:askForCard(damage.to,"Weapon","@sidao",data) then
			room:playSkillEffect("sidao")
			local damagee = sgs.DamageStruct()
			damagee.from = damage.to
			damagee.to = damage.from

			room:damage(damagee)
			return true
			elseif room:askForCard(damage.from,"jink","@@bati",data) then return false end
			local damagee = sgs.DamageStruct()
			damagee.from = damage.to
			damagee.to = damage.from

			room:damage(damagee)
			return true
            --damage.damage = 0
			--data:setValue(damage)
		end
		end
	end
}

sidaodistance = sgs.CreateSlashSkill
{
	name = "sidaodistance",
	s_range_func = function(self, from, to, slash)
		if from:hasSkill("sidao") then
			return -4
		end
	end,
}

fuhuo=sgs.CreateTriggerSkill
{--涅槃 by 【群】皇叔
	name = "fuhuo",
	frequency = sgs.Skill_Wake,
	events = {sgs.AskForPeaches},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying=data:toDying()
		    if dying.who:hasSkill("fuhuo") and dying.who:getMark("@fuhuo")==0 then
			room:playSkillEffect(self:objectName())
			player:gainMark("@fuhuo")
			player:gainMark("@dianbo")
			local x = player:getMaxHp()
			if x > 1 then x = 1 end
			local data=sgs.QVariant(x)
			room:setPlayerProperty(player, "hp", data)
			room:setPlayerProperty(player,"maxhp",sgs.QVariant(1))
			player:throwAllCards()
			player:drawCards(3)
			if not player:hasSkill("dianbo") then
		    room:acquireSkill(player,"dianbo")
			end
			return true
			end
	end,
}

fuhuohand = sgs.CreateTriggerSkill{
 name="#fuhuohand",
 events={sgs.PhaseChange},
 frequency = sgs.Skill_Compulsory,
 on_trigger=function(self,event,player,data)
  local room = player:getRoom()
  if (event==sgs.PhaseChange) and (player:getPhase()== sgs.Player_Discard) and player:hasSkill("fuhuo") and (player:getMark("@fuhuo")>0) then
  local x=player:getHp()
   local z = player:getHandcardNum()
   local w = player:getMark("@weilu")
   if z <= (2+x-w) then
   return true
   else
       local e = z-(2+x-w)
      room:askForDiscard(player,"#fuhuohand",e,e,false,false)
	  return true
  end
  end
  end,
  }

dianbocard=sgs.CreateSkillCard{  --??EX卡片
name="dianbo",
target_fixed=true,
will_throw=false,
on_use=function(self, room, source, targets)
		local players = room:getOtherPlayers(source)
		room:playSkillEffect("dianbo")
		for _,aplayer in sgs.qlist(players) do
		    for _,card in sgs.qlist(aplayer:getCards("he")) do
			    room:throwCard(card,aplayer)
			end
		end
		source:loseMark("@dianbo",1)
		source:turnOver()
end                
}

dianbovs=sgs.CreateViewAsSkill{ --??EX??技能
name="dianbo",
n=0,

view_as=function(self, cards)
        local acard=dianbocard:clone()
        acard:setSkillName(self:objectName())
		return acard
end,
enabled_at_play=function(self,player)
        return player:getMark("@dianbo")>0
end,
enabled_at_response=function(self,player,pattern) 
        return false 
end
}

dianbo=sgs.CreateTriggerSkill
{
	name="dianbo",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = dianbovs,
	
	on_trigger=function(self,event,player,data)
		player:gainMark("@dianbo",1)
	end,
}

tho:addSkill(sidao)
tho:addSkill(bati)
tho:addSkill(fuhuo)
tho:addSkill(fuhuohand)

fazz = sgs.General(extension, "fazz", "god", 4, true,false)

jvpao = sgs.CreateTriggerSkill
{
	name = "jvpao",
	events = {sgs.Predamage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamage and (damage.nature == sgs.DamageStruct_Thunder or (damage.card:inherits("Slash") and damage.nature == sgs.DamageStruct_Normal)) then
		local target = player -- 感谢 小胖子唐飞
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    if player:distanceTo(target) < player:distanceTo(p) then
		        target = p
		    end
		end
		if player:distanceTo(target) == player:distanceTo(damage.to) and room:askForSkillInvoke(player,self:objectName(),data) then
		    room:playSkillEffect("jvpao")
			damage.damage = damage.damage+1
			data:setValue(damage)
		end
		end
	end,
}

feidanvs = sgs.CreateViewAsSkill
{
	name = "feidan",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:inherits("Jink")
	end,

	view_as = function(self, cards)
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("archery_attack", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
			end
	end,

	enabled_at_play = function()
		return not (sgs.Self:getMark("feidanused") >= sgs.Self:getLostHp())
	end,
}

feidan=sgs.CreateTriggerSkill
{
	name="feidan",
	frequency = sgs.Skill_NotFrequent,
	events={sgs.CardUsed,sgs.PhaseChange},
	view_as_skill = feidanvs,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	if event == sgs.CardUsed then
        local use=data:toCardUse()
        local card = use.card
	if card:getSkillName() == "feidan" then
	room:setPlayerMark(player, "feidanused", player:getMark("feidanused")+1)
	end
	elseif event == sgs.PhaseChange and player:getPhase()== sgs.Player_Finish then
	    room:setPlayerMark(player, "feidanused", 0)
	end
	end,
}

xiejia = sgs.CreateTriggerSkill
{--突袭 by ibicdlcod
	name = "xiejia",
	events = sgs.HpChanged,
	priority = 10,
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	if player:getHp() <= 1 then
	if player:getMark("@xiejia") > 0 then return end
	player:gainMark("@xiejia")
	room:playSkillEffect("xiejia")
  for _, p in sgs.qlist(room:getPlayers()) do
    p:unicast("animate lightbox:xiejia:2000")
  end
		local recover = sgs.RecoverStruct()   --回复结构体
			recover.recover = 1  --回复点数
			recover.who = player   --回复来源
			room:recover(player,recover)
			room:loseMaxHp(player)
			if player:hasSkill("feidan") then
			room:detachSkillFromPlayer(player,"feidan")
			end
     local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "xiejia")
	 local damage=sgs.DamageStruct()
        damage.damage=1
        damage.nature=sgs.DamageStruct_Thunder
        damage.from=player
        damage.to=target
        room:damage(damage)
		
end
end
}

fazz:addSkill(jvpao)
fazz:addSkill(feidan)
fazz:addSkill(xiejia)

qbly = sgs.General(extension, "qbly", "god", 3,false)

fuyoucard = sgs.CreateSkillCard
{
        name="fuyou",
        target_fixed=true,
        will_throw=true,
		on_use = function(self, room, source, targets)
		 local choice=room:askForChoice(source, self:objectName(), "snatch+dismantlement+collateral+ex_nihilo+duel+fire_attack+amazing_grace+savage_assault+archery_attack+god_salvation+iron_chain")
		 if  choice == "archery_attack" then
            room:setPlayerFlag(source, "archery_attack")
		    source:addMark("qc")
        elseif choice == "snatch" then
		    room:setPlayerFlag(source, "snatch")	
		    source:addMark("qc")
		elseif choice == "dismantlement" then
		    room:setPlayerFlag(source, "dismantlement")
		    source:addMark("qc")
		elseif  choice == "collateral" then 
		   room:setPlayerFlag(source, "collateral")			 
		   source:addMark("qc")
        elseif choice == "ex_nihilo" then
		     room:setPlayerFlag(source, "ex_nihilo")		 
		     source:addMark("qc")
        elseif choice == "duel" then
		    room:setPlayerFlag(source, "duel")
		    source:addMark("qc")
        elseif choice == "fire_attack" then
		   room:setPlayerFlag(source, "fire_attack")
		   source:addMark("qc")
        elseif  choice == "amazing_grace" then 
		   room:setPlayerFlag(source, "amazing_grace")
		   source:addMark("qc")
		elseif  choice == "savage_assault" then 
		   room:setPlayerFlag(source, "savage_assault")
		   source:addMark("qc")
        elseif  choice == "god_salvation" then 
		   room:setPlayerFlag(source, "god_salvation")
		   source:addMark("qc")
		elseif choice == "iron_chain" then
		   room:setPlayerFlag(source, "iron_chain")
		   source:addMark("qc")	
        end			
		end,
}

fuyouvs=sgs.CreateViewAsSkill{
name="fuyou",
n=2,
view_filter=function(self,selected,to_select)
    if #selected ==0 then return not to_select:isEquipped() end
        if #selected == 1 then
                        local cc = selected[1]:getColor()
                        return (not to_select:isEquipped()) and to_select:getColor() == cc
        else return false
    end
end,
view_as=function(self, cards)
 if #cards < 2 then
       return fuyoucard:clone()
   elseif #cards == 2 then
       if sgs.Self:hasFlag("archery_attack") then
       local d_card = sgs.Sanguosha:cloneCard("archery_attack",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("snatch") then
	   local d_card = sgs.Sanguosha:cloneCard("snatch",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("dismantlement") then
	   local d_card = sgs.Sanguosha:cloneCard("dismantlement",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("collateral") then
	   local d_card = sgs.Sanguosha:cloneCard("collateral",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("ex_nihilo") then
	   local d_card = sgs.Sanguosha:cloneCard("ex_nihilo",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("duel") then
	   local d_card = sgs.Sanguosha:cloneCard("duel",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("fire_attack") then
	   local d_card = sgs.Sanguosha:cloneCard("fire_attack",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("amazing_grace") then
	   local d_card = sgs.Sanguosha:cloneCard("amazing_grace",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("savage_assault") then
	   local d_card = sgs.Sanguosha:cloneCard("savage_assault",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	   elseif sgs.Self:hasFlag("god_salvation") then
	   local d_card = sgs.Sanguosha:cloneCard("god_salvation",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
	    elseif sgs.Self:hasFlag("iron_chain") then
	   local d_card = sgs.Sanguosha:cloneCard("iron_chain",  sgs.Card_NoSuit, 0)
	   local i = 0
       while(i < #cards) do
	   i = i + 1
	   local card = cards[i]
       d_card:addSubcard(card:getId())
	   end
       d_card:setSkillName(self:objectName())
       return d_card
       end
end

end,

enabled_at_play=function(self,player)
return player:getPile("fy"):length() > 1 and ((sgs.Sanguosha:getCard(player:getPile("fy"):at(0)):isBlack() and sgs.Sanguosha:getCard(player:getPile("fy"):at(1)):isBlack()) or (sgs.Sanguosha:getCard(player:getPile("fy"):at(0)):isRed() and sgs.Sanguosha:getCard(player:getPile("fy"):at(1)):isRed()) or player:getPile("fy"):length() > 2)
end,

enabled_at_response=function(self,player,pattern)
return pattern == "@@fuyou" and player:getPile("fy"):length() > 1 and ((sgs.Sanguosha:getCard(player:getPile("fy"):at(0)):isBlack() and sgs.Sanguosha:getCard(player:getPile("fy"):at(1)):isBlack()) or (sgs.Sanguosha:getCard(player:getPile("fy"):at(0)):isRed() and sgs.Sanguosha:getCard(player:getPile("fy"):at(1)):isRed()) or player:getPile("fy"):length() > 2)
end,
}

fuyou = sgs.CreateTriggerSkill{
 name="fuyou",
 view_as_skill = fuyouvs,
 events={sgs.GameStart,sgs.Damaged,sgs.CardUsed,sgs.CardFinished,sgs.PhaseChange},
 on_trigger=function(self,event,player,data)
  local room = player:getRoom()
  local cardu=data:toCardUse().card
  local damage = data:toDamage()
		if event == sgs.GameStart then
		    room:playSkillEffect(self:objectName(),1)
			for i=1, 2, 1 do
				local card_id = room:drawCard()
				local cardf = sgs.Sanguosha:getCard(card_id)
                room:moveCardTo(cardf,nil,sgs.Player_Special,true)
                room:getThread():delay()
				player:addToPile("fy", card_id)
			end
		end
		if event == sgs.Damaged and player:getPile("fy"):length() < 6 then
		    room:playSkillEffect(self:objectName(),1)
		    local x = damage.damage
			for i=1, x*2, 1 do
			    local card_id = room:drawCard()
				local cardf = sgs.Sanguosha:getCard(card_id)
				room:moveCardTo(cardf,nil,sgs.Player_Special,true)
				room:getThread():delay()
				player:addToPile("fy", card_id)
			end
		end
  if event == sgs.CardFinished then
  if player:getMark("qc") > 0 then
     local handcards = player:handCards()
     for _,id in sgs.qlist(player:getPile("fy")) do
	    player:obtainCard(sgs.Sanguosha:getCard(id)) 
	 end
	 for _,cd in sgs.qlist(handcards) do
	    player:addToPile("fy",cd,false)
	 end
     if player:hasFlag("archery_attack") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@archery_attack:")
	 elseif player:hasFlag("snatch") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@snatch:")
     elseif player:hasFlag("dismantlement") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@dismantlement:")
     elseif player:hasFlag("collateral") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@collateral:")
     elseif player:hasFlag("ex_nihilo") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@ex_nihilo:")
     elseif player:hasFlag("duel") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@duel:")
     elseif player:hasFlag("fire_attack") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@fire_attack:")
     elseif player:hasFlag("amazing_grace") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@amazing_grace:")
     elseif player:hasFlag("savage_assault") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@savage_assault:")
	elseif player:hasFlag("god_salvation") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@god_salvation:")
	elseif player:hasFlag("iron_chain") then
        qcuse = room:askForUseCard(player, "@@fuyou", "@iron_chain:")
    end
	       room:setPlayerFlag(player, "-archery_attack")
		   room:setPlayerFlag(player, "-snatch")
		   room:setPlayerFlag(player, "-dismantlement")
		   room:setPlayerFlag(player, "-collateral")
		   room:setPlayerFlag(player, "-ex_nihilo")
		   room:setPlayerFlag(player, "-duel")
		   room:setPlayerFlag(player, "-fire_attack")
		   room:setPlayerFlag(player, "-amazing_grace")
		   room:setPlayerFlag(player, "-savage_assault")
		   room:setPlayerFlag(player, "-god_salvation")
		   room:setPlayerFlag(player, "-iron_chain")
		   player:setMark("qc",0)
	       if qcuse then return false
		   elseif not qcuse then
		     local handcardss = player:handCards()
			 for _,ids in sgs.qlist(player:getPile("fy")) do
				player:obtainCard(sgs.Sanguosha:getCard(ids)) 
			 end
			 for _,cds in sgs.qlist(handcardss) do
				player:addToPile("fy",cds,false)
			 end
		   end		   		   
  end
  end
  if event == sgs.CardUsed and player:getMark("qc") > 0 then
     player:setMark("qc",0)
	 local handcardss = player:handCards()
     for _,ids in sgs.qlist(player:getPile("fy")) do
	    player:obtainCard(sgs.Sanguosha:getCard(ids)) 
	 end
	 for _,cds in sgs.qlist(handcardss) do
	    player:addToPile("fy",cds,false)
	 end
  end
  if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish then
      player:setMark("qc",0)
  end
 end,
 }

zihun = sgs.CreateTriggerSkill
{
	name = "zihun",
	events = {sgs.GameStart, sgs.Predamaged},
	frequency = sgs.Skill_Limited,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		if event == sgs.GameStart then
		player:gainMark("@zihun")
		end
		if event == sgs.Predamaged and player:getMark("@zihun") > 0 then
		if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
		  room:playSkillEffect("zihun")
		  player:turnOver()
		  local x = player:getPile("fy"):length()
		  for i=1, 6-x, 1 do
				local card_id = room:drawCard()
				local card=sgs.Sanguosha:getCard(card_id)
                room:moveCardTo(card,nil,sgs.Player_Special,true)
                room:getThread():delay()
				player:addToPile("fy", card_id)
			end
		  player:loseAllMarks("@zihun")
				return true
	end
end,
}

qbly:addSkill(fuyou)
qbly:addSkill(zihun)

nu = sgs.General(extension, "nu", "god", 3, true, false)

jingshenskill={}
jingshen=sgs.CreateTriggerSkill{
	name="jingshen",
	frequency=sgs.Skill_NotFrequent,
	priority = 10,
	events={sgs.Predamaged},
	on_trigger=function(self,event,player,data)
	if event == sgs.Predamaged and player:askForSkillInvoke(self:objectName()) then
	    local room=player:getRoom()
        local damage=data:toDamage()
		local skilllist={}
			for _,skill in sgs.qlist(damage.from:getVisibleSkillList()) do
				local name=skill:objectName()
				if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or skill:isLordSkill() or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake)  then
					table.insert(skilllist,name)
				end
			end
		if #skilllist~=0 then
			if #jingshenskill~=0 then
			room:detachSkillFromPlayer(player,jingshenskill[1])
			table.remove(jingshenskill)
		    end
			local skill=room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
			table.insert(jingshenskill,skill)
			room:acquireSkill(player,skill)
			room:playSkillEffect("jingshen")
		end
		end
	end,
}

nu:addSkill("abao")
nu:addSkill(jingshen)
nu:addSkill("gujia")
nu:addSkill("#nihongL")

sazabi = sgs.General(extension, "sazabi", "god", 3, true, false)

nixi_card = sgs.CreateSkillCard
{
	name = "nixi",	
	target_fixed = false,	
	will_throw = true,

	filter = function(self, targets, to_select, player)
		if(#targets >= self:subcardsLength()) then return false end
		return to_select:isAlive() and to_select:objectName()~=player:objectName()
	end,

	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		local damage=sgs.DamageStruct()
        damage.damage=1
        damage.nature=sgs.DamageStruct_Normal
        damage.chain=false
        damage.from=effect.from
        damage.to=effect.to
		
        room:damage(damage)
	end,
}

nixi_viewas = sgs.CreateViewAsSkill
{
	name = "nixi",	
	n = 998,

	view_filter = function(self, selected, to_select)
        return to_select:isRed() and not to_select:isEquipped()
    end,
	
	view_as = function(self, cards)
	if #cards > 0 then
			local new_card = nixi_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("nixi")
			return new_card
		else return nil
		end	
	end,

	enabled_at_play = function()
		return false
	end,

	enabled_at_response = function(self, player, pattern)
		return pattern == "@@nixi"
	end
}

nixi = sgs.CreateTriggerSkill
{
	name = "nixi",
	view_as_skill = nixi_viewas,
	events = {sgs.Damaged},

	on_trigger = function(self, event, player, data)
	if event == sgs.Damaged then
			local room = player:getRoom()
			local damage = data:toDamage()
			local can_invoke = false
			local other = room:getOtherPlayers(player)
			for _,aplayer in sgs.qlist(other) do
				if (aplayer:isAlive()) then
					can_invoke = true
					break
				end
			end
			if player:isKongcheng() then return false end
			if(not room:askForSkillInvoke(player, "nixi")) then return false end
			if(can_invoke and room:askForUseCard(player, "@@nixi", "#nixi")) then return true end
		return false
		end
	end
}

sazabi:addSkill("xiaya")
sazabi:addSkill("sanbei")
sazabi:addSkill(nixi)

V2AB = sgs.General(extension, "V2AB", "god", 3, true, false)

guangdun=sgs.CreateTriggerSkill{
	name="guangdun",
	frequency=sgs.Skill_NotFrequent,
	events={sgs.GameStart,sgs.PhaseChange,sgs.Predamaged,sgs.Predamaged},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if (event == sgs.GameStart or (event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start)) and player:getMark("@guangdun")==0 and room:askForSkillInvoke(player,self:objectName()) then
		room:playSkillEffect(self:objectName(),1)
		player:gainMark("@guangdun")
		end
		if event == sgs.Predamaged and player:getMark("@guangdun")>0 then
		local x = player:getMark("@guangdun")
		if damage.damage == 1 then
		if not room:askForSkillInvoke(player,self:objectName()) then return false end
		room:playSkillEffect(self:objectName(),2)
		player:loseMark("@guangdun")
		return true
		elseif damage.damage > 1 then
		if damage.damage >= x then
		for var = 1, x, 1 do
		if not room:askForSkillInvoke(player,self:objectName()) then return false end
		room:playSkillEffect(self:objectName(),2)
		player:loseMark("@guangdun")
		player:addMark("guangdunused")
		end
		elseif damage.damage < x then
		for var = 1, damage.damage, 1 do
		if not room:askForSkillInvoke(player,self:objectName()) then return false end
		room:playSkillEffect(self:objectName(),2)
		player:loseMark("@guangdun")
		player:addMark("guangdunused")
		end
		end
		end
		end
		if event == sgs.Predamaged and player:getMark("guangdunused")>0 then 
		damage.damage = damage.damage-player:getMark("guangdunused")
		data:setValue(damage)
		room:setPlayerMark(player,"guangdunused",0)
		end
	end,
}

kuosancardf = sgs.CreateSkillCard
{--技能卡
        name="kuosancardf",
        target_fixed=false,
        will_throw=true,
        filter = function(self, targets, to_select, player)
             local cdid = self:getEffectiveId()
		     local cardx = sgs.Sanguosha:getCard(cdid)
			 local x = sgs.Self:getMark("guangyiadd")
                if #targets >= (2+x+x) then return false end
				if not cardx:inherits("FireAttack") and to_select:objectName() == player:objectName() then return false end
				if cardx:inherits("Duel") and to_select:isProhibited(to_select, sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)) then return false end
                if cardx:isBlack() and to_select:hasSkill("weimu") then return false end
				return true
        end,
		on_use = function(self, room, source, targets)
        local room = source:getRoom()
		local target = targets[1]
		local targett = targets[2]
		local targetr = targets[3]
		local targets = targets[4]
        local cdid = self:getEffectiveId()
		local cardx = sgs.Sanguosha:getCard(cdid)
		
		if cardx:inherits("SavageAssault") then
		    if target~=nil then
		    target:addMark("kuosant")
			end
			if targett~=nil then
		    targett:addMark("kuosant")
			end
			if targetr~=nil then
			targetr:addMark("kuosant")
			end
			if targets~=nil then
		    targets:addMark("kuosant")
			end
		    local sa = sgs.Sanguosha:cloneCard("savage_assault", cardx:getSuit(), cardx:getNumber())
		    sa:setSkillName("kuosanx")
			local use = sgs.CardUseStruct()
			use.from = source
			
			if target~=nil then
			use.to:append(target)
			end
			if targett~=nil then
			use.to:append(targett)
			end
			if targetr~=nil then
			use.to:append(targetr)
			end
			if targets~=nil then
			use.to:append(targets)
			end
			
			use.card = sa
			room:useCard(use, true)
		elseif cardx:inherits("ArcheryAttack") then
		    if target~=nil then
		    target:addMark("kuosant")
			end
			if targett~=nil then
		    targett:addMark("kuosant")
			end
			if targetr~=nil then
			targetr:addMark("kuosant")
			end
			if targets~=nil then
		    targets:addMark("kuosant")
			end
		    local aa = sgs.Sanguosha:cloneCard("archery_attack", cardx:getSuit(), cardx:getNumber())
		    aa:setSkillName("kuosanx")
			local use = sgs.CardUseStruct()
			use.from = source
			
			if target~=nil then
			use.to:append(target)
			end
			if targett~=nil then
			use.to:append(targett)
			end
			if targetr~=nil then
			use.to:append(targetr)
			end
			if targets~=nil then
			use.to:append(targets)
			end
			
			use.card = aa
			room:useCard(use, true)
	    end
		end,
}

kuosanx=sgs.CreateViewAsSkill{
name="kuosanx",
n=1,
view_filter=function(self,selected,to_select)
	return to_select:inherits("SavageAssault") or to_select:inherits("ArcheryAttack")
end,
view_as = function(self, cards)
	if #cards==1 then
		acard=kuosancardf:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName(self:objectName())
		return acard
	end
end,

enabled_at_play = function()
		return true
	end,
enabled_at_response=function(self,player,pattern)
 return false
end,
}

kuosan=sgs.CreateTriggerSkill
{
	name="kuosan",
	events={sgs.CardUsed,sgs.CardEffect,sgs.CardFinished},
	view_as_skill = kuosanx,
	
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		local effect = data:toCardEffect()
	if event == sgs.CardUsed and (use.card:inherits("Slash") or use.card:inherits("Duel") or use.card:inherits("FireAttack") or use.card:getSkillName() == "kuosanx") then
	    room:playSkillEffect(self:objectName())
		end
	if event == sgs.CardEffect and (effect.card:inherits("SavageAssault") or effect.card:inherits("ArcheryAttack")) and effect.to:getMark("kuosant")==0 then
		return true
		end
	if event == sgs.CardFinished and use.card:getSkillName() == "kuosanx" then
	   for _,p in sgs.qlist(use.to) do
        p:removeMark("kuosant")
        end
    end
	end,
}

kuosanmod = sgs.CreateTargetModSkill{
	name = "#kuosanmod",
	pattern = "Slash,Duel,FireAttack",
	extra_target_func = function(self, player)
		if player and player:hasSkill("kuosan") and player:getMark("guangyiadd") == 0 then
			return 1
		elseif player and player:hasSkill("kuosan") and player:getMark("guangyiadd") > 0 then
		    return 3
		end
	end,
}

guangyi_card = sgs.CreateSkillCard
{
	name = "guangyi",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
	    source:loseMark("@guangyi")
	    source:gainMark("@guangdun",2)
		source:addMark("guangdunremove")
		room:setPlayerMark(source,"guangyiadd",1)
	end,
}

guangyi_vs = sgs.CreateViewAsSkill
{
	name = "guangyi",
	n = 0,

	enabled_at_play = function()
		return sgs.Self:getMark("@guangyi") > 0
	end,

	view_as = function(self, cards)
		local card = guangyi_card:clone()
		card:setSkillName(self:objectName())
		return card
	end
}

guangyi=sgs.CreateTriggerSkill
{
	name="guangyi",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart,sgs.TurnStart,sgs.PhaseChange},
	view_as_skill = guangyi_vs,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	if event == sgs.GameStart then
		player:gainMark("@guangyi")
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:getMark("guangyiadd") > 0 then
	    room:setPlayerMark(player,"guangyiadd",0)
	elseif event == sgs.TurnStart and player:getMark("@guangyi") == 0 and player:getMark("guangdunremove") > 0 then
	    player:loseAllMarks("@guangdun")
		player:removeMark("guangdunremove")
	end
	end,
}

V2AB:addSkill(guangdun)
V2AB:addSkill(kuosan)
V2AB:addSkill(guangyi)
V2AB:addSkill(kuosanmod)

GOD = sgs.General(extension, "GOD", "god", 4, true, false)

shenzhang_card=sgs.CreateSkillCard{  --强袭EX卡片
name="shenzhang",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        local room=effect.from:getRoom()
        local damage=sgs.DamageStruct()
		damage.damage=1
        damage.nature=sgs.DamageStruct_Fire 
		damage.from=effect.from
        damage.to=effect.to
		room:setPlayerFlag(effect.from, "shenzhangused")
        room:damage(damage)
end                
}

shenzhang=sgs.CreateViewAsSkill{
name="shenzhang",
n=1,
view_filter=function(self, selected, to_select)
        return to_select:getSuit() == sgs.Card_Heart or to_select:getNumber() == 13
end,
view_as = function(self, cards)
        local card = cards[1]
		if #cards == 1 then
        if card:getSuit() == sgs.Card_Heart and card:getNumber() == 13 then
			local new_card = shenzhang_bigcard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("shenzhang")
			return new_card
		else
		local new_card = shenzhang_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("shenzhang")
			return new_card
			end
		end
	end,
	enabled_at_play = function(self,player)
	return not player:hasFlag("shenzhangused")
	end,
}

shenzhang_bigcard=sgs.CreateSkillCard{  --强袭EX卡片
name="shenzhang_big",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        local room=effect.from:getRoom()
        local damage=sgs.DamageStruct()
		local choice=room:askForChoice(effect.from, "shenzhang", "damage*1+damage*3")
		if choice == "damage*3" then
		damage.damage=3
		else damage.damage=1
		end
        damage.nature=sgs.DamageStruct_Fire 
		damage.from=effect.from
        damage.to=effect.to
		room:setPlayerFlag(effect.from, "shenzhangused")
		room:playSkillEffect("shenzhang")
        room:damage(damage)
end                
}

mingjing = sgs.CreateTriggerSkill
{
	name = "mingjing",
	events = {sgs.HpChanged},
	frequency=sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	local room=player:getRoom()
	if player:getMark("mingjing") > 0 then return end
	if player:getHp() <= 1 then
	player:addMark("mingjing")
	room:playSkillEffect("mingjing")
	for _, r in sgs.qlist(room:getPlayers()) do
        r:unicast("animate lightbox:$mingjinganimation:3000")
    end
	if player:getHp() < 1 then
	    local data=sgs.QVariant(1)
		room:setPlayerProperty(player, "hp", data)
		end
	for _, p in sgs.qlist(room:getOtherPlayers(player)) do
	if player:distanceTo(p)<=1 then
	    room:askForDiscard(p,"mingjing",1,1, false,true)
	end
	end
	if (not player:faceUp()) then
		player:turnOver()
	end
	if player:isChained() then 
		room:setPlayerProperty(player, "chained", sgs.QVariant(false))
	end
	room:transfigure(player, "Hyper_GOD", false, true)
end
end
}

GOD:addSkill(shenzhang)
GOD:addSkill(mingjing)

Hyper_GOD = sgs.General(extension, "Hyper_GOD", "god", 3, true,true,true)

zhishui = sgs.CreateTriggerSkill
{
	name = "zhishui",
	events = {sgs.Predamage},
	frequency = sgs.Skill_Compulsory,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Predamage and (damage.nature==sgs.DamageStruct_Thunder or damage.nature==sgs.DamageStruct_Fire) then
		    room:playSkillEffect("zhishui")
		    room:getThread():delay(1500)
		   damage.damage = damage.damage+1
				data:setValue(damage)
				return false
	end
end,
}

diandan_vs = sgs.CreateViewAsSkill
{
	name = "diandan",
	n = 0,

	enabled_at_play = function()
		return sgs.Self:getMark("@diandan") > 0
	end,

	view_as = function(self, cards)
		local card = diandan_card:clone()
		card:setSkillName(self:objectName())
		return card
	end
}

diandan_card = sgs.CreateSkillCard
{
	name = "diandan",
	target_fixed = false,
	will_throw = false,
	once = true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:getEquips():length() > 0 and to_select:objectName()~=player:objectName()
end,
	on_effect = function(self, effect)
	local room = effect.from:getRoom()
	room:loseMaxHp(effect.from)
	for _,id in sgs.qlist(effect.to:getEquips()) do
            room:throwCard(id)
	end
	effect.from:loseMark("@diandan")
	end,
}

diandan=sgs.CreateTriggerSkill
{
	name="diandan",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = diandan_vs,
	on_trigger=function(self,event,player,data)
		player:gainMark("@diandan")
	end,
}

lua_shipo_vs = sgs.CreateViewAsSkill
{
	name = "lua_shipo",
	n = 2,

	view_filter=function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
	
	enabled_at_play = function()
		return sgs.Self:getMark("@lua_shipo") > 0
	end,

	view_as = function(self, cards)
	if #cards==2 then
			local new_card = lua_shipo_card:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("lua_shipo")
			return new_card
		else return nil
	end
	end,
}

lua_shipo_card = sgs.CreateSkillCard
{
	name = "lua_shipo",
	target_fixed = false,
	will_throw = true,
	once = true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
	on_effect = function(self, effect)
	local room = effect.from:getRoom()
	local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_NoSuit, 0)
        fire_attack:setSkillName("lua_shipo")
        local use = sgs.CardUseStruct()
        use.from = effect.from
                                                          
        use.to:append(effect.to)
                                                         
        use.card = fire_attack
        room:useCard(use,false)
	local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
        dismantlement:setSkillName("lua_shipo")
        local use2 = sgs.CardUseStruct()
        use2.from = effect.from
                                                          
        use2.to:append(effect.to)
                                                         
        use2.card = dismantlement
        room:useCard(use2,false)
	if not effect.to:isProhibited(effect.to, sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)) then
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
        duel:setSkillName("lua_shipo")
        local use3 = sgs.CardUseStruct()
        use3.from = effect.from
                                                          
        use3.to:append(effect.to)
                                                         
        use3.card = duel
        room:useCard(use3,false)
	end
	if not effect.to:isProhibited(effect.to, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
	local fire_slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
        fire_slash:setSkillName("lua_shipo")
        local use4 = sgs.CardUseStruct()
        use4.from = effect.from
                                                          
        use4.to:append(effect.to)
                                                         
        use4.card = fire_slash
        room:useCard(use4,false)
	end
	effect.from:loseMark("@lua_shipo")
	end,
}

lua_shipo=sgs.CreateTriggerSkill
{
	name="lua_shipo",
	frequency = sgs.Skill_Limited,
	events={sgs.GameStart},
	view_as_skill = lua_shipo_vs,
	on_trigger=function(self,event,player,data)
		player:gainMark("@lua_shipo")
	end,
}

Hyper_GOD:addSkill(zhishui)
Hyper_GOD:addSkill(diandan)
Hyper_GOD:addSkill(lua_shipo)

MASTER = sgs.General(extension, "MASTER", "god", 6, true, false)

anzhangbigcard = sgs.CreateSkillCard{
	name = "anzhangbig",
	will_throw = true,
	target_fixed = false,
	filter = function(self, targets, to_select, player)
		return #targets<1 and to_select:objectName()~=player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerMark(effect.from, "anzhangbig_value", 0)
		local damage = effect.from:getTag("anzhangbig_damage"):toDamage()
		damage.to = effect.to
		damage.transfer = true
		room:damage(damage)
	end,
}

anzhangbigvs = sgs.CreateViewAsSkill{
	name = "anzhangbig",
	n = 998,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() and to_select:getNumber() == 13
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getMark("anzhangbig_value") then
		local new_card = anzhangbigcard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@anzhangbig"
	end,
}

anzhangbig = sgs.CreateTriggerSkill{
	name = "anzhangbig",
	frequency = sgs.Skill_NotFrequent,
	priority = 2,
	view_as_skill = anzhangbigvs,
	events = {sgs.Predamaged},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Predamaged and damage.nature ~= sgs.DamageStruct_Normal then
			if not damage.to:hasSkill(self:objectName()) then return false end
			if not damage.to:isAlive() then return false end
			if not room:askForSkillInvoke(damage.to, self:objectName()) then return false end
			damage.to:setTag("anzhangbig_damage", data)
			room:setPlayerMark(damage.to, "anzhangbig_value", damage.damage)
			if room:askForUseCard(damage.to, "@@anzhangbig", "@anzhangbig-card") then
				return true
			else room:setPlayerMark(damage.to,"anzhangbig_value",0)
			end
		end
		return false
	end
}

anzhangcard = sgs.CreateSkillCard
{
	name = "anzhang",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
	    room:setPlayerMark(source, "anzhang_value", 0)
	end,

	enabled_at_play = function()
		return true
	end
}

anzhangvs = sgs.CreateViewAsSkill{
	name = "anzhang",
	n = 998,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack()
	end,
	view_as = function(self, cards)
		if #cards == sgs.Self:getMark("anzhang_value") then
		local new_card = anzhangcard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@anzhang"
	end,
}

anzhang = sgs.CreateTriggerSkill{
	name = "anzhang",
	frequency = sgs.Skill_NotFrequent,
	priority = 3,
	view_as_skill = anzhangvs,
	events = {sgs.Predamaged},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Predamaged and damage.nature ~= sgs.DamageStruct_Normal then
			if not damage.to:hasSkill(self:objectName()) then return false end
			if not damage.to:isAlive() then return false end
			if not room:askForSkillInvoke(damage.to, self:objectName()) then return false end
			damage.to:setTag("anzhang_damage", data)
			room:setPlayerMark(damage.to,"anzhang_value",damage.damage)
			if room:askForUseCard(damage.to, "@@anzhang", "@anzhang-card") then
				return true
			else room:setPlayerMark(damage.to,"anzhang_value",0)
			end
		end
		return false
	end
}

shijiang = sgs.CreateTriggerSkill
{
	name = "shijiang",
	events = {sgs.CardLost},
	frequency = sgs.Skill_Wake,

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toCardMove()
		if player:isKongcheng() and move.from_place == sgs.Player_Hand and player:getMark("@shijiang") == 0 then
		room:playSkillEffect(self:objectName(),1)
		room:getThread():delay(2000)
		player:gainMark("@shijiang")
		player:drawCards(2)
	    local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "shijiang")
	    local damage=sgs.DamageStruct()
        damage.damage=1
        damage.nature=sgs.DamageStruct_Normal
        damage.from=player
        damage.to=target
		room:playSkillEffect(self:objectName(),2)
		room:getThread():delay(1000)
        room:damage(damage)
		end	
	end,
}

MASTER:addSkill(anzhang)
MASTER:addSkill(anzhangbig)
MASTER:addSkill(shijiang)

WZEW = sgs.General(extension, "WING-ZERO-EW", "god", 4, true, false)

feiyi = sgs.CreateSlashSkill
{
	name = "feiyi",
	s_range_func = function(self, from, to, slash)
		if (from:hasSkill("feiyi") and from:getEquips():length() < 2) then
			return -998
		end
	end,
}

shuangpaocard = sgs.CreateSkillCard
{
	name = "shuangpao",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
		room:loseHp(source)
		if(source:isAlive()) then
			room:setPlayerFlag(source,"shuangpaoused")
		end
	end,
}

shuangpaovs = sgs.CreateViewAsSkill
{
	name = "shuangpao",
	n = 0,

	view_as = function(self, cards)
	if #cards == 0 then
		local acard = shuangpaocard:clone()		
		acard:setSkillName("shuangpao")
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasFlag("shuangpaoused")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

shuangpao=sgs.CreateTriggerSkill
{
	name="shuangpao",
	events={sgs.Predamage},
	view_as_skill = shuangpaovs,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local damage = data:toDamage()
		if damage.card:inherits("Slash") and player:hasFlag("shuangpaoused") then
			damage.damage = damage.damage+1
		    data:setValue(damage)
			return false
		end
	end,
}

lingshi = sgs.CreateTriggerSkill
{
	name = "lingshi",
	frequency = sgs.Skill_Limited,
	priority = 4,
	events = {sgs.GameStart,sgs.AskForPeaches,sgs.PhaseChange},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.GameStart then
	    player:gainMark("@lingshi")
    elseif event == sgs.AskForPeaches and player:getMark("@lingshi") > 0 and data:toDying().who:objectName() == player:objectName() and room:askForSkillInvoke(player, self:objectName(), data) then
			player:loseMark("@lingshi")
			room:playSkillEffect("lingshi")
			local x = player:getMaxHp()
			local data = sgs.QVariant(x)
			room:setPlayerProperty(player, "hp", data)
			if not player:faceUp() then
		    player:turnOver()
            end
            for _,id in sgs.qlist(player:getJudgingArea()) do
            room:throwCard(id)
			end
			player:drawCards(2)
			room:setPlayerFlag(player,"-shuangpaoused")
			room:setPlayerFlag(player,"lingshislash")
			player:addMark("wzewdie")
			player:gainAnExtraTurn(player)
			return true
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:getMark("wzewdie") > 0 then
	    room:killPlayer(player)
		end
	end,
}

wzewslash = sgs.CreateSlashSkill
{
	name = "#wzewslash",
	s_extra_func = function(self, from, to, slash)
		if (from:hasSkill("shuangpao") or from:hasSkill("paoji")) and from:hasFlag("shuangpaoused") then
			return 1
		end
	end,
	s_residue_func = function(self, from)
		if (from:hasSkill("lingshi") and from:hasFlag("lingshislash")) or (from:hasSkill("ooqsanhong") and from:getMark("@ooqsanhong") > 0 and from:hasFlag("ooqsanhongused")) then
            local init =  1 - from:getSlashCount()
            return init + 1
        else
            return 0
		end
	end,
}

WZEW:addSkill(feiyi)
WZEW:addSkill(shuangpao)
WZEW:addSkill(lingshi)
WZEW:addSkill(wzewslash)

DSH = sgs.General(extension, "DEATHSCYTHE-HELL-EW", "god", 4, true, false)

yinxing = sgs.CreateTriggerSkill
{
	name = "yinxing",
	events = {sgs.PhaseChange},
	frequency = sgs.Skill_NotFrequent,

	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish then
			if room:askForSkillInvoke(player, self:objectName()) then
			    room:playSkillEffect(self:objectName())
				player:drawCards(1)
				player:turnOver()
			end
		end
	end
}

yinxingp = sgs.CreateProhibitSkill
{
	name = "#yinxingp",
	is_prohibited = function(self, from, to, card)
		if(to and to:hasSkill("yinxing") and not to:faceUp()) then
			return card:inherits("Slash")
		end
	end,
}

anshalist = {}
ansha=sgs.CreateTriggerSkill{
        name="ansha",
        events={sgs.CardLost, sgs.PhaseChange},
        priority=-1,
        
        can_trigger=function()
                  return true
        end,
        
        on_trigger=function(self,event,player,data)
                local room = player:getRoom()
                local selfplayer = room:findPlayerBySkillName(self:objectName())
                if selfplayer == nil then return end
                
                if event == sgs.CardLost then
                        if selfplayer:objectName() == player:objectName() then return end
                        
                        if player:getPhase() == sgs.Player_Discard then
                                local move = data:toCardMove()
                                table.insert(anshalist, move.card_id)
                        end
                else
                        if player:hasSkill(self:objectName()) then return end
                        if player:isDead() then return end

                        local cards = sgs.IntList()
                        for _,id in ipairs(anshalist) do
                                if room:getCardPlace(id) == sgs.Player_DiscardedPile then
                                        cards:append(id)
                                end
                        end
                        table.remove(anshalist)
						
                        if selfplayer:faceUp() then return end
				        if selfplayer:isNude() then return end
                        if cards:isEmpty() then return end

                        if player:getPhase() == sgs.Player_Discard and room:askForSkillInvoke(selfplayer, self:objectName()) then
						room:playSkillEffect(self:objectName())
						room:askForDiscard(selfplayer,"ansha",1,1,false,true)
						if not selfplayer:faceUp() then
						selfplayer:turnOver()
						end
                            room:loseHp(player)
							local x = player:getHp()
							   local z = player:getHandcardNum()
							   local w = player:getMark("@weilu")
							   if z <= (x-w) then return end
								   local e = z-(x-w)
								  room:askForDiscard(player,"ansha",e,e,false,false)
                        end
                end
        end,
}

DSH:addSkill(yinxing)
DSH:addSkill(yinxingp)
DSH:addSkill(ansha)

HAC = sgs.General(extension, "HEAVYARMS-C-EW", "god", 4, true, false)

xiaochou=sgs.CreateTriggerSkill
{
	name="xiaochou",
	events={sgs.GameStart,sgs.TurnedOver,sgs.CardDrawnDone,sgs.CardUsed,sgs.CardGot,sgs.CardGotDone,sgs.CardLost,sgs.CardLostDone,sgs.HpChanged,sgs.PhaseChange},
	frequency = sgs.Skill_Compulsory,
	priority = 2,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.GameStart or event == sgs.TurnedOver or event == sgs.CardDrawnDone or event == sgs.CardUsed or event == sgs.CardGot or event == sgs.CardGotDone or event == sgs.CardLost or event == sgs.CardLostDone or event == sgs.HpChanged then
	    if player:getCards("he"):length() <= player:getHp() then
			if player:hasSkill("sushe") then
			    room:detachSkillFromPlayer(player,"sushe")
			end
			if player:hasSkill("feidan") then
			    room:detachSkillFromPlayer(player,"feidan")
			end
			if not player:hasSkill("zaji") then
			    room:acquireSkill(player,"zaji")
			end
		    if player:faceUp() then
			    room:playSkillEffect(self:objectName())
			    player:turnOver()
			end
		elseif player:getCards("he"):length() > player:getHp() then
		    if player:hasSkill("zaji") then
			    room:detachSkillFromPlayer(player,"zaji")
			end
			if not player:hasSkill("sushe") then
		        room:acquireSkill(player,"sushe")
			end
			if not player:hasSkill("feidan") then
			    room:acquireSkill(player,"feidan")
			end
			if not player:faceUp() then
			    local current = room:getCurrent()
				room:setCurrent(player)
			    player:turnOver()
				local aoe = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
                aoe:setSkillName("xiaochou")
                local use = sgs.CardUseStruct()
                use.from = player
                use.card = aoe
                room:useCard(use,false)
				room:setCurrent(current)
			end
		end
	end
	if event == sgs.PhaseChange and player:getPhase()== sgs.Player_Finish then
	    room:setPlayerMark(player, "feidanused", 0)
	end
	end,
}

saoshe = sgs.CreateSlashSkill
{
	name = "saoshe",
	s_extra_func = function(self, from, to, slash)
		if from:hasSkill("saoshe") and to and to:getHp() > from:getHp() then
			return 1
		end
	end,
}

zaji = sgs.CreateTriggerSkill
{
	name = "zaji",
	events = sgs.Predamaged,
	priority = -1,
	
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
        if room:askForSkillInvoke(player,"zaji") then
		    room:playSkillEffect(self:objectName())
			room:getThread():delay(2500)
		    player:drawCards(1)
	    end
    end
}

HAC:addSkill(xiaochou)
HAC:addSkill(saoshe)

SC = sgs.General(extension, "SANDROCK-C-EW$", "god", 4, true, false)

shuanglian = sgs.CreateTriggerSkill
{
	name = "shuanglian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed,sgs.CardResponsed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardUsed then
	    local use = data:toCardUse()
		if use.card:inherits("Slash") and not player:isKongcheng() then
			if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
            room:askForDiscard(player,"shuanglian",1,1,false,false)
			        local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:inMyAttackRange(p) then
						tos:append(p)
						end
					end
			local target = room:askForPlayerChosen(player, tos, "shuanglian")
			local acard = room:askForCard(target,"jink","@shuanglian",data)
			    if target then
				    if not acard then
						local damage = sgs.DamageStruct()
						damage.damage = 1
						damage.nature = sgs.DamageStruct_Normal
						damage.from = player
						damage.to = target
						room:damage(damage)
					end
				end
			elseif use.card:inherits("Jink") then
			    if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
				local tot = sgs.SPlayerList()
					for _,q in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(q, true) and not q:isProhibited(q, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
						tot:append(q)
						end
					end
			local targett = room:askForPlayerChosen(player, tot, "shuanglian")
		        local slashe = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slashe:setSkillName("shuanglian")
				local usee = sgs.CardUseStruct()
				usee.from = player
				usee.to:append(targett)
				usee.card = slashe
				player:turnOver()
				room:useCard(usee,false)
			end
		elseif event == sgs.CardResponsed then
		    local cd = data:toCard()
			if cd:inherits("Jink") then
			    if (not room:askForSkillInvoke(player, self:objectName(), data)) then return false end
				local tou = sgs.SPlayerList()
					for _,r in sgs.qlist(room:getOtherPlayers(player)) do
					if player:canSlash(r, true) and not r:isProhibited(r, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
						tou:append(r)
						end
					end
			local targetr = room:askForPlayerChosen(player, tou, "shuanglian")
		        local slashr = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slashr:setSkillName("shuanglian")
				local user = sgs.CardUseStruct()
				user.from = player
				user.to:append(targetr)
				user.card = slashr
				player:turnOver()
				room:useCard(user,false)
			end
		end
	end
}

SC:addSkill(shuanglian)

ALTRON = sgs.General(extension, "ALTRON-EW", "god", 4, true, false)

shuanglongcard=sgs.CreateSkillCard{
        name = "shuanglong",
        will_throw = false,
        once = true,
        filter = function(self,targets,to_select,player)
        if (#targets>0) then return false end
		if to_select:isKongcheng() then return false end
        return to_select:objectName() ~= player:objectName()
        end,
        on_effect=function(self,effect)          
                local room = effect.from:getRoom()
                if (effect.from:pindian(effect.to,"shuanglong",self)) then
				    room:setPlayerFlag(effect.from, "shuanglong_success")
                    room:setPlayerFlag(effect.to, "wuqian")
					room:setPlayerFlag(effect.to, "shuanglongt")
                else
				    room:setPlayerFlag(effect.from, "shuanglong_failed")
					effect.from:skip(sgs.Player_Discard)
					if room:askForSkillInvoke(effect.from,"shuanglong") then
					local froms = sgs.SPlayerList()
					for _,r in sgs.qlist(room:getAlivePlayers()) do
					if r:getEquips():length() > 0 then
					    froms:append(r)
						end
					end
					local from = room:askForPlayerChosen(effect.from, froms, "shuanglong")
					if from:hasEquip() then
					local card_id = room:askForCardChosen(effect.from, from, "e", self:objectName())
					local card = sgs.Sanguosha:getCard(card_id)
					local place = room:getCardPlace(card_id)
					local tos = sgs.SPlayerList()
					local list = room:getAlivePlayers()
					for _,p in sgs.qlist(list) do
					if (card:inherits("Weapon") and p:getWeapon() == nil) or (card:inherits("Armor") and p:getArmor() == nil) or (card:inherits("DefensiveHorse") and p:getDefensiveHorse() == nil) or (card:inherits("OffensiveHorse") and p:getOffensiveHorse() == nil) then
						tos:append(p)
						end
					end
					local tag = sgs.QVariant()
					tag:setValue(from)
					room:setTag("shuanglongtarget", tag)
					local to = room:askForPlayerChosen(effect.from, tos, "shuanglong")
					if to then
						room:moveCardTo(card, to, place, true)
					end
					room:removeTag("shuanglongtarget")
					end
				end
			end
        end,
}

shuanglongvs=sgs.CreateViewAsSkill{
        name = "shuanglong",
        n = 1,
        view_filter = function(self, selected, to_select)
                return not to_select:isEquipped()
        end,
        view_as=function(self, cards)
		if #cards == 1 then
                        local acard = shuanglongcard:clone()
                        acard:addSubcard(cards[1])                
                        acard:setSkillName("shuanglong")
                        return acard
						end
        end,
        enabled_at_play = function(self,player)
                return not (player:hasFlag("shuanglong_success") or player:hasFlag("shuanglong_failed"))
        end,
        enabled_at_response = function(self,player,pattern) 
                return false
        end
}

shuanglong=sgs.CreateTriggerSkill
{
	name="shuanglong",
	events={sgs.PhaseChange,sgs.Death},
	view_as_skill = shuanglongvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if (event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish) or (event == sgs.Death) then
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		if p:hasFlag("wuqian") then
		room:setPlayerFlag(p,"-wuqian")
		end
		if p:hasFlag("shuanglongt") then
		room:setPlayerFlag(p,"-shuanglongt")
		end
		end
		end
	end,
}

shuanglongdis = sgs.CreateDistanceSkill{
   name = "#shuanglongdis",
   correct_func = function(self, from, to)
       if from:hasSkill("shuanglong") and from:hasFlag("shuanglong_success") and to and to:hasFlag("shuanglongt") then
       return -998
    end
end,
}

shuanglongslash = sgs.CreateSlashSkill
{
	name = "#shuanglongslash",
	s_residue_func = function(self, from)
		if from:hasSkill("shuanglong") and from:hasFlag("shuanglong_success") then
            local init =  1 - from:getSlashCount()
            return init + 998
        else
            return 0
		end
	end,
}

shuanglongp = sgs.CreateProhibitSkill
{
	name = "#shuanglongp",
	is_prohibited = function(self, from, to, card)
		if from:hasSkill("shuanglong") and from:hasFlag("shuanglong_success") and from:getSlashCount() > 0 and to and not to:hasFlag("shuanglongt") then
		if from:getWeapon() and from:getWeapon():className() == "Crossbow" then return false end
			return card:inherits("Slash")
		end
	end,
}

ALTRON:addSkill(shuanglong)
ALTRON:addSkill(shuanglongdis)
ALTRON:addSkill(shuanglongslash)
ALTRON:addSkill(shuanglongp)

DX = sgs.General(extension, "DX", "god", 4, true, false)

yueguang = sgs.CreateTriggerSkill{
    name = "yueguang",
    frequency = sgs.Skill_Compulsory,
    events = {sgs.PhaseChange},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
	if player:getPhase() == sgs.Player_Start then
	    local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(spade|club):(.*)")
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
	if judge:isGood() then
        if player:getMark("@yue") < 2 then
	        player:gainMark("@yue")
		end
	elseif judge:isBad() then
	    if player:getMark("@yue") > 0 then
	        player:loseMark("@yue")
		end
	end
	end
	end,
}

weibocard = sgs.CreateSkillCard
{
	name = "weibo",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
        source:loseMark("@yue")
		source:addMark("yueadd")
	end,
}

weibovs=sgs.CreateViewAsSkill{
        name = "weibo",
        n = 0,
        view_as=function(self, cards)
		if #cards == 0 then
            local acard = weibocard:clone()               
            acard:setSkillName(self:objectName())
            return acard
			end
        end,
        enabled_at_play = function(self,player)
                return player:getMark("@yue") > 0
        end,
}

weibo=sgs.CreateTriggerSkill
{
	name="weibo",
	events={sgs.Predamage,sgs.CardFinished,sgs.PhaseChange},
	view_as_skill = weibovs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local use = data:toCardUse()
	if event == sgs.Predamage and player:getMark("yueadd") > 0 and damage.card:inherits("Slash") then
        damage.damage = damage.damage+(player:getMark("yueadd"))
		data:setValue(damage)
		room:setPlayerMark(player,"yueadd",0)
		return false
	elseif event == sgs.CardFinished and use.card:inherits("Slash") and player:getMark("yueadd") > 0 then
	    room:setPlayerMark(player,"yueadd",0)
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and player:getMark("yueadd") > 0 then
	    room:setPlayerMark(player,"yueadd",0)
	end
	end,
}

weixingcard = sgs.CreateSkillCard
{
	name = "weixing",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
        source:loseMark("@weixing")
		source:turnOver()
		room:setPlayerMark(source,"@yue",2)
		source:addMark("weiadd")
	end,
}

weixingvs=sgs.CreateViewAsSkill{
        name = "weixing",
        n = 0,
        view_as=function(self, cards)
		if #cards == 0 then
            local acard = weixingcard:clone()               
            acard:setSkillName(self:objectName())
            return acard
			end
        end,
        enabled_at_play = function(self,player)
                return player:getMark("@weixing") > 0
        end,
}

weixing=sgs.CreateTriggerSkill
{
	name="weixing",
	events={sgs.GameStart,sgs.Predamage},
	frequency = sgs.Skill_Limited,
	view_as_skill = weixingvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.GameStart and player:getMark("@weixing") == 0 then
	    player:gainMark("@weixing")
	elseif event == sgs.Predamage and player:getMark("weiadd") > 0 then
        damage.damage = damage.damage+1
		data:setValue(damage)
		room:setPlayerMark(player,"weiadd",0)
		return false
	end
	end,
}

DX:addSkill(yueguang)
DX:addSkill(weibo)
DX:addSkill(weixing)

VIRSAGOCB = sgs.General(extension, "VIRSAGO-CB", "god", 4, true, false)

emo = sgs.CreateTriggerSkill
{
	name = "emo",
	events = {sgs.CardUsed,sgs.CardResponsed,sgs.SlashEffect},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local cd = data:toCard()
		local effect = data:toSlashEffect()
	if event == sgs.CardUsed and use.card:inherits("Slash") and not use.card:isVirtualCard() then
	    if use.card:getSkillName() == "liekong" then return false end
		    player:obtainCard(use.card)
		    if player:hasSkill("liekong") then
			    room:loseHp(player)
			else
			    return true
			end
	elseif event == sgs.CardResponsed and cd:inherits("Slash") and not cd:isVirtualCard() then
	    if cd:getSkillName() == "liekong" then return false end
	        player:obtainCard(cd)
		    if player:hasSkill("liekong") then
			    room:loseHp(player)
			else
			    return true
			end
	end
	if event == sgs.CardUsed and use.card:inherits("Jink") and not use.card:isVirtualCard() then
	    if use.card:getSkillName() == "liekong" then return false end
		    player:obtainCard(use.card)
		    if player:hasSkill("liekong") then
			    room:loseHp(player)
			else
			    return true
			end
	elseif event == sgs.CardResponsed and cd:inherits("Jink") and not cd:isVirtualCard() then
	    if cd:getSkillName() == "liekong" then return false end
	        player:obtainCard(cd)
		    if player:hasSkill("liekong") then
			    room:loseHp(player)
			else
			    return true
			end
	elseif event == sgs.SlashEffect and effect.nature ~= sgs.DamageStruct_Normal then
	    effect.nature = sgs.DamageStruct_Normal
		data:setValue(effect)
	end
	end,
}

lktmp={}
liekongvs = sgs.CreateViewAsSkill
{
	name = "liekongvs",
	n = 0,

	view_as = function(self, cards)
		if #cards == 0 then
			local ld_card = sgs.Sanguosha:cloneCard(lktmp[1], sgs.Card_NoSuit, 0)
			ld_card:setSkillName(self:objectName())
			return ld_card
		end
	end,

	enabled_at_play = function(self,player) 
		lktmp[1] = "slash"
		return sgs.Slash_IsAvailable(player)
	end,

	enabled_at_response = function(self, player, pattern)
		if(pattern == "jink") then 
			lktmp[1] = pattern
			return true 
		end
	end,
}

liekong = sgs.CreateTriggerSkill
{
	name = "liekong",
	events = {sgs.CardUsed,sgs.CardResponsed,sgs.CardAsked,sgs.PhaseEnd},
	view_as_skill = liekongvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local cd = data:toCard()
		local card = data:toString()
	if event == sgs.CardUsed and use.card:getSkillName() == "liekongvs" then
	    room:loseHp(player)
	end
	if event == sgs.CardResponsed and cd:getSkillName() == "liekongvs" then
	    room:loseHp(player)
	end
	if event == sgs.CardAsked and card == "slash" and room:askForSkillInvoke(player,"liekong") then
	    room:loseHp(player)
		if player:isAlive() then
		    local slash_card = sgs.Sanguosha:cloneCard ("slash",sgs.Card_NoSuit,0)
		    slash_card:setSkillName(self:objectName())
		    room:provide(slash_card)
			return true
		end
	end
	if event == sgs.CardAsked and card == "jink" and room:askForSkillInvoke(player,"liekong") then
	    room:loseHp(player)
		if player:isAlive() then
		    local jink_card = sgs.Sanguosha:cloneCard ("jink",sgs.Card_NoSuit,0)
		    jink_card:setSkillName(self:objectName())
		    room:provide(jink_card)
			return true
		end
	end
	if event == sgs.PhaseEnd and player:getPhase() == sgs.Player_Play and not player:isKongcheng() and room:askForSkillInvoke(player,"liekong") then
	    local handcards = player:handCards()
		room:fillAG(handcards)
		room:getThread():delay(1000)
		for _,h in sgs.qlist(handcards) do
			if sgs.Sanguosha:getCard(h):inherits("Slash") or sgs.Sanguosha:getCard(h):inherits("Jink") then
				room:throwCard(h)
				if player:getMark("lkr") < player:getLostHp() then
				    local choice = room:askForChoice(player, self:objectName(), "recover+lkdraw")
				    if choice == "recover" then
					    player:addMark("lkr")
					elseif choice == "lkdraw" then
					    player:addMark("lkd")
					end
				else
				    player:addMark("lkd")
				end
			end
		end
		if player:getMark("lkr") > 0 then
			local recover = sgs.RecoverStruct()
			recover.recover = player:getMark("lkr")
			recover.who = player
			room:recover(player,recover)
			room:setPlayerMark(player,"lkr",0)
		end
		if player:getMark("lkd") > 0 then
			player:drawCards(player:getMark("lkd"))
			room:setPlayerMark(player,"lkd",0)
		end
		for _,p in sgs.qlist(room:getPlayers()) do
		    p:invoke("clearAG")
		end
	end
	end,
}

VIRSAGOCB:addSkill(emo)
VIRSAGOCB:addSkill(liekong)

CROSSBONEX1 = sgs.General(extension, "CROSSBONE-X1", "god", 3, true, false)

haidaocard = sgs.CreateSkillCard
{
	name = "haidao",
	target_fixed = true,
	will_throw = true,

	on_use = function(self, room, source, targets)
	    source:speak("WCH超级连技！")
		local x = source:getLostHp()
		for _,c in sgs.qlist(self:getSubcards()) do
		    if sgs.Sanguosha:getCard(c):inherits("Weapon") then
			room:setPlayerMark(source,"cantdraw",1)
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:distanceTo(p) <= x+1 then
			room:setPlayerFlag(p,"hd")
				if not p:isChained() then 
					room:setPlayerProperty(p, "chained", sgs.QVariant(true))
		        end
			end
	    end
		for _,q in sgs.qlist(room:getOtherPlayers(source)) do
			if q:hasFlag("hd") then
				local tslash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
				tslash:setSkillName("haidaot")
				local use = sgs.CardUseStruct()
				use.from = source
				use.to:append(q)
				use.card = tslash
				room:useCard(use,false)
			end
			room:setPlayerFlag(q,"-hd")
	    end
		    elseif sgs.Sanguosha:getCard(c):inherits("Armor") then
			room:setPlayerMark(source,"cantdraw",1)
			    for _,r in sgs.qlist(room:getAlivePlayers()) do
					if source:distanceTo(r) <= x+1 then
					    room:setPlayerFlag(r,"hd2")
					end
				end
				local choice = room:askForChoice(source, self:objectName(), "ganraohp+recover")
				if choice == "ganraohp" then
					for _,s in sgs.qlist(room:getAlivePlayers()) do
						if s:hasFlag("hd2") then
							room:loseHp(s)
							room:setPlayerFlag(s,"-hd2")
						end
					end
				else
				    for _,t in sgs.qlist(room:getAlivePlayers()) do
						if t:hasFlag("hd2") then
							local recover = sgs.RecoverStruct()
							recover.recover = 1
							recover.who = t
							room:recover(t,recover)
							room:setPlayerFlag(t,"-hd2")
						end
					end
				end
			elseif sgs.Sanguosha:getCard(c):inherits("DefensiveHorse") or sgs.Sanguosha:getCard(c):inherits("OffensiveHorse") then
			room:setPlayerMark(source,"cantdraw",1)
			    for _,u in sgs.qlist(room:getOtherPlayers(source)) do
					if source:distanceTo(u) <= x+1 and not u:isNude() then
						room:moveCardTo(sgs.Sanguosha:getCard(room:askForCardChosen(source, u, "he", self:objectName())), source, sgs.Player_Hand, false)
					end
				end
		    end
		end
	end,
}

haidaovs=sgs.CreateViewAsSkill{
        name = "haidao",
        n = 2,
		view_filter=function(self, selected, to_select)
        if #selected ==0 then return to_select end
        if #selected == 1 then
            if selected[1]:inherits("Weapon") then
			    return to_select:inherits("IronChain")
			elseif selected[1]:inherits("Armor") then
			    return to_select:inherits("Slash")
		    elseif selected[1]:inherits("DefensiveHorse") or selected[1]:inherits("OffensiveHorse") then
			    return to_select:inherits("Jink")
			elseif selected[1]:inherits("IronChain") then
			    return to_select:inherits("Weapon") or to_select:inherits("BasicCard")
			elseif selected[1]:inherits("Slash") then
			    return to_select:inherits("Armor") or to_select:inherits("TrickCard")
			elseif selected[1]:inherits("Jink") then
			    return to_select:inherits("DefensiveHorse") or to_select:inherits("OffensiveHorse") or to_select:inherits("TrickCard")
			elseif selected[1]:inherits("BasicCard") and not selected[1]:inherits("Slash") and not selected[1]:inherits("Jink") then
                return to_select:inherits("TrickCard")
			elseif selected[1]:inherits("TrickCard") then
			    return to_select:inherits("BasicCard")
			else return false
			end
        else return false
        end
        end,
        view_as = function(self, cards)
		if #cards == 2 then
			local new_card = haidaocard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName(self:objectName())
			return new_card
		else return nil
		end
	    end,
        enabled_at_play = function(self,player)
                return true
        end,
		enabled_at_response = function(self, player, pattern)
                return false
        end,
}

haidao=sgs.CreateTriggerSkill
{
	name="haidao",
	events={sgs.CardFinished},
	view_as_skill = haidaovs,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	if event == sgs.CardFinished and data:toCardUse().card:getSkillName() == "haidao" then
	    if player:getMark("cantdraw") == 0 then
		    player:drawCards(player:getLostHp()+1)
		else
		    room:setPlayerMark(player,"cantdraw",0)
		end
	end
	end,
}

pifeng=sgs.CreateTriggerSkill
{
	name="pifeng",
	events={sgs.Predamaged},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamaged and player:getMark("pf") == 0 and not player:getArmor() and (damage.nature == sgs.DamageStruct_Fire or damage.nature == sgs.DamageStruct_Thunder) then
	    for i=1, damage.damage, 1 do
		    player:addMark("pifeng")
		end
		if player:getMark("pifeng") > 3 then
		    room:setPlayerMark(player,"pifeng",0)
			room:detachSkillFromPlayer(player,"pifeng")
			player:addMark("pf")
		end
		local log=sgs.LogMessage()
        log.from = player
		log.arg = self:objectName()
		log.arg2 = damage.damage
        log.type ="#pifeng"
        room:sendLog(log)
		return true
	end
	end,
}

CROSSBONEX1:addSkill(haidao)
CROSSBONEX1:addSkill(pifeng)

CROSSBONEX2 = sgs.General(extension, "CROSSBONE-X2", "god", 3, true, false)

heiying = sgs.CreateTriggerSkill
{
	    name = "heiying",
	    events = {sgs.Predamage,sgs.Damaged},
		priority = 1,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamage and damage.card:isBlack() and
	damage.from:objectName() ~= damage.to:objectName() and
	room:askForSkillInvoke(player,self:objectName(),data) then
	    damage.to:turnOver()
		return true
	elseif event == sgs.Damaged and room:askForSkillInvoke(player,self:objectName(),data) then
	    local x = player:getLostHp()
		local cd = room:getNCards(x+2)
		for i=1,x+2,1 do
			for _,c in sgs.qlist(cd) do
				if sgs.Sanguosha:getCard(c):isRed() then
					room:throwCard(c)
					cd:removeOne(c)
				end
			end
		end
		while cd:length() > 0 do
		    room:fillAG(cd)
		    local ob = room:askForAG(player, cd, true, self:objectName())
			local target = room:askForPlayerChosen(player, room:getAlivePlayers(), self:objectName())
			room:obtainCard(target,ob)
			cd:removeOne(ob)
			for _,p in sgs.qlist(room:getPlayers()) do
			    p:invoke("clearAG")
			end
		end
	end
    end,
}

CROSSBONEX2:addSkill(heiying)
CROSSBONEX2:addSkill("pifeng")

X1FC = sgs.General(extension, "X1FC", "god", 3, true, false)

kuangdaocard = sgs.CreateSkillCard
{
        name="kuangdao",
        target_fixed = false,
        will_throw = true,
        filter = function(self, targets, to_select, player)
			if (sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and (sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Halberd") and sgs.Self:getHandcardNum() == self:subcardsLength() then
			    return sgs.Self:canSlash(to_select, true) and #targets < 4
			elseif (sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and ((not sgs.Self:getWeapon()) or ((sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Halberd") and sgs.Self:getHandcardNum() ~= self:subcardsLength()) or (sgs.Self:getWeapon() and sgs.Self:getWeapon():className() ~= "Halberd")) then
			    return sgs.Self:canSlash(to_select, true) and #targets < 2
			elseif (not sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and (sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Halberd") and sgs.Self:getHandcardNum() == self:subcardsLength() then
			    return sgs.Self:canSlash(to_select, true) and #targets < 3
			end
		    return sgs.Self:canSlash(to_select, true) and #targets < 1
        end,
		on_use = function(self, room, source, targets)
		    room:setPlayerFlag(source,"kuangdaoused")
			local suit
			local number
			for _,cd in sgs.qlist(self:getSubcards()) do
			suit = sgs.Sanguosha:getCard(cd):getSuit()
			number = sgs.Sanguosha:getCard(cd):getNumber()
				if sgs.Sanguosha:getCard(cd):inherits("BasicCard") and not source:hasFlag("kdb") then
				    room:setPlayerFlag(source,"kdb")
					source:drawCards(1)
				end
			if sgs.Sanguosha:getCard(cd):isNDTrick() and not source:hasFlag("kdn") then
			    room:setPlayerFlag(source,"kdn")
			    if targets[1] then
				    targets[1]:addMark("qinggang")
				end
				if targets[2] then
				    targets[2]:addMark("qinggang")
				end
				if targets[3] then
				    targets[3]:addMark("qinggang")
				end
				if targets[4] then
				    targets[4]:addMark("qinggang")
				end
			end
			if sgs.Sanguosha:getCard(cd):inherits("EquipCard") and not source:hasFlag("kde") then
			    room:setPlayerFlag(source,"kde")
			    if targets[1] and not targets[1]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[1] ,"h",self:objectName()))
				end
				if targets[2] and not targets[2]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[2] ,"h",self:objectName()))
				end
				if targets[3] and not targets[3]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[3] ,"h",self:objectName()))
				end
				if targets[4] and not targets[4]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[4] ,"h",self:objectName()))
				end
			end
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if self:subcardsLength() == 1 then
			    slash = sgs.Sanguosha:cloneCard("slash", suit, number)
			end
			slash:setSkillName(self:objectName())
			for _,cd in sgs.qlist(self:getSubcards()) do
                slash:addSubcard(cd)
            end
			local use = sgs.CardUseStruct()
			use.from = source
			
			if targets[1] then
			    use.to:append(targets[1])
			end
			if targets[2] then
		    	use.to:append(targets[2])
			end
			if targets[3] then
		    	use.to:append(targets[3])
			end
			if targets[4] then
			    use.to:append(targets[4])
			end
			
			use.card = slash
			room:useCard(use,true)
			
			if targets[1] then
                targets[1]:removeMark("qinggang")
			end
			if targets[2] then
			    targets[2]:removeMark("qinggang")
			end
			if targets[3] then
				targets[3]:removeMark("qinggang")
			end
			if targets[4] then
			    targets[4]:removeMark("qinggang")
			end
		end,
}

kuangdao = sgs.CreateViewAsSkill
{
	name = "kuangdao",
	n = 4,

	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,

	view_as = function(self, cards)
		if #cards > 0 then
			local new_card = kuangdaocard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName(self:objectName())
			return new_card
		else return nil
		end
	end,

	enabled_at_play = function(self,player)
		return not player:hasFlag("kuangdaoused") and sgs.Slash_IsAvailable(player)
	end,
}

pijia=sgs.CreateTriggerSkill
{
	name="pijia",
	events={sgs.Predamaged},
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamaged and player:getMark("pj") == 0 and not player:getArmor() and damage.card:isBlack() then
	    for i=1, damage.damage, 1 do
		    player:addMark("pijia")
		end
		if player:getMark("pijia") > 3 then
		    room:setPlayerMark(player,"pijia",0)
			room:detachSkillFromPlayer(player,"pijia")
			player:addMark("pj")
		end
		local log = sgs.LogMessage()
        log.from = player
		log.arg = self:objectName()
		log.arg2 = damage.damage
		log.arg3 = damage.nature
        log.type = "#pijia"
        room:sendLog(log)
		return true
	end
	end,
}

X1FC:addSkill(kuangdao)
X1FC:addSkill(pijia)

GINN = sgs.General(extension, "GINN", "ZAFT", 5, true, false)

laobing = sgs.CreateTriggerSkill
{
	name = "laobing",
	events = {sgs.StartJudge,sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local judge = data:toJudge()
	if event == sgs.StartJudge and room:askForSkillInvoke(player,self:objectName(),data) then
	    local suit = room:askForSuit(player,self:objectName())
		
		local log = sgs.LogMessage()
		log.type = "#ChooseSuit"
		log.from = player
		log.arg = sgs.Card_Suit2String(suit)
		room:sendLog(log)
		
		if suit == sgs.Card_Spade then
		    room:setPlayerMark(player,"spade",1)
		elseif suit == sgs.Card_Heart then
		    room:setPlayerMark(player,"heart",1)
		elseif suit == sgs.Card_Club then
		    room:setPlayerMark(player,"club",1)
		elseif suit == sgs.Card_Diamond then
		    room:setPlayerMark(player,"diamond",1)
		end
	end
	if event == sgs.FinishJudge and
	(player:getMark("spade") == 1 or player:getMark("heart") == 1 or player:getMark("club") == 1 or player:getMark("diamond") == 1) then
		if judge.card:getSuit() == sgs.Card_Spade then
		    player:addMark("spade")
		elseif judge.card:getSuit() == sgs.Card_Heart then
		    player:addMark("heart")
		elseif judge.card:getSuit() == sgs.Card_Club then
		    player:addMark("club")
		elseif judge.card:getSuit() == sgs.Card_Diamond then
		    player:addMark("diamond")
		end
		if (player:getMark("spade") == 2 or player:getMark("heart") == 2 or player:getMark("club") == 2 or player:getMark("diamond") == 2) then
			room:setPlayerMark(player,"spade",0)
		    room:setPlayerMark(player,"heart",0)
		    room:setPlayerMark(player,"club",0)
		    room:setPlayerMark(player,"diamond",0)
			if player:isWounded() then
			    local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
				room:recover(player,recover)
			end
            room:throwCard(judge.card)
			local ju = sgs.JudgeStruct()
			ju.reason = judge.reason
			ju.who = player
			room:judge(ju)
            judge.card = sgs.Sanguosha:getCard(ju.card:getEffectiveId())
			room:moveCardTo(judge.card, nil, sgs.Player_Special)
			room:sendJudgeResult(judge)
			player:obtainCard(judge.card)
			return true
		elseif not(player:getMark("spade") == 2 and player:getMark("heart") == 2 and player:getMark("club") == 2 and player:getMark("diamond") == 2) then
			room:setPlayerMark(player,"spade",0)
		    room:setPlayerMark(player,"heart",0)
		    room:setPlayerMark(player,"club",0)
		    room:setPlayerMark(player,"diamond",0)
			player:obtainCard(judge.card)
			return true
		end
		return false
	end
	end,        
}

baopo = sgs.CreateTriggerSkill
{
	name = "baopo",
	events = {sgs.Damage},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:inherits("Slash") and damage.to:getEquips():length() > 0 and not player:isNude() and
	damage.to:objectName() ~= player:objectName() and not damage.chain and not damage.transfer and
	room:askForSkillInvoke(player,self:objectName(),data) then
	    if room:askForDiscard(player,self:objectName(),1,1,false,true) then
	        room:throwCard(room:askForCardChosen(player, damage.to ,"e",self:objectName()),damage.to,player)
		end
	end
    end,
}

GINN:addSkill(laobing)
GINN:addSkill(baopo)

BUCUE = sgs.General(extension, "BUCUE", "ZAFT", 5, true, false)

dizhan = sgs.CreateTriggerSkill
{
	name = "dizhan",
	events = {sgs.GameStart},
	frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    room:setPlayerMark(p,"dzdistance",p:distanceTo(player))
		end
    end,
}

dizhand = sgs.CreateDistanceSkill{

    name = "#dizhand",
    correct_func = function(self, from, to)
    if from and from:getMark("dzdistance") > 0 and to and to:hasSkill("dizhan") and to:getHp() > to:getHandcardNum() then
	    if from:getOffensiveHorse() and to:getDefensiveHorse() then
		    return (2-from:getMark("dzdistance"))
		elseif from:getOffensiveHorse() == nil and to:getDefensiveHorse() then
		    return (1-from:getMark("dzdistance"))
		elseif from:getOffensiveHorse() and to:getDefensiveHorse() == nil then
		    return (3-from:getMark("dzdistance"))
		elseif from:getOffensiveHorse() == nil and to:getDefensiveHorse() == nil then
		    return (2-from:getMark("dzdistance"))
	    end
	end
    end,
}

qunshou = sgs.CreateTriggerSkill
{
	name = "qunshou",
	events = {sgs.CardEffected},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local effect = data:toCardEffect()
	if effect.card:inherits("Snatch") and room:askForSkillInvoke(player,self:objectName(),data) then
	    local cd = sgs.Sanguosha:cloneCard("dismantlement", effect.card:getSuit(), effect.card:getNumber())
        cd:setSkillName(effect.card:getSkillName())
        local use = sgs.CardUseStruct()
        use.from = effect.from
                                                          
        use.to:append(effect.to)
                                                         
        use.card = cd
        room:useCard(use,true)
		return true
	end
    end,
}

BUCUE:addSkill(dizhan)
BUCUE:addSkill(dizhand)
BUCUE:addSkill(qunshou)

ZNO = sgs.General(extension, "ZNO", "ZAFT", 5, true, false)

shuizhan = sgs.CreateTriggerSkill
{
	name = "shuizhan",
	events = {sgs.Predamage,sgs.TurnedOver},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Predamage then
	    damage.from = nil
		data:setValue(damage)
	elseif event == sgs.TurnedOver and player:faceUp() then
	    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_Heart, 0)
	    slash:setSkillName(self:objectName())
		local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    if not p:isProhibited(p, slash) then
			    tos:append(p)
			end
		end
		local target = room:askForPlayerChosen(player,tos,self:objectName())
		local use = sgs.CardUseStruct()
		use.from = player
		
		use.to:append(target)
		
		use.card = slash
		player:speak("冒泡了")
		room:useCard(use,false)
	end
    end,
}

qianfu = sgs.CreateTriggerSkill
{
	name = "qianfu",
	events = {sgs.PhaseChange,sgs.Predamaged},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Discard and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:setPlayerMark(player,"qianfu",1)
		player:speak("潜水了")
		player:drawCards(1)
		player:turnOver()
		player:skip(sgs.Player_Discard)
		return true
	elseif event == sgs.Predamaged and player:getMark(self:objectName()) == 1 and damage.nature == sgs.DamageStruct_Thunder then
	    damage.damage = damage.damage+1
		data:setValue(damage)
		return false
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start and player:getMark(self:objectName()) == 1 then
		room:setPlayerMark(player,"qianfu",0)
	end
    end,
}

ZNO:addSkill(shuizhan)
ZNO:addSkill(qianfu)

STRIKE = sgs.General(extension, "STRIKE", "OMNI", 4, true, false)

huanzhuang = sgs.CreateTriggerSkill
{
	name = "huanzhuang",
	events = {sgs.PhaseChange,sgs.CardUsed,sgs.SlashMissed,sgs.Predamage},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local effect = data:toSlashEffect()
		local damage = data:toDamage()
	if event == sgs.PhaseChange then
	    if player:getPhase() == sgs.Player_Start then
	        if room:askForSkillInvoke(player,self:objectName(),data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = sgs.QRegExp("(.*):(spade|heart|club|diamond):(.*)")
				judge.good = true
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if judge.card:isBlack() then
				    room:setPlayerMark(player,"huanzhuangb",1)
				elseif judge.card:isRed() then
				    room:setPlayerMark(player,"huanzhuangr",1)
				end
		    else
		        room:setPlayerMark(player,"huanzhuangn",1)
		    end
		elseif player:getPhase() == sgs.Player_Finish then
		    if player:getMark("huanzhuangn") > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
			    player:drawCards(1)
			end
			room:setPlayerMark(player,"huanzhuangb",0)
		    room:setPlayerMark(player,"huanzhuangbi",0)
			room:setPlayerMark(player,"huanzhuangr",0)
			room:setPlayerMark(player,"huanzhuangn",0)
		end
	elseif event == sgs.CardUsed and use.card:inherits("Slash") and player:getMark("huanzhuangb") > 0 and player:getMark("huanzhuangbi") == 0 and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:setPlayerMark(player,"huanzhuangbi",1)
	elseif event == sgs.SlashMissed and player:getMark("huanzhuangbi") > 0 then
	    room:throwCard(room:askForCardChosen(effect.to, effect.from ,"h",self:objectName()),player,effect.to)
	elseif event == sgs.Predamage and damage.card:inherits("Slash") and player:getMark("huanzhuangbi") > 0 then
	    damage.damage = damage.damage+1
		data:setValue(damage)
	end
    end,
}

huanzhuangd = sgs.CreateDistanceSkill
{
	name = "#huanzhuangd",
	correct_func = function(self, from, to)
		if from:hasSkill("huanzhuang") and from:getMark("huanzhuangr") > 0 then
			return -1
		end
	end,
}

xiangzhuan = sgs.CreateTriggerSkill
{
	name = "xiangzhuan",
	events = {sgs.Predamaged},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:inherits("Slash") and damage.card:isBlack() and not player:isKongcheng() and room:askForSkillInvoke(player,self:objectName(),data) then
	    if room:askForDiscard(player,self:objectName(),1,1,false,false) then
	        return true
		end
	end
    end,
}

STRIKE:addSkill(huanzhuang)
STRIKE:addSkill(huanzhuangd)
STRIKE:addSkill(xiangzhuan)

AEGIS = sgs.General(extension, "AEGIS", "ZAFT", 4, true, false)

jiechicard = sgs.CreateSkillCard
{
	name = "jiechi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		if to_select:objectName() == player:objectName() then return false end
		return to_select:getEquips():length() > 0
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:throwCard(room:askForCardChosen(effect.from, effect.to ,"e",self:objectName()),effect.to,effect.from)
	end
}

jiechi = sgs.CreateViewAsSkill
{
	name = "jiechi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	if #cards == 1 then
		local acard = jiechicard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName(self:objectName())
		return acard
	end
	end,
}

juexincard = sgs.CreateSkillCard
{
	name = "juexin",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		if #targets > 0 then return false end
		return to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setEmotion(effect.from,"juexin")
		effect.from:loseMark("@juexin")
		for _,cd in sgs.qlist(effect.from:handCards()) do
		    room:throwCard(cd,effect.from)
		end
		room:setPlayerMark(effect.to,"2887",1)
	end
}

juexinvs = sgs.CreateViewAsSkill
{
	name = "juexin",
	n = 0,
	view_as = function(self, cards)
		local acard = juexincard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@juexin") > 0
	end,
}

juexin = sgs.CreateTriggerSkill
{
	name = "juexin",
	events = {sgs.GameStart,sgs.TurnStart},
	frequency = sgs.Skill_Limited,
	view_as_skill = juexinvs,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.GameStart and selfplayer:getMark("@juexin") == 0 then
	    selfplayer:gainMark("@juexin")
	end
	if event == sgs.TurnStart and player:getMark("2887") > 0 then
	    room:setPlayerMark(player,"2887",0)
	    local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(spade):(.*)")
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
		    room:loseHp(player,2)
			room:killPlayer(selfplayer)
		end
	end
	end,
}

AEGIS:addSkill(jiechi)
AEGIS:addSkill(juexin)
AEGIS:addSkill("xiangzhuan")

BUSTER = sgs.General(extension, "BUSTER", "ZAFT", 4, true, false)

shuangqiangvs = sgs.CreateViewAsSkill
{
	name = "shuangqiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:getSlashCount() > 0 and sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Crossbow" then
	        return (to_select:inherits("EquipCard") and not(to_select:isEquipped() and to_select:inherits("Weapon"))) or to_select:inherits("TrickCard")
		else
		    return to_select:inherits("EquipCard") or to_select:inherits("TrickCard")
		end
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 1 and card:inherits("EquipCard") then
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName("shuangqiang1")
			return acard
		elseif #cards == 1 and card:inherits("TrickCard") then
		    local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName("shuangqiang2")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,
}

shuangqiang = sgs.CreateTriggerSkill
{
	name = "shuangqiang",
	events = {sgs.Damage},
	view_as_skill = shuangqiangvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:inherits("Slash") and not damage.chain and not damage.transfer then
	    if damage.card:getSkillName() == "shuangqiang1" and damage.to:getEquips():length() > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
		    room:throwCard(room:askForCardChosen(player, damage.to ,"e",self:objectName()),damage.to,player)
		elseif damage.card:getSkillName() == "shuangqiang2" and not damage.to:isKongcheng() and room:askForSkillInvoke(player,self:objectName(),data) then
	        room:moveCardTo(sgs.Sanguosha:getCard(room:askForCardChosen(player, damage.to, "h", self:objectName())), player, sgs.Player_Hand, false)
		end
	end
	end,
}

zuzhuangvs = sgs.CreateViewAsSkill
{
	name = "zuzhuang",
	n = 2,
	view_filter = function(self, selected, to_select)
	if #selected == 0 then
	    if sgs.Self:getSlashCount() > 0 and sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Crossbow" then
	        return (to_select:inherits("EquipCard") and not(to_select:isEquipped() and to_select:inherits("Weapon"))) or to_select:inherits("TrickCard")
		else
		    return to_select:inherits("EquipCard") or to_select:inherits("TrickCard")
		end
	end
	if #selected == 1 then
	    if selected[1]:inherits("EquipCard") then
		    return to_select:inherits("TrickCard")
		elseif selected[1]:inherits("TrickCard") then
		    if sgs.Self:getSlashCount() > 0 and sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Crossbow" then
	            return to_select:inherits("EquipCard") and not(to_select:isEquipped() and to_select:inherits("Weapon"))
		    else
		        return to_select:inherits("EquipCard")
			end
		end
	else return false
	end
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 2 and card:inherits("EquipCard") then
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), 0) 
			acard:addSubcard(cards[1])
			acard:addSubcard(cards[2])
			acard:setSkillName("zuzhuang1")
			return acard
		elseif #cards == 2 and card:inherits("TrickCard") then
		    local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), 0) 
			acard:addSubcard(cards[1])
			acard:addSubcard(cards[2])
			acard:setSkillName("zuzhuang2")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,
}

zuzhuang = sgs.CreateTriggerSkill
{
	name = "zuzhuang",
	events = {sgs.Damage},
	view_as_skill = zuzhuangvs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:inherits("Slash") and not damage.chain and not damage.transfer then
	    if damage.card:getSkillName() == "zuzhuang1" and damage.to:getEquips():length() > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
		    damage.to:throwAllEquips()
		elseif damage.card:getSkillName() == "zuzhuang2" and not damage.to:isKongcheng() and room:askForSkillInvoke(player,self:objectName(),data) then
	        damage.to:throwAllHandCards()
		end
	end
	end,
}

BUSTER:addSkill(shuangqiang)
BUSTER:addSkill(zuzhuang)

DUEL = sgs.General(extension, "DUEL", "ZAFT", 4, true, false)

sijuevs = sgs.CreateViewAsSkill
{
	name = "sijue",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isBlack() and to_select:inherits("BasicCard")
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return true
	end,
}

sijue = sgs.CreateTriggerSkill
{
	name = "sijue",
	events = {sgs.CardEffect},
	view_as_skill = sijuevs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
	if effect.card:inherits("Duel") and effect.card:getSkillName() == self:objectName() then
	    effect.to:drawCards(1)
	end
	end,
}

pojia = sgs.CreateTriggerSkill
{
	name = "pojia",
	events = {sgs.GameStart,sgs.Damaged,sgs.Predamaged},
	frequency = sgs.Skill_Limited,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.GameStart then
	    player:gainMark("@pojia")
	elseif event == sgs.Damaged and player:getMark("@pojia") > 0 and player:getEquips():length() > 0 and damage.from and room:askForSkillInvoke(player,self:objectName(),data) then
	    player:loseMark("@pojia")
		player:throwAllEquips()
	    for i=1,2,1 do
		    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		    duel:setSkillName(self:objectName())
			local use = sgs.CardUseStruct()
            use.from = player
            use.to:append(damage.from)
            use.card = duel
            room:useCard(use)
		end
	elseif event == sgs.Predamaged and damage.card:inherits("Duel") and damage.card:getSkillName() == "pojia" and damage.from:objectName() ~= player:objectName() then
	    return true
	end
	end,
}

DUEL:addSkill(sijue)
DUEL:addSkill(pojia)

BLITZ = sgs.General(extension, "BLITZ", "ZAFT", 4, false, false)

shenlou = sgs.CreateTriggerSkill
{
	name = "shenlou",
	events = {sgs.CardResponsed,sgs.SlashProceed,sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local card = data:toCard()
		local effect = data:toSlashEffect()
		local use = data:toCardUse()
	if event == sgs.CardResponsed and card:inherits("Jink") and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:setPlayerMark(player,"shenlou",1)
	elseif event == sgs.SlashProceed and player:getMark("shenlou") > 0 then
	    room:setPlayerMark(player,"shenlou",0)
		effect.nature = sgs.DamageStruct_Thunder
		data:setValue(effect)
		room:slashResult(effect, nil)
		return true
	elseif event == sgs.CardFinished and use.card:inherits("Slash") and player:getMark("shenlou") > 0 then
	    room:setPlayerMark(player,"shenlou",0)
	end
	end,
}

zhuanjin = sgs.CreateTriggerSkill
{
	name = "zhuanjin",
	events = {sgs.GameStart,sgs.AskForPeaches},
	frequency = sgs.Skill_Limited,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
	if event == sgs.GameStart then
	    player:gainMark("@zhuanjin")
	end
	if dying.who:objectName() ~= player:objectName() and player:getMark("@zhuanjin") > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
	    player:loseMark("@zhuanjin")
	    room:setPlayerProperty(dying.who, "hp", sgs.QVariant(1))
		dying.who:drawCards(player:getLostHp()+dying.who:getLostHp())
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:setSkillName(self:objectName())
		if dying.damage.from and dying.damage.from:isAlive() and not player:isProhibited(player, slash) then
			local use = sgs.CardUseStruct()
			use.from = dying.damage.from
			use.to:append(player)
			use.card = slash
			room:useCard(use)
		end
	end
	end,
}

BLITZ:addSkill(shenlou)
BLITZ:addSkill(zhuanjin)

M1 = sgs.General(extension, "M1-ASTRAY", "ORB", 5, false, false)

yiduancard = sgs.CreateSkillCard
{
	name = "yiduan",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    if not source:hasUsed("Analeptic") then
		    local choice = room:askForChoice(source, self:objectName(), "analeptic+duel")
			if choice == "duel" then
			    room:setPlayerMark(source,"ydduel",1)
			elseif choice == "analeptic" then
			    room:setPlayerMark(source,"ydanaleptic",1)
			end
		else
		    room:setPlayerMark(source,"ydduel",1)
		end
		if source:hasMark("ydduel") or source:hasMark("ydanaleptic") then
		    room:askForUseCard(source, "@@yiduan", "$$yiduan")
		end
		room:setPlayerMark(source,"ydduel",0)
		room:setPlayerMark(source,"ydanaleptic",0)
	end,
}

ydtmp={}
yiduan = sgs.CreateViewAsSkill
{
	name = "yiduan",
	n = 2,
    view_filter=function(self, selected, to_select)
        if #selected ==0 then return not to_select:isEquipped() end
        if #selected == 1 then
            local cc = selected[1]:getSuit()
            return (not to_select:isEquipped()) and (to_select:getSuit() ~= cc)
        else return false
        end
    end,
	view_as = function(self, cards)
	if ydtmp[1] == "jink" or ydtmp[1] == "analeptic" then
		if #cards == 2 then
		    if cards[1]:getColor() == cards[2]:getColor() then
				local ydcard = sgs.Sanguosha:cloneCard(ydtmp[1], cards[1]:getSuit(), 0)
				ydcard:addSubcard(cards[1])
				ydcard:addSubcard(cards[2])
				ydcard:setSkillName(self:objectName())
				ydtmp={}
				return ydcard
			else
			    local ydcard = sgs.Sanguosha:cloneCard(ydtmp[1], sgs.Card_NoSuit, 0)
				ydcard:addSubcard(cards[1])
				ydcard:addSubcard(cards[2])
				ydcard:setSkillName(self:objectName())
				ydtmp={}
				return ydcard
			end
		end
	elseif ydtmp[1] ~= "jink" and ydtmp[1] ~= "analeptic" then
	    if not sgs.Self:hasMark("ydduel") and not sgs.Self:hasMark("ydanaleptic") then
			if #cards == 0 then
				local acard = yiduancard:clone()		
				acard:setSkillName(self:objectName())
				return acard
			end
		elseif sgs.Self:hasMark("ydduel") or sgs.Self:hasMark("ydanaleptic") then
		    if #cards == 2 then
				if sgs.Self:hasMark("ydduel") then
					if cards[1]:getColor() == cards[2]:getColor() then
						local ydcard = sgs.Sanguosha:cloneCard("duel", cards[1]:getSuit(), 0)
						ydcard:addSubcard(cards[1])
						ydcard:addSubcard(cards[2])
						ydcard:setSkillName(self:objectName())
						return ydcard
					else
						local ydcard = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
						ydcard:addSubcard(cards[1])
						ydcard:addSubcard(cards[2])
						ydcard:setSkillName(self:objectName())
						return ydcard
					end
				elseif sgs.Self:hasMark("ydanaleptic") then
					if cards[1]:getColor() == cards[2]:getColor() then
						local ydcard = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), 0)
						ydcard:addSubcard(cards[1])
						ydcard:addSubcard(cards[2])
						ydcard:setSkillName(self:objectName())
						return ydcard
					else
						local ydcard = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
						ydcard:addSubcard(cards[1])
						ydcard:addSubcard(cards[2])
						ydcard:setSkillName(self:objectName())
						return ydcard
					end
				end
			end
		end
	end
	end,
	enabled_at_play = function(self, player)
		return true
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "jink" then
			ydtmp[1] = pattern
			return pattern == "jink"
		elseif string.find(pattern, "analeptic") then
		    ydtmp[1] = "analeptic"
			return string.find(pattern, "analeptic")
		else
		    return pattern == "@@yiduan"
		end
	end,
}

aobu = sgs.CreateTriggerSkill
{
	name = "aobu",
	events = {sgs.GameStart,sgs.SkillAcquire,sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.GameStart or (event == sgs.SkillAcquire and player:hasSkill("aobu") and player:getMark("aobu") == 0)then
	    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    if p:getMark(player:objectName()) == 0 then
		        room:setPlayerMark(p,player:objectName(),p:getMark(player:objectName())+1)
			end
		end
		room:setPlayerMark(player,"aobu",1)
	elseif event == sgs.Damaged and damage.from:hasMark(player:objectName()) then
		room:setPlayerMark(damage.from,player:objectName(),damage.from:getMark(player:objectName())-1)
		room:loseHp(damage.from)
	end
	end,
}

aobup = sgs.CreateProhibitSkill
{
	name = "#aobup",
	is_prohibited = function(self, from, to, card)
		if from:hasSkill("aobu") and to:hasMark(from:objectName()) then
			return card:inherits("Slash")
		end
	end,
}

M1:addSkill(yiduan)
M1:addSkill(aobu)
M1:addSkill(aobup)

IWSP = sgs.General(extension, "STRIKE-IWSP", "ORB", 4, true, false)

zhuangjiacard = sgs.CreateSkillCard
{
	name = "zhuangjia",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setPlayerFlag(source,"zhuangjiaslash")
		source:loseMark("@jia")
	end,
}

zhuangjiavs = sgs.CreateViewAsSkill
{
	name = "zhuangjia",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
		local acard = zhuangjiacard:clone()		
		acard:setSkillName("zhuangjia")
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@jia") > 0 and not player:hasFlag("zhuangjiaslash")
	end,
}

zhuangjia = sgs.CreateTriggerSkill
{
	name = "zhuangjia",
	events = {sgs.GameStart,sgs.SlashEffect,sgs.Predamaged},
	view_as_skill = zhuangjiavs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		local damage = data:toDamage()
	if event == sgs.GameStart and player:getMark("@jia") == 0 then
	    player:gainMark("@jia",4)
	elseif event == sgs.SlashEffect and player:hasFlag("zhuangjiaslash") then
	    room:setPlayerFlag(player,"-zhuangjiaslash")
		effect.nature = sgs.DamageStruct_Fire
		data:setValue(effect)
	elseif event == sgs.Predamaged and player:getMark("@jia") > 0 and damage.nature == sgs.DamageStruct_Normal and room:askForSkillInvoke(player,self:objectName(),data) then
	    player:loseMark("@jia")
		return true
	end
	end,
}

zhuangjiaslash = sgs.CreateTargetModSkill{
	name = "#zhuangjiaslash",
	pattern = "Slash",
	distance_limit_func = function(self, player, card)
		if player and player:hasSkill("zhuangjia") and player:hasFlag("zhuangjiaslash") then
			return 998
		end
	end,
}

jiandao = sgs.CreateTriggerSkill
{
	name = "jiandao",
	events = {sgs.Predamage},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card:isKindOf("Slash") and damage.to:getArmor() and not damage.chain and not damage.transfer and room:askForSkillInvoke(player,self:objectName(),data) then
	    damage.damage = damage.damage + 1
		data:setValue(damage)
	end
	end,
}

xiaorencard = sgs.CreateSkillCard
{
	name = "xiaoren",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
	    return #targets < 1 and to_select:objectName() ~= player:objectName() and player:inMyAttackRange(to_select)
	end,
	on_effect = function(self,effect)
	    local room = effect.from:getRoom()
		effect.from:loseAllMarks("@jia")
		local damage = sgs.DamageStruct()
		damage.from = effect.from
        damage.to = effect.to
		damage.damage = 1
		room:damage(damage)
	end,
}

xiaoren = sgs.CreateViewAsSkill
{
	name = "xiaoren",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
		local acard = xiaorencard:clone()		
		acard:setSkillName("xiaoren")
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@jia") > 0
	end,
}

IWSP:addSkill(zhuangjia)
IWSP:addSkill(zhuangjiaslash)
IWSP:addSkill(jiandao)
IWSP:addSkill(xiaoren)

freedom = sgs.General(extension, "freedom", "ORB", 3, true,false)

--[[helieold=sgs.CreateTriggerSkill{
	name="helieold",
	events={sgs.HpChanged,sgs.CardLost,sgs.CardGot,sgs.CardLostDone,sgs.CardGotDone, sgs.CardDrawnDone, sgs.CardDiscarded,sgs.GameStart,sgs.PhaseChange},
	priority=2,
	frequency = sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local Hp = player:getHp()
		local HandcardNum = player:getHandcardNum()
		local CanInvoke = false
        if event == sgs.PhaseChange and player:getPhase()== sgs.Player_Discard then
		    local x =player:getHp()
            local z = player:getHandcardNum()
			local w = player:getMark("@weilu")
            if z <= (2+x-w) then
            return true
            else
            local e = z-(2+x-w)
            room:askForDiscard(player,"helie",e,e,false,false)
	        return true
			end
			end
		if (event == sgs.CardLost) then 
			local move=data:toCardMove()
			if (move.from_place==sgs.Player_Hand) then
				player:setFlags("HandCardChanged")
			end
		end
		if (event == sgs.CardGot) then 
			local move=data:toCardMove()
			if (move.to_place==sgs.Player_Hand) then
				player:setFlags("HandCardChanged")
			end
		end

		if (event ~= sgs.CardLost and event ~= sgs.CardGot) then
			if(event == sgs.CardLostDone or event == sgs.CardGotDone) then
				if  player:hasFlag("HandCardChanged") then
					player:setFlags("-HandCardChanged")
				else
					return
				end
			end
			if event == sgs.GameStart then return end
			local x = player:getMark("@weilu")
			if (Hp+2-x <= HandcardNum) then return end
			local log=sgs.LogMessage()
			log.type ="#InvokeSkill"
			room:playSkillEffect("helie")
			player:drawCards(Hp+2-x-HandcardNum)
		end
	end,
}

jiaoxieold = sgs.CreateTriggerSkill
{
	name = "jiaoxieold",
	events = {sgs.Predamage,sgs.Predamaged},
	frequency = sgs.Skill_NotFrequent,
	priority = -1,
on_trigger = function(self, event, player, data)
		 local room=player:getRoom()
		local damage = data:toDamage()
		if(event == sgs.Predamage and damage.damage >= damage.to:getHp()) then
		  if (not room:askForSkillInvoke(player, self:objectName())) then return end
		  room:playSkillEffect("jiaoxie")
		  local x = damage.to:getMaxHp()
		  if damage.to:getGeneral():isMale() then
		  room:transfigure(damage.to, "sujiang", false, true)
		  room:setPlayerProperty(damage.to,"maxhp",sgs.QVariant(x))
		  elseif damage.to:getGeneral():isFemale() then
		  room:transfigure(damage.to, "sujiangf", false, true)
		  room:setPlayerProperty(damage.to,"maxhp",sgs.QVariant(x))
		  end
		elseif(event == sgs.Predamaged and damage.damage >= damage.to:getHp()) then
		  if (not room:askForSkillInvoke(player, self:objectName())) then return end
		  room:playSkillEffect("jiaoxie")
		  local x = damage.from:getMaxHp()
		  if damage.from:getGeneral():isMale() then
		  room:transfigure(damage.from, "sujiang", false, true)
		  room:setPlayerProperty(damage.from,"maxhp",sgs.QVariant(x))
		  elseif damage.from:getGeneral():isFemale() then
		  room:transfigure(damage.from, "sujiangf", false, true)
		  room:setPlayerProperty(damage.from,"maxhp",sgs.QVariant(x))
		  end
	end
end,
}

jingshi = sgs.CreateTriggerSkill
{
	name = "jingshi",
	events = {sgs.Damage,sgs.DamageComplete},
	frequency = sgs.Skill_NotFrequent,
on_trigger = function(self, event, player, data)
		local room=player:getRoom()
		local damage = data:toDamage()
		local to = data:toDamage().to
		local data = sgs.QVariant(0)
		data:setValue(to)
		if event == sgs.Damage and (not player:inMyAttackRange(to)) then
		  if (not room:askForSkillInvoke(player, self:objectName())) then return end
		  room:playSkillEffect("jingshi")
		  if player:getHp() == player:getMaxHp() and to:isAlive() then
		     local damage = sgs.DamageStruct()
			  damage.from = nil
			  damage.to = to

			  room:damage(damage)
			  if (not to:isAlive()) and to:getRole()=="rebel" then player:drawCards(3) end
			  if (not to:isAlive()) and player:getRole()=="lord" and to:getRole()=="loyalist" then player:throwAllCards() end
		  elseif player:getHp() < player:getMaxHp() and (not to:isAlive()) then
		    local recover = sgs.RecoverStruct()   --回复结构体
			recover.recover = 1  --回复点数
			recover.who = player   --回复来源
			room:recover(player,recover)
		  elseif player:getHp() < player:getMaxHp() then
		  local choice=room:askForChoice(player, self:objectName(), "recover+hit")
		  if choice == "recover" then
		    local recover = sgs.RecoverStruct()   --回复结构体
			recover.recover = 1  --回复点数
			recover.who = player   --回复来源
			room:recover(player,recover)
          elseif choice == "hit" then
		      local damage = sgs.DamageStruct()
			  damage.from = nil
			  damage.to = to

			  room:damage(damage)
			  if (not to:isAlive()) and to:getRole()=="rebel" then player:drawCards(3) end
			  if (not to:isAlive()) and player:getRole()=="lord" and to:getRole()=="loyalist" then player:throwAllCards() end
	    end
		end
	end
end,
}

xishi_Card = sgs.CreateSkillCard {  --??技能卡
	name = "xishi",
	target_fixed = true,
	will_throw = false,
	once = true,
	on_use = function(self, room, source, targets)
	    local room = source:getRoom()
		local emplayer
		for _,p in sgs.qlist(room:getAlivePlayers()) do
	 		if p:getMark("xishi_Target") > 0 then
				emplayer = p
				break
			end
		end
		if emplayer:isKongcheng() then return end
		if source:pindian(emplayer,"xishi",self) then
		    if emplayer:isKongcheng() then return end
			room:throwCard(room:askForCardChosen(source, emplayer ,"h",self:objectName()))
	end
	end
}

xishi_Vskill = sgs.CreateViewAsSkill{
	name = "xishi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local acard = xishi_Card:clone() 
			acard:addSubcard(cards[1])
			acard:setSkillName("xishi")
			return acard
		end
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xishi"
	end,
}

xishi = sgs.CreateTriggerSkill
{
	name = "xishi",
	events = {sgs.Damaged,sgs.Pindian},
	view_as_skill=xishi_Vskill,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local from = data:toDamage().from
		local data = sgs.QVariant(0)
		data:setValue(from)
		if from == nil then return end
		if((not player:isKongcheng()) and player:inMyAttackRange(from) and (not from:isKongcheng()) and room:askForSkillInvoke(player, "xishi", data)) then
				if from:isKongcheng() then return end
				room:playSkillEffect("xishi")
				from:setMark("xishi_Target",1)
				room:askForUseCard(player,"@@xishi","@xishi")
			return false
		elseif event == sgs.Pindian then
			local room = player:getRoom()
			local pindian = data:toPindian()
			from:setMark("xishi_Target",0)
	end
	end
}]]

helie = sgs.CreateTriggerSkill{
	name = "helie",
	events = {sgs.PhaseChange,sgs.PhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	if (event == sgs.PhaseChange or event == sgs.PhaseEnd) and player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player,self:objectName(),data) then
	    if player:getGeneralName() == "freedom" then
		    room:playSkillEffect(self:objectName())
		end
		player:throwAllHandCards()
		player:drawCards(player:getMaxHp())
	end
	end,
}

jiaoxie = sgs.CreateTriggerSkill{
	name = "jiaoxie",
	events = {sgs.Dying,sgs.AskForPeaches},
	priority = 97,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
	if player:getMark("@seed") > 0 then return false end
	if event == sgs.Dying and dying.who:objectName() == player:objectName() then
	if dying.damage.from:objectName() == dying.who:objectName() then return false end
	    local skilllist={}
		local skill2list={}
		for _,skill in sgs.qlist(dying.damage.from:getVisibleSkillList()) do
		    local name = skill:objectName()
			if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake) then
				table.insert(skilllist,name)
			elseif (name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake) then
			    table.insert(skill2list,name)
			end
		end
		if #skilllist > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
		    local x = dying.damage.from:getMaxHp()
		    local y = dying.damage.from:getHp()
		    local skill = room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
		    if dying.damage.from:getGeneral():isMale() then
		        room:setPlayerProperty(dying.damage.from,"general",sgs.QVariant("sujiang"))
		    elseif dying.damage.from:getGeneral():isFemale() then
		        room:setPlayerProperty(dying.damage.from,"general",sgs.QVariant("sujiangf"))
		    end
			room:setPlayerProperty(dying.damage.from,"maxhp",sgs.QVariant(x))
	        room:setPlayerProperty(dying.damage.from,"hp",sgs.QVariant(y))
			local a = 0
			while(a < #skilllist) do
			a = a + 1
			    room:acquireSkill(dying.damage.from,skilllist[a])
			end
			local b = 0
			while(b < #skill2list) do
			b = b + 1
			    room:acquireSkill(dying.damage.from,skill2list[b])
			end
			room:detachSkillFromPlayer(dying.damage.from,skill)
			room:playSkillEffect(self:objectName())
		end
	    while #skilllist > 0 do
		    table.remove(skilllist)
		end
		while #skill2list > 0 do
		    table.remove(skill2list)
		end
	elseif event == sgs.AskForPeaches and dying.damage.from:objectName() == player:objectName() then
	if dying.damage.from:objectName() == dying.who:objectName() then return false end
	    local skilllist={}
		local skill2list={}
		for _,skill in sgs.qlist(dying.who:getVisibleSkillList()) do
		    local name = skill:objectName()
			if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake) then
				table.insert(skilllist,name)
			elseif (name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake) then
			    table.insert(skill2list,name)
			end
		end
		if #skilllist > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
		    local x = dying.who:getMaxHp()
		    local y = dying.who:getHp()
		    local skill = room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
		    if dying.who:getGeneral():isMale() then
		        room:setPlayerProperty(dying.who,"general",sgs.QVariant("sujiang"))
		    elseif dying.who:getGeneral():isFemale() then
		        room:setPlayerProperty(dying.who,"general",sgs.QVariant("sujiangf"))
		    end
			room:setPlayerProperty(dying.who,"maxhp",sgs.QVariant(x))
	        room:setPlayerProperty(dying.who,"hp",sgs.QVariant(y))
			local a = 0
			while(a < #skilllist) do
			a = a + 1
			    room:acquireSkill(dying.who,skilllist[a])
			end
			local b = 0
			while(b < #skill2list) do
			b = b + 1
			    room:acquireSkill(dying.who,skill2list[b])
			end
			room:detachSkillFromPlayer(dying.who,skill)
			room:playSkillEffect(self:objectName())
		end
	    while #skilllist > 0 do
		    table.remove(skilllist)
		end
		while #skill2list > 0 do
		    table.remove(skill2list)
		end
	end
	end,
}

zhongzi = sgs.CreateTriggerSkill{
	name = "zhongzi",
	events = {sgs.AskForPeachesDone},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	    local dying = data:toDying()
	if dying.who:objectName() == player:objectName() and player:getHp() < 1 and player:getMark("@seed") == 0 then
	    player:gainMark("@seed")
		room:setEmotion(player,"zhongzi")
		room:playSkillEffect(self:objectName())
		room:setPlayerProperty(player,"hp",sgs.QVariant(2))
		room:detachSkillFromPlayer(player,"jiaoxie")
	end
	end,
}

freedom:addSkill(helie)
freedom:addSkill(jiaoxie)
freedom:addSkill(zhongzi)

JUSTICE = sgs.General(extension, "JUSTICE", "ORB", 4, true, false)

--[[heliej=sgs.CreateTriggerSkill{
	name="heliej",
	events={sgs.HpChanged,sgs.CardLost,sgs.CardGot,sgs.CardLostDone,sgs.CardGotDone, sgs.CardDrawnDone, sgs.CardDiscarded,sgs.GameStart,sgs.PhaseChange},
	priority=2,
	frequency = sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local Hp = player:getHp()
		local HandcardNum = player:getHandcardNum()
		local CanInvoke = false
        if event == sgs.PhaseChange and player:getPhase()== sgs.Player_Discard and player:hasSkill("huaxiang") then
		    local x =player:getHp()
            local z = player:getHandcardNum()
			local w = player:getMark("@weilu")
            if z <= (2-3+x-w) then
            return true
            else
            local e = z-(2-3+x-w)
            room:askForDiscard(player,"heliej",e,e,false,false)
	        return true
			end
		elseif event == sgs.PhaseChange and player:getPhase()== sgs.Player_Discard and not player:hasSkill("huaxiang") then
		    local x =player:getHp()
            local z = player:getHandcardNum()
			local w = player:getMark("@weilu")
            if z <= (2+x-w) then
            return true
            else
            local e = z-(2+x-w)
            room:askForDiscard(player,"heliej",e,e,false,false)
	        return true
			end
			end
		if (event == sgs.CardLost) then 
			local move=data:toCardMove()
			if (move.from_place==sgs.Player_Hand) then
				player:setFlags("HandCardChanged")
			end
		end
		if (event == sgs.CardGot) then 
			local move=data:toCardMove()
			if (move.to_place==sgs.Player_Hand) then
				player:setFlags("HandCardChanged")
			end
		end

		if (event ~= sgs.CardLost and event ~= sgs.CardGot) then
			if(event == sgs.CardLostDone or event == sgs.CardGotDone) then
				if  player:hasFlag("HandCardChanged") then
					player:setFlags("-HandCardChanged")
				else
					return
				end
			end
			if event == sgs.GameStart then return end
			local x = player:getMark("@weilu")
			if not player:hasSkill("huaxiang") and (Hp+2-x <= HandcardNum) then return end
			if player:hasSkill("huaxiang") and (Hp+2-3-x <= HandcardNum) then return end
			local log=sgs.LogMessage()
			log.type ="#InvokeSkill"
			room:playSkillEffect("heliej")
			if not player:hasSkill("huaxiang") then
			player:drawCards(Hp+2-x-HandcardNum)
			elseif player:hasSkill("huaxiang") then
			player:drawCards(Hp+2-3-x-HandcardNum)
			end
		end
	end,
}

huaxiang = sgs.CreateDistanceSkill
{
	name = "huaxiang",
	correct_func = function(self, from, to)
		if from:hasSkill("huaxiang") then
			return -2
		end
	end,
}

huixuan = sgs.CreateTriggerSkill
{
	name = "huixuan",
	events = {sgs.CardEffect},
    priority=1,
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
        if event == sgs.CardEffect then
			local effect = data:toCardEffect()
			if effect.card:inherits("Slash") and effect.card:isRed() and room:askForSkillInvoke(player, "huixuan") then
			   local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                              slash:setSkillName("huixuan")
                              local use = sgs.CardUseStruct()
                              use.from = effect.from
                                                          
                              use.to:append(effect.to)
                                                         
                              use.card = slash
                              room:useCard(use,false)
			end
		end
	end,
}]]

shouwangvs = sgs.CreateViewAsSkill
{
	name = "shouwang",
	n = 0,
	view_as = function(self, cards)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		peach:setSkillName(self:objectName())
		return peach
	end,
	enabled_at_play = function(self,player)
		return player:isWounded()
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

shouwang = sgs.CreateTriggerSkill
{
	name = "shouwang",
	events = {sgs.AskForPeaches,sgs.CardUsed},
	view_as_skill = shouwangvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local dying = data:toDying()
		local use = data:toCardUse()
	if event == sgs.AskForPeaches then
	while dying.who:getHp() < 1 do
	if not room:askForSkillInvoke(player,self:objectName(),data) then break end
			local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
			peach:setSkillName(self:objectName())
			local us = sgs.CardUseStruct()
			us.from = player
																  
			us.to:append(dying.who)
																 
			us.card = peach
			room:useCard(us)
		end
	elseif event == sgs.CardUsed and use.card:inherits("Peach") and use.card:getSkillName() == "shouwang" then
	    room:loseMaxHp(player)
	end
	end,
}

huixuan = sgs.CreateTriggerSkill
{
	name = "huixuan",
	events = {sgs.SlashMissed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
    if effect.slash:isRed() and room:askForSkillInvoke(player,self:objectName(),data) then
	    if effect.to:getEquips():length() > 0 then
		    local choice = room:askForChoice(player, self:objectName(), "hxthrow+hxreturn")
			if choice == "hxthrow" then
			    for i=1,2,1 do
				    if effect.to:getEquips():length() == 0 then break end
					room:throwCard(room:askForCardChosen(player, effect.to ,"e",self:objectName()),effect.to,player)
				end
			else
			    player:obtainCard(effect.slash)
			end
		else
		    player:obtainCard(effect.slash)
		end
	end
	end,
}

JUSTICE:addSkill("helie")
JUSTICE:addSkill(shouwang)
JUSTICE:addSkill(huixuan)

CFR = sgs.General(extension, "CFR", "OMNI", 3, true, false)

wenshencard = sgs.CreateSkillCard
{
	name = "wenshen",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    if sgs.Slash_IsAvailable(source) and not source:hasUsed("Analeptic") then
		    local choice = room:askForChoice(source, self:objectName(), "slash+analeptic")
			if choice == "slash" then
			    room:setPlayerMark(source,"wsslash",1)
			elseif choice == "analeptic" then
			    room:setPlayerMark(source,"wsanaleptic",1)
			end
		elseif sgs.Slash_IsAvailable(source) and source:hasUsed("Analeptic") then
		    room:setPlayerMark(source,"wsslash",1)
		elseif not sgs.Slash_IsAvailable(source) and not source:hasUsed("Analeptic") then
		    room:setPlayerMark(source,"wsanaleptic",1)
		end
		if source:hasMark("wsslash") or source:hasMark("wsanaleptic") then
		    room:askForUseCard(source, "@@wenshen", "$wenshen")
		end
		room:setPlayerMark(source,"wsslash",0)
		room:setPlayerMark(source,"wsanaleptic",0)
	end,
}

wenshenvs = sgs.CreateViewAsSkill
{
	name = "wenshen",
	n = 1,
	view_filter = function(self, selected, to_select)
	if sgs.Self:getSlashCount() > 0 and sgs.Self:getWeapon() and sgs.Self:getWeapon():className() == "Crossbow" then
	    return to_select:isKindOf("EquipCard") and not(to_select:isEquipped() and to_select:inherits("Weapon"))
        else
		return to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self, cards)
	    local card = cards[1]
	if not sgs.Self:hasMark("wsdying") then
		if not sgs.Self:hasMark("wsslash") and not sgs.Self:hasMark("wsanaleptic") and #cards == 0 then
			local acard = wenshencard:clone()		
			acard:setSkillName("wenshen")
			return acard
		elseif (sgs.Self:hasMark("wsslash") or sgs.Self:hasMark("wsanaleptic")) and #cards == 1 then
			if sgs.Self:hasMark("wsslash") then
				local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
				acard:addSubcard(card)
				acard:setSkillName(self:objectName())
				return acard
			elseif sgs.Self:hasMark("wsanaleptic") then
				local acard = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
				acard:addSubcard(card)
				acard:setSkillName(self:objectName())
				return acard
			end
		end
	elseif sgs.Self:hasMark("wsdying") then
	    if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("analeptic", card:getSuit(), card:getNumber())
			acard:addSubcard(cards[1])
			acard:setSkillName(self:objectName())
			return acard
		end
	end
	end,
	enabled_at_play = function(self,player)
	    return sgs.Slash_IsAvailable(player) or (not player:hasUsed("Analeptic"))
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@wenshen"
	end,
}

wenshen = sgs.CreateTriggerSkill
{
	name = "wenshen",
	events = {sgs.Dying},
	view_as_skill = wenshenvs,
	priority = 3,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	if event == sgs.Dying then
	    room:setPlayerMark(player,"wsdying",1)
		while player:getHp() < 1 do
		    local card = room:askForUseCard(player, "@@wenshen", "$wenshen")
		    if not card then break end
		end
		room:setPlayerMark(player,"wsdying",0)
	end
	end,
}

jinduan = sgs.CreateTriggerSkill
{
	name = "jinduan",
	events = {sgs.CardEffected},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local effect = data:toCardEffect()
	if effect.card:isRed() and effect.from:objectName() ~= effect.to:objectName() and room:askForSkillInvoke(player,self:objectName(),data) then
	    local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName())
		effect.to = target
		room:cardEffect(effect)
		return true
	end
	end,
}

liesha = sgs.CreateTriggerSkill
{
	name = "liesha",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
	if use.card:isKindOf("Slash") and room:askForSkillInvoke(player,self:objectName(),data) then
	    player:drawCards(1)
	end
	end,
}

CFR:addSkill(wenshen)
CFR:addSkill(jinduan)
CFR:addSkill(liesha)

PROVIDENCE = sgs.General(extension, "PROVIDENCE", "ZAFT", 4, true, false)

longqi = sgs.CreateTriggerSkill
{
	name = "longqi",
	events = {sgs.CardResponsed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card = data:toCard()
	if card:isKindOf("Jink") and not player:isKongcheng() and room:askForSkillInvoke(player,self:objectName(),data) then
	    local acard = room:askForCard(player,"Slash","@@longqi",data)
		local tos = sgs.SPlayerList()
		local list = room:getOtherPlayers(player)
		for _,p in sgs.qlist(list) do
			if not p:isProhibited(p, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) then
			    tos:append(p)
			end
		end
		local target = room:askForPlayerChosen(player, tos, self:objectName())
		if acard and target then
			local use = sgs.CardUseStruct()
            use.from = player

            use.to:append(target)
                                                         
            use.card = acard
            room:useCard(use,false)
		end
	end
	end,
}

chuangshi = sgs.CreateTriggerSkill
{
	name = "chuangshi",
	events = {sgs.Predamaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    local damage = data:toDamage()
	if damage.from:isAlive() and damage.damage >= player:getHp() then
	    local d = sgs.DamageStruct()
		d.from = player
        d.to = damage.from
		d.damage = damage.damage
		room:damage(d)
		room:loseMaxHp(player)
	end
	end,
}

PROVIDENCE:addSkill("helie")
PROVIDENCE:addSkill(longqi)
PROVIDENCE:addSkill(chuangshi)

CAG = sgs.General(extension, "CAG", "OMNI", 3, true, false)

hunduncard = sgs.CreateSkillCard
{
	name = "hundun",	
	target_fixed = false,	
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return player:distanceTo(to_select) <= 1 and to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
	    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		local use = sgs.CardUseStruct()
		use.from = source
		local i = 0
		while(i < #targets) do
			i = i + 1
			use.to:append(targets[i])
		end
		use.card = slash
		room:useCard(use,false)
	end,
}

hundunvs = sgs.CreateViewAsSkill
{
	name = "hundun",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
		local card = hunduncard:clone()		
		card:setSkillName(self:objectName())
		return card
	end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@hundun"
	end,
}

hundun = sgs.CreateTriggerSkill
{
	name = "hundun",
	events = {sgs.TurnedOver},
	view_as_skill = hundunvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:faceUp() and room:askForSkillInvoke(player,self:objectName(),data) then
		    room:askForUseCard(player, "@@hundun", "$$hundun")
		end
	end,
}

shenyuan = sgs.CreateTriggerSkill
{
	name = "shenyuan",
	events = {sgs.Predamaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isRed() and room:askForSkillInvoke(player,self:objectName(),data) then
		    player:turnOver()
			local log = sgs.LogMessage()
			log.from = player
			log.arg = self:objectName()
			log.arg2 = damage.damage
			log.type = "#shenyuan"
			room:sendLog(log)
			return true
		end
	end,
}

dadi = sgs.CreateTriggerSkill
{
	name = "dadi",
	events = {sgs.Death},
	frequency=sgs.Skill_Compulsory,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamageStar()
	if player:hasSkill(self:objectName()) then
	    if damage.from and damage.to:hasSkill(self:objectName()) then
		    damage.from:turnOver()
		end
	else
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:isAlive() and p:hasSkill(self:objectName()) then
				p:turnOver()
			end
		end
    end
    end,
}

CAG:addSkill(hundun)
CAG:addSkill(shenyuan)
CAG:addSkill(dadi)

SAVIOUR = sgs.General(extension, "SAVIOUR", "ZAFT", 4, true, false)

zhongcheng = sgs.CreateTriggerSkill
{
	name = "zhongcheng",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and damage.from:hasEquip() and room:askForSkillInvoke(player,self:objectName(),data) then
		    damage.from:throwAllEquips()
		end
	end,
}

SAVIOUR:addSkill("bianxing")
SAVIOUR:addSkill(zhongcheng)

IMPULSE = sgs.General(extension, "IMPULSE", "ZAFT", 4, true, false)

daohe = sgs.CreateTriggerSkill
{
	name = "daohe",
	events = {sgs.TurnStart,sgs.PhaseChange},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.TurnStart then
	    if room:askForSkillInvoke(player,self:objectName(),data) then
		    local choice = room:askForChoice(player, self:objectName(), "@meiying+@jianying+@jiying")
			player:gainMark(choice)
			if player:hasMark("@emeng") then
			    if player:hasMark("@meiying") then
				    local choice1 = room:askForChoice(player, self:objectName(), "@jianying+@jiying")
			        player:gainMark(choice1)
				elseif player:hasMark("@jianying") then
				    local choice2 = room:askForChoice(player, self:objectName(), "@meiying+@jiying")
			        player:gainMark(choice2)
				elseif player:hasMark("@jiying") then
				    local choice3 = room:askForChoice(player, self:objectName(), "@meiying+@jianying")
			        player:gainMark(choice3)
				end
			end
		end
	elseif event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish then
	    room:setPlayerMark(player,"@meiying",0)
		room:setPlayerMark(player,"@jianying",0)
		room:setPlayerMark(player,"@jiying",0)
		room:setPlayerMark(player,"meiyingadd",0)
	end
	end,
}

meiying = sgs.CreateTriggerSkill
{
	name = "#meiying",
	events = {sgs.CardUsed,sgs.Damage,sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local damage = data:toDamage()
	if player:getMark("@meiying") == 0 then return false end
	if player:getPhase() ~= sgs.Player_Play then return false end
    if event == sgs.CardUsed and use.card:inherits("Slash") then
	    player:addMark("meiyingslash")
	elseif event == sgs.Damage and damage.card:inherits("Slash") and player:getMark("meiyingslash") > 0 then
	    player:removeMark("meiyingslash")
	elseif event == sgs.CardFinished and use.card:inherits("Slash") and player:getMark("meiyingslash") > 0 then
		player:removeMark("meiyingslash")
		if room:askForSkillInvoke(player,self:objectName(),data) then
		    room:setPlayerMark(player,"meiyingadd",player:getMark("meiyingadd")+1)
		end
	end
	end,
}

meiyingslash = sgs.CreateTargetModSkill{
	name = "#meiyingslash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player and player:hasSkill("#meiying") and player:getMark("@meiying") > 0 then
			return 1
		end
	end,
}

meiyingslash2 = sgs.CreateSlashSkill
{
	name = "#meiyingslash2",
	s_residue_func = function(self, from)
		if from and from:hasSkill("#meiying") and from:getMark("@meiying") > 0 and from:getMark("meiyingadd") > 0 then
            local init =  1 - from:getSlashCount()
            return init + from:getMark("meiyingadd")
        else
            return 0
		end
	end,
}

jianying = sgs.CreateTriggerSkill
{
	name = "#jianying",
	events = {sgs.CardUsed,sgs.Damage,sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local damage = data:toDamage()
	if player:getMark("@jianying") == 0 then return false end
	if player:getPhase() ~= sgs.Player_Play then return false end
    if event == sgs.CardUsed and use.card:inherits("Slash") then
	    player:addMark("jianyingslash")
	elseif event == sgs.Damage and damage.card:inherits("Slash") and player:getMark("jianyingslash") > 0 then
	    player:removeMark("jianyingslash")
	elseif event == sgs.CardFinished and use.card:inherits("Slash") and player:getMark("jianyingslash") > 0 then
		player:removeMark("jianyingslash")
		if room:askForSkillInvoke(player,self:objectName(),data) then
		    player:drawCards(1)
		end
	end
	end,
}

jianyingslash = sgs.CreateTargetModSkill{
	name = "#jianyingslash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player and player:hasSkill("#jianying") and player:getMark("@jianying") > 0 then
			return 1
		end
	end,
}

jiying = sgs.CreateTriggerSkill
{
	name = "#jiying",
	events = {sgs.Predamage},
	priority = -99,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if player:getMark("@jiying") == 0 then return false end
	if damage.card and damage.card:isKindOf("Slash") and damage.damage >= damage.to:getHp() and room:askForSkillInvoke(player,self:objectName(),data) then
	    damage.damage = damage.damage+1
		data:setValue(damage)
		return false
	end
	end,
}

emeng = sgs.CreateTriggerSkill
{
	name = "emeng",
	events = {sgs.Damaged},
	frequency = sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if player:hasMark("@emeng") then return false end
	if damage.from and not player:inMyAttackRange(damage.from) and damage.card and damage.card:isKindOf("Slash") then
	    player:gainMark("@emeng")
	end
	end,
}

IMPULSE:addSkill(daohe)
IMPULSE:addSkill(meiying)
IMPULSE:addSkill(meiyingslash)
IMPULSE:addSkill(meiyingslash2)
IMPULSE:addSkill(jianying)
IMPULSE:addSkill(jianyingslash)
IMPULSE:addSkill(jiying)
IMPULSE:addSkill(emeng)

FREEDOM_D = sgs.General(extension, "FREEDOM-D", "ORB", 4, true, false)

xinnianlist = {}
xinnian = sgs.CreateTriggerSkill
{
	name = "xinnian",
	events = {sgs.TurnStart,sgs.PhaseEnd,sgs.PreDeath,sgs.Predamaged},
	priority = 2,
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.TurnStart then
	    local wakelist = {}
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    table.insert(xinnianlist,p:getGeneralName())
			local n = 1
			for _,q in sgs.qlist(room:getOtherPlayers(player)) do
			    if q:hasMark("xinnian") then
				    n = n + 1
				end
			end
		        p:gainMark("xinnian",n)
			for _,skill in sgs.qlist(p:getVisibleSkillList()) do
		        if skill:getFrequency() == sgs.Skill_Wake then
					table.insert(wakelist,skill:objectName())
				end
			end
			local a = p:getMaxHp()
			local b = p:getHp()
			if p:getGeneral():isMale() then
				room:transfigure(p, "sujiang", false, false)
			elseif p:getGeneral():isFemale() then
				room:transfigure(p, "sujiangf", false, false)
			end
			room:setPlayerProperty(p,"maxhp",sgs.QVariant(a))
			room:setPlayerProperty(p,"hp",sgs.QVariant(b))
			local a = 0
			while(a < #wakelist) do
			a = a + 1
				room:acquireSkill(p,wakelist[a])
			end
			while #wakelist > 0 do
				table.remove(wakelist)
			end
		end
	end
	if (event == sgs.PhaseEnd and player:getPhase() == sgs.Player_Finish) or (event == sgs.PreDeath and player:getPhase() ~= sgs.Player_NotActive) then
	    for _,r in sgs.qlist(room:getOtherPlayers(player)) do
		    local x = r:getMaxHp()
			local y = r:getHp()
			local z = r:getMark("xinnian")
		    room:transfigure(r, xinnianlist[z], false, false)
			room:setPlayerProperty(r,"maxhp",sgs.QVariant(x))
			room:setPlayerProperty(r,"hp",sgs.QVariant(y))
			room:setPlayerMark(r,"xinnian",0)
		end
		while #xinnianlist > 0 do
	        table.remove(xinnianlist)
		end
	end
	if event == sgs.Predamaged then
	    room:loseHp(player)
		return true
	end
	end,
}

luanzhan = sgs.CreateTriggerSkill
{
	name = "luanzhan",
	events = {sgs.Dying},
	frequency = sgs.Skill_Wake,
	can_trigger = function(self,player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
	    local selfplayer = room:findPlayerBySkillName(self:objectName())
	if not selfplayer:hasMark("@luanzhan") and dying.who:objectName() ~= selfplayer:objectName() then
	    selfplayer:gainMark("@luanzhan")
	    room:loseMaxHp(selfplayer)
		room:acquireSkill(selfplayer,"shouwang")
	end
	end,
}

FREEDOM_D:addSkill(xinnian)
FREEDOM_D:addSkill(luanzhan)

DESTROY = sgs.General(extension, "DESTROY", "OMNI", 4, false, false)

huohai = sgs.CreateTriggerSkill
{
	name = "huohai",
	events = {sgs.CardUsed},
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if use.card and use.card:isKindOf("Peach") and player:objectName() ~= selfplayer:objectName() and not player:isKongcheng() and room:askForSkillInvoke(selfplayer,self:objectName(),data) then
	    room:askForDiscard(player, self:objectName(), 1, 1, false, false)
	end
	end,
}

tiebi = sgs.CreateTriggerSkill
{
	name = "tiebi",
	events = {sgs.CardEffected},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
	if player:hasMark("@kongjv") then return false end
    if effect.card:isRed() and player:distanceTo(effect.from) > 1 and room:askForSkillInvoke(player,self:objectName(),data) then
	    local log = sgs.LogMessage()
		log.type = "#tiebi"
		log.from = player
		log.arg  = self:objectName()
		log.arg2 = effect.card:objectName()
		room:sendLog(log)
		return true
	end
	end,
}

kongjv = sgs.CreateTriggerSkill
{
	name = "kongjv",
	events = {sgs.Death},
	frequency = sgs.Skill_Wake,
	can_trigger = function(self, player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamageStar()
	if damage.from and damage.to and not damage.to:hasSkill(self:objectName()) then
	    for _,p in sgs.qlist(room:getAlivePlayers()) do
		if p:hasMark("@kongjv") then return false end
		    if p:getHandcardNum() >= 2 then
		        room:askForDiscard(p, self:objectName(), 2, 2, false, false)
			end
			if p:hasSkill(self:objectName()) then
			    p:gainMark("@kongjv")
				room:detachSkillFromPlayer(p,"tiebi")
			end
		end
	end
	end,
}

DESTROY:addSkill(huohai)
DESTROY:addSkill(tiebi)
DESTROY:addSkill(kongjv)

AKATSUKI = sgs.General(extension, "AKATSUKI", "ORB", 3, true, false)

bachicard = sgs.CreateSkillCard
{
	name = "bachi",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		room:setPlayerFlag(effect.to,"bachi")
	end,
}

bachivs = sgs.CreateViewAsSkill
{
	name = "bachi",
	n = 1,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards == 0 then return nil end
		if #cards == 1 then         
			local card = cards[1]
			local acard = bachicard:clone()
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@bachi"
	end,
}

bachi = sgs.CreateTriggerSkill
{
	name = "bachi",
	events = {sgs.CardEffected},
	view_as_skill = bachivs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local effect = data:toCardEffect()
	if effect.card:isRed() and room:askForSkillInvoke(player,self:objectName(),data) then
	    if room:askForUseCard(player, "@@bachi", "##bachi") then
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			    if p:hasFlag("bachi") then
				    effect.to = p
					room:cardEffect(effect)
					room:setPlayerFlag(p,"-bachi")
				end
			end
		    return true
		end
	end
	end,
}

buqin = sgs.CreateTriggerSkill
{
	name = "buqin",
	events = {sgs.CardAsked},
	priority = 1,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
        local selfplayer = room:findPlayerBySkillName(self:objectName())
	if data:toString() == "slash" and player:objectName() ~= selfplayer:objectName() and selfplayer:inMyAttackRange(player) and room:askForSkillInvoke(selfplayer, self:objectName(),data) then
		local slash_card = room:askForCard(selfplayer, "slash", "@buqinslash", data)
		if slash_card then
		    room:provide(slash_card)
		    return true
		end
	end
	if data:toString() == "jink" and player:objectName() ~= selfplayer:objectName() and selfplayer:inMyAttackRange(player) and room:askForSkillInvoke(selfplayer, self:objectName(),data) then
		local jink_card = room:askForCard(selfplayer, "jink", "@buqinjink", data)
		if jink_card then
		    room:provide(jink_card)
		    return true
		end
	end
	end,
}

AKATSUKI:addSkill(bachi)
AKATSUKI:addSkill("aobu")
AKATSUKI:addSkill(buqin)

SF = sgs.General(extension, "SF", "ORB", 4, true, false)

ziyou = sgs.CreateTriggerSkill
{
	name = "ziyou",
	events = {sgs.Predamaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()	
		local damage = data:toDamage()
    if (not player:isKongcheng()) and ((not damage.card) or damage.card:inherits("SkillCard")) then
	    local log = sgs.LogMessage()
        log.from = player
		log.arg = self:objectName()
		log.arg2 = damage.damage
        log.type = "#ziyou"
        room:sendLog(log)
		return true
	end
	end,
}

daijincard = sgs.CreateSkillCard
{
	name = "daijin",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    return #targets < self:subcardsLength() and to_select:objectName() ~= player:objectName() and not to_select:getVisibleSkillList():isEmpty()
	end,
	on_use = function(self, room, source, targets)
		local i = 0
		while(i < #targets) do
			i = i + 1
			local to = targets[i]
		local skilllist={}
		local skilllist2={}
		for _,skill in sgs.qlist(to:getVisibleSkillList()) do
		    local name = skill:objectName()
			if not(name=="axe" or name=="fan" or name=="spear" or name=="jianwuskillvs" or name=="chunzhongv" or name=="xianzhislash" or name=="huangtianv" or name=="zhiba_pindian" or name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake) then
				table.insert(skilllist,name)
			end
			if name=="jianong" or name=="mouduan" or skill:getFrequency() == sgs.Skill_Limited or skill:getFrequency() == sgs.Skill_Wake then
			    table.insert(skilllist2,name)
			end
		end
		if #skilllist > 0 then
		    local skill = room:askForChoice(source,self:objectName(),table.concat(skilllist,"+"))
		    if to:getGeneral():isMale() then
		        room:setPlayerProperty(to,"general",sgs.QVariant("sujiang"))
		    elseif to:getGeneral():isFemale() then
		        room:setPlayerProperty(to,"general",sgs.QVariant("sujiangf"))
		    end
			local a = 0
			while(a < #skilllist) do
			a = a + 1
			    room:acquireSkill(to,skilllist[a])
			end
			table.remove(skilllist)
			local b = 0
			while(b < #skilllist2) do
			b = b + 1
			    room:acquireSkill(to,skilllist2[b])
			end
			table.remove(skilllist2)
			room:detachSkillFromPlayer(to,skill)
			room:setPlayerMark(to,"daijin",i)
		end
		end
	end,
}

daijinvs = sgs.CreateViewAsSkill
{
	name = "daijin",
	n = 998,
	view_filter = function(self, card)
        return true
    end,
	view_as = function(self, cards)
	if #cards > 0 then
		local acard = daijincard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				acard:addSubcard(card:getId())
			end
			acard:setSkillName(self:objectName())
			return acard
		else return nil
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#daijin") and not player:isKongcheng() and not player:hasFlag("djnouse")
	end,
}

daijinskill={}
daijin = sgs.CreateTriggerSkill
{
	name = "daijin",
	events = {sgs.CardUsed,sgs.TurnStart},
	view_as_skill = daijinvs,
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
	if event == sgs.CardUsed and use.card:getSkillName() == "daijin" then
		for _,p in sgs.qlist(use.to) do
		    table.insert(daijinskill,p:getGeneralName())
		end
	end
	if event == sgs.TurnStart and #daijinskill > 0 then
	    for _,q in sgs.qlist(room:getOtherPlayers(player)) do
		    if q:getMark("daijin") > 0 then
			    local x = q:getMaxHp()
				local y = q:getMark("daijin")
				local z = q:getHp()
				q:loseAllSkills()
				room:transfigure(q, daijinskill[y], false, false)
				room:setPlayerProperty(q,"maxhp",sgs.QVariant(x))
				room:setPlayerProperty(q,"hp",sgs.QVariant(z))
				room:setPlayerMark(q,"daijin",0)
			end
		end
		while #daijinskill > 0 do
	        table.remove(daijinskill)
		end
	end
	end,
}

chaoqi = sgs.CreateTriggerSkill
{
	name = "chaoqi",
	events = {sgs.SlashEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
    if room:askForSkillInvoke(player,self:objectName(),data) then
	    for _,cd in sgs.qlist(player:handCards()) do
		    player:addToPile("chaoqi",cd,false)
		end
		player:drawCards(1)
		local card = player:handCards():first()
        room:showCard(player,card)
		room:setPlayerFlag(player,"djnouse")
		local use = sgs.CardUseStruct()
		room:activate(player,use)
		if use:isValid() then
		    for _,id in sgs.qlist(player:getPile("chaoqi")) do
			    player:obtainCard(sgs.Sanguosha:getCard(id),false)
		    end
			room:useCard(use)
		end
		for _,id in sgs.qlist(player:getPile("chaoqi")) do
		    player:obtainCard(sgs.Sanguosha:getCard(id),false)
	    end
		room:setPlayerFlag(player,"-djnouse")
	end
	end,
}

chaoqit = sgs.CreateTargetModSkill{
	name = "#chaoqit",
	pattern = "Slash,Snatch,SupplyShortage",
	distance_limit_func = function(self, player)
		if player and (player:hasSkill("chaoqi") or player:hasSkill("shenyu")) and player:hasFlag("djnouse") then
			return 998
		end
	end,
}

chaoqis = sgs.CreateSlashSkill
{
	name = "#chaoqis",
	s_residue_func = function(self, from)
		if from and (from:hasSkill("chaoqi") or from:hasSkill("shenyu")) and from:hasFlag("djnouse") then
            local init =  1 - from:getSlashCount()
            return init + 998
        else
            return 0
		end
	end,
}

SF:addSkill(ziyou)
SF:addSkill(daijin)
SF:addSkill(chaoqi)
SF:addSkill(chaoqit)
SF:addSkill(chaoqis)

IJ = sgs.General(extension, "IJ", "ORB", 4, true, false)

zhengyi = sgs.CreateTriggerSkill
{
	name = "zhengyi",
	events = {sgs.Predamaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()	
		local damage = data:toDamage()
    if (player:hasEquip()) and ((not damage.card) or damage.card:inherits("SkillCard")) then
	    local log = sgs.LogMessage()
        log.from = player
		log.arg = self:objectName()
		log.arg2 = damage.damage
        log.type = "#ziyou"
        room:sendLog(log)
		return true
	end
	end,
}

hanweicard = sgs.CreateSkillCard
{
	name = "hanwei",	
	target_fixed = false,	
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 1 and to_select:hasEquip()
	end,
	on_use = function(self, room, source, targets)
	    local card_id = room:askForCardChosen(source, targets[1], "e", self:objectName())
		local card = sgs.Sanguosha:getCard(card_id)
		local place = room:getCardPlace(card_id)
		local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if (card:inherits("Weapon") and p:getWeapon() == nil) or (card:inherits("Armor") and p:getArmor() == nil) or (card:inherits("DefensiveHorse") and p:getDefensiveHorse() == nil) or (card:inherits("OffensiveHorse") and p:getOffensiveHorse() == nil) then
				tos:append(p)
			end
		end
		local to = room:askForPlayerChosen(source, tos, self:objectName())
		if to then
			room:moveCardTo(card, to, place, true)
		end
	end,
}

hanwei = sgs.CreateViewAsSkill{
    name = "hanwei",
    n = 1,
    view_filter = function(self, selected, to_select)
        return not to_select:isEquipped()
    end,
    view_as=function(self, cards)
	if #cards == 1 then
        local acard = hanweicard:clone()
        acard:addSubcard(cards[1])                
        acard:setSkillName(self:objectName())
        return acard
	    end
    end,
    enabled_at_play = function(self,player)
        return not player:isKongcheng()
    end,
}

shijiu = sgs.CreateTriggerSkill
{
	name = "shijiu",
	events = {sgs.CardLost},
    can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local move = data:toCardMove()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
		if player:objectName() ~= selfplayer:objectName() and move.from_place == sgs.Player_Hand and room:getCardPlace(move.card_id) == sgs.Player_DiscardedPile then
		    if player:hasFlag("shijiu") and player:getPhase() == sgs.Player_Play then return false end
			if player:getPhase() ~= sgs.Player_Play and player:getPhase() ~= sgs.Player_NotActive then return false end
		    if room:askForSkillInvoke(selfplayer, self:objectName()) then
			    if player:getPhase() == sgs.Player_Play then
				    room:setPlayerFlag(player,"shijiu")
				end
				selfplayer:drawCards(1)
				local hnum = selfplayer:getHandcardNum()
				local cdlist = sgs.IntList()
				cdlist:append(selfplayer:handCards():at(hnum-1))
				room:askForYiji(selfplayer, cdlist)
			end
		end        
	end
}

IJ:addSkill(zhengyi)
IJ:addSkill(hanwei)
IJ:addSkill(shijiu)

DESTINY = sgs.General(extension, "DESTINY", "ZAFT", 4, true, false)

huanyi = sgs.CreateTriggerSkill
{
	name = "huanyi",
	events = {sgs.PhaseChange,sgs.Predamaged,sgs.TurnStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player,self:objectName(),data) then
	    local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
		    room:setPlayerMark(player,"@huanyi",1)
			room:setEmotion(player,"good")
		else
		    room:setEmotion(player,"bad")
		end
	elseif event == sgs.Predamaged and (not damage.card or (damage.card and not damage.card:inherits("Slash"))) and player:getMark("@huanyi") > 0 then
	    local log = sgs.LogMessage()
        log.from = player
		log.arg = self:objectName()
		log.arg2 = damage.damage
        log.type = "#huanyi"
        room:sendLog(log)
		return true
	elseif event == sgs.TurnStart and player:getMark("@huanyi") > 0 then
	    room:setPlayerMark(player,"@huanyi",0)
	end
	end,
}

huanyiremove = sgs.CreateTriggerSkill
{
	name = "#huanyiremove",
	events = {sgs.TurnStart},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.TurnStart and player:getMark("@huanyi") > 0 then
	    room:setPlayerMark(player,"@huanyi",0)
	end
	end,
}

feiniao = sgs.CreateTriggerSkill
{
	name = "feiniao",
	events = {sgs.SlashEffected},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
	if player:getCards("he"):length() >= (player:getHp()-1) and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:askForDiscard(player,self:objectName(),player:getHp()-1,player:getHp()-1,false,true)
		player:drawCards(effect.from:getHp())
	end
	end,
}

nuhuo = sgs.CreateTriggerSkill
{
	name = "nuhuo",
	events = {sgs.PhaseChange,sgs.Predamage},
	frequency = sgs.Skill_Wake,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if player:getPhase() == sgs.Player_Start and player:getMark("@nuhuo") == 0 then
	    local n = 0
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    if player:distanceTo(p) == 1 then
			    n = n + 1
			end
		end
		if n == 0 then
		    player:gainMark("@nuhuo")
			player:gainMark("@jianying")
			room:setPlayerMark(player,"nuhuoadd",1)
		end
	elseif event == sgs.Predamage and player:getMark("nuhuoadd") > 0 then
	    room:setPlayerMark(player,"nuhuoadd",0)
	    damage.damage = damage.damage + 1
		data:setValue(damage)
		return false
	end
	end,
}

DESTINY:addSkill(huanyi)
DESTINY:addSkill(huanyiremove)
DESTINY:addSkill(feiniao)
DESTINY:addSkill(nuhuo)
DESTINY:addSkill("#jianying")

LEGEND = sgs.General(extension, "LEGEND", "ZAFT", 3, true, false)

jiqicard = sgs.CreateSkillCard
{
	name = "jiqi",	
	target_fixed = true,	
	will_throw = true,
	on_use = function(self, room, source, targets)
	    local x = self:subcardsLength()
		local y = room:getDrawPile():length()
		local cdlist = sgs.IntList()
		local i = 0
		while(i < 2*x) do
			i = i + 1
		    cdlist:append(room:getDrawPile():at(i-1))
		end
		local n = y-x
		while(n < y) do
			n = n + 1
		    cdlist:append(room:getDrawPile():at(n-1))
			cdlist:append(room:getDrawPile():at(n-x-1))
		end
		room:fillAG(cdlist)
		room:getThread():delay()
		for _,cd in sgs.qlist(cdlist) do
		    if sgs.Sanguosha:getCard(cd):isKindOf("BasicCard") then
			    room:obtainCard(source,cd)
			else
			    room:throwCard(cd)
			end
		end
		for _,p in sgs.qlist(room:getPlayers()) do
		    p:invoke("clearAG")
		end
    end,
}

jiqivs = sgs.CreateViewAsSkill
{
	name = "jiqi",	
	n = 998,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Slash")
    end,
	view_as = function(self, cards)
	if #cards > 0 then
			local new_card = jiqicard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName(self:objectName())
			return new_card
		else return nil
		end	
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@jiqi"
	end
}

jiqi = sgs.CreateTriggerSkill
{
	name = "jiqi",
	priority = 2,
	events = {sgs.SlashEffected,sgs.CardUsed,sgs.CardFinished},
	view_as_skill = jiqivs,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.SlashEffected and player:objectName() == selfplayer:objectName() and not player:isKongcheng() and room:askForSkillInvoke(player, "jiqi", data) then
		room:askForUseCard(player, "@@jiqi", "#jiqi")
	end
	if event == sgs.CardUsed and use.card:isKindOf("Slash") then
		for _,p in sgs.qlist(use.to) do
			if p:objectName() == selfplayer:objectName() then
				room:setPlayerFlag(use.from,"jiqi")
			end
		end
	end
	if event == sgs.CardFinished and use.card:isKindOf("Slash") and use.from:hasFlag("jiqi") then
		if room:askForSkillInvoke(selfplayer, "jiqi", data) then
			local acard = room:askForCard(selfplayer,"Slash","##jiqi",data)
			if acard then
				if not use.from:isProhibited(use.from, acard) then
				    room:playSkillEffect("jiqi")
					local usee = sgs.CardUseStruct()
                    usee.from = selfplayer

                    usee.to:append(use.from)
                                                         
                    usee.card = acard
                    room:useCard(usee,false)
				else
					room:obtainCard(selfplayer,acard)
				end
			end
		end
		room:setPlayerFlag(use.from,"-jiqi")
	end
	end,
}

kelong = sgs.CreateTriggerSkill
{
	name = "kelong",
	events = {sgs.Dying,sgs.DamageComplete,sgs.Death},
	priority = 3,
	can_trigger=function(self,player)
	    return player:hasSkill("kelong")
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		local damage = data:toDamage()
		local damaged = data:toDamageStar()
	if event == sgs.Dying and dying.damage.from and room:askForSkillInvoke(player, "kelong", data) then
	    room:playSkillEffect("kelong",1)
	    room:setPlayerFlag(player,"kelong")
		dying.damage.from:turnOver()
	end
	if event == sgs.DamageComplete and player:hasFlag("kelong") then
	    room:playSkillEffect("kelong",2)
	    room:setPlayerFlag(player,"-kelong")
		local d = sgs.DamageStruct()
		d.damage = damage.damage
		d.from = player
        d.to = damage.from
        room:damage(d)
	end
	if event == sgs.Death and player:hasFlag("kelong") then
	    room:setPlayerFlag(player,"-kelong")
		local dd = sgs.DamageStruct()
		dd.damage = damaged.damage
        dd.to = damaged.from
        room:damage(dd)
	end
	end,
}

LEGEND:addSkill(jiqi)
LEGEND:addSkill(kelong)

NOIR = sgs.General(extension, "NOIR", "OMNI", 4, true, false)

huantong = sgs.CreateFilterSkill{
    name = "huantong",
	
    view_filter = function(self, card)
        return card:inherits("Peach")
    end,
	
    view_as = function(self, card)
        local acard = sgs.Sanguosha:cloneCard("iron_chain", card:getSuit(), card:getNumber())
        acard:addSubcard(card)
		acard:setSkillName(self:objectName())
        return acard
    end,
}

huantongk=sgs.CreateTriggerSkill
{
	name = "#huantongk",
	events = {sgs.Dying},
	frequency = sgs.Skill_Compulsory,
	priority = 12,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
	if event == sgs.Dying and dying.damage.from and dying.damage.from:hasSkill("huantong") then
	    room:killPlayer(dying.damage.to,dying.damage)
	end
	end,
}

jianmievs = sgs.CreateViewAsSkill
{
	name = "jianmie",
	n = 1,

	view_filter = function(self, selected, to_select)
		return to_select:objectName() == "slash"
	end,

	view_as = function(self, cards)
		if #cards == 0 then return nil end
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("fire_slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,

	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,

	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

jianmie=sgs.CreateTriggerSkill
{
	name = "jianmie",
	events = {sgs.Damage,sgs.CardFinished},
	view_as_skill = jianmievs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local use = data:toCardUse()
	if event == sgs.Damage and damage.card and damage.card:isKindOf("FireAttack") and damage.to:isAlive() then
		room:setPlayerMark(damage.to,"jm",damage.damage)
	elseif event == sgs.CardFinished and use.card:isKindOf("FireAttack") then
	    for _,m in sgs.qlist(room:getAlivePlayers()) do
		    if m:hasMark("jm") and room:askForSkillInvoke(player,self:objectName(),data) then
				local players = room:getOtherPlayers(m)
				local distance_list=sgs.IntList()
				local nearest = 1000 
				for _,p in sgs.qlist(players) do
					local distance = m:distanceTo(p)
					distance_list:append(distance)
					nearest = math.min(nearest, distance)
				end
				local targets = sgs.SPlayerList()
				for var=0,distance_list:length(),1 do 
					if(distance_list:at(var) == nearest) then
					targets:append(players:at(var)) end
				end
				local jm = room:askForPlayerChosen(player, targets, "jianmie")
				local d=sgs.DamageStruct()
				d.damage=m:getMark("jm")
				d.nature=sgs.DamageStruct_Fire
				d.from=player
				d.to=jm
				room:damage(d)
			end
			room:setPlayerMark(m,"jm",0)
		end
	end
	end,
}

jianmieslash = sgs.CreateSlashSkill
{
	name = "#jianmieslash",
	s_extra_func = function(self, from, to, slash)
		if from and from:hasSkill("jianmie") and slash and slash:getSkillName() == "jianmie" and to and to:isKongcheng() then
			return 998
		end
	end,
	s_range_func = function(self, from, to, slash)
		if from and from:hasSkill("jianmie") and slash and slash:getSkillName() == "jianmie" then
			return -998
		end
	end,
}

NOIR:addSkill(huantong)
NOIR:addSkill(huantongk)
NOIR:addSkill(jianmie)
NOIR:addSkill(jianmieslash)

STARGAZER = sgs.General(extension, "STARGAZER", "god", 3, false, false)

xinghuan = sgs.CreateTriggerSkill
{
	name = "xinghuan",
	events = {sgs.CardResponsed,sgs.CardUsed,sgs.CardFinished},
	can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.CardResponsed then
	    local cd = data:toCard()
		if cd:inherits("Jink") and player:objectName() == selfplayer:objectName() and room:askForSkillInvoke(selfplayer, self:objectName(), data) then
			player:drawCards(1)
		end
	end
	if event == sgs.CardUsed and use.card:isKindOf("Slash") then
		for _,p in sgs.qlist(use.to) do
			if p:objectName() == selfplayer:objectName() then
				room:setPlayerFlag(use.from,"xinghuan")
			end
		end
	end
	if event == sgs.CardFinished and use.card:isKindOf("Slash") and room:obtainable(use.card, selfplayer) and use.from:hasFlag("xinghuan") then
		if room:askForSkillInvoke(selfplayer, "xinghuan", data) then
		    room:obtainCard(selfplayer,use.card)
		end
		room:setPlayerFlag(use.from,"-xinghuan")
	end
	end,
}

guanghui = sgs.CreateTriggerSkill
{
	name = "guanghui",
	events = {sgs.PhaseChange,sgs.PhaseEnd},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player,self:objectName(),data) then
		room:setPlayerFlag(player,"guanghui")
			local x = room:alivePlayerCount()
			if x > 5 then
				x = 5 
			end 
			room:doGuanxing(player,room:getNCards(x),false)
		player:skip(sgs.Player_Draw)
	end
	if event == sgs.PhaseEnd and player:getPhase() == sgs.Player_Play and player:getSlashCount() == 0 and player:hasFlag("guanghui") then
	    player:drawCards(2)
	end
	end,
}

guanghuislash = sgs.CreateTargetModSkill{
	name = "#guanghuislash",
	pattern = "Slash",
	extra_target_func = function(self, player)
		if player and player:hasSkill("guanghui") and player:hasFlag("guanghui") then
			return 1
		end
	end,
}

STARGAZER:addSkill(xinghuan)
STARGAZER:addSkill(guanghui)
STARGAZER:addSkill(guanghuislash)

RED = sgs.General(extension, "RED", "god", 3, true, false)

jianhuncard = sgs.CreateSkillCard
{
	name = "jianhun",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select, player)
	if(#targets >= 1) then return false end
	    return to_select:getPile("hun"):length() == 0
	end,
	on_effect = function(self, effect)
	    effect.to:addToPile("hun",self)
	end,
}

jianhunvs = sgs.CreateViewAsSkill
{
	name = "jianhun",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
		    local acard = jianhuncard:clone()
		    acard:addSubcard(cards[1])
		    acard:setSkillName(self:objectName())
		    return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#jianhun")
	end,
	
}

jianhun = sgs.CreateTriggerSkill
{
	name = "jianhun",
	events = {sgs.Predamage,sgs.PhaseChange},
	view_as_skill = jianhunvs,
	can_trigger = function(self, player)
        return true
    end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if event == sgs.Predamage and player:getPile("hun"):length() > 0 then
		room:moveCardTo(sgs.Sanguosha:getCard(player:getPile("hun"):at(0)),nil,sgs.Player_DrawPile,true)
		damage.damage = damage.damage + 1
		data:setValue(damage)
		return false
	elseif event == sgs.PhaseChange and selfplayer:getPhase() == sgs.Player_Start then
	    for _,p in sgs.qlist(room:getAlivePlayers()) do
		    if p:getPile("hun"):length() > 0 then
			  room:throwCard(sgs.Sanguosha:getCard(p:getPile("hun"):at(0)))
            end
        end
    end		
	end,
}

huishoucard = sgs.CreateSkillCard
{
	name = "huishou",
	target_fixed = false,
	will_throw = false,

	filter = function(self, targets, to_select, player)
	if(#targets >= 1) then return false end
	    return to_select:getPile("hun"):length() > 0 and to_select:getWeapon() and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    effect.from:obtainCard(effect.to:getWeapon())
	end,
}

huishouvs = sgs.CreateViewAsSkill
{
	name = "huishou",
	n = 0,
	view_as = function(self, cards)
		local acard = huishoucard:clone()
		acard:addSubcard(cards[1])
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return true
	end,
	
}

huishou = sgs.CreateTriggerSkill
{
	name = "huishou",
	events = {sgs.CardFinished},
	view_as_skill = huishouvs,
	can_trigger = function(self, player)
        return true
    end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
	if (use.card:isKindOf("Slash") or use.card:isKindOf("Duel")) and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardedPile and selfplayer:objectName() ~= use.from:objectName() and room:obtainable(use.card, selfplayer) and room:askForSkillInvoke(selfplayer,self:objectName(),data) then
	    room:obtainCard(selfplayer,use.card)
	end
	end,
}

RED:addSkill(jianhun)
RED:addSkill(huishou)

BLUE = sgs.General(extension, "BLUE", "god", 3, true, false)

qiangwu = sgs.CreateTriggerSkill
{
	name = "qiangwu",
	events = {sgs.Damage},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	for i=1,damage.damage,1 do
	    if room:askForSkillInvoke(player,self:objectName(),data) then
		    player:drawCards(2)
			room:askForDiscard(player,self:objectName(),1,1, false,true)
		else break
        end
	end
	end,
}

sheweivs = sgs.CreateViewAsSkill
{
	name = "shewei",
	n = 1,
	view_filter = function(self, selected, to_select)
	if sgs.Self:hasFlag("shewei") then
	    return true
	else
		return to_select:isEquipped()
	end
	end,
	view_as = function(self, cards)
		if #cards == 1 then         
			local card = cards[1]
			local acard = sgs.Sanguosha:cloneCard("duel", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@shewei"
	end,
}

shewei = sgs.CreateTriggerSkill
{
	name = "shewei",
	events = {sgs.PhaseChange,sgs.CardUsed},
	view_as_skill = sheweivs,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
	if event == sgs.PhaseChange and player:getPhase() == sgs.Player_Start and player:getCards("ej"):length() > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
	    if player:getCards("j"):length() > 0 then
		    room:setPlayerFlag(player,"shewei")
			for _,card in sgs.qlist(player:handCards()) do
				player:addToPile("shewei",card,false)
		    end
			for _,jd in sgs.qlist(player:getJudgingArea()) do
			    player:obtainCard(jd)
			end
		end
		room:acquireSkill(player,"wushuang")
		room:askForUseCard(player, "@@shewei", "#shewei")
		room:detachSkillFromPlayer(player,"wushuang")
	end
	if event == sgs.CardUsed and use.card:getSkillName() == "shewei" and player:hasFlag("shewei") then
		room:setPlayerFlag(player,"-shewei")
	    for _,re in sgs.qlist(player:handCards()) do
			room:moveCardTo(sgs.Sanguosha:getCard(re), player, sgs.Player_Judging, true)
		end
		for _,id in sgs.qlist(player:getPile("shewei")) do
			player:obtainCard(sgs.Sanguosha:getCard(id),false)
		end
	end
	end,
}

BLUE:addSkill(qiangwu)
BLUE:addSkill(shewei)

UNICORN = sgs.General(extension, "UNICORN", "god", 4, true, false)

shenshou = sgs.CreateTriggerSkill
{
	name = "shenshou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.SlashProceed},

	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toSlashEffect()
		if effect.slash:isRed() then
			if (not room:askForSkillInvoke(player, self:objectName())) then return false end
				room:playSkillEffect("shenshou")
				local acard = room:askForCard(effect.to, ".|.|.|hand|red", "@@shenshou", data)
				if acard then
				     player:obtainCard(acard)
					 return false
			    else
				    room:slashResult(effect, nil)      
				    return true
				end
		end
	end
}

NTD = sgs.CreateTriggerSkill
{
	name = "NTD",
	frequency = sgs.Skill_Wake,
	events = {sgs.CardUsed},
    can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		local can_invoke = false
	if use.card:isNDTrick() and selfplayer:getHp() < 3 and selfplayer:getMark("@NTD") == 0 then
		    for _,p in sgs.qlist(use.to) do
			if p:objectName() == selfplayer:objectName() then
				can_invoke = true
				break
			end
		    end
		if can_invoke == false and not(use.card:inherits("ExNihilo") and use.from:objectName() == selfplayer:objectName()) then return false end
			room:setEmotion(selfplayer,"NTD")
			room:getThread():delay(3000)
			room:playSkillEffect("NTD")
			selfplayer:gainMark("@NTD")
		    room:loseMaxHp(selfplayer)
				local handcards = selfplayer:handCards()
				room:fillAG(handcards)
				for _,h in sgs.qlist(handcards) do
				    if sgs.Sanguosha:getCard(h):isRed() then
					    selfplayer:addMark("ntdshow")
					end
				end
				if selfplayer:getMark("ntdshow") == 0 then
				    room:showAllCards(selfplayer, true)
				end
				for i=1,selfplayer:getMark("ntdshow"),1 do
				    if selfplayer:isWounded() then
					    local choice = room:askForChoice(selfplayer, self:objectName(), "lkdraw+recover")
						if choice == "recover" then
						    local recover = sgs.RecoverStruct()
							recover.recover = 1
							recover.who = selfplayer
							room:recover(selfplayer,recover)
						else
						    room:drawCards(selfplayer, 1)
						end
					else
					    room:drawCards(selfplayer, 1)
					end
				end
				room:setPlayerMark(selfplayer,"ntdshow",0)
				
				for _,p in sgs.qlist(room:getPlayers()) do
		            p:invoke("clearAG")
		        end
				
				room:acquireSkill(selfplayer,"huimie")
		return true
	end
	end
}

huimiecard = sgs.CreateSkillCard{
        name = "huimie",
        will_throw = true,
        target_fixed = true,
        on_use = function(self, room, source, targets)
        end,
}

huimievs = sgs.CreateViewAsSkill
{
	name = "huimie",
	n = 1,

	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern) 
			return pattern == "@@huimie"
	end,
	view_filter = function(self, selected, to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,

	view_as = function(self, cards)
	if #cards == 1 then
		local new_card = huimiecard:clone()
		new_card:addSubcard(cards[1])
		new_card:setSkillName(self:objectName())
		return new_card
	end
	end,
}

huimie = sgs.CreateTriggerSkill
{
	name = "huimie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed},
	view_as_skill = huimievs,
    can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
		local use = data:toCardUse()
		local can_invoke = false
	if use.card:isNDTrick() and use.from:objectName() ~= selfplayer:objectName() then
		    for _,p in sgs.qlist(use.to) do
			if p:objectName() == selfplayer:objectName() then
				can_invoke = true
				break
			end
		    end
		if can_invoke == false then return false end
		if(not room:askForSkillInvoke(selfplayer, self:objectName()))then return false end
			if room:askForUseCard(selfplayer, "@@huimie", ":huimie") then
			    if use.card:inherits("ArcheryAttack") or use.card:inherits("SavageAssault") or use.card:inherits("AmazingGrace") or use.card:inherits("GodSalvation") then
					local current = room:getCurrent()
				    room:setCurrent(selfplayer)
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					room:setCurrent(current)
				elseif use.card:inherits("IronChain") then
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isProhibited(p, use.card) then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
					local target2 = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    if target and target2 and target:objectName() ~= target2:objectName() then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					usee.to:append(target2)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					else
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				elseif use.card:inherits("FireAttack") then
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAlivePlayers()) do
					if not p:isProhibited(p, use.card) and not p:isKongcheng() then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    if target then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				elseif use.card:inherits("Dismantlement") then
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
					if not p:isProhibited(p, use.card) and not p:isAllNude() then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    if target then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				elseif use.card:inherits("Snatch") then
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
					if not p:isProhibited(p, use.card) and not p:isAllNude() and selfplayer:distanceTo(p) <= 1 then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    if target then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				elseif use.card:inherits("Collateral") then
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
					if not p:isProhibited(p, use.card) and p:getWeapon() then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    local tot = sgs.SPlayerList()
					for _,q in sgs.qlist(room:getOtherPlayers(target)) do
					if not q:isProhibited(q, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)) and target:inMyAttackRange(q) then
						tot:append(q)
						end
					end
					local target2 = room:askForPlayerChosen(selfplayer,tot,self:objectName())
					if target and target2 then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					usee.to:append(target2)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				else
				    local tos = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getOtherPlayers(selfplayer)) do
					if not p:isProhibited(p, use.card) then
						tos:append(p)
						end
					end
					local target = room:askForPlayerChosen(selfplayer,tos,self:objectName())
				    if target then
					local usee = sgs.CardUseStruct()
					usee.from = selfplayer
					
					usee.to:append(target)
					
					local tocard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
					tocard:setSkillName(self:objectName())
					usee.card = tocard
					room:useCard(usee)
					end
				end
                return true
			end
		return false
	end
	end
}

UNICORN:addSkill(shenshou)
UNICORN:addSkill(NTD)

JESTA = sgs.General(extension, "JESTA", "god", 3, true, true, true)

zhanshivs = sgs.CreateViewAsSkill
{
	name = "zhanshi",
	n = 0,
	view_as = function(self, cards)
		local acard = sgs.Sanguosha:cloneCard(sgs.Self:getFlags(), sgs.Card_NoSuit, 0)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern) 
		return pattern == "@@zhanshi"
	end,
}

zhanshi = sgs.CreateTriggerSkill
{
	name = "zhanshi",
	events = {sgs.CardFinished,sgs.JinkUsed,sgs.CardUsed,sgs.TurnStart,sgs.CardAsked,sgs.SlashEffected,sgs.CardEffected,sgs.Predamaged},
	view_as_skill = zhanshivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if (event == sgs.CardFinished and use.card:isKindOf("BasicCard") and use.card:isBlack()) or (event == sgs.JinkUsed and data:toCard():isBlack()) then
	    if room:askForSkillInvoke(player,self:objectName(),data) then
		    local choice = room:askForChoice(player, self:objectName(), "snatch+dismantlement+collateral+ex_nihilo+duel+fire_attack+amazing_grace+savage_assault+archery_attack+god_salvation+iron_chain")
		    if choice == "ex_nihilo" or choice == "amazing_grace" or choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then
			    local current = room:getCurrent()
				room:setCurrent(player)
				local acard = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, 0)
                acard:setSkillName(self:objectName())
                local usee = sgs.CardUseStruct()
                usee.from = player
                usee.card = acard
                room:useCard(usee)
				room:setCurrent(current)
			else
			    room:setPlayerFlag(player,choice)
			    room:askForUseCard(player, "@@zhanshi", ":zhanshi")
			    player:clearFlags()
			end
		end
	elseif event == sgs.CardUsed and use.card:isNDTrick() then
	    local n = 0
	    for _,p in sgs.qlist(use.to) do
		    n = n + 1
		end
		for _,q in sgs.qlist(use.to) do
			if ((n == 1 and q:objectName() ~= player:objectName() and not use.card:isKindOf("Collateral")) or (use.card:isKindOf("Collateral") and n == 2)) and room:askForSkillInvoke(player,self:objectName(),data) then
				if player:hasFlag("zsonlyone") then return false end
				if player:distanceTo(q) == 1 then
					local choice = room:askForChoice(player, self:objectName(), "eight_diagram+renwang_shield+silver_lion+vine")
					room:setPlayerMark(player,choice,1)
					--local log = sgs.LogMessage()
		            --log.type = ""
		            --room:sendLog(log)
				elseif player:distanceTo(q) > 1 then
					room:setPlayerMark(player,"zsadd",player:getMark("zsadd")+1)
					--local log = sgs.LogMessage()
		            --log.type = ""
		            --room:sendLog(log)
				end
				room:setPlayerFlag("zsonlyone")
			end
		end
		room:setPlayerFlag("-zsonlyone")
	elseif event == sgs.TurnStart then
	    room:setPlayerMark(player,"eight_diagram",0)
		room:setPlayerMark(player,"renwang_shield",0)
		room:setPlayerMark(player,"silver_lion",0)
		room:setPlayerMark(player,"vine",0)
		room:setPlayerMark(player,"zsadd",0)
	elseif event == sgs.CardAsked and data:toString() == "jink" and not player:hasArmorEffect("eight_diagram") and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and player:getMark("eight_diagram") > 0 and room:askForSkillInvoke(player,"eight_diagram") then
		local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(heart|diamond):(.*)")
		judge.good = true
		judge.reason = "eight_diagram"
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
		    room:setEmotion(player, "armor/eight_diagram")
			local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
			jink:setSkillName("eight_diagram")
			room:provide(jink)
			return true
		end
	elseif event == sgs.SlashEffected and data:toSlashEffect().slash:isBlack() and not player:hasArmorEffect("renwang_shield") and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and player:getMark("renwang_shield") > 0 then
		room:setEmotion(player, "armor/renwang_shield")
		local log = sgs.LogMessage()
		log.arg = "renwang_shield"
		log.arg2 = "slash"
		log.type = "#ArmorNullify"
		room:sendLog(log)
		return true
	elseif event == sgs.CardEffected and ((data:toCardEffect().card:isKindOf("Slash") and data:toCardEffect().nature == sgs.DamageStruct_Normal) or data:toCardEffect().card:isKindOf("SavageAssault") or data:toCardEffect().card:isKindOf("ArcheryAttack")) and not player:hasArmorEffect("vine") and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and player:getMark("vine") > 0 then
	    room:setEmotion(player, "armor/vine")
		local log = sgs.LogMessage()
		log.arg = "vine"
		log.arg2 = data:toCardEffect().card:objectName()
		log.type = "#ArmorNullify"
		room:sendLog(log)
	    return true
	elseif event == sgs.Predamaged and data:toDamage().nature == sgs.DamageStruct_Fire and not player:hasArmorEffect("vine") and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and player:getMark("vine") > 0 then
	    room:setEmotion(player, "armor/vineburn")
		local log = sgs.LogMessage()
		log.from = player
		log.arg = "vine"
		log.type = "#TriggerSkill"
		room:sendLog(log)
		local damage = data:toDamage()
		damage.damage = damage.damage + 1
		data:setValue(damage)
	elseif event == sgs.Predamaged and data:toDamage().damage > 1 and not player:hasArmorEffect("silver_lion") and player:getMark("qinggang") == 0 and player:getMark("wuqian") == 0 and player:getMark("silver_lion") > 0 then
	    room:setEmotion(player, "armor/silver_lion")
		local log = sgs.LogMessage()
		log.from = player
		log.arg = "silver_lion"
		log.type = "#TriggerSkill"
		room:sendLog(log)
		local damage = data:toDamage()
		damage.damage = 1
		data:setValue(damage)
	end
	end,
}

zhanshid = sgs.CreateDistanceSkill{

    name = "#zhanshid",
    correct_func = function(self, from, to)
        if to:hasSkill("zhanshi") and to:getMark("zsadd") > 0 then
            return to:getMark("zsadd")
        end
    end,
}

heixing = sgs.CreateFilterSkill{
	name = "heixing",
	view_filter = function(self, to_select)
		return to_select:getSuit() == sgs.Card_Diamond and to_select:isKindOf("Jink")
	end,
	view_as = function(self, card)
		local acard = sgs.Sanguosha:cloneCard("jink", sgs.Card_Spade, card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end,
}

heixingj = sgs.CreateTriggerSkill
{
	name = "#heixingj",
	events = {sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
	if judge.card:getSuit() == sgs.Card_Diamond and judge.card:isKindOf("Jink") then
        judge.card:setSuit(sgs.Card_Spade)
		room:sendJudgeResult(judge)
	end
	end,
}

JESTA:addSkill(zhanshi)
JESTA:addSkill(zhanshid)
JESTA:addSkill(heixing)
JESTA:addSkill(heixingj)

EXTREME = sgs.General(extension, "EXTREME", "god", 4, true, false)

jixian = sgs.CreateTriggerSkill
{
	name = "jixian",
	events = {sgs.Damage,sgs.Damaged},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Damage or event == sgs.Damaged then
	if event == sgs.Damage and damage.to:objectName() ~= player:objectName() then
	    room:playSkillEffect(self:objectName(),math.random(1, 2))
	else
	    room:playSkillEffect(self:objectName(),math.random(3, 4))
	end
	    for i=1,damage.damage,1 do
		    if player:getMark("@ex") < player:getMaxHp() then
				player:drawCards(1)
				player:gainMark("@ex")
            end
		end
	end
	end,
}

jinhua = sgs.CreateTriggerSkill
{
	name = "jinhua",
	events = {sgs.Damage,sgs.Damaged},
	frequency = sgs.Skill_Wake,
	priority = -2,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if (event == sgs.Damage or event == sgs.Damaged) and player:getMark("@ex") == player:getMaxHp() and not player:hasMark("@jinhua") then
		player:gainMark("@jinhua")
		local judge = sgs.JudgeStruct()
		judge.pattern = sgs.QRegExp("(.*):(.*):(.*)")
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge.card:getNumber() >= 1 and judge.card:getNumber() <= 5 then
		    local target = player -- 感谢 小胖子唐飞
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if player:distanceTo(target) < player:distanceTo(p) then
					target = p
				end
		    end
			for _,q in sgs.qlist(room:getOtherPlayers(player)) do
			    if player:distanceTo(target) == player:distanceTo(q) then
				    room:setPlayerProperty(q, "chained", sgs.QVariant(true))
				end
			end
			room:setEmotion(player,"jinhua")
			room:playSkillEffect(self:objectName(),math.random(1,3))
			local log = sgs.LogMessage()
			log.type = "#jinhua1"
			log.from = player
			room:sendLog(log)
			room:transfigure(player, "ECLIPSE", false, true)
		elseif judge.card:getNumber() >= 6 and judge.card:getNumber() <= 9 then
		    local players = room:getOtherPlayers(player)
			local distance_list = sgs.IntList()
		    local nearest = 1000 
		    for _,p in sgs.qlist(players) do
			    local distance = player:distanceTo(p)
			    distance_list:append(distance)
			    nearest = math.min(nearest, distance)
		    end
			local targets = sgs.SPlayerList()
		    for var=0,distance_list:length(),1 do 
		        if(distance_list:at(var) == nearest) then
                targets:append(players:at(var)) end
		    end
			for _,q in sgs.qlist(targets) do
			    room:askForDiscard(q,"jinhua",1,1, false,true)
			end
			room:setEmotion(player,"jinhua")
			room:playSkillEffect(self:objectName(),math.random(4,7))
			local log = sgs.LogMessage()
			log.type = "#jinhua2"
			log.from = player
			room:sendLog(log)
		    room:transfigure(player, "XENON", false, true)
		elseif judge.card:getNumber() >= 10 and judge.card:getNumber() <= 13 then
            local m={} 
            for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                table.insert(m,p:getHp())                        
            end
			for _,q in sgs.qlist(room:getOtherPlayers(player)) do
                if q:getHp() == math.max(unpack(m)) then
				    room:showAllCards(q, true)
				end
			end
			while #m > 0 do
			    table.remove(m)
			end
			room:setEmotion(player,"jinhua")
			room:playSkillEffect(self:objectName(),math.random(8,10))
			local log = sgs.LogMessage()
			log.type = "#jinhua3"
			log.from = player
			room:sendLog(log)
		    room:transfigure(player, "AIOS", false, true)
		end
	end
	end,
}

EXTREME:addSkill(jixian)
EXTREME:addSkill(jinhua)

ECLIPSE = sgs.General(extension, "ECLIPSE", "god", 3, true, true, true)

paojicard = sgs.CreateSkillCard
{
	name = "paojicard",
	target_fixed = true,
	will_throw = false,

	on_use = function(self, room, source, targets)
	    room:playSkillEffect("paoji",math.random(1,3))
	    source:loseMark("@ex")
		room:loseHp(source)
		if(source:isAlive()) then
			room:setPlayerFlag(source,"shuangpaoused")
		end
	end,
}

paojivs = sgs.CreateViewAsSkill
{
	name = "paoji",
	n = 0,
	view_as = function(self, cards)
	if #cards == 0 then
		local acard = paojicard:clone()		
		acard:setSkillName("shuangpao")
		return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasFlag("shuangpaoused") and player:hasMark("@ex")
	end,
}

paoji = sgs.CreateTriggerSkill
{
	name = "paoji",
	events = {sgs.Predamage},
	view_as_skill = paojivs,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		local use = data:toCardUse()
	if event == sgs.Predamage and damage.card:inherits("Slash") and player:hasFlag("shuangpaoused") then
        damage.damage = damage.damage+1
		data:setValue(damage)
	end
	if event == sgs.Predamage and player:hasMark("@ex") and (damage.nature == sgs.DamageStruct_Thunder or (damage.card:inherits("Slash") and damage.nature == sgs.DamageStruct_Normal)) then
		local target = player -- 感谢 小胖子唐飞
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
		    if player:distanceTo(target) < player:distanceTo(p) then
		        target = p
		    end
		end
		if player:distanceTo(target) == player:distanceTo(damage.to) and room:askForSkillInvoke(player,"jvpao",data) then
		    player:loseMark("@ex")
		    room:playSkillEffect("paoji",math.random(4,5))
			damage.damage = damage.damage+1
			data:setValue(damage)
		end
		end
	end,
}

zhongyan = sgs.CreateTriggerSkill
{
	name = "zhongyan",
	events = {sgs.PhaseChange},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if player:getPhase() == sgs.Player_Start and player:getMark("@ex") == 1 and not player:hasMark("@zhongyan") then
	    room:getThread():delay(1500)
		room:setEmotion(player,"jinhua")
		room:playSkillEffect(self:objectName())
		player:gainMark("@zhongyan")
		player:gainMark("@ex",2)
		room:acquireSkill(player,"paoji")
		room:acquireSkill(player,"wudou")
		room:acquireSkill(player,"shenyu")
		local log = sgs.LogMessage()
		log.type = "#zhongyan"
		log.from = player
		room:sendLog(log)
	end
	end,
}

ECLIPSE:addSkill(paoji)
ECLIPSE:addSkill(zhongyan)

XENON = sgs.General(extension, "XENON", "god", 3, true, true, true)

wudoucard2=sgs.CreateSkillCard{
name="wudoucard2",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        effect.from:loseMark("@ex")
        local room=effect.from:getRoom()
        local damage=sgs.DamageStruct()
		damage.damage=1
        damage.nature=sgs.DamageStruct_Fire 
		damage.from=effect.from
        damage.to=effect.to
		room:setPlayerFlag(effect.from, "shenzhangused")
		room:playSkillEffect("wudou",math.random(1,2))
        room:damage(damage)
end                
}

wudoucard3=sgs.CreateSkillCard{
name="wudoucard3",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        effect.from:loseMark("@ex")
        local room=effect.from:getRoom()
        local damage=sgs.DamageStruct()
		local choice=room:askForChoice(effect.from, "shenzhang", "damage*1+damage*3")
		if choice == "damage*3" then
		damage.damage=3
		else damage.damage=1
		end
        damage.nature=sgs.DamageStruct_Fire 
		damage.from=effect.from
        damage.to=effect.to
		room:setPlayerFlag(effect.from, "shenzhangused")
		room:playSkillEffect("wudou",3)
        room:damage(damage)
end                
}

wudoucard4 = sgs.CreateSkillCard
{
        name="wudoucard4",
        target_fixed = false,
        will_throw = true,
        filter = function(self, targets, to_select, player)
			if (sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and sgs.Self:hasFlag("shuangpaoused") then
			    return sgs.Self:canSlash(to_select, true) and #targets < 3
			elseif (sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") or sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and not sgs.Self:hasFlag("shuangpaoused") then
			    return sgs.Self:canSlash(to_select, true) and #targets < 2
			elseif (not sgs.Sanguosha:getCard(self:getSubcards():at(0)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(1)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(2)):inherits("DelayedTrick") and not sgs.Sanguosha:getCard(self:getSubcards():at(3)):inherits("DelayedTrick")) and sgs.Self:hasFlag("shuangpaoused") then
			    return sgs.Self:canSlash(to_select, true) and #targets < 2
			end
		    return sgs.Self:canSlash(to_select, true) and #targets < 1
        end,
		on_use = function(self, room, source, targets)
		    if self:subcardsLength() == 1 then
			    room:playSkillEffect("wudou",math.random(4,5))
			elseif self:subcardsLength() == 2 then
			    room:playSkillEffect("wudou",math.random(6,7))
			elseif self:subcardsLength() > 2 then
			    room:playSkillEffect("wudou",math.random(8,10))
			end
		    source:loseMark("@ex")
		    room:setPlayerFlag(source,"kuangdaoused")
			local suit
			local number
			for _,cd in sgs.qlist(self:getSubcards()) do
			suit = sgs.Sanguosha:getCard(cd):getSuit()
			number = sgs.Sanguosha:getCard(cd):getNumber()
				if sgs.Sanguosha:getCard(cd):inherits("BasicCard") and not source:hasFlag("kdb") then
				    room:setPlayerFlag(source,"kdb")
					source:drawCards(1)
				end
			if sgs.Sanguosha:getCard(cd):isNDTrick() and not source:hasFlag("kdn") then
			    room:setPlayerFlag(source,"kdn")
			    if targets[1] then
				    targets[1]:addMark("qinggang")
				end
				if targets[2] then
				    targets[2]:addMark("qinggang")
				end
				if targets[3] then
				    targets[3]:addMark("qinggang")
				end
			end
			if sgs.Sanguosha:getCard(cd):inherits("EquipCard") and not source:hasFlag("kde") then
			    room:setPlayerFlag(source,"kde")
			    if targets[1] and not targets[1]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[1] ,"h",self:objectName()))
				end
				if targets[2] and not targets[2]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[2] ,"h",self:objectName()))
				end
				if targets[3] and not targets[3]:isKongcheng() then
				    room:throwCard(room:askForCardChosen(source, targets[3] ,"h",self:objectName()))
				end
			end
			end
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			if self:subcardsLength() == 1 then
			    slash = sgs.Sanguosha:cloneCard("slash", suit, number)
			end
			slash:setSkillName(self:objectName())
			for _,cd in sgs.qlist(self:getSubcards()) do
                slash:addSubcard(cd)
            end
			local use = sgs.CardUseStruct()
			use.from = source
			
			if targets[1] then
			    use.to:append(targets[1])
			end
			if targets[2] then
		    	use.to:append(targets[2])
			end
			if targets[3] then
		    	use.to:append(targets[3])
			end
			
			use.card = slash
			room:useCard(use,true)
			
			if targets[1] then
                targets[1]:removeMark("qinggang")
			end
			if targets[2] then
			    targets[2]:removeMark("qinggang")
			end
			if targets[3] then
				targets[3]:removeMark("qinggang")
			end
		end,
}

wudoucard = sgs.CreateSkillCard
{
	name = "wudoucard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
	    if (not source:hasFlag("shenzhangused") and (not source:hasFlag("kuangdaoused") and sgs.Slash_IsAvailable(source))) then
		    local choice = room:askForChoice(source, self:objectName(), "shenzhang+kuangdao")
			if choice == "shenzhang" then
			    room:setPlayerFlag(source,"wdsz")
			elseif choice == "kuangdao" then
			    room:setPlayerFlag(source,"wdkd")
			end
		elseif (not source:hasFlag("shenzhangused") and (source:hasFlag("kuangdaoused") or not sgs.Slash_IsAvailable(source))) then
		    room:setPlayerFlag(source,"wdsz")
		elseif (source:hasFlag("shenzhangused") and (not source:hasFlag("kuangdaoused") and sgs.Slash_IsAvailable(source))) then
		    room:setPlayerFlag(source,"wdkd")
		end
		if source:hasFlag("wdsz") or source:hasFlag("wdkd") then
		    room:askForUseCard(source, "@@wudou", "$$wudou")
		end
		room:setPlayerFlag(source,"-wdsz")
		room:setPlayerFlag(source,"-wdkd")
	end,
}

wudou = sgs.CreateViewAsSkill{
name = "wudou",
n = 998,
view_filter=function(self, selected, to_select)
    if sgs.Self:hasFlag("wdsz") then
        return to_select:getSuit() == sgs.Card_Heart or to_select:getNumber() == 13
	elseif sgs.Self:hasFlag("wdkd") then
	    return not to_select:isEquipped()
	else return false
	end
end,
view_as = function(self, cards)
        local card = cards[1]
	if not sgs.Self:hasFlag("wdsz") and not sgs.Self:hasFlag("wdkd") then
	    if #cards == 0 then
			local acard = wudoucard:clone()
			acard:setSkillName(self:objectName())
			return acard
		end
	elseif sgs.Self:hasFlag("wdsz") then
	    if #cards == 1 then
			if card:getSuit() == sgs.Card_Heart and card:getNumber() == 13 then
				local new_card = wudoucard3:clone()
				local i = 0
				while(i < #cards) do
					i = i + 1
					local card = cards[i]
					new_card:addSubcard(card:getId())
				end
				new_card:setSkillName("shenzhang")
				return new_card
			else
			local new_card = wudoucard2:clone()
				local i = 0
				while(i < #cards) do
					i = i + 1
					local card = cards[i]
					new_card:addSubcard(card:getId())
				end
				new_card:setSkillName("shenzhang")
				return new_card
			end
		end
		elseif sgs.Self:hasFlag("wdkd") then
		    if #cards >= 1 and #cards <= 4 then
				local new_card = wudoucard4:clone()
				local i = 0
				while(i < #cards) do
					i = i + 1
					local card = cards[i]
					new_card:addSubcard(card:getId())
				end
				new_card:setSkillName("kuangdao")
				return new_card
			end
		end
	end,
	enabled_at_play = function(self,player)
	    return (not player:hasFlag("shenzhangused") or (not player:hasFlag("kuangdaoused") and sgs.Slash_IsAvailable(player))) and player:hasMark("@ex")
	end,
	enabled_at_response = function(self, player, pattern)
        return pattern == "@@wudou"
    end,
}

XENON:addSkill(wudou)
XENON:addSkill("zhongyan")

AIOS = sgs.General(extension, "AIOS", "god", 3, true, true, true)

shenyucard = sgs.CreateSkillCard
{
	name = "shenyucard",	
	target_fixed = true,	
	will_throw = true,
	on_use = function(self, room, source, targets)
	    room:playSkillEffect("shenyu",math.random(3,4))
	    source:loseMark("@ex")
	    local x = self:subcardsLength()
		local y = room:getDrawPile():length()
		local cdlist = sgs.IntList()
		local i = 0
		while(i < 2*x) do
			i = i + 1
		    cdlist:append(room:getDrawPile():at(i-1))
		end
		local n = y-x
		while(n < y) do
			n = n + 1
		    cdlist:append(room:getDrawPile():at(n-1))
			cdlist:append(room:getDrawPile():at(n-x-1))
		end
		room:fillAG(cdlist)
		room:getThread():delay()
		for _,cd in sgs.qlist(cdlist) do
		    if sgs.Sanguosha:getCard(cd):isKindOf("BasicCard") then
			    room:obtainCard(source,cd)
			else
			    room:throwCard(cd)
			end
		end
		for _,p in sgs.qlist(room:getPlayers()) do
		    p:invoke("clearAG")
		end
    end,
}

shenyuvs = sgs.CreateViewAsSkill
{
	name = "shenyu",	
	n = 998,
	view_filter = function(self, selected, to_select)
        return to_select:isKindOf("Slash")
    end,
	view_as = function(self, cards)
	if #cards > 0 then
			local new_card = shenyucard:clone()
			local i = 0
			while(i < #cards) do
				i = i + 1
				local card = cards[i]
				new_card:addSubcard(card:getId())
			end
			new_card:setSkillName("jiqi")
			return new_card
		else return nil
		end	
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@shenyu"
	end
}

shenyu = sgs.CreateTriggerSkill
{
	name = "shenyu",
	events = {sgs.SlashEffected,sgs.CardUsed,sgs.CardFinished},
	view_as_skill = shenyuvs,
	can_trigger=function(self,player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		local selfplayer = room:findPlayerBySkillName(self:objectName())
    if event == sgs.SlashEffected and player:objectName() == selfplayer:objectName() and player:hasMark("@ex") and not player:isKongcheng() and room:askForSkillInvoke(player, "jiqi", data) then
		room:askForUseCard(player, "@@shenyu", "#jiqi")
	end
	if event == sgs.CardUsed and use.card:isKindOf("Slash") then
		for _,p in sgs.qlist(use.to) do
			if p:objectName() == selfplayer:objectName() then
				room:setPlayerFlag(use.from,"shenyu")
			end
		end
	end
	if event == sgs.CardFinished and use.card:isKindOf("Slash") and use.from:hasFlag("shenyu") and selfplayer:hasMark("@ex") then
		if room:askForSkillInvoke(selfplayer, "jiqi", data) then
			local acard = room:askForCard(selfplayer,"Slash","##jiqi",data)
			if acard then
				if not use.from:isProhibited(use.from, acard) then
					local usee = sgs.CardUseStruct()
                    usee.from = selfplayer

                    usee.to:append(use.from)
                                                         
                    usee.card = acard
					room:playSkillEffect("shenyu",5)
					selfplayer:loseMark("@ex")
                    room:useCard(usee,false)
				else
					room:obtainCard(selfplayer,acard)
				end
			end
		end
		room:setPlayerFlag(use.from,"-shenyu")
	end
	if event == sgs.SlashEffected and player:objectName() == selfplayer:objectName() and player:hasMark("@ex") and room:askForSkillInvoke(player,"chaoqi",data) then
	    room:playSkillEffect("shenyu",1)
		player:loseMark("@ex")
	    for _,cd in sgs.qlist(player:handCards()) do
		    player:addToPile("shenyu",cd,false)
		end
		player:drawCards(1)
		local card = player:handCards():first()
        room:showCard(player,card)
		room:setPlayerFlag(player,"djnouse")
		local usee = sgs.CardUseStruct()
		room:activate(player,usee)
		if usee:isValid() then
		    for _,id in sgs.qlist(player:getPile("shenyu")) do
			    player:obtainCard(sgs.Sanguosha:getCard(id)) 
		    end
			room:playSkillEffect("shenyu",2)
			room:useCard(usee)
		end
		for _,id in sgs.qlist(player:getPile("shenyu")) do
		    player:obtainCard(sgs.Sanguosha:getCard(id),false) 
	    end
		room:setPlayerFlag(player,"-djnouse")
	end
	end,
}

AIOS:addSkill(shenyu)
AIOS:addSkill("zhongyan")

yincangzhe_li = sgs.General(extension, "yincangzhe_li", "qun", 4, true, true, true)

--[[function CreateNewCard(oldname,newname,suit,number)
local card = sgs.Sanguosha:cloneCard(oldname,suit,number)
card:setObjectName(newname)
return card
end
local card = CreateNewCard("ex_nihilo", "shuijiao", sgs.Card_Heart, 13)
card:setParent(extension)

szhangcard=sgs.CreateSkillCard{
name="szhang",
once=true,
will_throw=true,
filter=function(self,targets,to_select,player)
    if #targets >= 1 then return false end
          return to_select:objectName()~=player:objectName()
end,
on_effect=function(self,effect)
        local room=effect.from:getRoom()
		for _,ap in sgs.qlist(room:getAlivePlayers()) do
        local nullification = room:askForCard(ap, "nullification", "@askfornull")
           if nullification~=nil then
                local damage=sgs.DamageStruct()
				damage.damage=1
				damage.nature=sgs.DamageStruct_Fire 
				damage.from=effect.from
				damage.to=effect.to
				room:playSkillEffect("shenzhang",1)
				room:damage(damage)
              break
           end
        end
end                
}

sjiao = sgs.CreateFilterSkill{
    name = "sjiao",
	
    view_filter = function(self, card)
        return card:objectName() == "shuijiao"
    end,
	
    view_as = function(self, card)
        local acard = szhangcard:clone()
        acard:addSubcard(card)
        return acard
    end
}

yincangzhe_li:addSkill(sjiao)]]
yincangzhe_li:addSkill(sidaodistance)
yincangzhe_li:addSkill(dianbo)
yincangzhe_li:addSkill(nihong)
yincangzhe_li:addSkill(fengong)
yincangzhe_li:addSkill(liansuo)
yincangzhe_li:addSkill(jidong)
yincangzhe_li:addSkill(zaisheng)
yincangzhe_li:addSkill(xiaya)
yincangzhe_li:addSkill(zaishi)
yincangzhe_li:addSkill(huixing)
yincangzhe_li:addSkill(jianwu2)
yincangzhe_li:addSkill(chunzhongv)
yincangzhe_li:addSkill(benchi)
yincangzhe_li:addSkill(zaji)
yincangzhe_li:addSkill(zailinv)
yincangzhe_li:addSkill(huimie)

sgs.LoadTranslationTable{
    ["gaoda"] = "高达杀",
	["LUAWanSha"] = "完杀",
	[":LUAWanSha"] = "<b>锁定技</b>，在你的回合，除你以外，只有处于濒死状态的角色才能使用【桃】",
	["jianwu_sword"] = "GN剑五型",
	["#jianwuskill"] = "GN剑五型",
	[":#jianwuskill"] = "你的回合内，若你以【杀】和【决斗】以外的伤害，使一名角色进入濒死状态时，你可以发动技能【完杀】。",
	["jianwuskillvs"] = "GN剑五型",
	["jianwuskillcard"] = "GN剑五型",
	[":jianwuskill"] = "出牌阶段，你可以将此武器置于任意一名其他角色的装备区里，然后你摸1张牌；你的回合内，若你以【杀】和【决斗】以外的伤害，使一名角色进入濒死状态时，你可以发动技能【完杀】。",
	[":jianwuskillvs"] = "出牌阶段，你可以将此武器置于任意一名其他角色的装备区里，然后你摸1张牌；你的回合内，若你以【杀】和【决斗】以外的伤害，使一名角色进入濒死状态时，你可以发动技能【完杀】。",
	[":jianwu_sword"] = "装备牌·武器\
	攻击范围：5\
	武器特效：出牌阶段，你可以将此武器置于任意一名其他角色的装备区里，然后你摸1张牌；你的回合内，若你以【杀】和【决斗】以外的伤害，使一名角色进入濒死状态时，你可以发动技能【完杀】。",
	["liuren_shield"] = "GN浮游剑型位元",
	["#liurenskill"] = "GN浮游剑型位元",
	[":#liurenskill"] = "当你从装备区里失去此装备时，你可以指定一名其他角色，视为对之使用一张【杀】。",
	[":liuren_shield"] = "装备牌·防具\
	防具特效：<b>锁定技</b>，属性【杀】对你无效。\
	当你从装备区里失去此装备时，你可以指定一名其他角色，视为对之使用一张【杀】。",
	["#liuren_shield_msg"] = "【%arg】技能被触发，属性【杀】对其无效",
	["exia"] = "EXIA",
	["yuanjian"] = "原剑",
	[":yuanjian"] = "当你使用一张【杀】时，你可以进行一次判定，若不为<font color='red'>♥</font>，你的杀有以下效果：\
♠【杀】：无视防具。\
<font color='red'>♥</font>【杀】：即将造成的伤害视为失去体力。\
♣【杀】：结算前弃置目标一张手牌。\
<font color='red'>♦</font>【杀】：须连续使用两张【闪】才能抵消。",
	["$yuanjian"]="EXIA，介入任务开始。",
	["#yuanjian"] = "削人棍吧，混蛋！",
	["lingmin"] = "灵敏",
	[":lingmin"]="<b>锁定技</b>，任何其他角色的手牌数小于或等于你的体力值时，你计算与这些角色的距离时，始终-1。",
	["~exia"] = "给我动呀，EXIA！给我动呀，高达！",
	["#exia"] = "能天使",
	["designer:exia"] = "wch5621628 & Sankies",
	["cv:exia"] = "刹那·F·塞尔",
	["illustrator:exia"] = "Sankies",
	["dynames"] = "DYNAMES",
	["yazhi"] = "压制",
	[":yazhi"] = "当你使用【杀】时，你可以指定目标不可使用【闪】抵消该【杀】的效果，而是打出一张【杀】或手牌的非基本牌抵消之。",
	["@yazhi"] = "请打出一张【杀】或手牌的非基本牌",
	["$yazhi1"] = "DYNAMES——目标狙击！",
	["$yazhi2"] = "洛奥·史当斯——连地平线都能狙击的男人！",
	["$yazhi3"] = "狙击！",
	["jingzhun"] = "精准",
	[":jingzhun"]="<b>锁定技</b>，当你使用【杀】时，无视目标装备。",
	["~dynames"] = "这里已成为战场了吗？",
	["#dynames"] = "力天使",
	["designer:dynames"] = "wch5621628 & Sankies",
	["cv:dynames"] = "洛奥·史当斯",
	["illustrator:dynames"] = "wch5621628",
	["kyrios"] = "KYRIOS",
	["hongzhacard"] = "轰炸",
	["hongzha"] = "轰炸",
	["hongzhaTS"] = "轰炸",
	["@hongzha"] = "轰炸",
	[":hongzhaTS"] = "<b>限定技</b>，出牌阶段，你可以弃置X张装备区里的牌，及X-1张手牌，然后对任意一名其他角色造成X点伤害。",
	["sushe"] = "速射",
	[":sushe"]="当你使用一张【杀】时，你可以展示牌堆顶的一张牌，若为【杀】、【借刀殺人】或装备牌，你将之收入手牌；若不是，将之置入弃牌堆。",
	["~kyrios"] = "",
	["#kyrios"] = "主天使",
	["designer:kyrios"] = "wch5621628 & Sankies",
	["cv:kyrios"] = "阿路耶·哈帝姆",
	["illustrator:kyrios"] = "Sankies",
	["#CHERUDIM"] = "智天使",
	["jvji"] = "狙击",
	[":jvji"] = "<b>锁定技</b>，当你使用黑色普通【杀】时，目标只能使用点数比之大的【闪】。",
	["@jvji"] = "你只能使用点数比此【杀】大的【闪】。",
	["dunqiang"] = "盾墙",
	[":dunqiang"] = "你可以将你的<font color='red'>红色</font>牌当【闪】使用或打出；当你攻击范围内的角色需要使用（或打出）一张【闪】时，你可以替之打出。",
	["@dunqiang"] = "请打出一张【闪】。",
	["haro"] = "哈啰",
	[":haro"] = "当你成为【南蛮入侵】或【万箭齐发】的目标时，你可以立即摸一张牌，若如此做，该锦囊对你无效。",
	["chsanhong"] = "三红",
	["@chsanhong"] = "三红",
	[":chsanhong"] = "<b>限定技</b>，当你受到伤害时，你转移此伤害给任意一名角色，然後你须弃置所有牌并将你的武将牌翻面。",
	["designer:CHERUDIM"] = "wch5621628 & Sankies",
	["cv:CHERUDIM"] = "洛奥·史当斯",
	["illustrator:CHERUDIM"] = "Sankies",
	["#arios"] = "弓兵堕天使",
    ["arios"] = "ARCHER ARIOS",
	["shuangjia"] = "双驾",
	[":shuangjia"] = "你可以将你的<font color='red'>♥</font>牌当【闪】使用或打出。",
	["lueduo"] = "掠夺",
	[":lueduo"] = "你可以将你的♠或♣手牌当【借刀杀人】使用；若成为你的【借刀杀人】目标的角色使用了【杀】，你可以获得该角色的一张手牌。",
	["designer:arios"] = "wch5621628 & Sankies",
	["asanhong"] = "三红",
	["@asanhong"] = "三红",
	[":asanhong"] = "<b>限定技</b>，任一角色的回合开始阶段前，你令任意一名角色摸3张牌，该角色在下一个回合计算与其他角色的距离视为1，使用【杀】时可以额外指定至多两名目标。",
	["cv:arios"] = "哈路耶·哈帝姆",
	["illustrator:arios"] = "Sankies",
    ["sinanju"] = "SINANJU",
	["#sinanju"] = "夏亚再世",
    ["xiaya"] = "夏亚",
    [":xiaya"]="你可以将你的<font color='red'>♥</font>或<font color='red'>♦</font>牌当【闪】使用或打出。",
	["$xiaya"]="只要不被打中，就没什么大不了的！",
    ["zaishi"] = "再世",
    ["su"] = "速",
	[":zaishi"]="当你受到一点伤害后，可将牌堆顶的一张牌置于你的武将牌上，称之为【速】。当你受到伤害时，你可以弃置一个【速】，视为对伤害来源使用一张【杀】。出牌阶段，你可用任意数量的手牌等量交换这些【速】。",
    ["$zaishi"]="让我见识一下吧，新型MS的性能！",
	["huixing"] = "彗星",
    [":huixing"]="<b>锁定技</b>，当你计算与其他角色的距离时，始终-X（X为你当前体力值）。",
    ["wangling"] = "亡灵",
	["wling"] = "亡灵",
	["@wangling"] = "亡灵",
    [":wangling"]="当你受到伤害时，你可以永久放弃X项其他技能，使你下一次造成的伤害+X。当你进入濒死状态时，你可以永久放弃一项其他技能，视为使用一张【酒】。（失去【再世】时，将全部【速】置于你手上。）",
    ["$wangling"]="哼哼哼哼哼哼...哈哈哈哈哈哈哈哈...",
	["~sinanju"] = "不可能，我...！",
	["designer:sinanju"] = "wch5621628 & Sankies",
	["cv:sinanju"] = "弗尔·伏朗托",
	["illustrator:sinanju"] = "Sankies",
	["tallgeese"] = "TALLGEESE Ⅲ",
	["#tallgeese"] = "灭火的风",
	["lua_jisu"] = "极速",
	[":lua_jisu"]="<b>锁定技</b>，任何其他角色的手牌数大于或等于你的时，你计算与这些角色的距离视为1；这些角色计算与你的距离时，始终+1。",
	["baofeng"] = "暴风",
	[":baofeng"]="当你使用【杀】时，你可令该【杀】即将造成的伤害+X（X为目标当前装备区里的牌数）。",
	["$baofeng"]="这里是风，目标破坏！",
	["~tallgeese"]="为什么？为什么我会这么弱？！",
	["designer:tallgeese"] = "wch5621628 & Sankies",
	["cv:tallgeese"] = "米利安·皮斯克拉夫特",
	["illustrator:tallgeese"] = "wch5621628",
	["f91"] = "F91",
	["#f91"] = "生物电脑",
	["fangcheng"] = "方程",
	[":fangcheng"] = "当其他角色的<font color='red'>♦</font>牌或点数为A、9的牌，因弃置或判定而进入弃牌堆时，你可以获得之。",
	["canying"] = "残影",
	[":canying"] = "当你受到一点伤害后，你可获得一个【残影标记】，并永久获得以下技能：\
	1.<b>锁定技</b>，当其他角色计算与你的距离时，始终+X。 \
	2.任一其他角色的回合开始前或回合结束后，你可以弃置一个【残影标记】和一张【闪】，视为对之使用一张【杀】。\
	3.摸牌阶段，你可以摸X张牌。\
	（X为你当前【残影标记】的数量且最多为5）",
	["#canyingdistance"] = "残影（距离）",
	[":canyingdistance"] = "1.<b>锁定技</b>，当其他角色计算与你的距离时，始终+X（X为你当前【残影标记】的数量且最多为5）。",
	["#canyingkill"] = "残影（杀）",
	[":canyingkill"] = "2.任一其他角色的回合开始前，你可以弃置一个【残影标记】和一张【闪】，视为对之使用一张【杀】。",
	["#canyingkill2"] = "残影（杀）",
	[":canyingkill2"] = "2.任一其他角色的回合结束后，你可以弃置一个【残影标记】和一张【闪】，视为对之使用一张【杀】。",
	["@canyingkill"] = "请选择一张【闪】。",
	["@canyingkillresponse"] = "请选择一张【闪】。",
	["canyingmopai"] = "残影（摸牌）",
	[":canyingmopai"] = "3.摸牌阶段，你可以摸X张牌（X为你当前【残影标记】的数量且最多为5）。",
	["@formula"] = "残影",
	["~f91"] = "死了吗？我…",
	["designer:f91"] = "wch5621628 & Sankies & NOS7IM",
	["cv:f91"] = "西布克·亚诺",
	["illustrator:f91"] = "wch5621628",
	["susanowo"] = "SUSANOWO",
	["#susanowo"] = "须助之男",
	["ruhun"] = "入魂",
	[":ruhun"] = "任一其他角色的回合开始前，你可以摸一张牌。",
	["erdao"] = "二刀",
	[":erdao"] = "<b>锁定技</b>，当你使用一张【杀】时，你须弃置一张【杀】，否则该【杀】不能对目标造成伤害；出牌阶段，你可以使用任意数量的【杀】。",
	["#erdao2"] = "二刀",
	["@erdao"] = "请选择一张【杀】，否则该【杀】不能对目标造成伤害。",
	["designer:susanowo"] = "wch5621628 & Sankies",
	["cv:susanowo"] = "Mr.武士道",
	["illustrator:susanowo"] = "wch5621628",
	["luaqianggong"] = "强攻",
	[":luaqianggong"] = "你可以将能造成伤害的牌当具火焰伤害的牌使用；摸牌阶段，你可以额外摸一张牌。",
	["fanqin"] = "反侵",
	[":fanqin"] = "当你于回合外受到伤害时，你可以依次弃置伤害来源的两张牌。",
	["yongbing"] = "佣兵",
	[":yongbing"] = "当你造成伤害时，你可以指定任意一名其他角色为伤害来源。",
	["weijiao"] = "围剿",
	["@weijiao"] = "围剿",
	[":weijiao"] = "<b>限定技</b>，出牌阶段，你可以减一点体力上限并对任意一名其他角色造成两点伤害，若如此做，你的手牌上限+2，你可以将任意一张手牌当【酒】使用。",
	["~ARCHE"] = "",
	["#ARCHE"] = "权天使",
	["designer:ARCHE"] = "wch5621628 & Sankies",
	["cv:ARCHE"] = "阿里·阿尔·萨谢斯",
	["illustrator:ARCHE"] = "Sankies",
	["ooq"] = "00QAN[T]",
	["#ooq"] = "所期待的机体",
	["jianwu"] = "剑五",
	[":jianwu"] = "<b>锁定技</b>，当你没装备武器时，你的攻击范围视为5；你的武器手牌均视为【杀】。",
	["liuren"] = "六刃",
	["liurencard"] = "六刃",
	["liurenvs"] = "六刃",
	[":liuren"] = "每当你使用或打出一张【杀】，你可获得一个【刃标记】。\
	出牌阶段，你可以弃置六个【刃标记】并对攻击范围内的任意一名角色造成一点伤害。\
	每当你受到伤害时，你可以弃置六个【刃标记】抵消之。",
	["@ooqren"] = "刃",
	["ooqsanhong"] = "三红",
	["ooqsanhong_vs"] = "三红",
	["ooqsanhong_card"] = "三红",
	["@ooqsanhong"] = "三红",
	[":ooqsanhong"] = "<b>限定技</b>,出牌阶段,你可以额外摸3张牌,该回合可以额外使用一张杀并将你的武将牌翻面；若以此做法将武将牌翻面时受到伤害,你立即将之翻回正面。",
	["liangzi"] = "量子",
	[":liangzi"] = "<b>觉醒技</b>，回合开始阶段，若你的体力值为一，将武将牌重置并更换为【量子爆发- 00QANT】。",
	["$liangzianimate"] = "赌上人类的存亡，开始对话！",
	["ooqb"] = "00QAN[T](Quantum Burst)",
	["#ooqb"] = "量子爆发",
	["tuojia"] = "脱甲",
	[":tuojia"] = "<b>锁定技</b>，当你更换成此武将后，须弃置你的判定区所有牌并回复至两点体力；受到属性【杀】时，伤害+1。",
	["lijie"] = "理解",
	["@lijie"] = "理解",
	[":lijie"] = "出牌阶段，你可弃置一张牌并选择以下一项：\
1.观看任意一名角色的2张手牌（由该角色决定让你观看哪2张）。\
2.指定其他任意一名角色，若该角色同意，各自弃置一张手牌及回复一点体力。\
每回合限用一次。",
    ["watch"] = "观看手牌",
	["agree"] = "同意各回复1点体力",
	["disagree"] = "反对各回复1点体力",
	["baofa"] = "爆发",
	[":baofa"] = "摸牌阶段，你可以摸5-X张牌，X为你当前体力值。",
	["~ooq"] = "给我动呀，QAN[T]!",
	["~ooqb"] = "啊！！！ELS的意识。。。",
	["designer:ooq"] = "wch5621628 & Sankies",
	["cv:ooq"] = "刹那·F·塞尔",
	["illustrator:ooq"] = "wch5621628",
	["new_ooq"] = "新·00QAN[T]",
	["#new_ooq"] = "醒觉的先驱者",
	["new_jianwu"] = "新·剑五",
	[":new_jianwu"] = "若你的装备区没有武器牌，你的攻击范围为5；若你的装备区有武器牌，你可以将一张手牌的武器牌当【杀】使用或打出，你以此法使用【杀】时不计入出牌阶段内的使用次数限制。",
	["designer:new_ooq"] = "wch5621628 & Sankies",
	["cv:new_ooq"] = "刹那·F·塞尔",
	["illustrator:new_ooq"] = "Sankies",
	["harute"] = "HARUTE",
	["#harute"] = "妖天使",
	["bianxing"] = "变型",
	[":bianxing"] = "<b>锁定技</b>，【借刀杀人】对你无效；其他角色计算与你的距离时，始终+1。",
	["bianxingdistance"] = "变型（距离）",
	[":bianxingdistance"] = "（详见技能【变型】）",
	["liuyan"] = "六眼",
	[":liuyan"] = "<b>觉醒技</b>，任何時候，若你的体力值小于或等于二、装备区的牌多于或等于二，将武将牌重置并更换为【六眼的妖魔 - HARUTE】。",
	["$liuyananimate"] = "去吧！",
	["harute6"] = "HARUTE(Marut System)",
	["#harute6"] = "六眼的妖魔",
	["jiefang"] = "解放",
	[":jiefang"] = "<b>锁定技</b>，当你更换成此武将后，须摸3张牌、弃置你的判定区所有牌，并跳过下一次的摸牌阶段；你计算与其他角色的距离时，始终-1。",
	["weishan"] = "伪善",
	[":weishan"] = "当有角色进入濒死状态时，你可以弃置一张装备牌，视为对之使用一张【桃】。",
	["harute6sanhong"] = "大·三红",
	["@harute6sanhong"] = "三红",
	["harute6sanhong_vs"] = "大·三红",
	["harute6sanhong_card"] = "大·三红",
	["harute6sanhong2"] = "小·三红",
	["harute6sanhong2_vs"] = "小·三红",
	["harute6sanhong2_card"] = "小·三红",
	[":harute6sanhong"] = "<b>限定技</b>，出牌阶段，你可以弃置一张牌并视为对一名目标使用三张【杀】，然后将你的武将牌翻面。",
	[":harute6sanhong2"] = "<b>限定技</b>，出牌阶段，你可以弃置一张牌并视为对三名目标使用一张【杀】，然后将你的武将牌翻面。",
	["designer:harute"] = "wch5621628 & Sankies",
	["cv:harute"] = "哈路耶·哈帝姆",
	["illustrator:harute"] = "Sankies",
	["#RAPHAEL"] = "疗天使",
	["liepao"] = "烈炮",
	[":liepao"] = "<b>锁定技</b>，你的黑色【杀】均视为【雷杀】，你的<font color='red'>红色</font>【杀】均视为【火杀】。",
	["rpsanhong"] = "三红",
	["@rpsanhong"] = "三红",
	[":rpsanhong"] = "<b>限定技</b>，出牌阶段，可令任意角色处于【连环状态】，该回合你使用【杀】时无距离限制；可额外使用一张【杀】；然后将你的武将牌翻面。",
	["fenli"] = "分离",
	["#fenli"] = "请选择两名角色（可选自己）。",
	["##fenli"] = "请选择任意张装备牌（包括装备区）。",
	["fenshen"] = "分身",
	[":fenli"] = "<b>觉醒技</b>，有角色的体力值为一时，你须减一点体力上限，并获得至多两个装备区的所有牌，然后将你任意数量的装备牌移出游戏，称之为【分身】；有角色受到X点伤害时，你可以弃置X个【分身】抵消之。你的手牌上限为你当前体力值+【分身】数。",
	["@fenli"] = "分离",
	["zibao"] = "自爆",
	[":zibao"] = "<b>锁定技</b>，杀死你的角色失去一点体力上限。",
	["weida"] = "韦达",
	[":weida"] = "<b>锁定技</b>，你托管時拥有非一般的能力。",
	["#weida"] = "我也是可以用脑量子波的！",
	["~RAPHAEL"] = "",
	["designer:RAPHAEL"] = "wch5621628 & Sankies",
	["cv:RAPHAEL"] = "迪尼亞·艾迪",
	["illustrator:RAPHAEL"] = "wch5621628",
	["SOLBRAVES"] = "SOLBRAVES小队",
	["#SOLBRAVES"] = "未来的勇者",
	["duixing"] = "队形",
	[":duixing"] = "<b>锁定技</b>，当你的手牌数大于或等于你的体力值时，【顺手牵羊】和【过河拆桥】对你无效。",
	["solsanhong"] = "三红",
	["@solsanhong"] = "三红",
	[":solsanhong"] = "<b>限定技</b>，当你受到伤害后，你可以立即进行一个额外的回合，你在该回合跳过判定阶段，摸牌阶段额外摸一张牌，使用【杀】时无距离限制；然后将你的武将牌翻面。",
	["kaituo"] = "开拓",
	[":kaituo"] = "出牌阶段，可令一至三名角色各受到一点无伤害来源的伤害，然后让任意一名其他角色摸X张牌（X为你当前手牌数），并且让该角色进行一个额外的回合；该额外回合进行前，须把你的武将牌永久移出游戏。",
	["~SOLBRAVES"] = "",
	["designer:SOLBRAVES"] = "wch5621628 & Sankies",
	["cv:SOLBRAVES"] = "古萊哈姆·依卡",
	["illustrator:SOLBRAVES"] = "wch5621628",
	["00-RAISER"] = "00 RAISER（剧场版）",
	["#00-RAISER"] = "前代的主力",
	["jian3"] = "剑三（剧场版）",
	[":jian3"] = "<b>锁定技</b>，你的红色【杀】攻击范围视为3。",
	["kuairen"] = "快刃",
	[":kuairen"] = "当你使用的黑色【杀】被【闪】抵消时，你可以立即对相同的目标再使用一张【杀】，直到【杀】生效或你不愿意出了为止。",
	["shuangyi"] = "双翼",
	[":shuangyi"] = "<b>锁定技</b>，每位其他角色在其回合中，只能对你造成至多1点伤害。",
	["oorsanhong"] = "三红",
	["$oorsanhong"] = "回答我！你们的目的是什么？",
	[":oorsanhong"] = "<b>觉醒技</b>，任何时候，若你的体力值低于或等于三，将武将牌重置并更换为【强制对话 - 00RAISER】。",
	["~00-RAISER"] = "",
	["designer:00-RAISER"] = "wch5621628 & Sankies",
	["cv:00-RAISER"] = "刹那·F·塞尔",
	["illustrator:00-RAISER"] = "wch5621628",
	["00-RAISER2"] = "00 RAISER（剧场版.三红）",
	["#00-RAISER2"] = "强制对话",
	["xiaohao"] = "消耗",
	[":xiaohao"] = "<b>锁定技</b>，回合结束阶段，你须失去1点体力，或减1点体力上限，或弃置三张手牌。",
	["xhhp"] = "失去1点体力",
	["xhmaxhp"] = "减1点体力上限",
	["xhdis"] = "弃置三张手牌",
	["chunzhong"] = "纯种",
	["@chunzhongcard"] = "请选择一至三名角色（可选自己）。",
	["@chunzhong"] = "纯种",
	["chunzhongv"] = "纯种给牌",
	[":chunzhong"] = "弃牌阶段前，你可以指定至多三名角色的手牌上限+2；当这些角色没装备防具时，始终视为装备着【八卦阵】；这些角色在各自的出牌阶段，可以将一张手牌交给你。直到你下回合开始。",
	["sanhua"] = "散化",
	[":sanhua"] = "若你的武将牌正面朝上并受到X点伤害时，你可以弃置X张手牌抵消之；然后将你的武将牌翻面。",
	["hinu"] = "HI-ν",
	["#hinu"] = "阿宝最终座机",
	["abao"] = "阿宝",
	[":abao"] = "你可以将你的一张♠或♣牌当【雷杀】使用或打出；你以此法使用【雷杀】时无距离限制。 ",
	["ganying"] = "感应",
	[":ganying"] = "出牌阶段，当你使用一张属性【杀】时（在结算前），你可以拥有一名目标角色的一项技能，直到你的下回合开始前。每回合限用一次。（你不可拥有限定技、觉醒技或主公技）",
	["gujia"] = "骨架",
	["@gujia"] = "骨架",
	[":gujia"] = "<b>觉醒技</b>，当你处于濒死状态时，你须弃置所有的牌和你判定区里的牌，然后摸X张牌并回复X点体力（X为场上现存势力数），且获得技能<b>“霓虹”</b>(<b>锁定技</b>，所有角色不能成为<font color='red'>红色</font>【杀】或【决斗】的目标。)。",
	["nihong"] = "霓虹",
	[":nihong"] = "<b>锁定技</b>，所有角色不能成为<font color='red'>红色</font>【杀】或【决斗】的目标。",
	["~hinu"] = "什么都做不到！啊…",
	["designer:hinu"] = "wch5621628 & Sankies",
	["cv:hinu"] = "阿姆罗·雷",
	["illustrator:hinu"] = "wch5621628",
	["els"] = "ELS",
	["#els"] = "变异性金属体",
	["ronghe"] = "融合",
	[":ronghe"] = "你可以永远获得死亡角色的一项技能。（你不可获得觉醒技或主公技）",
	["qunxi"] = "群袭",	
	[":qunxi"] = "出牌阶段，你可以将一张【杀】当【万箭齐发】使用。",
	["qinshi"] = "侵蚀",
	[":qinshi"] = "每当你造成一次伤害后，可进行一次判定，若为♠或♣，你获得受到该伤害的角色一张牌。",
	["designer:els"] = "wch5621628 & Sankies",
	["cv:els"] = "ELS",
	["illustrator:els"] = "wch5621628",
	["elssmall"] = "ELS分体",
	["#elssmall"] = "金属体的分体",
	["tongzhong"] = "同种",
	[":tongzhong"] = "<b>锁定技</b>，【变异性金属体 - ELS】对你造成的伤害无效；你造成伤害时，【变异性金属体 - ELS】视为该伤害的伤害来源；你不能成为【融合】的目标。",
	["zailin"] = "再临",
	[":zailin"] = "你死亡后，【变异性金属体 - ELS】可在其出牌阶段，弃置两张相同花色或点数的手牌，然后你回到游戏并回复至两点体力。",
	["zailinv"] = "再临",
	[":zailinv"] = "出牌阶段，你可以弃置两张相同花色或点数的手牌，然后让已死亡的“分体”回到游戏并回复至两点体力。",
	["throne2"] = "THRONE ZWEI",
	["#throne2"] = "座天使二号",
	["jvren"] = "巨刃",	
	[":jvren"] = "<b>锁定技</b>，当你使用一张【杀】时，须额外弃置一张牌。",
	["jianya"] = "尖牙",
	[":jianya"] = "游戏开始前，共发你六个【尖牙标记】，你可以弃置一个【尖牙标记】当【杀】使用，若如此做，技能【巨刃】不能被触发。",
	["lua_fanji"] = "反击",	
	[":lua_fanji"] = "当你于回合外失去一张【闪】时，你摸一张牌；当你于回合外失去一张非【闪】的牌时，你获得一个【尖牙标记】。",
	["weigong"] = "围攻",	
	[":weigong"] = "<b>限定技</b>，出牌阶段，你可以弃置八个【尖牙标记】并对一名其他角色造成三点伤害。",
	["weigongcard"] = "围攻",
	["#weigong"] = "佣兵真可怕！",
	["@jianya"] = "尖牙",
	["@weigong"] = "围攻",
	["designer:throne2"] = "wch5621628 & Sankies",
	["cv:throne2"] = "阿里·阿尔·萨谢斯",
	["illustrator:throne2"] = "wch5621628",
	["sp_exia"] = "SP EXIA",
	["yuanlu"] = "原炉",
	[":yuanlu"] = "<b>锁定技</b>，若你已受伤，你的手牌上限+1。",
	["jianyi"] = "剑一",
	[":jianyi"]="当你打出或于回合外失去一张【杀】时，你可以摸一张牌。",
	["sp_exia_sanhong"] = "三红",
	[":sp_exia_sanhong"] = "<b>觉醒技</b>，当你受到使你体力值减少至一或更低的伤害时，你防止此伤害，将武将牌重置并更换为【三红始动 - EXIA】。",
	["~sp_exia"] = "给我动呀，EXIA！给我动呀，高达！",
	["~transam_exia"] = "给我动呀，EXIA！给我动呀，高达！",
	["#sp_exia"] = "七剑天使",
	["transam_exia"] = "SP EXIA(Trans-AM)",
	["#transam_exia"] = "三红始动",
	["pohuai"] = "破坏",
	["pohuaicard"] = "破坏",
	[":pohuai"] = "出牌阶段，你可以减一点体力上限并弃置一张手牌，然后对任意一名其他角色造成一点伤害。每回合限用一次。",
	["#pohuai"] = "我要破坏！",
	["niuqv"] = "扭曲",
	["niuqvVS"] = "扭曲",
	[":niuqv"] = "回合结束阶段，若你没有手牌，可指定一名其他角色并视为对之使用一张【杀】。",
	["@niuqv"] = "请选择一名其他角色。",
	["~niuqv"] = "视为对之使用一张【杀】。",
	["qijiandraw"] = "七剑",
	[":qijiandraw"] = "若要发动【七剑】，请先按此。",
	["qijian"] = "小·七剑",
	["qijiancard"] = "小·七剑",
	["qijianTS"] = "小·七剑",
	["qijian2"] = "中·七剑",
	["qijiancard2"] = "中·七剑",
	["qijianTS2"] = "中·七剑",
	["qijian3"] = "大·七剑",
	["qijiancard3"] = "大·七剑",
	["qijianTS3"] = "大·七剑",
	["@qijian"] = "七剑",
	["@qijiandraw"] = "三红",
	[":qijianTS"] = "<b>限定技</b>，出牌阶段，你摸两张牌，弃置X张牌并失去Y点体力（Y至多为2），然后对任意一名其他角色造成X+Y的一半（向下取整）伤害。",
	[":qijianTS2"] = "<b>限定技</b>，出牌阶段，你摸两张牌，弃置X张牌并失去Y点体力（Y至多为2），然后对任意一名其他角色造成X+Y的一半（向下取整）伤害。",
	[":qijianTS3"] = "<b>限定技</b>，出牌阶段，你摸两张牌，弃置X张牌并失去Y点体力（Y至多为2），然后对任意一名其他角色造成X+Y的一半（向下取整）伤害。",
	["#qijian"] = "我才是高达！",
	["#qijian2"] = "我才是高达！",
	["#qijian3"] = "我才是高达！",
	["designer:sp_exia"] = "wch5621628 & Sankies",
	["cv:sp_exia"] = "刹那·F·塞尔",
	["illustrator:sp_exia"] = "Sankies",
	["throne1"] = "THRONE EINS",
	["hongguangcard"] = "红光",
	["hongguangVS"] = "红光",
	["hongguang"] = "红光",
	["#hongguangcard"] = "若要发动技能【红光】，请按技能按钮。，",
	[":hongguang"] = "当你成为<font color='red'>红色</font>【杀】的目标时，你可以弃置一张牌，将此【杀】转移给任意一至两名其他角色（该角色不得是此【杀】的使用者）。",
	["weilu"] = "伪炉",
	["@weilu"] = "伪炉",
	[":weilu"] = "<b>锁定技</b>，任何角色在各自的回合内回复一点体力后，这些角色该回合的手牌上限-1。",
	["xianzhi"] = "限制",
	[":xianzhi"] = "<b>锁定技</b>，你的【无中生有】均视为【闪】；你不可以将【铁索连环】重铸，但可以将之当【杀】使用或打出。",
	["xianzhislash"] = "限制（杀）",
	[":xianzhislash"] = "你可以将你的一张【铁索连环】当【杀】使用或打出。",
	["#throne1"] = "座天使一号",
	["designer:throne1"] = "wch5621628 & Sankies",
	["cv:throne1"] = "约翰·崔尼提",
	["illustrator:throne1"] = "wch5621628",
	["1target"] = "若已指定了1名角色，必须按此",
	["2targets"] = "若已指定了2名角色，必须按此",
	["throne3"] = "THRONE DREI",
	["lua_zhiyuan"] = "支援",
	[":lua_zhiyuan"] = "当你使用【桃】时，你可以选择不回复体力，而是观看牌堆顶的两张牌，将其中一张交给任意一名角色，然后将另一张交给任意一名角色。",
	["jiahai"] = "加害",
	[":jiahai"]="当你使用【杀】造成一共两点或以上伤害时，你摸一张牌；你对体力值为一的角色造成伤害时，可令即将造成的伤害+1。",
	["sanbu"] = "散布",
	["sanbuFS"] = "散布",
	[":sanbuFS"] = "<b>锁定技</b>，【南蛮入侵】、【万箭齐发】、【决斗】及技能【伪炉】对你无效；你的【决斗】均视为【桃】。",
	["#throne3"] = "座天使三号",
	["designer:throne3"] = "wch5621628 & Sankies",
	["cv:throne3"] = "妮娜·崔尼提",
	["illustrator:throne3"] = "wch5621628",
	["gundam"] = "GUNDAM",
	["yuanzu"] = "元祖",
	[":yuanzu"] = "所有人都展示武将牌后、你的每个回合开始时和结束后，你可以获得一名其他角色的一项技能，直到你下一次发动“元祖”。（不可为限定技、觉醒技或主公技）",
	["$yuanzu"] = "我来让你见识一下，高达不只是白兵战用MS！",
	["~gundam"] = "可…可恶！到此为止了吗？",
	["#gundam"] = "白色恶魔",
	["designer:gundam"] = "wch5621628 & Sankies & NOS7IM",
	["cv:gundam"] = "阿姆罗·雷",
	["illustrator:gundam"] = "wch5621628",
	["zaku2"] = "CHAR's ZAKU Ⅱ",
	["sanbei"] = "三倍",
	["$sanbei"] = "见到了，我见到我的敌人了！",
	[":sanbei"] = "摸牌阶段，你可以少摸一张牌，然后展示牌堆顶的三张牌，你获得其中的<font color='red'>红色</font>牌，然后将其余的牌置入弃牌堆 。",
	["feiti"] = "飞踢",
	["$feiti"] = "真抱歉，把你踢了。",
	[":feiti"] = "当你使用<font color='red'>红色</font>【杀】指定一名角色为目标后，你可以令此【杀】不可被【闪】响应。",
	["~zaku2"] = "拉拉！",
	["#zaku2"] = "赤色彗星",
	["designer:zaku2"] = "wch5621628 & Sankies & NOS7IM",
	["cv:zaku2"] = "夏亚·阿兹纳布尔",
	["illustrator:zaku2"] = "wch5621628",
	["zeta"] = "ZETA",
	["chihun"] = "赤魂",
	[":chihun"] = "当你攻击范围内的一名角色受到一次伤害后，你可以弃置一张手牌，并进行一次判定，判定结果为：\
♠或♣：你获得该判定牌；\
<font color='red'>♥</font>：伤害来源失去1点体力；\
<font color='red'>♦</font>：该角色回复1点体力。",
    ["$chihun1"] = "我要把自己的身体借给大家！",
	["$chihun2"] = "你是不会明白，我身体所发放出的这种力量！",
	["tucicard"] = "突刺",
	["tuci"] = "突刺",
	["tuciTS"] = "突刺",
	["$tuciTS1"] = "给我消失！",
	["$tuciTS2"] = "滚回女人的身边去！",
	["$tuciTS3"] = "啊~~~~~~~",
	["@tucimain"] = "突刺",
	["@tuci"] = "已死亡角色",
	[":tuciTS"] = "<b>限定技</b>，出牌阶段，若有角色已死亡，你可以失去X点体力，并令一名其他角色减X点体力上限（X为已死亡角色的数量）。",
	["~zeta"] = "啊！！！！！！！",
	["#zeta"] = "星之继承者",
	["designer:zeta"] = "wch5621628 & Sankies & NOS7IM",
	["cv:zeta"] = "嘉美尤·维达",
	["illustrator:zeta"] = "wch5621628",
	["tho"] = "THE-O",
	["sidao"] = "四刀",
	["$sidao"] = "坠落吧！",
	[":sidao"] = "当你使用【杀】（或发动技能【霸体】）时，你可以弃置一张武器牌，令该角色不能使用（或打出）【闪】；攻击范围始终为4。",
	["@sidao"] = "请弃置一张武器牌（包括装备），令目标不能使用（或打出）【闪】",
	["bati"] = "霸体",
	["$bati"] = "咳……你…疯了吗！？",
	["@bati"] = "请弃置一张【杀】",
	["@@bati"] = "请打出一张【闪】，否则受到1点伤害、并防止你的【杀】对目标造成的伤害",
	[":bati"] = "当你受到【杀】造成的一次伤害时，你可以弃置一张【杀】，令伤害来源选择一项：打出一张【闪】，或受到1点伤害并防止该【杀】对你造成的伤害。",
	["fuhuo"] = "复活",
	["$fuhuo"] = "哼……这种程度！",
	["@fuhuo"] = "复活",
	[":fuhuo"] = "<b>觉醒技</b>，当你处于濒死状态时，你须弃置所有的牌和你判定区里的牌，然后摸三张牌，体力回复至1点，体力上限减至1，手牌上限+2，且获得技能<b>“电波”</b>（<b>限定技</b>，出牌阶段，可令所有其他角色各弃置所有的牌，然后将你的武将牌翻面。）。",
	["dianbo"] = "电波",
	["$dianbo"] = "坠落吧，电波！",
	["dianbovs"] = "电波",
	["@dianbo"] = "电波",
	[":dianbo"] = "<b>限定技</b>，出牌阶段，可令所有其他角色各弃置所有的牌，然后将你的武将牌翻面。",
	["~tho"] = "不会只是我死的…你的心我也要一起带走！",
	["#tho"] = "最灵活的胖子",
	["designer:tho"] = "wch5621628 & Sankies & NOS7IM",
	["cv:tho"] = "巴布迪斯·斯洛哥",
	["illustrator:tho"] = "NOS7IM",
	["reborns"] = "REBORNS",
	["jianong"] = "加农",
	[":jianong"] = "<b>转化技</b>，通常状态下，你拥有标记【REBORNS CANNON】并拥有技能【奋攻】和【连锁】。当你的标记翻面为【REBORNS GUNDAM】时，你须将该两项技能转化为【机动】和【再生】。任一角色的回合开始前，你可以弃置一张牌将标记翻回。",
	["@jn"] = "REBORNS CANNON",
	["@gd"] = "REBORNS GUNDAM",
	["rbsanhong"] = "三红",
	["rbsanhong_vs"] = "三红",
	["rbsanhong_card"] = "三红",
	["@rbsanhong"] = "三红",
	[":rbsanhong"] = "<b>限定技</b>，出牌阶段，你可以任意多次将标记翻面为【REBORNS CANNON】或【REBORNS GUNDAM】。",
	["fengong"] = "奋攻",
	[":fengong"] = "你可以将你的属性【杀】当普通【杀】使用，若如此做，你使用该【杀】时可以额外指定至多一个目标。",
	["liansuo"] = "连锁",
	[":liansuo"] = "出牌阶段，你可以将你的武将牌翻至背面朝上，若如此做，该回合你可以使用任意数量的【杀】。",
	["#reborns"] = "再生的存在",
	["jidong"] = "机动",
	[":jidong"] = "<b>锁定技</b>，你的武将牌始终正面朝上。",
	["zaisheng"] = "再生",
	["zaisheng_card"] = "再生",
	[":zaisheng"] = "出牌阶段，你可以弃置X张手牌，并重复展示牌堆顶的牌，其中每有一张基本牌，你将之收入手牌，其中每有一张非基本牌，你将之置入弃牌堆，直到你将X张基本牌收入手牌。每回合限用一次。",
	["designer:reborns"] = "wch5621628 & Sankies",
	["cv:reborns"] = "利邦兹·阿尔马克",
	["illustrator:reborns"] = "wch5621628",
	["$jianong1"] = "没错，这部机体才是…引导人类的高达！",
	["$jianong2"] = "再生加农！",
	["$rbsanhong1"] = "TRANS-AM……",
	["$rbsanhong2"] = "TRANS-AM！",
	["$fengong"] = "这可是傲慢！",
	["$liansuo"] = "和下等的人类一起……",
	["$zaisheng"] = "哼…哼…哼…哼……开始吧，为了所期待的未来。",
	["~reborns"] = "怎么会…难道是…难道是……",
	["nu"] = "νGUNDAM",
	["jingshen"] = "精神",
	[":jingshen"] = "当你受到一次伤害时，你可以声明伤害来源的一项技能并拥有之，你以此法拥有多于一项技能时，你须放弃所拥有的其他技能。（你不可拥有限定技、觉醒技或主公技）",
	["~nu"] = "什么都做不到！啊…",
	["#nu"] = "阿宝再现",
	["designer:nu"] = "wch5621628 & Sankies & NOS7IM",
	["cv:nu"] = "阿姆罗·雷",
	["illustrator:nu"] = "wch5621628",
	["sazabi"] = "SAZABI",
	["nixi"] = "逆袭",
	[":nixi"] = "当你受到一次伤害后，你可以弃置任意数量的<font color='red'>红色</font>手牌，然后对等量名其他角色各造成1点伤害。",
	["#nixi"] = "1.选择任意张<font color='red'>红色</font>手牌 2.选择等量名其他角色。",
	["~sazabi"] = "监视器香咗，点会甘架？",
	["#sazabi"] = "逆袭之夏亚",
	["designer:sazabi"] = "wch5621628 & Sankies & NOS7IM",
	["cv:sazabi"] = "夏亚·阿兹纳布尔",
	["illustrator:sazabi"] = "wch5621628",
	["fazz"] = "FAZZ",
	["jvpao"] = "巨炮",
	[":jvpao"] = "当你对距离最远的一名角色造成一次普通【杀】或雷电伤害时，你可令该伤害+1。",
	["feidan"] = "飞弹",
	[":feidan"] = "出牌阶段，若你已受伤，你可以将一张【闪】当【万箭齐发】使用。每回合限用X次（X为你已损失的体力值）。",
	["xiejia"] = "卸甲",
	["@xiejia"] = "卸甲",
	[":xiejia"] = "<b>觉醒技</b>，若你的体力小于或等于1，你须回复1点体力，减1点体力上限并失去技能“飞弹”，然后对一名其他角色造成1点雷电伤害。",
	["~fazz"] = "FAZZ，別掛掉啊！",
	["#fazz"] = "香格里拉之魂",
	["designer:fazz"] = "wch5621628 & Sankies & NOS7IM",
	["cv:fazz"] = "捷度·桑达",
	["illustrator:fazz"] = "wch5621628",
	["qbly"] = "QUBELEY",
	["fuyou"] = "浮游",
	["fy"] = "浮游",
	["@archery_attack"] = "【万剑齐发】请选择两张相同颜色的“浮游”",
	["@snatch"] = "【顺手牵羊】请选择两张相同颜色的“浮游”",
	["@dismantlement"] = "【过河拆桥】请选择两张相同颜色的“浮游”",
	["@collateral"] = "【借刀杀人】请选择两张相同颜色的“浮游”",
	["@ex_nihilo"] = "【无中生有】请选择两张相同颜色的“浮游”",
	["@duel"] = "【决斗】请选择两张相同颜色的“浮游”",
	["@fire_attack"] = "【火攻】请选择两张相同颜色的“浮游”",
	["@amazing_grace"] = "【五谷丰登】请选择两张相同颜色的“浮游”",
	["@savage_assault"] = "【南蛮入侵】请选择两张相同颜色的“浮游”",
	["@god_salvation"] = "【桃园结义】请选择两张相同颜色的“浮游”",
	["@iron_chain"] = "【铁索连环】请选择两张相同颜色的“浮游”",
	[":fuyou"] = "游戏开始前、当你受到1点伤害后，你可以从牌堆顶亮出两张牌置于你的武将牌上，称为“浮游”；当你需要使用一张非延时类锦囊牌时，你可以弃置两张相同颜色的“浮游”，视为你使用该锦囊牌。（“浮游”上限为六张）",
	["zihun"] = "紫魂",
	["@zihun"] = "紫魂",
	[":zihun"] = "<b>限定技</b>，当你受到一次伤害时，你可以防止该伤害，将“浮游”补至六张，然后将你的武将牌翻面。",
	["~qbly"] = "",
	["#qbly"] = "紫色女王",
	["designer:qbly"] = "wch5621628 & Sankies & NOS7IM",
	["cv:qbly"] = "哈曼·卡恩",
	["illustrator:qbly"] = "wch5621628",
	["guangdun"] = "光盾",
	["@guangdun"] = "光盾",
	[":guangdun"] = "游戏开始前、你的每个回合开始时，若你没有“光盾”标记，你可以获得1个“光盾”标记；当你受到一次伤害时，你可以弃置任意数量的“光盾”标记，然后防止等量点伤害。",
	["kuosancardf"] = "扩散",
	["kuosanx"] = "扩散",
	["kuosan"] = "扩散",
	[":kuosan"] = "<b>锁定技</b>，你使用的【杀】、【决斗】、【南蛮入侵】、【万箭齐发】和【火攻】只可指定至多2名角色为目标。",
	["guangyi"] = "光翼",
	["@guangyi"] = "光翼",
	[":guangyi"] = "<b>限定技</b>，出牌阶段，你可以获得2个“光盾”标记，你于该回合发动技能“扩散”时，可额外指定至多2名角色为目标；你的下回合开始前，你需弃置所有“光盾”标记。",
	["~V2AB"] = "",
	["#V2AB"] = "光之翼",
	["designer:V2AB"] = "wch5621628 & Sankies & NOS7IM",
	["cv:V2AB"] = "胡索·艾宾",
	["illustrator:V2AB"] = "NOS7IM",
	["shenzhang"] = "神掌",
	["shenzhang_big"] = "神掌",
	["$shenzhang"] = "GOD FINGER——！",
	["damage*1"] = "1点火焰伤害",
	["damage*3"] = "3点火焰伤害",
	[":shenzhang"] = "出牌阶段，你可以弃置一张<font color='red'>♥</font>牌或点数K的牌，然后对一名其他角色造成1点火焰伤害；或弃置一张【<font color='red'>♥K</font>】的牌，然后对一名其他角色造成3点火焰伤害。每回合限用一次。",
	["mingjing"] = "明镜",
	["$mingjing"] = "出來吧！高達——！",
	["$mingjinganimation"] = "明镜止水",
	[":mingjing"] = "<b>觉醒技</b>，若你的体力小于或等于1，体力回复至1点，距离1以内的其他角色须各弃置一张牌，然后将你的武将牌翻至正面朝上，重置之，并更换为【明镜止水 - GOD】。",
	["~GOD"] = "",
	["#GOD"] = "红心之王",
	["designer:GOD"] = "wch5621628 & Sankies & NOS7IM",
	["cv:GOD"] = "多蒙·卡修",
	["illustrator:GOD"] = "wch5621628",
	["Hyper_GOD"] = "GOD（明镜止水）",
	["zhishui"] = "止水",
	[":zhishui"] = "<b>锁定技</b>，你造成的属性伤害+1。",
	["$zhishui"] = "HEAT END！",
	["diandan"] = "电弹",
	["@diandan"] = "电弹",
	[":diandan"] = "<b>限定技</b>，出牌阶段，你可以减1点体力上限，然后令一名其他角色弃置其装备区里的所有牌。",
	["lua_shipo"] = "石破",
	["@lua_shipo"] = "石破",
	[":lua_shipo"] = "<b>限定技</b>，出牌阶段，你可以弃置两张手牌，视为依次对一名其他角色使用一张【火攻】，【过河拆桥】，【决斗】和【火杀】。",
	["~GOD"] = "输……输了？",
	["#Hyper_GOD"] = "明镜止水",
	["designer:Hyper_GOD"] = "wch5621628 & Sankies & NOS7IM",
	["cv:Hyper_GOD"] = "多蒙·卡修",
	["illustrator:Hyper_GOD"] = "wch5621628",
	["renpo"] = "刃破",
	[":renpo"] = "出牌阶段，你可以与一名其他角色拼点。若你赢，你获得该角色的X张牌（X为该角色当前体力值）。若你没赢，你须直接跳过该回合的出牌阶段。",
	["ganrao"] = "干扰",
	[":ganrao"] = "<b>锁定技</b>，当你使用【杀】时，你须弃置一张牌，或失去1点体力。",
	["glsanhong"] = "三红",
	["@glsanhong"] = "三红",
	[":glsanhong"] = "<b>觉醒技</b>，任何时候，若你的体力是全场最少的(或之一)，你须减1点体力上限，失去技能【干扰】及获得技能【奔驰】：出牌阶段，你可以失去1点体力，视为对一名目标使用一张【杀】。（此【杀】不计入每回合的使用限制）",
	["benchi"] = "奔驰",
	[":benchi"] = "出牌阶段，你可以失去1点体力，视为对一名目标使用一张【杀】。（此【杀】不计入每回合的使用限制）",
	["~GADELAZA"] = "",
	["#GADELAZA"] = "联邦的纯种",
	["designer:GADELAZA"] = "wch5621628 & Sankies",
	["cv:GADELAZA"] = "笛卡尔·沙曼",
	["illustrator:GADELAZA"] = "wch5621628",
	["#ganrao"] = "%from 的技能【%arg】被触发",
	["#glsanhong"] = "%from 的体力是全场最少的（或之一），%from 的技能【%arg】被触发",
	["ganraohp"] = "失去1点体力",
	["ganraodis"] = "弃置一张牌",
	["starooq"] = "☆SP 00QAN[T]",
	["#starooq"] = "全刃式",
	["jiansi"] = "剑四",
	[":jiansi"] = "当你对体力值大于或等于四的角色造成伤害时，可令该伤害+1。",
	["quanren"] = "全刃",
	[":quanren"] = "在你的判定牌生效前，你可以亮出牌堆顶的一张牌代替之；若这两张牌的颜色不同，你获得其中一张牌。",
	["starsanhong"] = "三红",
	["@starsanhong"] = "三红",
	[":starsanhong"] = "<b>限定技</b>，出牌阶段，你弃置一张手牌并进行一次判定，若结果为黑色，你获得此牌，你可以重复此流程，直到出现<font color='red'>红色</font>的判定结果为止；然后将你的武将牌翻面。",
	["designer:starooq"] = "wch5621628 & Sankies",
	["cv:starooq"] = "刹那·F·塞尔",
	["illustrator:starooq"] = "Sankies",
	["#MASTER"] = "东方不败",
	["anzhangbig"] = "大·暗掌",
	["@anzhangbig-card"] = "大·暗掌",
	[":anzhangbig"] = "当你受到一次属性伤害时，你可以弃置X张点数K的黑色牌，然后将此伤害转移给一名其他角色（X为即将受到的伤害）。",
	["anzhang"] = "小·暗掌",
	["@anzhang-card"] = "小·暗掌",
	[":anzhang"] = "当你受到一次属性伤害时，你可以弃置X张黑色牌防止此伤害（X为即将受到的伤害）。",
	["shijiang"] = "师匠",
	["@shijiang"] = "师匠",
	[":shijiang"] = "<b>觉醒技</b>，当你失去最后的手牌时，你须摸两张牌，然后对一名其他角色造成1点伤害。",
	["~MASTER"] = "",
	["designer:MASTER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:MASTER"] = "东方不败·MASTER ASIA",
	["illustrator:MASTER"] = "Sankies",
	["WING-ZERO-EW"] = "WING ZERO EW",
	["#WING-ZERO-EW"] = "纯白之翼",
	["feiyi"] = "飞翼",
	[":feiyi"] = "<b>锁定技</b>，若你装备区里的牌少于两张，你使用【杀】时无距离限制。",
	["shuangpao"] = "双炮",
	["shuangpaovs"] = "双炮",
	[":shuangpao"] = "出牌阶段，你可以失去1点体力，若如此做，你本回合使用【杀】时可额外指定一个目标且造成的伤害+1。每回合限用一次。",
	["lingshi"] = "零式",
	["@lingshi"] = "零式",
	[":lingshi"] = "<b>限定技</b>，当你处于濒死状态时，你可以将体力回复至全满，武将牌翻至正面朝上，弃置判定区里的牌并摸两张牌，然后进行一个额外的回合；你在该回合可以额外使用一张【杀】；你在该回合结束后死亡。",
	["~WING-ZERO-EW"] = "任务完成……自爆。",
	["designer:WING-ZERO-EW"] = "wch5621628 & Sankies & NOS7IM",
	["cv:WING-ZERO-EW"] = "希罗·尤",
	["illustrator:WING-ZERO-EW"] = "wch5621628",
	["DEATHSCYTHE-HELL-EW"] = "DEATHSCYTHE HELL EW",
	["#DEATHSCYTHE-HELL-EW"] = "月下的死神",
	["yinxing"] = "隐形",
	[":yinxing"] = "回合结束时，你可以摸一张牌，然后将武将牌翻面；当你的武将牌背面朝上时，你不能成为【杀】的目标。",
	["ansha"] = "暗杀",
	[":ansha"] = "当一名其他角色于其弃牌阶段弃置牌后，若你的武将牌背面朝上，你可以弃置一张牌并将武将牌翻至正面朝上，然后令该角色失去1点体力。",
	["~DEATHSCYTHE-HELL-EW"] = "可恶，结果还是死了。",
	["designer:DEATHSCYTHE-HELL-EW"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DEATHSCYTHE-HELL-EW"] = "迪奥·麦克斯维尔",
	["illustrator:DEATHSCYTHE-HELL-EW"] = "wch5621628",
	["HEAVYARMS-C-EW"] = "HEAVYARMS改EW",
	["#HEAVYARMS-C-EW"] = "小丑的眼泪",
	["xiaochou"] = "小丑",
	[":xiaochou"] = "<b>锁定技</b>，若你的牌数不大于体力值，你拥有技能“杂技”（当你受到一次伤害时，你可以摸一张牌。），你的武将牌始终背面朝上；当你的牌数大于体力值时，你拥有技能“速射”和“飞弹”，将武将牌翻至正面朝上，然后视为使用一张【南蛮入侵】。",
	["saoshe"] = "扫射",
	[":saoshe"] = "出牌阶段，当你使用【杀】时，你可以额外指定一名体力比你多的角色为此【杀】的目标。",
	["zaji"] = "杂技",
	[":zaji"] = "当你受到一次伤害时，你可以摸一张牌。",
	["~HEAVYARMS-C-EW"] = "开始了吗？——我的自爆装置",
	["designer:HEAVYARMS-C-EW"] = "wch5621628 & Sankies & NOS7IM",
	["cv:HEAVYARMS-C-EW"] = "多洛华·巴顿",
	["illustrator:HEAVYARMS-C-EW"] = "wch5621628",
	["SANDROCK-C-EW"] = "SANDROCK改EW",
	["#SANDROCK-C-EW"] = "沙漠的双镰",
	["shuanglian"] = "双镰",
	["@shuanglian"] = "请打出一张【闪】，否则受到1点伤害。",
	[":shuanglian"] = "当你使用【杀】时，你可以弃置一张手牌，令攻击范围内的一名其他角色打出一张【闪】，否则你对之造成1点伤害；当你使用（或打出）【闪】时，你可以将武将牌翻面，视为对一个目标使用一张【杀】。",
	["~SANDROCK-C-EW"] = "",
	["designer:SANDROCK-C-EW"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SANDROCK-C-EW"] = "卡托鲁·拉贝巴·温纳",
	["illustrator:SANDROCK-C-EW"] = "wch5621628",
	["ALTRON-EW"] = "ALTRON EW",
	["#ALTRON-EW"] = "哪咤之魂",
	["shuanglong"] = "双龙",
	[":shuanglong"] = "出牌阶段，你可以与一名其他角色拼点。若你赢，你与该角色的距离始终视为1；你无视该角色的防具；你对该角色使用【杀】时无次数限制。直到回合结束。若你没赢，你可以将场上的一张装备牌置于一名角色的装备区里；你跳过该回合的弃牌阶段。每回合限用一次。",
	["~ALTRON-EW"] = "",
	["designer:ALTRON-EW"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ALTRON-EW"] = "张五飞",
	["illustrator:ALTRON-EW"] = "wch5621628",
	["#DX"] = "月色下的恶魔",
	["yueguang"] = "月光",
	[":yueguang"] = "<b>锁定技</b>，回合开始时，你须进行一次判定，若判定结果为黑色，你获得1个“月”标记，若判定结果为红色，你失去1个“月”标记。（“月”标记上限为2个）",
	["@yue"] = "月",
	["weibo"] = "微波",
	[":weibo"] = "出牌阶段，你可以弃置1个“月”标记，令你本回合使用的下一张【杀】造成的伤害+1。",
	["weixing"] = "卫星",
	[":weixing"] = "<b>限定技</b>，出牌阶段，你可以将你的武将牌翻面并将“月”标记补至2个，令你下一次造成的伤害+1。",
	["@weixing"] = "卫星",
	["~DX"] = "",
	["designer:DX"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DX"] = "卡洛德·兰",
	["illustrator:DX"] = "wch5621628",
	["VIRSAGO-CB"] = "VIRSAGO CB",
	["#VIRSAGO-CB"] = "凶暴的赤兽",
	["emo"] = "恶魔",
	[":emo"] = "<b>锁定技</b>，你不能使用或打出手牌的【杀】或【闪】。",
	["liekong"] = "裂空",
	["liekongvs"] = "裂空",
	[":liekong"] = "当你需要使用或打出一张【杀】或【闪】时，你可以失去1点体力，视为你使用或打出之；出牌阶段结束时，你可以展示所有手牌，其中每有一张【杀】或【闪】，你弃置之并选择一项：回复1点体力，或摸一张牌。",
	["lkdraw"] = "摸一张牌",
	["recover"] = "回复1点体力",
	["~VIRSAGO-CB"] = "",
	["designer:VIRSAGO-CB"] = "wch5621628 & Sankies & NOS7IM",
	["cv:VIRSAGO-CB"] = "夏基亚·弗罗斯特",
	["illustrator:VIRSAGO-CB"] = "wch5621628",
	["CROSSBONE-X1"] = "CROSSBONE X1",
	["#CROSSBONE-X1"] = "新十字先锋",
	["haidao"] = "海盗",
	["haidaot"] = "海盗",
	[":haidao"] = "出牌阶段，你可以按下列规则各弃置一张牌：\
>武器牌+【铁索连环】：距离X+1以内的所有其他角色进入“连环状态”，视为你依次对其各使用一张具雷电伤害的【杀】。\
>防具牌+【杀】：距离X+1以内的所有角色各失去或回复1点体力。\
>坐骑牌+【闪】：你获得距离X+1以内的所有其他角色各一张牌。\
>基本牌+锦囊牌：你摸X+1张牌。\
（X为你已损失的体力值）",
	["pifeng"] = "披风",
	[":pifeng"] = "<b>锁定技</b>，若你的装备区没有防具，你防止你受到的属性伤害，累计防止的伤害多于3点后，你失去此技能。",
	["~CROSSBONE-X1"] = "",
	["designer:CROSSBONE-X1"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CROSSBONE-X1"] = "金凯杜·那乌",
	["illustrator:CROSSBONE-X1"] = "wch5621628",
	["CROSSBONE-X2"] = "CROSSBONE X2",
	["#CROSSBONE-X2"] = "反乱的骑士",
	["heiying"] = "黑影",
	[":heiying"] = "当你使用黑色牌对一名其他角色造成一次伤害时，你可以防止此伤害并将其武将牌翻面；当你受到一次伤害后，你可以展示牌堆顶的X+2张牌，将其中的黑色牌以任意方式交给任意角色，其余的牌置入弃牌堆。（X为你已损失的体力值）",
	["~CROSSBONE-X2"] = "",
	["designer:CROSSBONE-X2"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CROSSBONE-X2"] = "萨比尼·沙路",
	["illustrator:CROSSBONE-X2"] = "wch5621628",
	["#X1FC"] = "钢铁之骷髅",
	["kuangdao"] = "狂刀",
	[":kuangdao"] = "出牌阶段限一次，你可以将一至四张手牌当【杀】使用，其中若有：\
>基本牌：你可以摸一张牌。\
>装备牌：你可以弃置目标角色的一张手牌。\
>延时类锦囊牌：你可以额外指定一个目标。\
>非延时类锦囊牌：你无视目标角色的防具。",
	["pijia"] = "披甲",
	[":pijia"] = "<b>锁定技</b>，若你的装备区没有防具，你防止黑色牌对你造成的伤害，累计防止的伤害多于3点后，你失去此技能。",
	["~X1FC"] = "",
	["designer:X1FC"] = "wch5621628 & Sankies & NOS7IM",
	["cv:X1FC"] = "托比亚·阿罗纳克斯",
	["illustrator:X1FC"] = "wch5621628",
	["#pifeng"] = "%from 的技能【%arg】被触发，防止 %arg2 点属性伤害",
	["#pijia"] = "%from 的技能【%arg】被触发，防止 %arg2 点黑色牌造成的伤害",
	["GINN"] = "MIGUEL's GINN",
	["#GINN"] = "黄昏的魔弹",
	["laobing"] = "老兵",
	[":laobing"] = "当你进行判定前，你可以声明一种花色，若该次判定牌的花色与你声明的相同，你可以回复1点体力并重新进行判定；若花色不同，你获得判定牌。",
	["baopo"] = "爆破",
	[":baopo"] = "当你使用【杀】对目标角色造成一次伤害后，你可以弃置一张牌，然后弃置其装备区里的一张牌。",
	["~GINN"] = "",
	["designer:GINN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:GINN"] = "米基尔·艾曼",
	["illustrator:GINN"] = "Sankies",
	["#BUCUE"] = "地之猎犬",
	["dizhan"] = "地战",
	[":dizhan"] = "<b>锁定技</b>，若你的体力值大于手牌数，当其他角色计算与你的距离时，始终为2。",
	["qunshou"] = "群兽",
	[":qunshou"] = "当你成为【顺手牵羊】的目标时，你可以令此牌视为【过河拆桥】。",
	["~BUCUE"] = "",
	["designer:BUCUE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BUCUE"] = "安德鲁·巴尔特菲尔德",
	["illustrator:BUCUE"] = "Sankies",
	["#ZNO"] = "水之妖魔",
	["shuizhan"] = "水战",
	[":shuizhan"] = "<b>锁定技</b>，你造成的伤害均视为无伤害来源；当你的武将牌翻至正面朝上时，视为对一名其他角色使用一张红色的【杀】。",
	["qianfu"] = "潜伏",
	[":qianfu"] = "出牌阶段结束时，你可以摸一张牌并将你的武将牌翻面，若如此做，你跳过此回合的弃牌阶段；直到你的下回合开始时，你受到的雷电伤害+1。",
	["~ZNO"] = "",
	["designer:ZNO"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ZNO"] = "马可·摩拉西姆",
	["illustrator:ZNO"] = "Sankies",
	["#STRIKE"] = "觉醒的利刃",
	["huanzhuang"] = "换装",
	[":huanzhuang"] = "回合开始阶段开始时，你可以进行一次判定，你可以获得相应技能直到回合结束：\
>黑色：你使用【杀】造成的伤害+1、被目标角色的【闪】抵消时，该角色可以弃置你的一张手牌。\
>红色：当你计算与其他角色的距离时，始终-1。\
>不判定：回合结束阶段开始时，你摸一张牌。",
	["xiangzhuan"] = "相转",
	[":xiangzhuan"] = "当你受到黑色【杀】造成的伤害时，你可以弃置一张手牌防止此伤害。",
	["~STRIKE"] = "",
	["designer:STRIKE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STRIKE"] = "基拉·大和",
	["illustrator:STRIKE"] = "Sankies",
	["#AEGIS"] = "青之旧友",
	["jiechi"] = "劫持",
	[":jiechi"] = "出牌阶段，你可以弃置一张手牌，然后弃置一名其他角色装备区里的一张牌。",
    ["juexin"] = "决心",
	["@juexin"] = "决心",
	[":juexin"] = "<b>限定技</b>，出牌阶段，你可以弃置所有手牌并指定一名其他角色，该角色于其回合开始前进行一次判定，若不为♠，该角色失去2点体力，然后你死亡。",
    ["~AEGIS"] = "",
	["designer:AEGIS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:AEGIS"] = "亚斯兰·察拉",
	["illustrator:AEGIS"] = "wch5621628",
	["#BUSTER"] = "决意的炮火",
	["shuangqiang"] = "双枪",
	["shuangqiang1"] = "双枪",
	["shuangqiang2"] = "双枪",
	[":shuangqiang"] = "出牌阶段，你可以将一张装备牌或锦囊牌当【杀】使用，对目标角色造成伤害后：若为前者，你弃置其装备区里的一张牌；后者，你获得其一张手牌。",
    ["zuzhuang"] = "组装",
	["zuzhuang1"] = "组装",
	["zuzhuang2"] = "组装",
	[":zuzhuang"] = "出牌阶段，你可以先打出装备牌后打出锦囊牌、或先打出锦囊牌后打出装备牌，当【杀】使用，对目标角色造成伤害后：若为前者，你弃置其装备区里的所有牌；后者，你弃置其所有手牌。",
    ["~BUSTER"] = "",
	["designer:BUSTER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BUSTER"] = "迪亚卡·艾尔斯曼",
	["illustrator:BUSTER"] = "wch5621628",
	["#DUEL"] = "战意的疤痕",
	["sijue"] = "死决",
	[":sijue"] = "出牌阶段，你可以将一张黑色基本牌当【决斗】使用，你以此法指定一名角色为目标后，该角色摸一张牌。",
    ["pojia"] = "破甲",
	["@pojia"] = "破甲",
	[":pojia"] = "<b>限定技</b>，当你受到伤害后，你可以弃置你装备区里的所有牌（至少一张），视为对伤害来源使用两张【决斗】，并防止此【决斗】对你造成的伤害。",
    ["~DUEL"] = "",
	["designer:DUEL"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DUEL"] = "伊撒古·玖尔",
	["illustrator:DUEL"] = "wch5621628",
	["#BLITZ"] = "消失的高达",
	["shenlou"] = "蜃楼",
	[":shenlou"] = "当你使用或打出一张【闪】时，你可以令你下一张使用的【杀】具雷电伤害且不可被【闪】响应。",
    ["zhuanjin"] = "转进",
	["@zhuanjin"] = "转进",
	[":zhuanjin"] = "<b>限定技</b>，当一名其他角色处于濒死状态时，你可以令其体力回复至1点并摸X张牌（X为你与其已损失的体力值和），然后视为伤害来源对你使用一张【杀】。",
    ["~BLITZ"] = "",
	["designer:BLITZ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLITZ"] = "尼哥路·阿玛菲",
	["illustrator:BLITZ"] = "wch5621628",
	["M1-ASTRAY"] = "M1 ASTRAY",
	["#M1-ASTRAY"] = "中立的理念",
	["yiduan"] = "异端",
	["$$yiduan"] = "请选择两张不同花色的手牌。",
	[":yiduan"] = "你可以将两张不同花色的手牌当【闪】、【酒】或【决斗】使用或打出。",
    ["aobu"] = "奥布",
	[":aobu"] = "<b>锁定技</b>，你使用【杀】时不可指定未曾对你造成伤害的角色为目标；当一名其他角色首次对你造成伤害后，该角色须失去1点体力。",
    ["~M1-ASTRAY"] = "",
	["designer:M1-ASTRAY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:M1-ASTRAY"] = "茱莉·吴·尼恩&亚沙琪·考德威尔&玛尤拉·拉巴托",
	["illustrator:M1-ASTRAY"] = "Sankies",
	["STRIKE-IWSP"] = "STRIKE[IWSP]",
	["#STRIKE-IWSP"] = "完整之强袭",
	["zhuangjia"] = "装甲",
	["@jia"] = "甲",
	[":zhuangjia"] = "游戏开始前，你获得4个“甲”标记；出牌阶段，你可以弃置1个“甲”标记，令你本回合下一张使用的【杀】具火焰伤害且无距离限制；当你受到一次普通伤害时，你可以弃置1个“甲”标记防止此伤害。",
    ["jiandao"] = "舰刀",
	[":jiandao"] = "当你使用【杀】对装备区有防具牌的目标角色造成一次伤害时，你可以令此伤害+1。",
	["xiaoren"] = "小刃",
	[":xiaoren"] = "出牌阶段，你可以弃置所有“甲”标记，然后对攻击范围内的一名其他角色造成1点伤害。",
    ["~STRIKE-IWSP"] = "",
	["designer:STRIKE-IWSP"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STRIKE-IWSP"] = "基拉·大和",
	["illustrator:STRIKE-IWSP"] = "Sankies",	
	["freedom"] = "FREEDOM",
	["helie"] = "核裂",
	[":helie"] = "出牌阶段开始和结束时，你可以弃置所有手牌，然后摸等同于你体力上限的牌。",
	["$helie"] = "这机体的能量很不寻常，难道是……核能？",
	["jiaoxie"] = "缴械",
	[":jiaoxie"] = "当你使一名其他角色进入濒死状态、或一名其他角色使你进入濒死状态时，你可以令其失去一项技能（不可为限定技、觉醒技或转化技）。",
	["$jiaoxie"] = "想找死么？",
	["zhongzi"] = "种子",
	["@seed"] = "SEED",
	[":zhongzi"] = "<b>觉醒技</b>，当你处于濒死状态求桃完毕后，你须将体力回复至2点，然后失去技能“缴械”。",
	["$zhongzi"] = "SEED……",
	["~freedom"] = "对不起…拉克丝，珍贵的机体…我…保不住了……",
	["#freedom"] = "自由之翼",
	["designer:freedom"] = "wch5621628 & Sankies & NOS7IM",
	["cv:freedom"] = "基拉·大和",
	["illustrator:freedom"] = "Sankies",
	["shouwang"] = "守望",
	[":shouwang"] = "当你需要使用一张【桃】时，你可以减1点体力上限，视为你使用之。",
	["huixuan"] = "回旋",
	["hxthrow"] = "依次弃置其装备区里的两张牌",
	["hxreturn"] = "获得此【杀】",
	[":huixuan"] = "当你使用的<font color='red'>红色</font>【杀】被目标角色的【闪】抵消时，你可以依次弃置其装备区里的两张牌、或获得此【杀】。",
	["~JUSTICE"] = "",
	["#JUSTICE"] = "正义之剑",
	["designer:JUSTICE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:JUSTICE"] = "亚斯兰·察拉",
	["illustrator:JUSTICE"] = "Sankies",
	["wenshen"] = "瘟神",
	[":wenshen"] = "你可以将一张装备牌当【酒】或【杀】使用。",
	["$wenshen"] = "请选择一张装备牌（包括装备区）",
	["jinduan"] = "禁断",
	[":jinduan"] = "当其他角色使用<font color='red'>红色</font>牌指定你为目标时，你可以将此牌转移给一名其他角色。",
	["liesha"] = "猎杀",
	[":liesha"] = "当你使用一张【杀】时，你可以摸一张牌。",
	["~CFR"] = "",
	["CFR"] = "瘟神x禁断x猎杀",
	["#CFR"] = "恶之三兵器",
	["designer:CFR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CFR"] = "奥尔加·萨布纳克&夏尼·安德拉斯&古朗度·布路",
	["illustrator:CFR"] = "Sankies",
	["longqi"] = "龙骑",
	["@@longqi"] = "请选择一张【杀】，然后选择一名其他角色。",
	[":longqi"] = "当你使用或打出一张【闪】后，你可以对一名其他角色使用一张【杀】。",
    ["chuangshi"] = "创世",
	[":chuangshi"] = "<b>锁定技</b>，当你受到一次即将使你进入濒死状态的伤害时，你须对伤害来源造成等量伤害，然后你减1点体力上限。",
	["~PROVIDENCE"] = "",
	["#PROVIDENCE"] = "终末之光",
	["designer:PROVIDENCE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:PROVIDENCE"] = "劳·鲁·克鲁泽",
	["illustrator:PROVIDENCE"] = "wch5621628",
	["hundun"] = "混沌",
	[":hundun"] = "当你的武将牌翻至正面朝上时，你可以视为对任意多名距离1以内的其他角色使用一张【杀】。",
	["$$hundun"] = "请选择任意多名距离1以内的其他角色。",
	["shenyuan"] = "深渊",
	[":shenyuan"] = "当你受到一次<font color='red'>红色</font>牌造成的伤害时，你可以将你的武将牌翻面，然后防止此伤害。",
	["#shenyuan"] = "%from 发动技能【%arg】，防止 %arg2 点<font color='red'>红色</font>牌造成的伤害",
	["dadi"] = "大地",
	[":dadi"] = "<b>锁定技</b>，当一名其他角色死亡时，你须将你的武将牌翻面；杀死你的角色须将其武将牌翻面。",
	["~CAG"] = "",
	["CAG"] = "混沌x深渊x大地",
	["#CAG"] = "妖气的微笑",
	["designer:CAG"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CAG"] = "史汀·奥古利&奥尔·尼达&史汀娜·露茜",
	["illustrator:CAG"] = "wch5621628",
	["zhongcheng"] = "忠诚",
	[":zhongcheng"] = "当你受到一次伤害后，你可以弃置伤害来源的装备区里的所有牌。",
	["~SAVIOUR"] = "",
	["#SAVIOUR"] = "忠诚的回归",
	["designer:SAVIOUR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SAVIOUR"] = "亚斯兰·察拉",
	["illustrator:SAVIOUR"] = "wch5621628",
	["daohe"] = "氘核",
	[":daohe"] = "回合开始阶段开始时，你可获得以下一项效果直到回合结束：\
>><b><font color='blue'>魅影</font></b>：你的攻击范围+1；当你使用一张【杀】后没有造成伤害，你可以额外使用一张【杀】。\
>><b><font color='red'>剑影</font></b>：你的攻击范围+1；当你使用一张【杀】后没有造成伤害，你可以摸一张牌。\
>><b><font color='green'>疾影</font></b>：当你使用一张【杀】造成即将使目标角色进入濒死状态的伤害时，你可以令此伤害+1。",
	["#meiying"] = "魅影",
	["@meiying"] = "魅影",
	[":#meiying"] = "你的攻击范围+1；当你使用一张【杀】后没有造成伤害，你可以额外使用一张【杀】。",
	["#jianying"] = "剑影",
	["@jianying"] = "剑影",
	[":#jianying"] = "你的攻击范围+1；当你使用一张【杀】后没有造成伤害，你可以摸一张牌。",
	["#jiying"] = "疾影",
	["@jiying"] = "疾影",
	[":#jiying"] = "当你使用一张【杀】造成即将使目标角色进入濒死状态的伤害时，你可以令此伤害+1。",
	["emeng"] = "恶梦",
	["@emeng"] = "恶梦",
	[":emeng"] = "<b>觉醒技</b>，当你受到一次由你攻击范围外的角色使用【杀】造成的伤害后，将技能<b>“氘核”</b>改为<b>“你可以获得以下两项效果”</b>。",
	["~IMPULSE"] = "",
	["#IMPULSE"] = "新生之鸟",
	["designer:IMPULSE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IMPULSE"] = "真·飞鸟",
	["illustrator:IMPULSE"] = "Sankies",
	["FREEDOM-D"] = "FREEDOM（乱战）",
	["xinnian"] = "信念",
	[":xinnian"] = "<b>锁定技</b>，你的回合内，所有其他角色失去所有非觉醒技的技能；当你受到一次伤害时，你须失去1点体力防止此伤害。",
	["luanzhan"] = "乱战",
	["@luanzhan"] = "乱战",
	[":luanzhan"] = "<b>觉醒技</b>，当一名其他角色处于濒死状态时，你须减1点体力上限，然后获得技能“守望”。",
	["~FREEDOM-D"] = "",
	["#FREEDOM-D"] = "甦醒之翼",
	["designer:FREEDOM-D"] = "wch5621628 & Sankies & NOS7IM",
	["cv:FREEDOM-D"] = "基拉·大和",
	["illustrator:FREEDOM-D"] = "Sankies",
	["huohai"] = "火海",
	[":huohai"] = "当一名其他角色使用一张【桃】时，你可以令其弃置一张手牌。",
	["tiebi"] = "铁壁",
	[":tiebi"] = "当你成为一名角色使用的<font color='red'>红色</font>牌的目标时，若其为距离1以外的角色，你可以令此牌对你无效。",
	["#tiebi"] = "%from 的技能【%arg】被触发，<font color='red'>红色</font>的 %arg2 对你无效",
	["kongjv"] = "恐惧",
	["@kongjv"] = "恐惧",
	[":kongjv"] = "<b>觉醒技</b>，当一名角色被其他角色杀死后，所有角色须弃置两张牌，然后你失去技能<b>“铁壁”</b>。",
	["~DESTROY"] = "",
	["#DESTROY"] = "未明之夜",
	["designer:DESTROY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DESTROY"] = "史汀娜·露茜",
	["illustrator:DESTROY"] = "wch5621628",
	["bachi"] = "八呎",
	["##bachi"] = "请选择一张牌，然后选择一至两名其他角色",
	[":bachi"] = "当你成为<font color='red'>红色</font>牌的目标时，你可以弃置一张牌将此牌转移给一至两名其他角色。",
	["buqin"] = "不侵",
	["@buqinslash"] = "请打出一张【杀】",
	["@buqinjink"] = "请打出一张【闪】",
	[":buqin"] = "当你攻击范围内的一名角色需要使用或打出一张【杀】或【闪】时，你可以替之打出。",
	["~AKATSUKI"] = "",
	["#AKATSUKI"] = "黄金的意志",
	["designer:AKATSUKI"] = "wch5621628 & Sankies & NOS7IM",
	["cv:AKATSUKI"] = "穆·拉·弗拉加",
	["illustrator:AKATSUKI"] = "wch5621628",
	["SF"] = "STRIKE FREEDOM",
	["#SF"] = "黄金之翼",
	["ziyou"] = "自由",
	[":ziyou"] = "<b>锁定技</b>，若你有手牌，你防止非牌对你造成的伤害。",
	["#ziyou"] = "%from 的技能【%arg】被触发，防止 %arg2 点技能伤害",
    ["daijin"] = "殆烬",
	[":daijin"] = "(请从<font color='red'><b>逆时针</b></font>顺序选择目标，否则会有BUG)\
出牌阶段限一次，你可以弃置任意数量的牌，令等量名其他角色各失去一项技能（不可为限定技、觉醒技或转化技），直到你的下回合开始前。",
    ["chaoqi"] = "超骑",
	[":chaoqi"] = "当你成为【杀】的目标后，你可以摸一张牌并展示之，你可以使用之且无距离限制。",
	["~SF"] = "",
	["designer:SF"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SF"] = "基拉·大和",
	["illustrator:SF"] = "Sankies",
	["IJ"] = "∞JUSTICE",
	["#IJ"] = "白银之剑",
	["zhengyi"] = "正义",
	[":zhengyi"] = "<b>锁定技</b>，若你的装备区里有牌，你防止非牌对你造成的伤害。",
    ["hanwei"] = "捍卫",
	[":hanwei"] = "出牌阶段，你可以弃置一张手牌，将场上的一张装备牌置于一名角色的装备区里。",
    ["shijiu"] = "狮鹫",
	[":shijiu"] = "其他角色的出牌阶段限一次、 其他角色的回合外，当其失去手牌时，你可以观看牌堆顶的一张牌，然后交给一名角色。",
	["~IJ"] = "",
	["designer:IJ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IJ"] = "亚斯兰·察拉",
	["illustrator:IJ"] = "Sankies",
	["#DESTINY"] = "明日的业火",
	["huanyi"] = "幻翼",
	[":huanyi"] = "回合结束阶段开始时，你可以进行一次判定，若为<font color='red'>红色</font>，你防止非【杀】对你造成的伤害，直到你的下回合开始前。",
	["#huanyi"] = "%from 的技能【%arg】被触发，防止 %arg2 点非【杀】造成的伤害",
    ["feiniao"] = "飞鸟",
	[":feiniao"] = "当你成为【杀】的目标时，你可以弃置X-1张牌（X为你当前体力值），然后摸等同于对方体力值的牌。",
    ["nuhuo"] = "怒火",
	["@nuhuo"] = "怒火",
	[":nuhuo"] = "<b>觉醒技</b>，回合开始阶段开始时，若你距离1以内没有其他角色，你获得效果<font color='red'><b>“剑影”</b></font>，且你下一次造成的伤害+1。",
	["~DESTINY"] = "",
	["designer:DESTINY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DESTINY"] = "真·飛鳥",
	["illustrator:DESTINY"] = "wch5621628",
	["NOIR"] = "STRIKE NOIR",
	["huantong"] = "幻痛",
	[":huantong"] = "<b>锁定技</b>，当你使一名其他角色进入濒死状态时，其立即死亡。你的【桃】均视为【铁索连环】。",
	["jianmie"] = "歼灭",
	[":jianmie"] = "你可以将一张普通【杀】当火【杀】使用且无距离限制、可额外指定多名没有手牌的角色为目标。当你使用【火攻】对一名角色造成伤害结算后，可对与其距离最近的另一名角色造成等量火焰伤害。",
	["~NOIR"] = "",
	["#NOIR"] = "幻痛之袭",
	["designer:NOIR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:NOIR"] = "史威恩·卡尔·巴亚",
	["illustrator:NOIR"] = "wch5621628",
	["xinghuan"] = "星环",
	[":xinghuan"] = "当你使用或打出一张【闪】时，你可以摸一张牌；当一名角色对你使用一张【杀】后，你可以获得此【杀】。",
	["guanghui"] = "光辉",
	[":guanghui"] = "准备阶段开始时，你可发动<b>“观星”</b>并跳过摸牌阶段，本回合：你的【杀】可额外指定一个目标，若你未使用过【杀】，你于出牌阶段结束时摸两张牌。",
	["~STARGAZER"] = "",
	["#STARGAZER"] = "光辉传递者",
	["designer:STARGAZER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STARGAZER"] = "赛雷妮·马克古里夫&索尔·琉尼·兰裘",
	["illustrator:STARGAZER"] = "wch5621628",
	["RED"] = "ASTRAY RED",
	["jianhun"] = "剑魂",
	["hun"] = "魂",
	[":jianhun"] = "出牌阶段限一次，你可以将一张<font color='red'>红色</font>牌置于一名角色的武将牌上，称为<b><font color='red'>“魂”</font></b>，你的下回合开始时，将<b><font color='red'>“魂”</font></b>置入弃牌堆；当拥有<b><font color='red'>“魂”</font></b>的角色造成一次伤害时，将<b><font color='red'>“魂”</font></b>置于牌堆顶，此伤害+1。",
	["huishou"] = "回收",
	[":huishou"] = "若其他角色使用的【杀】或【决斗】在结算后置入弃牌堆，你可以获得之；出牌阶段，若一名其他角色拥有<b><font color='red'>“魂”</font></b>，你可以获得其装备区里的武器牌。",
	["~RED"] = "",
	["#RED"] = "回收屋的斗志",
	["designer:RED"] = "wch5621628 & Sankies & NOS7IM",
	["cv:RED"] = "罗·裘尔",
	["illustrator:RED"] = "wch5621628",
	["BLUE"] = "ASTRAY BLUE",
	["qiangwu"] = "强武",
	[":qiangwu"] = "当你造成1点伤害后，你可以摸两张牌，然后弃置一张牌。",
	["shewei"] = "蛇尾",
	["#shewei"] = "请选择一张牌当【决斗】使用。",
	[":shewei"] = "准备阶段开始时，你可以将你的装备区或判定区里的一张牌当【决斗】使用，你以此法对目标角色使用【决斗】时，其须连续打出两张【杀】。",
	["~BLUE"] = "",
	["#BLUE"] = "最强的佣兵",
	["designer:BLUE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLUE"] = "叢雲·劾",
	["illustrator:BLUE"] = "wch5621628",
	["shenshou"] = "神兽",
	[":shenshou"] = "当你使用一张红色的【杀】指定一名角色为目标后，你可以令其交给你一张<font color='red'>红色</font>牌，否则此【杀】不可被【闪】响应。",
	["@@shenshou"] = "请交给对方一张<font color='red'>红色</font>牌，否则此【杀】不可被【闪】响应。",
	[":NTD"] = "<b>觉醒技</b>，当你成为一张非延时类锦囊牌的目标时，若你的体力不多于2，你须减1点体力上限终止此牌结算，展示你当前手牌，其中每有一张<font color='red'>红色</font>牌，你回复1点体力或摸一张牌，并获得技能<b>“毁灭”</b>（当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'>红色</font>手牌终止此牌结算，并视为你使用此牌）。",
	["huimie"] = "毁灭",
	[":huimie"] = "当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'>红色</font>手牌终止此牌结算，并视为你使用此牌。",
	["@NTD"] = "NTD",
	["$shenshou"] = "（Beam Magnum）",
	["$NTD"] = "（NTD Activated）",
	["$huimie"] = "高达，借给我力量！",
	["~UNICORN"] = "对不起……奥黛莉",
	["#UNICORN"] = "可能性之兽",
	["designer:UNICORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:UNICORN"] = "巴纳吉·林克斯",
	["illustrator:UNICORN"] = "wch5621628",
	["jiqi"] = "极骑",
	[":jiqi"] = "当你成为【杀】的目标时，你可以弃置X张【杀】，然后展示牌堆顶和牌堆底的各2X张牌，你获得其中的基本牌，其余的牌置入弃牌堆；当一名角色对你使用一张【杀】后，你可以对其使用一张【杀】。",
	["#jiqi"] = "请弃置任意张【杀】。",
	["##jiqi"] = "请使用一张【杀】。",
	["kelong"] = "克隆",
	[":kelong"] = "当你处于濒死状态时，你可以令伤害来源将其武将牌翻面，伤害结算后，其受到等量点伤害。",
	["$jiqi1"] = "敌人…由我来击落。",
	["$jiqi2"] = "这不是闹玩的，快消失吧。",
	["$kelong1"] = "向不断战斗的历史休止符开枪，我……",
	["$kelong2"] = "怎能让你们为所欲为！",
	["~LEGEND"] = "啊————",
	["#LEGEND"] = "最后之力",
	["designer:LEGEND"] = "wch5621628 & Sankies & NOS7IM",
	["cv:LEGEND"] = "雷·札·巴雷尔",
	["illustrator:LEGEND"] = "Sankies",
	["jixian"] = "极限",
	[":jixian"] = "<b>锁定技</b>，当你造成或受到1点伤害后，你须摸一张牌并获得1个<font color='red'><b>“极”</b></font>标记。",
	["@ex"] = "<b><font color='red'>極</font></b>",
	["jinhua"] = "进化",
	["#jinhua1"] = "%from 进化为<b><font color='red'>“月蚀</font><font color='orange'>面 - ECLI</font><font color='red'>PSE-F”</font></b>",
	["#jinhua2"] = "%from 进化为<b><font color='red'>“异化</font><font color='orange'>面 - XEN</font><font color='red'>ON-F”</font></b>",
	["#jinhua3"] = "%from 进化为<b><font color='red'>“神圣</font><font color='orange'>面 - AIO</font><font color='red'>S-F”</font></b>",
	["@jinhua"] = "<b><font color='red'>極</font><font color='orange'>限進</font><font color='red'>化</font></b>",
	[":jinhua"] = "<b>觉醒技</b>，当你的<font color='red'><b>“极”</b></font>标记数量达到体力上限时，你须进行一次判定并将形态进化，若点数为：\
A~5：<b><font color='red'>“月蚀</font><font color='orange'>面 - ECLI</font><font color='red'>PSE-F”</font></b>\
（距离最远的角色进入“连环状态”）\
6~9：<b><font color='red'>“异化</font><font color='orange'>面 - XEN</font><font color='red'>ON-F”</font></b>\
（距离最近的其他角色各弃置一张牌）\
10~K：<b><font color='red'>“神圣</font><font color='orange'>面 - AIO</font><font color='red'>S-F”</font></b>\
（体力最多的其他角色展示所有手牌）",
	["$jixian1"] = "信じられんほどスキだらけだ！",
	["$jixian2"] = "GAデータは頭に入っているんだ！",
	["$jixian3"] = "ああああぁぁぁあ！",
	["$jixian4"] = "くっそぉおおお！",
	["$jinhua1"] = "進化発動。応えて見せろ、エクリプス·フェース…！",
	["$jinhua2"] = "エクリプス·フェース！",
	["$jinhua3"] = "これぞ…射撃進化の極限…",
	["$jinhua4"] = "格闘進化ァ！天地を引き裂け！ゼノン·フェースゥゥゥゥゥゥゥゥ！！",
	["$jinhua5"] = "来ォォォォい！ゼノン·フェースゥゥゥゥゥゥ！！",
	["$jinhua6"] = "ゼノン·フェース！",
	["$jinhua7"] = "こいつが…格闘進化の極限ッ！！",
	["$jinhua8"] = "進化発動！未来を護ろう、アイオス·フェース！",
	["$jinhua9"] = "アイオス·フェース！",
	["$jinhua10"] = "これは、ファンネル進化の極限！",
    ["paoji"] = "炮击",
	["paojicard"] = "炮击",
	["$paoji1"] = "ヴァリアブル·サイコ·ライフル…！",
	["$paoji2"] = "クロスバスターモード…！",
	["$paoji3"] = "ニュータイプも、コーディネーターも、等しく人間の本質なんだ！",
	["$paoji4"] = "全ての人類の希望を…この一撃に！",
	["$paoji5"] = "全ての戦術を知るこの俺に、貴様を落とせぬ理由など無い…",
	[":paoji"] = "你可以弃置1个<font color='red'><b>“极”</b></font>标记发动技能<b>“巨炮”</b>或<b>“双炮”</b>。\
>><b><font color='red'>巨炮</font></b>：当你对距离最远的一名角色造成一次普通【杀】或雷电伤害时，你可令该伤害+1。\
>><b><font color='red'>双炮</font></b>：出牌阶段，你可以失去1点体力，若如此做，你本回合使用【杀】时可额外指定一个目标且造成的伤害+1。每回合限用一次。",
	["wudou"] = "武斗",
	["wudoucard"] = "武斗",
	["wudoucard2"] = "神掌",
	["wudoucard3"] = "神掌",
	["wudoucard4"] = "狂刀",
	["$wudou1"] = "シャァイニング、ゴッド、バンカァァァッ！！",
	["$wudou2"] = "パイルピリオド！",
	["$wudou3"] = "極限全力！！シャァイニング、バンカァァァァァァ！！",
	["$wudou4"] = "チェストォォォッ！！",
	["$wudou5"] = "獅子咆哮ォッ！！",
	["$wudou6"] = "スーゥパァァ、レオスナッコォウッ！！",
	["$wudou7"] = "獅子奮迅ッ！",
	["$wudou8"] = "一撃必殺ッ！！",
	["$wudou9"] = "極！！限！！全！！力ッ！！",
	["$wudou10"] = "いい加減、極限の熱さを…受け入れろォォォォォッ！！",
	["$$wudou"] = "请选择所需的牌和目标角色。",
	[":wudou"] = "你可以弃置1个<font color='red'><b>“极”</b></font>标记发动技能<b>“神掌”</b>或<b>“狂刀”</b>。\
>><b><font color='red'>神掌</font></b>：出牌阶段，你可以弃置一张<font color='red'>♥</font>牌或点数K的牌，然后对一名其他角色造成1点火焰伤害；或弃置一张【<font color='red'>♥K</font>】的牌，然后对一名其他角色造成3点火焰伤害。每回合限用一次。\
>><b><font color='red'>狂刀</font></b>：出牌阶段限一次，你可以将一至四张手牌当【杀】使用，其中若有：\
 >基本牌：你可以摸一张牌。\
 >装备牌：你可以弃置目标角色的一张手牌。\
 >延时类锦囊牌：你可以额外指定一个目标。\
 >非延时类锦囊牌：你无视目标角色的防具。",
    ["shenyu"] = "神羽",
	["shenyucard"] = "神羽",
	["$shenyu1"] = "アリス·ファンネル！",
	["$shenyu2"] = "俺の…正義は！",
	["$shenyu3"] = "理想のためなら！",
	["$shenyu4"] = "あなたが絶望と呼んでいるものを、俺はそれが、希望なのだと知っている！",
	["$shenyu5"] = "命を無駄にするなんて！",
	[":shenyu"] = "你可以弃置1个<font color='red'><b>“极”</b></font>标记发动技能<b>“超骑”</b>或<b>“极骑”</b>。\
>><b><font color='red'>超骑</font></b>：当你成为【杀】的目标后，你可以摸一张牌并展示之，你可以使用之且无距离限制。\
>><b><font color='red'>极骑</font></b>：当你成为【杀】的目标时，你可以弃置X张【杀】，然后展示牌堆顶和牌堆底的各2X张牌，你获得其中的基本牌，其余的牌置入弃牌堆；当一名角色对你使用一张【杀】后，你可以对其使用一张【杀】。",
	["~EXTREME"] = "レオス！！帰ってきてください…お願いっ…！！",
	["zhongyan"] = "终焉",
	["$zhongyan"] = "極限の希望をくれてやる！",
	["#zhongyan"] = "%from 进化为<b><font color='red'>“全位</font><font color='orange'>面 - EX</font><font color='red'>A-F”</font></b>",
	[":zhongyan"] = "<b>觉醒技</b>，准备阶段开始时，若你只有1个<font color='red'><b>“极”</b></font>标记，你获得2个<font color='red'><b>“极”</b></font>标记并将形态进化至3种形态<b><font color='red'>“全位</font><font color='orange'>面 - EX</font><font color='red'>A-F”</font></b>。",
	["@zhongyan"] = "<b><font color='red'>全</font><font color='orange'>位</font><font color='red'>面</font></b>",
	["#EXTREME"] = "极限进化",
	["designer:EXTREME"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EXTREME"] = "雷奥斯·阿莱",
	["illustrator:EXTREME"] = "wch5621628",
}