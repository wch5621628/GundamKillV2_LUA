module("extensions.gaoda",package.seeall)
extension=sgs.Package("gaoda")
--extension = sgs.Package("gaoda", sgs.Package_GeneralPack)

--高达杀胆创功能（true:开启, false:关闭）
animation = true --萌妹纸动画
auto_bgm = true --自动切换BGM
auto_backdrop = true --自动切换起始背景
gg_effect = true --阵亡特效
opening = true --开场对白
dlc = true --武将解锁系统（每5场游戏解锁1名隐藏武将）节日武将？
map_attack = true --地图炮系统（5~7人：1|8~9人场：2|10人场：3，每受到1点伤害增加1点能量，5点能量可发炮）

gdata = "g.lua" --DO NOT DELETE THIS FILE!
--BUG:death=>json huashen failed
do
    require  "lua.config"
	local config = config
	local kingdoms = config.kingdoms
	config.kingdoms = { "EFSF", "SLEEVE", "OMNI", "ZAFT", "ORB", "CB", "OTHERS"--[[, "wei", "shu", "wu", "qun", "god"]] }
	config.kingdom_colors = {
		EFSF = "#547998",
        SLEEVE = "#96943D",
		OMNI = "#3cc451",
		ZAFT = "#FF0000",
		ORB = "#feea00",
		CB = "#7097df",
        OTHERS = "#8A807A",
		wei = "#547998",
		shu = "#D0796C",
		wu = "#4DB873",
		qun = "#8A807A",
		god = "#96943D"
	}
end

Table2IntList = function(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end

function Set(list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then io.close(f) return true else return false end
end

--[[function CardList2IntList(cards)
	local ids = sgs.IntList()
	for _,card in sgs.qlist(cards) do
		ids:append(card:getId())
	end
	return ids
end

function IntList2CardList(ids)
	local cards = sgs.CardList()
	for _,id in sgs.qlist(ids) do
		cards:append(sgs.Sanguosha:getCard(id))
	end
	return cards
end]]-- Useful functions

--===============↓↓For FA_UNICORN Use↓↓===============--
hasEquipArea = function(player, name)
	if (name == "treasure" and (Set(sgs.Sanguosha:getBanPackages()))["limitation_broken"])
	or player:getMark(name.."AreaRemoved") > 0 then
		return false
	end
	return true
end

removeEquipArea = function(player, name)
	if hasEquipArea(player, name) then
		local room = player:getRoom()
		room:setPlayerMark(player, name.."AreaRemoved", 1)
		local classname
		if name == "defensive_horse" then classname = "DefensiveHorse"
		elseif name == "offensive_horse" then classname = "OffensiveHorse"
		else classname = name:gsub("^%l", string.upper) end
		room:setPlayerCardLimitation(player, "use", classname.."$0", false)
		local equips = {"weapon", "armor", "defensive_horse", "offensive_horse", "treasure"}
		for i = 1, 5, 1 do
			if name == equips[i] and player:getEquip(i-1) then
				room:throwCard(player:getEquip(i-1), nil)
				break
			end
		end
		local log = sgs.LogMessage()
		log.type = "#RemoveEquipArea"
		log.from = player
		log.arg = name
		room:sendLog(log)
	end
end

removeWholeEquipArea = function(player)
	local equips = {"weapon", "armor", "defensive_horse", "offensive_horse", "treasure"}
	for _,equip in ipairs(equips) do
		removeEquipArea(player, equip)
	end
end

blankEquipArea = function(player)
	if hasEquipArea(player, "weapon") or hasEquipArea(player, "armor") or hasEquipArea(player, "defensive_horse")
	or hasEquipArea(player, "offensive_horse") or hasEquipArea(player, "treasure") then
		return false
	end
	return true
end

equipprohibit = sgs.CreateProhibitSkill
{
	name = "#equipprohibit",
	is_prohibited = function(self, from, to, card)
		if to and card:isKindOf("EquipCard") and (not hasEquipArea(to, card:getSubtype()))  then
			return true
		end
	end
}
--===============↑↑For FA_UNICORN Use↑↑===============--

--【阵亡特效】
gdsrule = sgs.CreateTriggerSkill{
	name = "gdsrule",
	events = {sgs.Death--[[,sgs.GameStart]]},
	global = true,
	can_trigger = function(self, player)
		return gg_effect
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.Death then
	    local death = data:toDeath()
		if death.who:objectName() == player:objectName() then
			if file_exists("image/generals/card/"..death.who:getGeneralName()..".jpg") then
				room:doLightbox(("image=image/generals/card/%s.jpg"):format(death.who:getGeneralName()), 0500)
			end
			if sgs.Sanguosha:translate("~"..death.who:getGeneralName()) ~= "~"..death.who:getGeneralName() and
				sgs.Sanguosha:translate("~"..death.who:getGeneralName()) ~= "" then
				room:doLightbox("~"..death.who:getGeneralName(), 1000)
			end
		end
	end
	--[[if event == sgs.GameStart then
	    if player:getPhase() == sgs.Player_Play then return false end
	    if player:getGeneral():getPackage() ~= "gaoda" then
		    local changelist = {}
		    local all = sgs.Sanguosha:getLimitedGeneralNames()
			for _,name in ipairs(all) do
		        if sgs.Sanguosha:getGeneral(name):getPackage() == "gaoda" and not table.contains(changelist,name) then
				    table.insert(changelist,name)
				end
			end
			local rand = math.random(1,#changelist)
			room:changeHero(player, changelist[rand], true, true, false, false)
			room:setPlayerProperty(player, "kingdom", sgs.QVariant(sgs.Sanguosha:getGeneral(changelist[rand]):getKingdom()))
		end
	end]]
	end
}

--【萌妹纸动画】
gdsvoice = sgs.CreateTriggerSkill{
	name = "gdsvoice",
	events = {sgs.AfterDrawInitialCards, sgs.EventPhaseStart, sgs.ChoiceMade},
	global = true,
	can_trigger = function(self, player)
	    return animation == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		math.random()
	if event == sgs.AfterDrawInitialCards then
	    if player:getState() ~= "robot" then
			room:setPlayerFlag(player, "skip_anime")
			local choice = {"seshia", "meiling"}
			room:setPlayerProperty(player, "emotion", sgs.QVariant(choice[math.random(2)]))
			local emotion = player:property("emotion"):toString()
			if emotion == "seshia" then
				room:broadcastSkillInvoke("gdsvoice",math.random(1,4))
			elseif emotion == "meiling" then
			    room:broadcastSkillInvoke("gdsvoice",math.random(5,8))
			end
			local json = require("json")
			local jsonValue = {
			player:objectName(),
			emotion
			}
			local wholist = sgs.SPlayerList()
            wholist:append(player)
			room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
        end
	end
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
			room:setEmotion(player,"light")
    	    if player:getState() ~= "robot" and math.random(1,10) <= 7 and not player:hasFlag("skip_anime") then
			    local emotion = player:property("emotion"):toString()
				if emotion == "seshia" then
				    room:broadcastSkillInvoke("gdsvoice",math.random(1,4))
			    elseif emotion == "meiling" then
			        room:broadcastSkillInvoke("gdsvoice",math.random(5,8))
			    end
			    local json = require("json")
				local jsonValue = {
				player:objectName(),
				emotion
				}
				local wholist = sgs.SPlayerList()
				wholist:append(player)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
            end
		end
		if player:getPhase() == sgs.Player_Finish then
		    room:setEmotion(player,"dark")
		end
	end
	if event == sgs.ChoiceMade then
	    if player:getState() ~= "robot" and math.random(1,10) == 1 then
		    local emotion = player:property("emotion"):toString()
		    if emotion == "seshia" then
				room:broadcastSkillInvoke("gdsvoice",math.random(2,4))
			elseif emotion == "meiling" then
			    room:broadcastSkillInvoke("gdsvoice",math.random(6,8))
			end
			local json = require("json")
			local jsonValue = {
			player:objectName(),
			emotion
			}
			local wholist = sgs.SPlayerList()
			wholist:append(player)
			room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
        end
	end
	end,
}

--【自动切换BGM】
changeBGM = function(name)
	sgs.SetConfig("BackgroundMusic", "audio/system/"..name..".ogg")
end

generalName2BGM = function(name)
	local bgms = {
		{"BGM0", "IIVS"},
		{"BGM1", "HARUTE", "ELSQ"},
		{"BGM14", "REBORNS_CANNON", "REBORNS_GUNDAM"},
		{"BGM13", "GINN", "STRIKE", "AEGIS", "BUSTER", "DUEL_AS", "BLITZ", "BLITZ_Y"},
		{"BGM8", "IMPULSE", "SP_DESTINY"},
		{"BGM9", "UNICORN", "UNICORN_NTD", "FA_UNICORN", "KSHATRIYA", "SINANJU", "ReZEL", "DELTA_PLUS", "BANSHEE", "NORN", "PHENEX"},
		{"BGM10", "FREEDOM"},
		{"BGM11", "WZ", "EPYON"},
		{"BGM12", "WZC", "DSH", "HAC", "SANDROCK", "ALTRON"},
		{"BGM15", "EX_S"},
		{"BGM16", "DX"},
		{"BGM17", "JUSTICE"},
		{"BGM18", "CFR"},
		{"BGM19", "PROVIDENCE"},
		{"BGM20", "EXIA_R"},
		{"BGM21", "SBS"}
	}
	for _,bgm in ipairs(bgms) do
		if table.contains(bgm, name) and file_exists("audio/system/"..bgm[1]..".ogg") then
			return bgm[1]
		end
	end
	math.random()
	local n = -1
	for i = 0, 998, 1 do
		if file_exists("audio/system/BGM"..i..".ogg") then
			n = i
		else
			break
		end
	end
	if n == -1 then return "background" end
	return "BGM"..math.random(0, n)
end

gdsbgm = sgs.CreateTriggerSkill{
	name = "gdsbgm",
	events = {sgs.DrawInitialCards},
	global = true,
	can_trigger = function(self, player)
	    return auto_bgm == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if player:isLord() then
			local name = generalName2BGM(player:getGeneralName())
			changeBGM(name)
			local ip = room:getOwner():getIp()
			if ip ~= "" and string.find(ip, "127.0.0.1") and room:getMode() ~= "06_3v3" then --联机状态时切换BGM无效
				if name == "background" then name = "BGM0" end
				if dlc then
					local log = sgs.LogMessage()
					log.type = "#BGM"
					log.arg = name
					room:sendLog(log)
				else
					room:doLightbox(name, 1000, 50)
				end
			end
		end
	end
}
--[[bgm = {"0","0"}
gdsbgm = sgs.CreateTriggerSkill{
	name = "gdsbgm",
	events = {sgs.ChoiceMade,sgs.DrawInitialCards},
	global = true,
	can_trigger = function(self, player)
	    return auto_bgm == true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	    if (event == sgs.ChoiceMade or event == sgs.DrawInitialCards) then
			local BGM_No = math.random(1,3)
			local t = os.clock()
			if t >= tonumber(bgm[1]) + tonumber(bgm[2]) then
				table.removeOne(bgm,bgm[1])
				table.insert(bgm,1,""..t.."")
				if BGM_No == 1 then
					table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"140")
					room:broadcastSkillInvoke("gdsbgm",1)
				elseif BGM_No == 2 then
					table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"203")
					room:broadcastSkillInvoke("gdsbgm",2)
				elseif BGM_No == 3 then
				    table.removeOne(bgm,bgm[2])
					table.insert(bgm,2,"177")
					room:broadcastSkillInvoke("gdsbgm",3)
				end
			end
	    end
	end,
}]]

--【自动切换起始背景】
if auto_backdrop then
	--[[os.remove("backdrop/default.jpg")
	local no = math.random(1,4)
	os.execute("copy change/default"..no..".jpg backdrop")
	os.rename("backdrop/default"..no..".jpg", "backdrop/default.jpg")
	os.execute太危险了(＞﹏＜)]]
    math.random() --傲娇的lua随机数，要我用挫计来骗他
	local n = 0
	for i = 1, 998, 1 do
		if file_exists("image/system/backdrop/new-version"..i..".jpg") then
			n = i
		else
			break
		end
	end
	local index = math.random(n)
	if n == 0 then index = "" end
	sgs.SetConfig("BackgroundImage", "image/system/backdrop/new-version"..index..".jpg")
end

--【开场对白】
if opening then
    math.random()
	sgs.Sanguosha:playAudioEffect("audio/system/op"..math.random(2)..".ogg", false)
end

--【武将解锁系统】
gdsrecord = sgs.CreateTriggerSkill{
	name = "gdsrecord",
	events = {sgs.DrawInitialCards},
	global = true,
	can_trigger = function(self, player)
	    return dlc == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:objectName() == room:getOwner():objectName() then
			local file = assert(io.open(gdata, "r"))
			local t = file:read("*all")
			file:close()
			t = t:split("\n")
			times = {}
			for id,item in pairs(t) do
				local s = item:split("=")
				t[id] = s[1]
				table.insert(times, tonumber(s[2]))
			end
			if not table.contains(t, "GameTimes") then
				table.insert(t, "GameTimes")
				table.insert(times, 0)
			end
		    local all = sgs.Sanguosha:getLimitedGeneralNames()
			for _,name in pairs(all) do
		        if sgs.Sanguosha:getGeneral(name):getPackage() == "gaoda" and not table.contains(t, name) then
					table.insert(t, name)
					table.insert(times, 0)
				end
			end
			local record2 = assert(io.open(gdata, "w"))
			for d,text in pairs(t) do
				local n = times[d]
				if text == "GameTimes" or player:getGeneralName() == text then
					n = n + 1
				end
				if player:getGeneralName() == text and n >= 5 then
					local log = sgs.LogMessage()--BUG:Mind double mode
					log.type = "#gdsrecord"
					log.from = player
					log.arg = tostring(n)
					room:sendLog(log)
					liberate(player)
				end
				record2:write(text.."="..tostring(n))
				if d ~= #t then
					record2:write("\n")
				end
			end
			record2:close()
		end
	end
}

liberate = function(player)
	local room = player:getRoom()
	local name = player:getGeneralName()
	if name == "UNICORN" then
		room:addPlayerMark(player, player:objectName().."_shenshou_liberated")
		sgs.AddTranslationEntry("shenshou", "神兽•解放")
		sgs.AddTranslationEntry(":shenshou", "当你使用一张<s><font color='#BDBDBD'><b>红色</b>的</font></s>【杀】指定一名角色为目标后，你可以令其交给你一张<font color='red'><b>红色</b></font>牌，否则此【杀】不可被【闪】响应。")
	end
end--sgs.Sangousha:addTranslationEntry or sgs.AddTranslationEntry? It is a question.

isLiberated = function(player, skill_name)
	return player:getMark(player:objectName().."_"..skill_name.."_liberated") > 0
end--BUG:1.use tag to make all liberate, 2.network failed to translate

--【地图炮系统】
mapcard = sgs.CreateSkillCard{
	name = "map",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName()
	end,
	on_use = function(self, room, source, targets)
		room:setPlayerMark(source, "@map5", 0)
		room:detachSkillFromPlayer(source, "map", true)
		if source:getKingdom() == "OMNI" or source:getKingdom() == "ZAFT" or source:getKingdom() == "ORB" then
			local log = sgs.LogMessage()
			log.type = "#map"
			log.from = source
			log.arg = "map2"
			room:sendLog(log)
			room:broadcastSkillInvoke("maprecord", 2)
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"map2"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:getThread():delay(1500)
			for _,q in ipairs(targets) do
				room:loseHp(q, 2)
			end
		else
			local log = sgs.LogMessage()
			log.type = "#map"
			log.from = source
			log.arg = "map1"
			room:sendLog(log)
			room:broadcastSkillInvoke("maprecord", 1)
			for _,p in sgs.qlist(room:getAllPlayers(true)) do
				local json = require("json")
				local jsonValue = {
				p:objectName(),
				"map1"
				}
				local wholist = sgs.SPlayerList()
				wholist:append(p)
				room:doBroadcastNotify(wholist,sgs.CommandType.S_COMMAND_SET_EMOTION, json.encode(jsonValue))
			end
			room:getThread():delay(1500)
			for _,q in ipairs(targets) do
				room:damage(sgs.DamageStruct(self:objectName(), nil, q, 2, sgs.DamageStruct_Thunder))
			end
		end
	end
}

map = sgs.CreateZeroCardViewAsSkill{
	name = "map&",
	view_as = function(self)
		return mapcard:clone()
    end,
	enabled_at_play = function(self, player)
		return player:getMark("@map5") == 1
	end
}

maprecord = sgs.CreateTriggerSkill{
	name = "maprecord",
	events = {sgs.AfterDrawInitialCards, sgs.Damaged},
	priority = 10,
	global = true,
	can_trigger = function(self, player)
	    return map_attack == true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.AfterDrawInitialCards then
			if room:getTag("map"):toBool() then return false end
			math.random()
			room:setTag("map", sgs.QVariant(true))
			local players = room:getAllPlayers()
			local num = players:length()
			if num < 5 or room:getMode() == "06_3v3" then return false end
			local p = players:at(math.random(0, num - 1))
			if not p:hasSkill("map") then
				room:attachSkillToPlayer(p, "map")
			end
			room:setPlayerMark(p, "@map0", 1)
			if num >= 8 then
				players:removeOne(p)
				local q = players:at(math.random(0, num - 2))
				if not q:hasSkill("map") then
					room:attachSkillToPlayer(q, "map")
				end
				room:setPlayerMark(q, "@map0", 1)
				if num >= 10 then
					players:removeOne(q)
					local r = players:at(math.random(0, num - 3))
					if not r:hasSkill("map") then
						room:attachSkillToPlayer(r, "map")
					end
					room:setPlayerMark(r, "@map0", 1)
				end
			end
		else
			if (not player:hasSkill("map")) or player:getMark("@map5") == 1 then return false end
			local damage = data:toDamage()
			for i=1, damage.damage, 1 do
				if player:getMark("@map0") == 1 then
					room:setPlayerMark(player, "@map0", 0)
					room:setPlayerMark(player, "@map1", 1)
				elseif player:getMark("@map1") == 1 then
					room:setPlayerMark(player, "@map1", 0)
					room:setPlayerMark(player, "@map2", 1)
				elseif player:getMark("@map2") == 1 then
					room:setPlayerMark(player, "@map2", 0)
					room:setPlayerMark(player, "@map3", 1)
				elseif player:getMark("@map3") == 1 then
					room:setPlayerMark(player, "@map3", 0)
					room:setPlayerMark(player, "@map4", 1)
				elseif player:getMark("@map4") == 1 then
					room:broadcastSkillInvoke("gdsbgm", 2)
					room:setPlayerMark(player, "@map4", 0)
					room:setPlayerMark(player, "@map5", 1)
				else
					break
				end
			end
		end
	end
}

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("gdsrule") then skills:append(gdsrule) end
if not sgs.Sanguosha:getSkill("gdsvoice") then skills:append(gdsvoice) end
if not sgs.Sanguosha:getSkill("gdsbgm") then skills:append(gdsbgm) end
if not sgs.Sanguosha:getSkill("#equipprohibit") then skills:append(equipprohibit) end
if not sgs.Sanguosha:getSkill("gdsrecord") then skills:append(gdsrecord) end
if not sgs.Sanguosha:getSkill("map") then skills:append(map) end
if not sgs.Sanguosha:getSkill("maprecord") then skills:append(maprecord) end
sgs.Sanguosha:addSkills(skills)

IIVS = sgs.General(extension, "IIVS", "OTHERS", 4, true, false)

yuexiancard=sgs.CreateSkillCard{
    name="yuexian",
    target_fixed=true,
    will_throw=false,
on_use=function(self, room, source, targets)
    local jihuo = {"rishi","yihua","shensheng"}
	if source:hasSkill("rishi") then
		table.removeOne(jihuo,"rishi")
	end
	if source:hasSkill("yihua") then
		table.removeOne(jihuo, "yihua")
	end
	if source:hasSkill("shensheng") then
		table.removeOne(jihuo, "shensheng")
	end
    local choice = room:askForChoice(source, self:objectName(), table.concat(jihuo,"+"), sgs.QVariant())
	if choice then
		if choice == "rishi" then
			room:broadcastSkillInvoke("yuexian", 1)
		elseif choice == "yihua" then
			room:broadcastSkillInvoke("yuexian", 2)
		elseif choice == "shensheng" then
			room:broadcastSkillInvoke("yuexian", 3)
		end
	    source:gainMark("@point")
	    room:acquireSkill(source, choice)
		room:setPlayerMark(source, "@"..choice,1)
	end
	if source:getMark("@point") >=3 then
	    source:loseAllMarks("@point")
		local log = sgs.LogMessage()
		log.from = source
        log.type = "#point"
        log.arg = "#IIVSp"
        room:sendLog(log)
	    room:setPlayerMark(source, "yuexian",2)
		room:setEmotion(source, "yuexian")
	end
end,
}

yuexian=sgs.CreateViewAsSkill{
    name="yuexian",
    n=0,
view_as=function(self, cards)
    local acard=yuexiancard:clone()
    acard:setSkillName(self:objectName())
    return acard
end,
enabled_at_play=function(self,player)
    return player:getMark("yuexian") ~= 1 and not(player:hasSkill("rishi") and player:hasSkill("yihua") and player:hasSkill("shensheng"))
end,
enabled_at_response=function(self,player,pattern) 
    return false 
end,
}

yuexianmark=sgs.CreateTriggerSkill{
	name="#yuexianmark",
	events={sgs.TurnStart, sgs.PreCardUsed},
	on_trigger=function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.TurnStart then
			if player:getMark("yuexian") > 0 then
				room:removePlayerMark(player, "yuexian", 1)
			end
			room:handleAcquireDetachSkills(player, "-rishi|-yihua|-shensheng")
			room:setPlayerMark(player,"@rishi",0)
			room:setPlayerMark(player,"@yihua",0)
			room:setPlayerMark(player,"@shensheng",0)
		else
			local use = data:toCardUse()
			if use.card and use.card:getSkillName() == "yuexian" then
				return true
			end
		end
	end,
}

rishi = sgs.CreateTargetModSkill{
	name = "rishi",
	pattern = "Slash,TrickCard+^DelayedTrick",
	extra_target_func = function(self, player)
	if player and player:hasSkill("rishi") then
		return 1
	end
	end,
	distance_limit_func = function(self, player)
	if player and player:hasSkill("rishi") then
	    return 998
	end
	end,
}

rishiv = sgs.CreateTriggerSkill{
	name = "#rishiv",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	    if use.card and use.card:getSkillName() ~= "yihua" and use.card:getSkillName() ~= "shensheng" and ((use.card:isKindOf("Slash") or use.card:isKindOf("SingleTargetTrick")) and use.to:length() > 1) or (use.card:isKindOf("IronChain") and use.to:length() > 2) then
		    room:broadcastSkillInvoke("rishi")
		end
	end,
}

yihua = sgs.CreateTriggerSkill{
	name = "yihua",
	events = {sgs.PostCardEffected,sgs.PreCardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.PostCardEffected then
	    local effect = data:toCardEffect()
		if effect.card:isNDTrick() and effect.from:objectName() ~= player:objectName() and room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
			player:drawCards(1)
			if player:canSlash(effect.from, false) then
			    room:setPlayerFlag(player,"yihua")
			    room:askForUseSlashTo(player, effect.from, "#yihua", false)
			end
		end
		room:setPlayerFlag(player,"-yihua")
	elseif event == sgs.PreCardUsed then
	    local use = data:toCardUse()
	    if use.card:isKindOf("Slash") and (not use.card:isKindOf("FireSlash")) and player:hasFlag("yihua") then
		    room:setPlayerFlag(player,"-yihua")
		    local fslash = sgs.Sanguosha:cloneCard("fire_slash",use.card:getSuit(),use.card:getNumber())
			fslash:addSubcard(use.card)
			fslash:setSkillName(self:objectName())
			use.card = fslash
			data:setValue(use)
			room:setEmotion(player, "fire_slash")
		end
	end
	end,
}

shenshengvs = sgs.CreateViewAsSkill{
	name = "shensheng",
	n = 0,
	view_as = function(self, cards)
	    local id = sgs.Sanguosha:getCard(sgs.Self:getMark("shensheng"))
		local acard = sgs.Sanguosha:cloneCard(id:objectName(), id:getSuit(), id:getNumber())
		acard:setSkillName("shensheng")
		acard:addSubcard(id)
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern)
		return pattern == "@@shensheng"
	end,
}

shensheng = sgs.CreateTriggerSkill{
	name = "shensheng",
	events = {sgs.TargetConfirmed},
	view_as_skill = shenshengvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if use.card and use.card:isKindOf("Slash") and use.to:contains(player) and room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
		local show = room:getNCards(3)
		room:fillAG(show)
		for i=0,2,1 do
		    local cd = show:at(i)
		    local card = sgs.Sanguosha:getCard(cd)
			if card:isKindOf("EquipCard") then
			    local choice = room:askForChoice(player, self:objectName(), "ssuse+ssobtain", sgs.QVariant(""..card:getId()))
				if choice == "ssuse" then
					room:useCard(sgs.CardUseStruct(card, player, player))
				elseif choice == "ssobtain" then
				    room:obtainCard(player,cd)
				end
			else
				if card:isKindOf("Jink") or card:isKindOf("Nullification") or (card:isKindOf("Peach") and not player:isWounded()) then
					room:obtainCard(player,cd)
				else
					room:setPlayerMark(player,"shensheng",card:getId())
					local scard = sgs.Sanguosha:getCard(player:getMark("shensheng"))
					local use = room:askForUseCard(player, "@@shensheng", ("#shensheng:%s:%s:%s:%s"):format(scard:objectName(),scard:getSuitString(),scard:getNumber(),scard:getEffectiveId()))
					if use then
					else
						room:obtainCard(player,cd)
					end
				end
			end
		end
		room:clearAG()
		room:setPlayerMark(player,"shensheng",0)
	end
	end,
}

IIVS:addSkill(yuexian)
IIVS:addSkill(yuexianmark)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("rishi") then skills:append(rishi) end
if not sgs.Sanguosha:getSkill("#rishiv") then skills:append(rishiv) end
if not sgs.Sanguosha:getSkill("yihua") then skills:append(yihua) end
if not sgs.Sanguosha:getSkill("shensheng") then skills:append(shensheng) end
sgs.Sanguosha:addSkills(skills)
IIVS:addRelateSkill("rishi")
IIVS:addRelateSkill("yihua")
IIVS:addRelateSkill("shensheng")
extension:insertRelatedSkills("rishi", "#rishiv")

UNICORN = sgs.General(extension, "UNICORN", "EFSF", 4, true, false)

shenshou = sgs.CreateTriggerSkill{
	name = "shenshou",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if player:objectName() == use.from:objectName() and use.card:isKindOf("Slash") and (use.card:isRed() or isLiberated(player, self:objectName())) and
	room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke("shenshou")
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			local acard = room:askForCard(p, ".|red|.|.", "@@shenshou:"..player:getGeneralName(), data, sgs.Card_MethodNone, player, false, self:objectName(), true)
			if acard then
				player:obtainCard(acard)
			    return false
			else
				jink_table[index] = 0
			end
			index = index + 1
		end
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	end
	end,
}

NTD = sgs.CreateTriggerSkill
{
	name = "NTD",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and player:getHp() < 3 and
		player:getMark("@NTD") == 0 then
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			--[[if auto_bgm then
				room:getThread():trigger(sgs.NonTrigger, room, player, sgs.QVariant("audio/system/bgm_uc.ogg"))
			end]]
			room:broadcastSkillInvoke("NTD")
			room:doLightbox("image=image/animate/NTD.png", 1500)
			room:setEmotion(player, "NTD")
			room:getThread():delay(2700)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("UNICORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"huimie",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			player:gainMark("@NTD")
			room:setPlayerMark(player, "NTD", 1)
			room:loseMaxHp(player)
			if not player:isKongcheng() then
				local n = 0
				local handcards = player:handCards()
				room:fillAG(handcards)
				for _,h in sgs.qlist(handcards) do
					if sgs.Sanguosha:getCard(h):isRed() then
						n = n + 1
					end
				end
				if n > 0 then
					for i=1, n ,1 do
						if player:isWounded() then
							local choice = room:askForChoice(player, self:objectName(), "ntdrecover+ntddraw")
							if choice == "ntdrecover" then
								local recover = sgs.RecoverStruct()
								recover.recover = 1
								recover.who = player
								room:recover(player,recover)
							else
								room:drawCards(player, 1)
							end
						else
							room:drawCards(player, 1)
						end
					end
				else
					room:getThread():delay(1500)
				end
				room:clearAG()
			end
			room:acquireSkill(player,"huimie")
			use.to = sgs.SPlayerList()
			data:setValue(use)
		end
	end,
}

huimievs = sgs.CreateZeroCardViewAsSkill{
	name = "huimie",
	view_as = function(self)
	    local pattern = sgs.Self:property("hmuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName("huimiecard")
		return acard
    end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@huimie"
	end,
}

huimie = sgs.CreateTriggerSkill
{
	name = "huimie",
	events = {sgs.TargetConfirming},
	view_as_skill = huimievs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and (not player:isKongcheng())
		and room:askForSkillInvoke(player, self:objectName(), data) then
			local red = room:askForCard(player, ".|red|.|hand", "@huimie:"..use.card:objectName(), data, sgs.Card_MethodDiscard, nil, false, self:objectName(), false)
			if red then
				room:broadcastSkillInvoke("huimie")
				local acard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, 0)
				if acard:isAvailable(player) then
					if use.card:objectName() == "ex_nihilo" or use.card:objectName() == "amazing_grace"
					or use.card:objectName() == "savage_assault" or use.card:objectName() == "archery_attack"
					or use.card:objectName() == "god_salvation" then
						local u = sgs.CardUseStruct()
						local acard = sgs.Sanguosha:cloneCard(use.card:objectName(), sgs.Card_NoSuit, -1)
						acard:setSkillName("huimiecard")
						u.card = acard
						u.from = player
						room:useCard(u)
					else
						room:setPlayerProperty(player, "hmuse", sgs.QVariant(use.card:objectName()))
						room:askForUseCard(player, "@@huimie", "#huimie:"..use.card:objectName())
						room:setPlayerProperty(player, "hmuse", sgs.QVariant())
					end
				end
				use.to = sgs.SPlayerList()
				data:setValue(use)
			end
		end
	end
}

quanwu = sgs.CreateTriggerSkill
{
	name = "quanwu",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@NTD") > 0 and player:getEquips():length() >= 3 then
			room:broadcastSkillInvoke("quanwu")
			room:doLightbox("image=image/animate/quanwu.png", 1500)
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:setPlayerMark(player, "quanwu", 1)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("FA_UNICORN")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
			room:setPlayerMark(player, "@NTD", 0)
			room:changeHero(player, "FA_UNICORN", false, true, false, true)
		end
	end
}

UNICORN:addSkill(shenshou)
UNICORN:addSkill(quanwu)
UNICORN:addSkill(NTD)

local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("huimie") then skills:append(huimie) end
sgs.Sanguosha:addSkills(skills)
UNICORN:addRelateSkill("huimie")

UNICORN_NTD = sgs.General(extension, "UNICORN_NTD", "EFSF", 4, true, true, true)
UNICORN_NTD:addSkill("shenshou")
UNICORN_NTD:addSkill("quanwu")
UNICORN_NTD:addSkill("NTD")
UNICORN_NTD:addRelateSkill("huimie")

FA_UNICORN = sgs.General(extension, "FA_UNICORN", "EFSF", 3, true, false)

zhonggongcard = sgs.CreateSkillCard{
	name = "zhonggong",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local choices = {}
		if hasEquipArea(effect.from, "weapon") then table.insert(choices, "weapon") end
		if hasEquipArea(effect.from, "armor") then table.insert(choices, "armor") end
		if hasEquipArea(effect.from, "defensive_horse") then table.insert(choices, "defensive_horse") end
		if hasEquipArea(effect.from, "offensive_horse") then table.insert(choices, "offensive_horse") end
		if hasEquipArea(effect.from, "treasure") then table.insert(choices, "treasure") end
		local choice = room:askForChoice(effect.from, "zhonggong", table.concat(choices, "+"), sgs.QVariant())
		removeEquipArea(effect.from, choice)
		room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
	end
}

zhonggong = sgs.CreateZeroCardViewAsSkill{
	name = "zhonggong",
	view_as = function()
	    local acard = zhonggongcard:clone()
		acard:setSkillName("zhonggong")
		return acard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#zhonggong")) and (not blankEquipArea(player))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

qingzhuang = sgs.CreateTriggerSkill{
	name = "qingzhuang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local effect = data:toCardEffect()
	    if blankEquipArea(player) and effect.card:isRed() and effect.card:isKindOf("Slash") then
			room:broadcastSkillInvoke("qingzhuang")
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#SkillNullify"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = "qingzhuang_redslash"
			room:sendLog(log)
			return true
		end
	end
}

qingzhuangdistance = sgs.CreateDistanceSkill{
    name = "#qingzhuangdistance",
    correct_func = function(self, from, to)
		if from:hasSkill("qingzhuang") and blankEquipArea(from) then
			return -2
		end
    end
}

linguangcard = sgs.CreateSkillCard{
	name = "linguang",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@linguang")
		room:doSuperLightbox("FA_UNICORN", "linguang")
		room:recover(source, sgs.RecoverStruct(source))
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			p:turnOver()
		end
		removeWholeEquipArea(source)
		room:acquireSkill(source, "#linguangfilter", false)
		room:filterCards(source, source:getCards("he"), false)
	end
}

linguangvs = sgs.CreateZeroCardViewAsSkill{
	name = "linguang",
	view_as = function()
	    local acard = linguangcard:clone()
		acard:setSkillName("linguang")
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@linguang") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end
}

linguang = sgs.CreateTriggerSkill{
	name = "linguang",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart},
	view_as_skill = linguangvs,
	on_trigger = function(self, event, player, data)
		if player:getMark("@linguang") == 0 then
			player:gainMark("@linguang")
		end
	end
}

linguangfilter = sgs.CreateFilterSkill{
	name = "#linguangfilter",
	view_filter = function(self, card)
		return card:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}

FA_UNICORN:addSkill(zhonggong)
FA_UNICORN:addSkill(qingzhuang)
FA_UNICORN:addSkill(qingzhuangdistance)
FA_UNICORN:addSkill(linguang)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#linguangfilter") then skills:append(linguangfilter) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("qingzhuang", "#qingzhuangdistance")

KSHATRIYA = sgs.General(extension, "KSHATRIYA", "SLEEVE", 4, false, false)

qingyuvs = sgs.CreateViewAsSkill{
	name = "qingyu",
	n = 0,
	view_as = function(self, cards)
	if sgs.Self:getMark("qingyuspade") > 0 then
		local acard = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_Spade, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyuheart") > 0 then
		local acard = sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_Heart, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyuclub") > 0 then
		local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_Club, -1)
		acard:setSkillName("qingyu")
		return acard
	elseif sgs.Self:getMark("qingyudiamond") > 0 then
		local acard = sgs.Sanguosha:cloneCard("snatch", sgs.Card_Diamond, -1)
		acard:setSkillName("qingyu")
		return acard
	else return nil
	end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
    enabled_at_response=function(self,player,pattern)
		return pattern == "@@qingyu"
	end
}

qingyuspade = {}
qingyuheart = {}
qingyuclub = {}
qingyudiamond = {}
qingyu = sgs.CreateTriggerSkill{
	name = "qingyu",
	events = {sgs.CardsMoveOneTime, sgs.EventPhaseEnd, sgs.PreCardUsed},
	view_as_skill = qingyuvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from and move.from:objectName() == player:objectName() and move.to_place == sgs.Player_DiscardPile and player:getPhase() == sgs.Player_Discard and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
			for _,id in sgs.qlist(move.card_ids) do
				if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then
					table.insert(qingyuspade,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart then
				    table.insert(qingyuheart,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club then
				    table.insert(qingyuclub,id)
				elseif sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Diamond then
				    table.insert(qingyudiamond,id)
				end
			end
		end
	elseif event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Discard and
		(#qingyuspade > 0 or #qingyuheart > 0 or #qingyuclub > 0 or #qingyudiamond > 0)
		and room:askForSkillInvoke(player, self:objectName(), data) then
		local show = sgs.IntList()
		for _,a in ipairs(qingyuspade) do
		    show:append(a)
		end
		for _,b in ipairs(qingyuheart) do
		    show:append(b)
		end
		for _,c in ipairs(qingyuclub) do
		    show:append(c)
		end
		for _,d in ipairs(qingyudiamond) do
		    show:append(d)
		end
		room:fillAG(show)
			if #qingyuspade > 0 then
			    room:setPlayerMark(player, "qingyuspade", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu1")
				room:setPlayerMark(player, "qingyuspade", 0)
			end
			if #qingyuheart > 0 then
			    room:setPlayerMark(player, "qingyuheart", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu2")
				room:setPlayerMark(player, "qingyuheart", 0)
			end
			if #qingyuclub > 0 then
			    room:setPlayerMark(player, "qingyuclub", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu3")
				room:setPlayerMark(player, "qingyuclub", 0)
			end
			if #qingyudiamond > 0 then
			    room:setPlayerMark(player, "qingyudiamond", 1)
				room:askForUseCard(player, "@@qingyu", "#qingyu4")
				room:setPlayerMark(player, "qingyudiamond", 0)
			end
		end
			while #qingyuspade > 0 do
				table.remove(qingyuspade)
			end
			while #qingyuheart > 0 do
				table.remove(qingyuheart)
			end
			while #qingyuclub > 0 do
				table.remove(qingyuclub)
			end
			while #qingyudiamond > 0 do
				table.remove(qingyudiamond)
			end
			room:clearAG()
	elseif event == sgs.PreCardUsed then
	    local use = data:toCardUse()
		if use.card:subcardsLength() == 0 and use.card:getSkillName() == "qingyu" then
		    if use.card:isKindOf("SavageAssault") then
			    for _,e in ipairs(qingyuspade) do
		            use.card:addSubcard(e)
		        end
			elseif use.card:isKindOf("ArcheryAttack") then
			    for _,f in ipairs(qingyuheart) do
		            use.card:addSubcard(f)
		        end
			elseif use.card:isKindOf("Dismantlement") then
			    for _,g in ipairs(qingyuclub) do
		            use.card:addSubcard(g)
		        end
			elseif use.card:isKindOf("Snatch") then
			    for _,h in ipairs(qingyudiamond) do
		            use.card:addSubcard(h)
		        end
			end
			data:setValue(use)
		else return false
		end
	end
	end
}

siyicard = sgs.CreateSkillCard{
	name = "siyi",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:hasFlag("siyitarget") and #targets < player:getEquips():length()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:setPlayerFlag(effect.to,"siyiflag")
		local log = sgs.LogMessage()
		log.type = "$siyilog"
		log.from = effect.from
		log.to:append(effect.to)
		room:sendLog(log)
	end
}

siyivs = sgs.CreateZeroCardViewAsSkill{
	name = "siyi" ,
	view_as = function()
	    local acard = siyicard:clone()
		acard:setSkillName("siyi")
		return acard
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response=function(self,player,pattern)
		return pattern == "@@siyi"
	end
}

siyi = sgs.CreateTriggerSkill{
	name = "siyi",
	events = {sgs.TargetSpecifying,sgs.CardUsed},
	view_as_skill = siyivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.TargetSpecifying then
		local use = data:toCardUse()
		if (use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect"))
		and player:hasEquip() and use.to:length() > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			for _,c in sgs.qlist(use.to) do
				room:setPlayerFlag(c,"siyitarget")
			end
			if use.card:isKindOf("AOE") then
			    room:askForUseCard(player, "@@siyi", "#siyi1")
			else
			    room:askForUseCard(player, "@@siyi", "#siyi2")
			end
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p,"-siyitarget")
				if p:hasFlag("siyiflag") then
					room:setPlayerFlag(p,"-siyiflag")
					use.to:removeOne(p)
				end
			end
		end
		data:setValue(use)
	elseif event == sgs.CardUsed then
		local use = data:toCardUse()
	    if (use.card:isKindOf("SingleTargetTrick") and use.to:length() > 1) or (use.card:isKindOf("IronChain") and use.to:length() > 2) then
		    room:broadcastSkillInvoke("siyi")
		end
	end
	end
}

siyiadd = sgs.CreateTargetModSkill{
	name = "#siyiadd",
	pattern = "TrickCard+^DelayedTrick",
	extra_target_func = function(self, player)
	if player and player:hasSkill("siyi") and player:hasEquip() then
		return (player:getEquips():length())
	end
	end
}

KSHATRIYA:addSkill(qingyu)
KSHATRIYA:addSkill(siyi)
KSHATRIYA:addSkill(siyiadd)
extension:insertRelatedSkills("siyi", "#siyiadd")

SINANJU = sgs.General(extension, "SINANJU", "SLEEVE", 4, true, false)

xiaya = sgs.CreateViewAsSkill{
	name = "xiaya",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return to_select:isRed()
	end,
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:setSkillName(self:objectName())
			jink:addSubcard(card:getId())
			return jink
		end
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "jink"
	end
}

zaishi = sgs.CreateTriggerSkill{
	name = "zaishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DrawNCards},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if room:askForSkillInvoke(player,self:objectName(),sgs.QVariant()) then
	    room:broadcastSkillInvoke("zaishi")
	    local n = 0
	    data:setValue(0)
		while player:isAlive() do
		    n = n + 1
		    room:fillAG(player:handCards())
			room:getThread():delay(700)
			local red = 0
			for _,cd in sgs.qlist(player:handCards()) do
			    if sgs.Sanguosha:getCard(cd):isRed() then
				    red = red + 1
				end
			end
			if red >= 3 then break end
		    player:drawCards(1)
		end
		for i=1,n,1 do
		    room:clearAG()
		end
	end
	end
}

wangling = sgs.CreateTriggerSkill{
	name = "wangling",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	    local skilllist = {}
		for _,skill in sgs.qlist(player:getVisibleSkillList()) do
			if skill:objectName() ~= "wangling" and (not skill:isAttachedLordSkill()) then
		        table.insert(skilllist,skill:objectName())
			end
		end
		if #skilllist == 1 then
		    if room:askForSkillInvoke(player,self:objectName(),data) then
			    room:broadcastSkillInvoke("wangling")
				room:detachSkillFromPlayer(player, skilllist[1], false, false)
				if damage.from then
					local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
					slash:setSkillName("wangling")
					local use = sgs.CardUseStruct()
					use.from = player
					use.to:append(damage.from)
					use.card = slash
					room:useCard(use,true)
				end
				return true
			end
		elseif #skilllist > 1 then
		    if room:askForSkillInvoke(player,self:objectName(),data) then
			    room:broadcastSkillInvoke("wangling")
			    local choice = room:askForChoice(player,self:objectName(),table.concat(skilllist,"+"))
				if choice then
					room:detachSkillFromPlayer(player, choice, false, false)
					if damage.from then
						local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
						slash:setSkillName("wangling")
						local use = sgs.CardUseStruct()
						use.from = player
						use.to:append(damage.from)
						use.card = slash
						room:useCard(use,true)
					end
				    return true
				end
			end
		elseif #skilllist == 0 then return false
		end
		while #skilllist > 0 do
		    table.remove(skilllist)
		end
	end
}

SINANJU:addSkill(xiaya)
SINANJU:addSkill(zaishi)
SINANJU:addSkill(wangling)

ReZEL = sgs.General(extension, "ReZEL", "EFSF", 4, true, false)

duilie = sgs.CreateTriggerSkill{
	name = "duilie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
		    for _,q in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerMark(q,"@duilieA",0)
				room:setPlayerMark(q,"@duilieB",0)
				room:setPlayerMark(q,"@duilieC",0)
				room:setPlayerMark(q,"@duilieD",0)
		    end
			if room:askForSkillInvoke(player,self:objectName(),data) then
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				if math.mod(judge.card:getNumber(),2) == 1 then
					room:setPlayerMark(player,"@duilieA",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type = "#duilieA"
					room:sendLog(log)
				end
				if math.mod(judge.card:getNumber(),2) == 0 then
					room:setPlayerMark(player,"@duilieB",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieB"
					room:sendLog(log)
				end
				if judge.card:isBlack() then
					room:setPlayerMark(player,"@duilieC",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieC"
					room:sendLog(log)
				end
				if judge.card:isRed() then
					room:setPlayerMark(player,"@duilieD",1)
					local log = sgs.LogMessage()
					log.from = player
					log.type ="#duilieD"
					room:sendLog(log)
				end
			end
		end
	end
	end,
}

duiliee = sgs.CreateTriggerSkill{
	name = "#duiliee",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardEffected, sgs.CardUsed, sgs.Death},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()   
	if event == sgs.CardEffected then
		local can_invoke = false
		for _,owner in sgs.qlist(room:getAlivePlayers()) do
			if owner:hasSkill("duilie") and owner:hasSkill("zhihui") then
				can_invoke = true
			end
		end
		if can_invoke == false then return false end
	    local effect = data:toCardEffect()
		if player:getMark("@duilieD") > 0 and effect.card:isRed() and (not effect.card:isKindOf("EquipCard")) and (not effect.card:isKindOf("SkillCard")) then
		    if room:askForSkillInvoke(player,"duilie",sgs.QVariant(string.format("draw:%s:%s", player:objectName(), self:objectName()))) then
		        player:drawCards(1)
			end
		end
		if player:getMark("@duilieB") > 0 and math.mod(effect.card:getNumber(),2) == 0 and effect.card:getNumber() > 0 and (not effect.card:isKindOf("EquipCard")) and (not effect.card:isKindOf("SkillCard")) then
			local log = sgs.LogMessage()
			log.from = player
			log.arg = "duilie"
			log.type = "#duilieBe"
			room:sendLog(log)
			return true
		end
	end
	if event == sgs.CardUsed then
	    local can_invoke = false
		for _,owner in sgs.qlist(room:getAlivePlayers()) do
			if owner:hasSkill("duilie") then
				can_invoke = true
			end
		end
		if can_invoke == false then return false end
	    local use = data:toCardUse()
		if player:getMark("@duilieC") > 0 and use.card:isBlack() and (not use.card:isKindOf("EquipCard")) and (not use.card:isKindOf("SkillCard")) then
		    for _,p in sgs.qlist(use.to) do
		        if (not p:isNude()) and room:askForSkillInvoke(player,"duilie",sgs.QVariant(string.format("throw:%s:%s", p:objectName(), self:objectName()))) then
				    local to_throw = room:askForCardChosen(player, p, "he", self:objectName())
					local card = sgs.Sanguosha:getCard(to_throw)
					room:throwCard(card, p, player)
				end
			end
		end
	end
	if event == sgs.Death then
	    local death = data:toDeath()
		if death.who:hasSkill("zhihui") then
		    room:setPlayerMark(player,"@duilieA",0)
			room:setPlayerMark(player,"@duilieB",0)
			room:setPlayerMark(player,"@duilieC",0)
			room:setPlayerMark(player,"@duilieD",0)
		end
	end
	end,
}

duilied = sgs.CreateTargetModSkill{
	name = "#duilied",
	pattern = ".",
	distance_limit_func = function(self, player, card)
		local can_invoke = false
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("duilie") and p:hasSkill("zhihui") then
				can_invoke = true
			end
		end
		if player and player:getMark("@duilieA") > 0 and math.mod(card:getNumber(),2) == 1 and card:getNumber() > 0 and (can_invoke or player:hasSkill("duilie")) then
			return 998
		end
	end,
}

zhihui = sgs.CreateTriggerSkill{
	name = "zhihui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	priority = -1,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    local n = 0
	    local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				tos:append(p)
				n = n + 1
			end
		end
		if n == 0 then return false end
	    if player:getPhase() == sgs.Player_Start and (player:getMark("@duilieA") > 0 or player:getMark("@duilieB") > 0 or player:getMark("@duilieC") > 0 or player:getMark("@duilieD") > 0) and room:askForSkillInvoke(player,self:objectName(),data) then
			local target = room:askForPlayerChosen(player, tos, self:objectName(), "@@zhihui", true, true)
			if target then
			    room:acquireSkill(target, "#duiliee")
				if player:getMark("@duilieA") > 0 then
				    room:setPlayerMark(target,"@duilieA",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieA"
					room:sendLog(log)
				end
				if player:getMark("@duilieB") > 0 then
				    room:setPlayerMark(target,"@duilieB",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieB"
					room:sendLog(log)
				end
				if player:getMark("@duilieC") > 0 then
				    room:setPlayerMark(target,"@duilieC",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieC"
					room:sendLog(log)
				end
				if player:getMark("@duilieD") > 0 then
				    room:setPlayerMark(target,"@duilieD",1)
					local log = sgs.LogMessage()
					log.from = target
					log.type = "#duilieD"
					room:sendLog(log)
				end
			end
		end
	end
	end,
}

ReZEL:addSkill(duilie)
ReZEL:addSkill(duiliee)
ReZEL:addSkill(duilied)
ReZEL:addSkill(zhihui)
extension:insertRelatedSkills("duilie", "#duiliee")
extension:insertRelatedSkills("duilie", "#duilied")

DELTA_PLUS = sgs.General(extension, "DELTA_PLUS", "EFSF", 4, true, false)

xiezhancard = sgs.CreateSkillCard{
	name = "xiezhan",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
		local card_id = self:getSubcards():first()
		local range_fix = 0
		if player:getWeapon() and player:getWeapon():getId() == card_id then
			local weapon = player:getWeapon():getRealCard():toWeapon()
			range_fix = range_fix + weapon:getRange() - 1
		elseif player:getOffensiveHorse() and player:getOffensiveHorse():getId() == card_id then
			range_fix = range_fix + 1
		end
		if #targets ~= 0 or to_select:objectName() == player:objectName() then return false end
		local card = sgs.Sanguosha:getCard(card_id)
		local equip = card:getRealCard():toEquipCard()
		local equip_index = equip:location()
		return to_select:getEquip(equip_index) == nil and player:distanceTo(to_select, range_fix) <= player:getAttackRange() and sgs.Slash_IsAvailable(to_select) and hasEquipArea(to_select, card:getSubtype())
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceEquip, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, effect.from:objectName(), self:objectName(), ""))
		local players = room:getOtherPlayers(effect.to)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuitRed, 0)
		slash:setSkillName("xiezhancard")
		for _,p in sgs.qlist(players) do
			if p:isProhibited(p, slash) then
				players:removeOne(p)
			end
		end
		if players:isEmpty() then return false end
		local target = room:askForPlayerChosen(effect.from, players, self:objectName(), "@dummy-slash2:"..effect.to:objectName())
		if target then
			room:useCard(sgs.CardUseStruct(slash, effect.to, target), false)
		end
	end,
}

xiezhan = sgs.CreateOneCardViewAsSkill{
	name = "xiezhan",
	filter_pattern = "EquipCard",
	view_as = function(self, card)
	    local acard = xiezhancard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end,
	enabled_at_play = function(self, player)
		return not player:isNude()
	end,
}

tupovs = sgs.CreateZeroCardViewAsSkill{
	name = "tupo",
	view_as = function(self)
		local acard = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		local card = sgs.Sanguosha:cloneCard("collateral", sgs.Card_NoSuit, 0)
		return card:isAvailable(player) and (not player:hasFlag("tupo_used"))
	end,
}

tupo = sgs.CreateTriggerSkill{
	name = "tupo",
	events = {sgs.CardEffected, sgs.PostCardEffected, sgs.ChoiceMade},
	view_as_skill = tupovs,
	can_trigger = function(self, player)
		return player
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.CardEffected or event == sgs.PostCardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("Collateral") and effect.card:getSkillName() == "tupo" then
				if event == sgs.CardEffected then
					room:setPlayerFlag(player, "tupo_target")
				else
					if player:hasFlag("tupo_target") then
						room:setPlayerFlag(player, "-tupo_target")
					else
						for _,p in sgs.qlist(room:getAlivePlayers()) do
							if p:hasFlag("tupo_used") then
								local card = sgs.Sanguosha:getCard(player:getMark("tupo_id"))
								if card then
									room:useCard(sgs.CardUseStruct(card, p, p))
								end
								room:setPlayerMark(player, "tupo_id", 0)
								local players = room:getOtherPlayers(p)
								local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
								slash:setSkillName("tupocard")
								for _,q in sgs.qlist(players) do
									if q:isProhibited(q, slash) then
										players:removeOne(q)
									end
								end
								if not players:isEmpty() then
									local target = room:askForPlayerChosen(p, players, self:objectName(), "@dummy-slash")
									if target then
										room:useCard(sgs.CardUseStruct(slash, p, target), true)
									end
								end
								break
							end
						end
						room:loseHp(effect.from)
					end
				end
			end
		elseif event == sgs.ChoiceMade then
			if not player:hasFlag("tupo_target") then return false end
			local choice_data = data:toString():split(":")
			if choice_data[1] == "cardUsed" and choice_data[2] == "slash" and choice_data[3]:startsWith("collateral-slash") then
				room:setPlayerFlag(player, "-tupo_target")
				room:setPlayerMark(player, "tupo_id", player:getWeapon():getRealCard():getId())
			end
		end
	end,
}

tuporecord = sgs.CreateTriggerSkill{
	name = "#tuporecord",
	events = {sgs.CardUsed,  sgs.CardFinished},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Collateral") and use.card:getSkillName() == "tupo" then
			room:setPlayerFlag(player, "tupo_used")
		end
	end,
}

DELTA_PLUS:addSkill(xiezhan)
DELTA_PLUS:addSkill(tupo)
DELTA_PLUS:addSkill(tuporecord)
extension:insertRelatedSkills("tupo", "#tuporecord")

BANSHEE = sgs.General(extension, "BANSHEE", "EFSF", 4, false, false)

mengshi = sgs.CreateTriggerSkill{
	name = "mengshi",
	events = {sgs.TargetSpecified, sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:isBlack() then
				for _,p in sgs.qlist(use.to) do
					if p:hasEquip() and room:askForSkillInvoke(player, self:objectName(), data) then
						room:broadcastSkillInvoke(self:objectName())
						local to_return = room:askForCardChosen(player, p, "e", self:objectName())
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION, player:objectName())
						room:obtainCard(p, sgs.Sanguosha:getCard(to_return), reason)
						if not player:getPhase() ~= sgs.Player_NotActive then
							room:addPlayerMark(player, self:objectName())
						end
					end
				end
			end
		else
			if player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player, self:objectName(), 0)
			end
		end
	end,
}

mengshislash = sgs.CreateTargetModSkill{
	name = "#mengshislash",
	residue_func = function(self, from)
		if from:hasSkill("mengshi") then
			return from:getMark("mengshi")
		else
			return 0
		end
	end
}

NTD2card = sgs.CreateSkillCard{
	name = "ntdtwo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("NTD")
		room:doLightbox("image=image/animate/ntdtwo.png", 1500)
		room:setEmotion(source, "NTD2")
		room:getThread():delay(2400)
		local json = require ("json")
		local general = sgs.Sanguosha:getGeneral("BANSHEE_NTD")
		assert(general)
		local jsonValue = {
			10,
			source:objectName(),
			general:objectName(),
			"baosang",
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		source:loseMark("@NTD2")
	    room:loseMaxHp(source)
		if not source:isKongcheng() then
			local n = 0
			local handcards = source:handCards()
			room:fillAG(handcards)
			for _,h in sgs.qlist(handcards) do
				if sgs.Sanguosha:getCard(h):isBlack() then
					n = n + 1
				end
			end
			if n > 0 then
				for i = 1, n, 1 do
					if not room:askForUseCard(source, "@@ntdtwo", "@ntdtwo") then break end
				end
			else
				room:getThread():delay(1500)
			end
			room:clearAG()
		end
		room:acquireSkill(source, "baosang")
	end
}

NTD2vs = sgs.CreateZeroCardViewAsSkill{
    name = "ntdtwo",
	response_pattern = "@@ntdtwo",
    view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@ntdtwo" then
			local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
			acard:setSkillName(self:objectName())
			return acard
		else
			return NTD2card:clone()
		end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@NTD2") > 0
    end
}

NTD2 = sgs.CreateTriggerSkill{
	name = "ntdtwo",
	frequency = sgs.Skill_Limited,
	limit_mark = "@NTD2",
	view_as_skill = NTD2vs,
	on_trigger = function() 
	end
}

baosangvs = sgs.CreateOneCardViewAsSkill{
	name = "baosang",
	filter_pattern = ".|black|.|hand",
	response_pattern = "@@baosang",
	response_or_use = true,
	view_as = function(self, card)
	    local pattern = sgs.Self:property("bsuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, card:getSuit(), card:getNumber())
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
    end
}

baosang = sgs.CreateTriggerSkill{
	name = "baosang",
	events = {sgs.TargetConfirming},
	view_as_skill = baosangvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isNDTrick() and use.to:contains(player) and (not player:isKongcheng())
			and room:askForSkillInvoke(player, self:objectName(), data) then
			local choice = room:askForChoice(player, self:objectName(), "indulgence+supply_shortage", data)
			room:setPlayerProperty(player, "bsuse", sgs.QVariant(choice))
			if room:askForUseCard(player, "@@baosang", "@baosang:"..choice) then
				use.to = sgs.SPlayerList()
				data:setValue(use)
			end
			room:setPlayerProperty(player, "bsuse", sgs.QVariant())
		end
	end
}

BANSHEE:addSkill(mengshi)
BANSHEE:addSkill(mengshislash)
BANSHEE:addSkill(NTD2)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("baosang") then skills:append(baosang) end
sgs.Sanguosha:addSkills(skills)
BANSHEE:addRelateSkill("baosang")
extension:insertRelatedSkills("mengshi", "#mengshislash")

BANSHEE_NTD = sgs.General(extension, "BANSHEE_NTD", "EFSF", 4, false, true, true)
BANSHEE_NTD:addSkill("mengshi")
BANSHEE_NTD:addSkill("ntdtwo")
BANSHEE_NTD:addRelateSkill("baosang")

NORN = sgs.General(extension, "NORN", "EFSF", 4, true, false)

function ShenshiMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "shenshi", ""))
		move.to_pile_name = "po"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "shenshi", ""))
		move.from_pile_name = "po"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = room:getAllPlayers(true)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

shenshicard = sgs.CreateSkillCard{
	name = "shenshi",
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select, player)
	    return #targets < 1 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, effect.from:objectName(), effect.to:objectName(), "shenshi","")
		room:moveCardTo(self, effect.from, effect.to, sgs.Player_PlaceHand, reason, true)
		ShenshiMove(self:getSubcards(), true, effect.to)
		room:setPlayerProperty(effect.to, "shenshi", sgs.QVariant(table.concat(sgs.QList2Table(self:getSubcards()), "+")))
	end,
}

shenshivs = sgs.CreateViewAsSkill{
	name = "shenshi",
	n = 3,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	response_pattern = "@@shenshi",
	view_as = function(self, cards)
		if #cards > 0 and #cards < 4 then
			local acard = shenshicard:clone()
			for _,c in ipairs(cards)do
				acard:addSubcard(c)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
    end,
}

shenshi = sgs.CreateTriggerSkill{
	name = "shenshi",
	events = {sgs.EventPhaseEnd},
	view_as_skill = shenshivs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and not player:isKongcheng() then
			room:askForUseCard(player, "@@shenshi", "@shenshi")
		end
	end,
}

shenshi_damage = sgs.CreateTriggerSkill{
	name = "#shenshi_damage",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self, player)
		return player and player:isAlive()
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Finish then
			local splayer = room:findPlayerBySkillName("shenshi")
			local list = player:property("shenshi"):toString():split("+")
			if #list > 0 then
				room:damage(sgs.DamageStruct(self:objectName(), splayer, player))
				local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				dummy:addSubcards(Table2IntList(list))
				room:throwCard(dummy, nil)
			end
		end
	end
}

shenshi_global = sgs.CreateTriggerSkill{
	name = "#shenshi_global",
	events = {sgs.CardsMoveOneTime, sgs.BeforeCardsMove},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() then
				local list = player:property("shenshi"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					for _,l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						end
					end
					ShenshiMove(to_remove, false, player)
					for _,id in sgs.qlist(to_remove) do
						table.removeOne(list, tostring(id))
					end
					local pattern = sgs.QVariant()
					if #list > 0 then
						pattern = sgs.QVariant(table.concat(list, "+"))
					end
					room:setPlayerProperty(player, "shenshi", pattern)
				end
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			local source = move.reason.m_playerId
			if source and move.from and move.from:objectName() ~= source and player:objectName() == source
				and move.from_places:contains(sgs.Player_PlaceHand) and move.reason.m_skillName ~= "longqi"
				and not(room:getTag("Dongchaer"):toString() == player:objectName()
				and room:getTag("Dongchaee"):toString() == move.from:objectName()) then
				local list = move.from:property("shenshi"):toString():split("+")
				if #list > 0 then
					if #list == 1 and move.from:getHandcards():length() == 1 then return false end
					local ids = sgs.IntList()
					for _,l in pairs(list) do
						ids:append(tonumber(l))
					end
					local to_move = move.card_ids
					local invisible_hands = move.from:getHandcards()
					for _,k in sgs.qlist(move.from:getHandcards()) do
						if ids:contains(k:getId()) then
							invisible_hands:removeOne(k)
						end
					end
					if invisible_hands:length() == 0 then
						local po = ids
						for _,x in sgs.qlist(move.card_ids) do
							if ids:contains(x) then
								room:fillAG(po)
								local id = room:askForAG(player, po, false, "shenshi")
								if id ~= -1 then
									to_move:append(id)
									to_move:removeOne(x)
									po:removeOne(id)
								end
								room:clearAG()
							end
						end
					else
						local hands = sgs.IntList()
						for _,i in sgs.qlist(move.card_ids) do
							if room:getCardPlace(i) == sgs.Player_PlaceHand then
								if ids:contains(i) then
									local rand = invisible_hands:at(math.random(0, invisible_hands:length() - 1)):getId()
									to_move:append(rand)
									to_move:removeOne(i)
									i = rand
								end
								hands:append(i)
							end
						end
						if hands:length() == move.from:getHandcardNum() or hands:length() == 0 then return false end
						local view = ids
						for _,j in sgs.qlist(hands) do
							if view:length() == 0 then break end
							local choice = room:askForChoice(player, "shenshi", "shenshipile+shenshihand", data)
							if choice == "shenshipile" then
								if view:length() == 1 then
									local id = view:first()
									to_move:append(id)
									to_move:removeOne(j)
									view:removeOne(id)
								else
									room:fillAG(view)
									local id = room:askForAG(player, view, false, "shenshi")
									if id ~= -1 then
										to_move:append(id)
										to_move:removeOne(j)
										view:removeOne(id)
									end
									room:clearAG()
								end
							else
								break
							end
						end
					end
					local bools = sgs.BoolList()
					for _,t in sgs.qlist(to_move) do
						bools:append(ids:contains(t))
					end
					move.card_ids = to_move
					move.open = bools
					data:setValue(move)
				end
			end
		end
	end
}

NTD3card = sgs.CreateSkillCard{
	name = "ntdthree",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:broadcastSkillInvoke("NTD")
		room:doLightbox("image=image/animate/ntdthree.png", 1500)
		room:setEmotion(source, "NTD3")
		room:getThread():delay(2400)
		local json = require ("json")
		local general = sgs.Sanguosha:getGeneral("NORN_NTD")
		assert(general)
		local jsonValue = {
			10,
			source:objectName(),
			general:objectName(),
			"zuzhou",
		}
		room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		source:loseMark("@NTD3")
	    room:loseMaxHp(source)
		if not source:isKongcheng() then
			local n = 0
			local handcards = source:handCards()
			room:fillAG(handcards)
			for _,h in sgs.qlist(handcards) do
				if sgs.Sanguosha:getCard(h):isBlack() then
					n = n + 1
				end
			end
			if n > 0 then
				for i = 1, n, 1 do
					if not room:askForUseCard(source, "@@ntdthree", "@ntdthree") then break end
				end
			else
				room:getThread():delay(1500)
			end
			room:clearAG()
		end
		room:acquireSkill(source, "zuzhou")
	end
}

NTD3vs = sgs.CreateZeroCardViewAsSkill{
    name = "ntdthree",
	response_pattern = "@@ntdthree",
    view_as = function(self)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "@@ntdthree" then
			local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
			acard:setSkillName(self:objectName())
			return acard
		else
			return NTD3card:clone()
		end
    end,
    enabled_at_play = function(self, player)
        return player:getMark("@NTD3") > 0
    end
}

NTD3 = sgs.CreateTriggerSkill{
	name = "ntdthree",
	frequency = sgs.Skill_Limited,
	limit_mark = "@NTD3",
	view_as_skill = NTD3vs,
	on_trigger = function() 
	end
}

zuzhou = sgs.CreateTriggerSkill{
	name = "zuzhou" ,
	events = {sgs.TargetConfirmed, sgs.TargetSpecified},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified or (event == sgs.TargetConfirmed and use.to:contains(player)) then
			if use.card and use.card:isKindOf("Slash") and use.card:isBlack() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					local duel = sgs.Sanguosha:cloneCard("duel", use.card:getSuit(), use.card:getNumber())
					duel:addSubcard(use.card)
					use.card = duel
					data:setValue(use)
				end
			end
		end
	end
}

xuanguang = sgs.CreateTriggerSkill
{
	name = "xuanguang",
	events = {sgs.Dying},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who:objectName() == player:objectName() and player:getMark("@xuanguang") == 0 and player:getMark("@NTD3") == 0 then
			room:broadcastSkillInvoke("xuanguang")
			room:doLightbox("image=image/animate/xuanguang.png", 1500)
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:setPlayerMark(player, "xuanguang", 1)
			player:gainMark("@xuanguang")
			removeWholeEquipArea(player)
			room:handleAcquireDetachSkills(player, "-shenshi|-zuzhou|#xuanguangfilter|#xuanguangdefense")
			room:recover(player, sgs.RecoverStruct(player, nil, 1 - player:getHp()))
			room:filterCards(player, player:getCards("he"), false)
			local json = require ("json")
			local general = sgs.Sanguosha:getGeneral("NORN_NTD")
			assert(general)
			local jsonValue = {
				10,
				player:objectName(),
				general:objectName(),
				"xuanguang",
			}
			room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
		end
	end
}

xuanguangfilter = sgs.CreateFilterSkill{
	name = "#xuanguangfilter",
	view_filter = function(self, card)
		return card:isKindOf("EquipCard")
	end,
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(peach)
		return wrap
	end
}

xuanguangdefense = sgs.CreateTriggerSkill
{
	name = "#xuanguangdefense",
	events = {sgs.DamageForseen},
	can_trigger = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			if p:getMark("@xuanguang") > 0 then
				return true
			end
		end
		return false
	end,
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.nature ~= sgs.DamageStruct_Normal and player:getEquips():isEmpty() then
			room:notifySkillInvoked(player, "xuanguang")
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#xuanguang"
			log.from = player
			log.arg = "xuanguang"
			room:sendLog(log)
			return true
		end
    end
}

NORN:addSkill(shenshi)
NORN:addSkill(shenshi_damage)
NORN:addSkill(shenshi_global)
NORN:addSkill(xuanguang)
NORN:addSkill(NTD3)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("zuzhou") then skills:append(zuzhou) end
if not sgs.Sanguosha:getSkill("#xuanguangfilter") then skills:append(xuanguangfilter) end
if not sgs.Sanguosha:getSkill("#xuanguangdefense") then skills:append(xuanguangdefense) end
sgs.Sanguosha:addSkills(skills)
NORN:addRelateSkill("zuzhou")
extension:insertRelatedSkills("shenshi", "#shenshi_damage")

NORN_NTD = sgs.General(extension, "NORN_NTD", "EFSF", 4, true, true, true)
NORN_NTD:addSkill("shenshi")
NORN_NTD:addSkill("ntdthree")
NORN_NTD:addRelateSkill("zuzhou")

PHENEX = sgs.General(extension, "PHENEX", "EFSF", 4, true, true, true)

shenniaocard = sgs.CreateSkillCard{
	name = "shenniao",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
	    return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
	    local room = effect.from:getRoom()
		room:setPlayerMark(effect.to, "@shenniao", 1)
		room:setPlayerMark(effect.to, "Equips_Nullified_to_Yourself", 1)
		if effect.to:hasEquip() then
			local log = sgs.LogMessage()
			log.type = "$shenniaolog"
			log.from = effect.from
			log.to:append(effect.to)
			log.arg = self:objectName()
			local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			card:addSubcards(effect.to:getEquips())
			log.card_str = card:subcardString()
			room:sendLog(log)
		end
	end,
}

shenniaovs = sgs.CreateViewAsSkill{
    name = "shenniao",
    n = 2,
	view_filter = function(self, selected, to_select)
		return to_select:isKindOf("BasicCard")
	end,
    view_as = function(self, cards)
	if #cards == 2 then
        local acard = shenniaocard:clone()
		for _,card in pairs(cards) do
			acard:addSubcard(card)
		end
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return not player:hasUsed("#shenniao")
    end,
}

shenniao = sgs.CreateTriggerSkill{
	name = "shenniao",
	events = {sgs.EventPhaseStart},
	view_as_skill = shenniaovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
    if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
		    for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			    if p:getMark("@shenniao") > 0 then
				    room:setPlayerMark(p, "@shenniao", 0)
					room:setPlayerMark(p, "Equips_Nullified_to_Yourself", 0)
				end
			end
		end
	end
	end,
}

PHENEX:addSkill(shenniao)

EX_S = sgs.General(extension, "EX_S", "EFSF", 4, true, false)

fanshecard = sgs.CreateSkillCard{
	name = "fanshe",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local ids = room:getNCards(1, false)
		local move = sgs.CardsMoveStruct()
		move.card_ids = ids
		move.to = source
		move.to_place = sgs.Player_PlaceTable
		move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
		room:moveCardsAtomic(move, true)
		local card = sgs.Sanguosha:getCard(ids:first())
		if card:isRed() then
			room:setEmotion(source, "judgegood")
			local target = room:askForPlayerChosen(source, room:getOtherPlayers(source), self:objectName(), "@fanshe")
			if target then
				target:addToPile("INCOM", card)
				room:setEmotion(target, "INCOM1")
			end
		else
			room:setEmotion(source, "judgebad")
			room:throwCard(card, nil)
		end
	end,
}

fanshevs = sgs.CreateViewAsSkill{
	name = "fanshe",
	n = 0,
	view_as = function(self, cards)
		if #cards == 0 then
			local acard = fanshecard:clone()
			acard:setSkillName("fanshe")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#fanshe")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

fanshe = sgs.CreateTriggerSkill{
	name = "fanshe",
	events = {sgs.EventPhaseStart, sgs.PreCardUsed, sgs.EventPhaseEnd},
	view_as_skill = fanshevs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPile("INCOM"):length() > 0 then
					local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
					card:addSubcards(p:getPile("INCOM"))
					local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXCHANGE_FROM_PILE, player:objectName())
					room:obtainCard(player, card, reason)
				end
			end
		end
	elseif event == sgs.PreCardUsed then
		local use = data:toCardUse()
		if use.card and not use.card:isKindOf("SkillCard") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getPile("INCOM"):length() > 0 then
					local move = sgs.CardsMoveStruct()
					local int = sgs.IntList()
					int:append(use.card:getId())
					move.card_ids = int
					move.to = p
					move.to_place = sgs.Player_PlaceTable
					move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_USE, p:objectName(), self:objectName(), nil)
					room:moveCardsAtomic(move, true)
					room:setEmotion(p, "INCOM2")
					room:doAnimate(1, player:objectName(), p:objectName())
					room:getThread():delay(0400)
					local log = sgs.LogMessage()
					log.type = "#BecomeUser"
					log.from = p
					log.card_str = use.card:toString()
					room:sendLog(log)
					use.from = p
					if use.card:isKindOf("AOE") then
						use.to = room:getOtherPlayers(p)
					elseif use.card:isKindOf("GlobalEffect") then
						use.to = room:getAlivePlayers()
					elseif use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") or use.card:isKindOf("Analeptic") or
					use.card:isKindOf("EquipCard") or use.card:isKindOf("Lightning") then
						local list = sgs.SPlayerList()
						list:append(p)
						use.to = list
					end
					data:setValue(use)
					break
				end
			end
		end
	elseif event == sgs.EventPhaseEnd then -- For AI use only
		if player:getPhase() == sgs.Player_Play then
			if player:getAI() then
				if not player:hasUsed("#fanshe") then
					room:askForUseCard(player, "@@fanshe", "@fansheAI")
				end
			end
		end
	end
	end,
}

fansheD = sgs.CreateTriggerSkill{
	name = "#fansheD",
	events = {sgs.ConfirmDamage},
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getPile("INCOM"):length() > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if damage and damage.card and not damage.card:isKindOf("SkillCard") then
		local skillowners = room:findPlayersBySkillName("fanshe")
		for _,p in sgs.qlist(skillowners) do
			if p:hasUsed("#fanshe") then
				room:setEmotion(player, "INCOM2")
				room:doAnimate(1, p:objectName(), player:objectName())
				room:getThread():delay(0400)
				room:doAnimate(1, player:objectName(), damage.to:objectName())
				damage.from = p
				data:setValue(damage)
				break
			end
		end
	end
	end,
}

fansheTM = sgs.CreateTargetModSkill{
	name = "#fansheTM",
	pattern = ".",
	distance_limit_func = function(self, player, card)
		local valid = false
		for _,p in sgs.qlist(player:getAliveSiblings()) do
			if p:getPile("INCOM"):length() > 0 then
				valid = true
				break
			end
		end
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") and valid then
			return 998
		else
			return 0
		end
	end,
	extra_target_func = function(self, player, card)
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					return sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, p, card)
				else
					return 0
				end
			end
		end
	end,
	residue_func = function(self, player, card)
		if player:hasSkill("fanshe") and player:hasUsed("#fanshe") then
			for _,p in sgs.qlist(player:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					return 998
				else
					return 0
				end
			end
		end
	end,
}

fansheP = sgs.CreateProhibitSkill
{
	name = "#fansheP",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("fanshe") and from:hasUsed("#fanshe") and to then
			for _,p in sgs.qlist(from:getAliveSiblings()) do
				if p:getPile("INCOM"):length() > 0 then
					if p:isProhibited(p, card) or not card:isAvailable(p) then
						return true
					else
						return (card:isKindOf("Slash") and not p:canSlash(to)) or
						((card:isKindOf("Snatch") or card:isKindOf("SupplyShortage")) and (p:objectName() == to:objectName()
						or p:distanceTo(to) > 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, p, card)))
						or ((card:isKindOf("Dismantlement") or card:isKindOf("Collateral") or card:isKindOf("Duel") or
						card:isKindOf("Indulgence")) and p:objectName() == to:objectName())
					end
				end
			end
		end
	end,
}

ALICE = sgs.CreateTriggerSkill{
	name = "ALICE",
	events = {sgs.DamageInflicted},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if room:askForSkillInvoke(player, self:objectName(), data) then
			room:setPlayerFlag(player, "-ALICE")
			local ids = sgs.IntList()
			for i=0, 2, 1 do
				ids:append(room:getDrawPile():at(i))
			end
			room:fillAG(ids, player)
			room:getThread():delay(1500)
			room:clearAG(player)
			local plist = sgs.SPlayerList()
			plist:append(player)
			local list = sgs.IntList()
			if sgs.Sanguosha:getCard(ids:at(0)):getSuit() == sgs.Sanguosha:getCard(ids:at(1)):getSuit() then
				if not list:contains(ids:at(0)) then list:append(ids:at(0)) end
				if not list:contains(ids:at(1)) then list:append(ids:at(1)) end
			end
			if sgs.Sanguosha:getCard(ids:at(0)):getSuit() == sgs.Sanguosha:getCard(ids:at(2)):getSuit() then
				if not list:contains(ids:at(0)) then list:append(ids:at(0)) end
				if not list:contains(ids:at(2)) then list:append(ids:at(2)) end
			end
			if sgs.Sanguosha:getCard(ids:at(1)):getSuit() == sgs.Sanguosha:getCard(ids:at(2)):getSuit() then
				if not list:contains(ids:at(1)) then list:append(ids:at(1)) end
				if not list:contains(ids:at(2)) then list:append(ids:at(2)) end
			end
			if list:length() >= 2 then
				local move = sgs.CardsMoveStruct()
				move.card_ids = ids
				move.to = player
				move.to_place = sgs.Player_PlaceTable
				move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, player:objectName(), self:objectName(), nil)
				room:moveCardsAtomic(move, true)
				local move2 = sgs.CardsMoveStruct(list, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceHand,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DEMONSTRATE, player:objectName(), self:objectName(), nil))
				local moves = sgs.CardsMoveList()
				moves:append(move2)
				room:notifyMoveCards(true, moves, false, plist)
				room:notifyMoveCards(false, moves, false, plist)
				local pattern = ""
				for _,id in sgs.qlist(list) do
					if pattern == "" then
						pattern = sgs.Sanguosha:getCard(id):toString()
					else
						pattern = pattern .. "," .. sgs.Sanguosha:getCard(id):toString()
					end
				end
				local card2obtain = room:askForCard(player, pattern, "@ALICE-obtain", data, sgs.Card_MethodNone,
										nil, false, self:objectName(), false)
				if card2obtain then
					local move3 = sgs.CardsMoveStruct(card2obtain:getId(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movess = sgs.CardsMoveList()
					movess:append(move3)
					room:notifyMoveCards(true, movess, false, plist)
					room:notifyMoveCards(false, movess, false, plist)
					room:obtainCard(player, card2obtain)
					list:removeOne(card2obtain:getId())
				else
					local random_id = list:at(math.random(0, list:length()-1))
					local move3 = sgs.CardsMoveStruct(random_id, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movess = sgs.CardsMoveList()
					movess:append(move3)
					room:notifyMoveCards(true, movess, false, plist)
					room:notifyMoveCards(false, movess, false, plist)
					room:obtainCard(player, random_id)
					list:removeOne(random_id)
				end
				if damage.from then
					if list:length() >= 2 then
						local pattern2 = ""
						for _,id2 in sgs.qlist(list) do
							if pattern2 == "" then
								pattern2 = sgs.Sanguosha:getCard(id2):toString()
							else
								pattern2 = pattern2 .. "," .. sgs.Sanguosha:getCard(id2):toString()
							end
						end
						local card2give = room:askForCard(player, pattern2, "@ALICE-give:"..damage.from:getGeneralName(),
											data, sgs.Card_MethodNone, damage.from, false, self:objectName(), true)
						if card2give then
							local move3 = sgs.CardsMoveStruct(card2give:getId(), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
							local movess = sgs.CardsMoveList()
							movess:append(move3)
							room:notifyMoveCards(true, movess, false, plist)
							room:notifyMoveCards(false, movess, false, plist)
							room:obtainCard(damage.from, card2give)
							list:removeOne(card2give:getId())
						else
							local random_id = list:at(math.random(0, list:length()-1))
							local move3 = sgs.CardsMoveStruct(random_id, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
							local movess = sgs.CardsMoveList()
							movess:append(move3)
							room:notifyMoveCards(true, movess, false, plist)
							room:notifyMoveCards(false, movess, false, plist)
							room:obtainCard(damage.from, random_id)
							list:removeOne(random_id)
						end
					else
						local move3 = sgs.CardsMoveStruct(list:at(0), player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
						local movess = sgs.CardsMoveList()
						movess:append(move3)
						room:notifyMoveCards(true, movess, false, plist)
						room:notifyMoveCards(false, movess, false, plist)
						room:obtainCard(damage.from, list:at(0))
						list:removeOne(list:at(0))
					end
					room:setPlayerFlag(player, "ALICE")
				end
				for i=0, 2, 1 do
					if list:contains(ids:at(i)) then
						room:throwCard(ids:at(i), nil)
					end
				end
				if list:length() > 0 then
					local movef = sgs.CardsMoveStruct(list, player, nil, sgs.Player_PlaceHand, sgs.Player_PlaceTable,
						sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_UNKNOWN, player:objectName(), self:objectName(), nil))
					local movesf = sgs.CardsMoveList()
					movesf:append(movef)
					room:notifyMoveCards(true, movesf, false, plist)
					room:notifyMoveCards(false, movesf, false, plist)
				end
				if player:hasFlag("ALICE") then
					room:setPlayerFlag(player, "-ALICE")
					return true
				end
			end
		end
	end,
}

EX_S:addSkill(fanshe)
EX_S:addSkill(fansheD)
EX_S:addSkill(ALICE)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#fansheTM") then skills:append(fansheTM) end
if not sgs.Sanguosha:getSkill("#fansheP") then skills:append(fansheP) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("fanshe", "#fansheD")

WZ = sgs.General(extension, "WZ", "OTHERS", 4, true, false)

wzpointcard = sgs.CreateSkillCard{
	name = "wzpoint",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local x = source:getMark("@point")
		source:loseAllMarks("@point")
		source:drawCards(x)
	end
}

wzpoint = sgs.CreateZeroCardViewAsSkill{
	name = "wzpoint",
	view_as = function(self, cards)
		return wzpointcard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@point") > 0
	end,
}

feiyi = sgs.CreateTargetModSkill{
	name = "feiyi",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHp() <= 2 then
			return 998
		end
	end,
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:getHp() == 1 then
			return 1
		end
	end,
}

liuxingvs = sgs.CreateViewAsSkill{
	name = "liuxing",
	n = 2,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self, cards)
	    if #cards == 2 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			for _,card in ipairs(cards) do
			    slash:addSubcard(card)
			end
			slash:setSkillName("liuxing")
			return slash
		end
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and player:getHandcardNum() >= 2
	end,
	enabled_at_response = function(self, player, pattern)
		if pattern == "slash" then
		    return player:getHandcardNum() >= 2 and
			sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
		end
		return false
	end,
}

liuxing = sgs.CreateTriggerSkill{
	name = "liuxing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed,sgs.ConfirmDamage,sgs.CardFinished},
	view_as_skill = liuxingvs,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
	if event == sgs.CardUsed then
		if use.card:isKindOf("Slash") and use.card:getSkillName() == "liuxing" then
			player:gainMark("@point")
			local judge = sgs.JudgeStruct()
		    judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge:isGood() then
				room:setCardFlag(use.card, "liuxing")
			end
		end
	end
	if event == sgs.ConfirmDamage then
	    local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "liuxing" and damage.card:hasFlag("liuxing") then
			room:broadcastSkillInvoke("liuxing",5)
			room:clearCardFlag(damage.card)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
		return false
	end
	if event == sgs.CardFinished then
	    if use.card:hasFlag("liuxing") then
		    room:clearCardFlag(use.card)
		end
	end
	end,
}

lingshi = sgs.CreateTriggerSkill{
	name = "lingshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
    if player:getPhase() == sgs.Player_Start and player:getMark("@point") == 3 and room:askForSkillInvoke(player, "lingshi", data) then
		if room:findPlayer("EPYON") then
			room:broadcastSkillInvoke("qishi",3)
			room:getThread():delay(2400)
			room:broadcastSkillInvoke("lingshi",8)
			room:broadcastSkillInvoke("lingshi",7)
		else
			room:broadcastSkillInvoke("lingshi",8)
			room:broadcastSkillInvoke("lingshi",math.random(1,6))
		end
		room:askForGuanxing(player, room:getNCards(3), sgs.Room_GuanxingUpOnly)
	end
	end,
}

WZ:addSkill(wzpoint)
WZ:addSkill(feiyi)
WZ:addSkill(liuxing)
WZ:addSkill(lingshi)

EPYON = sgs.General(extension, "EPYON", "OTHERS", 4, true, false)

qishi = sgs.CreateFilterSkill{
	name = "qishi",
	view_filter = function(self, card)
		return card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("FireAttack")
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName(self:objectName())
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end,
}

--[[qishislash = sgs.CreateTargetModSkill{
	name = "#qishislash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
	if player and player:hasSkill("qishi") then
	    return (1 - player:getAttackRange(true))
	end
	end,
}]]

qishislash = sgs.CreateAttackRangeSkill{
	name = "#qishislash",
	fixed_func = function(self, player, include_weapon)
		if player:hasSkill("qishi") then
			return 1
		end
	end,
}

mosu = sgs.CreateTriggerSkill{
	name = "mosu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.EventPhaseEnd},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.Damaged then
	    local damage = data:toDamage()
		if damage.from and damage.from:getPhase() ~= sgs.Player_NotActive and damage.from:objectName() ~= player:objectName()
			and player:getMark("mosufrom") == 0 and room:askForSkillInvoke(player, "mosu", data) then
			if room:findPlayer("WZ+WZC") then
			    room:broadcastSkillInvoke("mosu",7)
				room:getThread():delay(1700)
				room:broadcastSkillInvoke("wzpoint",4)
			else
				room:broadcastSkillInvoke("mosu",math.random(1,6))
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				room:setPlayerMark(p,"mosufrom",0)
				room:setPlayerMark(p,"mosuto",0)
			end
			room:setPlayerMark(player,"mosufrom",1)
			room:setPlayerMark(damage.from,"mosuto",1)
			local log = sgs.LogMessage()
			log.type = "#SkipAllPhase"
			log.from = damage.from
			room:sendLog(log)
			local log2 = sgs.LogMessage()
			log2.type = "#Fangquan"
			log2.to:append(player)
			room:sendLog(log2)
			room:clearAG()
			player:gainAnExtraTurn()
			room:throwEvent(sgs.TurnBroken)
		end
	elseif event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Finish then
		    if player:getMark("mosufrom") > 0 then
			    room:setPlayerMark(player,"mosufrom",0)
			end
			for _,p in sgs.qlist(room:getPlayers()) do
				if p:getMark("mosuto") > 0 then
				    room:setPlayerMark(p,"mosuto",0)
				end
			end
		end
	end
	end,
}

mosudistance = sgs.CreateDistanceSkill{
    name = "#mosudistance",
    correct_func = function(self, from, to)
		if from and from:hasSkill("mosu") and from:getMark("mosufrom") > 0 and to and to:getMark("mosuto") > 0 then
			return -998
		end
    end
}

cishi = sgs.CreateTriggerSkill{
	name = "cishi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Death},
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local death = data:toDeath()
		if death.damage and death.damage.from and death.damage.from:hasSkill("cishi") and death.damage.from:getPhase() == sgs.Player_Play and death.who:objectName() == player:objectName() then
			if room:askForSkillInvoke(death.damage.from, "cishi", data) then
				room:broadcastSkillInvoke("cishi")
				room:setPlayerFlag(death.damage.from,"cishi")
				death.damage.from:drawCards(2)
			end
		end
	end
}

cishislash = sgs.CreateTargetModSkill{
	name = "#cishislash",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) and player:hasFlag("cishi") then
			return 998
		end
	end,
}

EPYON:addSkill(qishi)
EPYON:addSkill(qishislash)
EPYON:addSkill(mosu)
EPYON:addSkill(mosudistance)
EPYON:addSkill(cishi)
EPYON:addSkill(cishislash)
extension:insertRelatedSkills("qishi", "#qishislash")
extension:insertRelatedSkills("mosu", "#mosudistance")
extension:insertRelatedSkills("cishi", "#cishislash")

WZC = sgs.General(extension, "WZC", "OTHERS", 4, true, false)

shuangpaocard = sgs.CreateSkillCard{
	name = "shuangpao",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:loseHp(source)
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#shuangpao"
        room:sendLog(log)
	end,
}

shuangpaovs = sgs.CreateViewAsSkill{
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
		return not player:hasUsed("#shuangpao")
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

shuangpao = sgs.CreateTriggerSkill{
	name = "shuangpao",
	events = {sgs.ConfirmDamage},
	view_as_skill = shuangpaovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:distanceTo(damage.to) > 1 and damage.card:isKindOf("Slash") and player:hasUsed("#shuangpao") then
			damage.damage = damage.damage + 1
		    data:setValue(damage)
			return false
		end
	end,
}

ew_lingshi = sgs.CreateTriggerSkill{
	name = "ew_lingshi",
	frequency = sgs.Skill_Limited,
	events = {sgs.GameStart,sgs.HpLost, sgs.Damaged},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getMark("@ew_lingshi") == 0 then
		    player:gainMark("@ew_lingshi")
		end
	end
	if event == sgs.HpLost or event == sgs.Damaged then
		if player:isKongcheng() and player:getMark("@ew_lingshi") > 0 and room:askForSkillInvoke(player, "ew_lingshi", data) then
		    player:loseMark("@ew_lingshi")
			local sp_voice = 0
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				if p:getGeneralName() == "EPYON" then
					sp_voice = 1
					break
				elseif p:getGeneralName() == "ALTRON" then
				    sp_voice = 2
					break
				end
			end
			if sp_voice == 1 then
			    room:broadcastSkillInvoke("qishi",3)
				--room:getThread():delay(2400)
				room:doSuperLightbox("WZC", self:objectName())
				room:broadcastSkillInvoke("ew_lingshi",8)
				room:broadcastSkillInvoke("ew_lingshi",7)
			elseif sp_voice == 2 then
			    room:broadcastSkillInvoke("ew_lingshi", 9)
				--room:getThread():delay(3000)
				room:doSuperLightbox("WZC", self:objectName())
				room:broadcastSkillInvoke("ew_lingshi",8)
			else
				room:broadcastSkillInvoke("ew_lingshi",8)
				room:broadcastSkillInvoke("ew_lingshi",math.random(1,6))
				room:doSuperLightbox("WZC", self:objectName())
			end
			local id = sgs.Sanguosha:getCard(room:getDrawPile():at(room:getDrawPile():length()-1)):getId()
			room:askForGuanxing(player, room:getNCards(10))
			while sgs.Sanguosha:getCard(room:getDrawPile():at(room:getDrawPile():length()-1)):getId() ~= id do
			    room:obtainCard(player, room:getDrawPile():at(room:getDrawPile():length()-1), false)
			end
			player:turnOver()
		end
	end
	end,
}

WZC:addSkill("feiyi")
WZC:addSkill(shuangpao)
WZC:addSkill(ew_lingshi)

DSH = sgs.General(extension, "DSH", "OTHERS", 4, true, false)

yindun = sgs.CreateTriggerSkill
{
	name = "yindun",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if player:getPhase() == sgs.Player_Finish and room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke(self:objectName())
		player:drawCards(1)
		player:turnOver()
	end
	end,
}

yindunp = sgs.CreateProhibitSkill
{
	name = "#yindunp",
	is_prohibited = function(self, from, to, card)
		if(to and to:hasSkill("yindun") and not to:faceUp()) then
			return card:isKindOf("Slash")
		end
	end,
}

anshalist = {}
ansha = sgs.CreateTriggerSkill{
    name = "ansha",
    events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
    priority = -1,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
	if event == sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if room:getCurrent():getPhase() ~= sgs.Player_Discard then return false end
		for _,card_id in sgs.qlist(move.card_ids) do
			local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
			if flag == sgs.CardMoveReason_S_REASON_DISCARD and room:getCardPlace(card_id) == sgs.Player_DiscardPile then
                table.insert(anshalist, card_id)
			end
        end
	end
	if event == sgs.EventPhaseEnd then
        if #anshalist == 0 or player:getPhase() ~= sgs.Player_Discard then return false end
		while #anshalist > 0 do
	        table.remove(anshalist)
	    end
		for _,selfplayer in sgs.qlist(allplayers) do
            if selfplayer:objectName() == player:objectName() or
			selfplayer:faceUp() or
			selfplayer:isNude() then return false end
			if room:askForSkillInvoke(selfplayer, self:objectName(), data) then
				room:broadcastSkillInvoke(self:objectName())
				room:askForDiscard(selfplayer, "ansha", 1, 1, false, true)
				if not selfplayer:faceUp() then
					selfplayer:turnOver()
				end
				room:doAnimate(1, selfplayer:objectName(), player:objectName())
				room:loseHp(player)
				--[[local x = player:getMaxCards()
				local z = player:getHandcardNum()
				if z > x then
					local e = z-x
					room:askForDiscard(player, "gamerule", e, e)
				end]]
			end
		end
	end
    end,
}

DSH:addSkill(yindun)
DSH:addSkill(yindunp)
DSH:addSkill(ansha)
extension:insertRelatedSkills("yindun", "#yindunp")

HAC = sgs.General(extension, "HAC", "OTHERS", 4, true, false)

gelinvs = sgs.CreateViewAsSkill{
    name = "gelin",
	n = 2,
	expand_pile = "dan",
	view_filter = function(self, selected, to_select)
		local pat = ".|.|.|dan"
		if string.endsWith(pat, "!") then
			if sgs.Self:isJilei(to_select) then return false end
			pat = string.sub(pat, 1, -2)
		end
	    local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if to_select:hasFlag("using") then return false end
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return #selected == 0 and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or
		(usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return #selected == 0 and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
			else
				return (#selected <= 1) and sgs.Sanguosha:matchExpPattern(pat, sgs.Self, to_select)
			end
		end
		return false
	end,
    view_as = function(self, cards)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY or pattern == "slash" then
			if #cards == 1 then
				local glcard = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				glcard:addSubcard(cards[1])
				glcard:setSkillName(self:objectName())
				return glcard
			else
				return nil
			end
		else
			if #cards == 2 then
				local glcard = sgs.Sanguosha:cloneCard("jink", sgs.Card_SuitToBeDecided, -1)
				glcard:addSubcard(cards[1])
				glcard:addSubcard(cards[2])
				glcard:setSkillName(self:objectName())
				return glcard
			else
				return nil
			end
		end
    end,
    enabled_at_play = function(self,player)
        return sgs.Slash_IsAvailable(player) and player:getPile("dan"):length() >= 1
    end,
	enabled_at_response = function(self, player, pattern)
		return (pattern == "slash" or pattern == "jink") and player:getPile("dan"):length() >= 1
	end,
}

gelin = sgs.CreateTriggerSkill{
	name = "gelin",
	events = {sgs.GameStart, sgs.CardsMoveOneTime},
	view_as_skill = gelinvs,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getPile("dan"):isEmpty() then
	        player:addToPile("dan", room:getNCards(10))
		end
	end
	end,
}

saoshe = sgs.CreateTriggerSkill
{
	name = "saoshe",
	events = {sgs.CardFinished,sgs.EventPhaseStart},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(use.to) do
				room:setPlayerFlag(p, "ssp")
			end
		end
	end
    if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Discard then
			for _,p in sgs.qlist(room:getAlivePlayers()) do
				room:setPlayerFlag(p, "-ssp")
			end
		end
	end
	end,
}

saoshet = sgs.CreateTargetModSkill{
	name = "#saoshet",
	pattern = "Slash",
	residue_func = function(self, player)
		if player:hasSkill(self:objectName()) then
			return player:getAliveSiblings():length() - 1
		end
	end,
}

saoshep = sgs.CreateProhibitSkill
{
	name = "#saoshep",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("saoshe") and
		not(from:getSlashCount() >= from:getAliveSiblings():length() and from:canSlashWithoutCrossbow()) and
		not((from:getWeapon() and from:getWeapon():getClassName() == "Crossbow")) and to and to:hasFlag("ssp") then
			return card:isKindOf("Slash")
		end
	end,
}

--[[感谢小胖子唐飞通宵完成，但AI依然不礼貌→_→
function getMarkCount(room)
	local splist = room:getAllPlayers(true)
	local n = 0
	for _, p in sgs.qlist(splist) do
		n = n + p:getMark("numforcount")
	end
	return n
end

saoshe = sgs.CreateTriggerSkill{
	name = "saoshe",
	events = {sgs.CardFinished, sgs.EventPhaseStart, sgs.Death},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			local tos = use.to
			for _, to in sgs.qlist(tos) do
				room:setPlayerMark(to, "numforcount", to:getMark("numforcount") + 1)
				local n = player:getSlashCount()
				local sum = getMarkCount(room)
				local ton = to:getMark("numforcount")
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				local valid = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash)
				if sum > n then
					local y = sum - n
					room:setPlayerMark(to, "numforcount", to:getMark("numforcount") - y)
				end
				if not player:canSlashWithoutCrossbow() then
					local ton = to:getMark("numforcount")
					local splist = room:getAllPlayers()
					local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
					for _, p in sgs.qlist(splist) do
						if not (p:hasFlag("countmax") and p:getMark("numforcount") < valid) then continue end
						room:setPlayerFlag(p, "-countmax")
						if table.contains(nameslist, p:objectName()) then continue end
						table.insert(nameslist, p:objectName())
					end
					room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
					if sum >= valid then
						if ton < valid then continue end
						if to:hasFlag("countmax") then continue end
						local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
						table.removeOne(nameslist, to:objectName())
						room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
						room:setPlayerFlag(to, "countmax")
					end
				end
			end
		else
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
			local valid = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, player, slash)
			local splist = room:getAllPlayers()
			for _, p in sgs.qlist(splist) do
				if not (p:hasFlag("countmax") and p:getMark("numforcount") < valid) then continue end
				room:setPlayerFlag(p, "-countmax")
				if table.contains(nameslist, p:objectName()) then continue end
				table.insert(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	elseif event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_Play then
			local splist = room:getAllPlayers(true)
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			for _, p in sgs.qlist(splist) do
			    if table.contains(nameslist, p:objectName()) then continue end
				table.insert(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		elseif player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish then
			local splist = room:getAllPlayers(true)
			local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
			for _, p in sgs.qlist(splist) do
				room:setPlayerMark(p, "numforcount", 0)
				if p:hasFlag("countmax") or p:isDead() then continue end
				table.removeOne(nameslist, p:objectName())
			end
			room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	elseif event == sgs.Death then
		local death = data:toDeath()
		if death.who:objectName() == player:objectName() then return false end
		local nameslist = player:property("extra_slash_specific_assignee"):toString():split("+")
		table.removeOne(nameslist, death.who:objectName())
		room:setPlayerProperty(player, "extra_slash_specific_assignee", sgs.QVariant(table.concat(nameslist, "+")))
		end
	end
}]]

HAC:addSkill(gelin)
HAC:addSkill(saoshe)
HAC:addSkill(saoshet)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#saoshep") then skills:append(saoshep) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("saoshe", "#saoshet")

SANDROCK = sgs.General(extension, "SANDROCK", "OTHERS", 4, true, false)

shuanglian = sgs.CreateTriggerSkill{
	name = "shuanglian",
	events = {sgs.CardUsed,sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local can_invoke = false
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if player:inMyAttackRange(p) then
				can_invoke = true
				break
			end
		end
	if event == sgs.CardUsed then
	    local use = data:toCardUse()
		if use.card:isKindOf("Slash") and (not player:isKongcheng()) and can_invoke and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("slash")) then
            local jink = room:askForCard(player, "Jink", "@@shuanglianjink", data, sgs.Card_MethodDiscard, player, false, self:objectName(), false)
			if jink then
				room:broadcastSkillInvoke("shuanglian", 1)
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player)) do
					if player:inMyAttackRange(p) then
						tos:append(p)
					end
				end
				local target = room:askForPlayerChosen(player, tos, "shuanglian", "@@shuanglianjinktar", false, true)
				local acard = room:askForCard(target, "jink", "@@shuanglianjinkres", data, sgs.Card_MethodResponse, target, false, self:objectName(), false)
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
		    end
		end
	elseif event == sgs.CardResponded then
		local card = data:toCardResponse().m_card
		if card:isKindOf("Jink") and can_invoke and room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("jink")) then
			room:setPlayerFlag(player, "shuanglian_jink")
			local tou = sgs.SPlayerList()
			for _,r in sgs.qlist(room:getOtherPlayers(player)) do
				if player:canSlash(r, true) and not r:isProhibited(r, sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)) then
					tou:append(r)
				end
			end
			local targetr = room:askForPlayerChosen(player, tou, "shuanglian", "@@shuanglianslashtar", true, true)
			if targetr then
				room:broadcastSkillInvoke("shuanglian", 2)
			    local slashr = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
				slashr:setSkillName("shuangliancard")
				player:turnOver()
				room:useCard(sgs.CardUseStruct(slashr, player, targetr, true), true)
			end
			room:setPlayerFlag(player, "-shuanglian_jink")
		end
	end
	end,
}

zaizhancard = sgs.CreateSkillCard{
	name = "zaizhan",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return #targets < player:getLostHp()
	end,
	on_use = function(self, room, source, targets)
	    source:loseMark("@zaizhan")
		room:doSuperLightbox("SANDROCK", "zaizhan")
		source:turnOver()
		local all = sgs.SPlayerList()
		for _,p in ipairs(targets) do
		    all:append(p)
		end
		room:drawCards(all, 1, self:objectName())
		for _,q in ipairs(targets) do
		    q:gainAnExtraTurn()
		end
	end,
}

zaizhanvs = sgs.CreateZeroCardViewAsSkill{
	name = "zaizhan" ,
	view_as = function()
	    local acard = zaizhancard:clone()
		acard:setSkillName("zaizhan")
		return acard
	end,
	enabled_at_play = function(self, player)
		return false
	end,
	enabled_at_response=function(self, player, pattern) 
    return pattern == "@@zaizhan" and player:getMark("@zaizhan") > 0
end,
}

zaizhan = sgs.CreateTriggerSkill{
	name = "zaizhan",
	events = {sgs.GameStart, sgs.EventPhaseEnd},
	frequency = sgs.Skill_Limited,
	view_as_skill = zaizhanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	if event == sgs.GameStart then
	    if player:getMark("@zaizhan") == 0 then
		    player:gainMark("@zaizhan")
		end
	end
	if event == sgs.EventPhaseEnd then
	    if player:getPhase() == sgs.Player_Finish and player:getMark("@zaizhan") > 0 and player:isWounded() and
		room:askForSkillInvoke(player, self:objectName(), data) then
		    room:askForUseCard(player, "@@zaizhan", "#zaizhan")
		end
	end
	end,
}

SANDROCK:addSkill(shuanglian)
SANDROCK:addSkill(zaizhan)

ALTRON = sgs.General(extension, "ALTRON", "OTHERS", 4, true, false)

shuanglongcard = sgs.CreateSkillCard{
    name = "shuanglong",
    will_throw = false,
    target_fixed = false,
    filter = function(self,targets,to_select,player)
        return to_select:objectName() ~= player:objectName() and (not to_select:isKongcheng()) and #targets < 1
    end,
    on_effect=function(self,effect)          
        local room = effect.from:getRoom()
        if (effect.from:pindian(effect.to,"shuanglong",self)) then
			room:setPlayerFlag(effect.from, "shuanglong_success")
            room:addPlayerMark(effect.to, "Armor_Nullified")
			room:setPlayerFlag(effect.to, "shuanglongt")
        else
			room:setPlayerFlag(effect.from, "shuanglong_failed")
			local froms = sgs.SPlayerList()
			for _,r in sgs.qlist(room:getAlivePlayers()) do
				if r:getEquips():length() > 0 then
					froms:append(r)
				end
			end
			local from = room:askForPlayerChosen(effect.from, froms, "shuanglong1", "shuanglong_movefrom", true, false)
			if from then
				local card_id = room:askForCardChosen(effect.from, from, "e", self:objectName())
				local card = sgs.Sanguosha:getCard(card_id)
				local place = room:getCardPlace(card_id)
				local tos = sgs.SPlayerList()
				local list = room:getAlivePlayers()
				for _,p in sgs.qlist(list) do
					if ((card:isKindOf("Weapon") and p:getWeapon() == nil) or
					(card:isKindOf("Armor") and p:getArmor() == nil) or
					(card:isKindOf("DefensiveHorse") and p:getDefensiveHorse() == nil) or
					(card:isKindOf("OffensiveHorse") and p:getOffensiveHorse() == nil) or
					(card:isKindOf("Treasure") and p:getTreasure() == nil)) and hasEquipArea(p, card:getSubtype()) then
						tos:append(p)
					end
				end
				local to = room:askForPlayerChosen(effect.from, tos, "shuanglong2", ("shuanglong_moveto:%s"):format(card:objectName()), false, false)
				if to then
					room:moveCardTo(card, to, place, true)
				end
			end
	    end
    end,
}

shuanglongvs = sgs.CreateViewAsSkill{
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
}

shuanglong = sgs.CreateTriggerSkill
{
	name = "shuanglong",
	events = {sgs.EventPhaseStart,sgs.Death},
	view_as_skill = shuanglongvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
	if (event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish))
	or (event == sgs.Death and data:toDeath().who:hasSkill(self:objectName())) then
		for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			if p:getMark("Armor_Nullified") > 0 then
				room:removePlayerMark(p,"Armor_Nullified")
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

shuanglongslash = sgs.CreateTargetModSkill{
	name = "#shuanglongslash",
	pattern = "Slash",
	residue_func = function(self, player, card)
		if player:hasSkill(self:objectName()) and player:hasFlag("shuanglong_success") then
			return 998
		else
		    return 0
		end
	end,
}

shuanglongp = sgs.CreateProhibitSkill
{
	name = "#shuanglongp",
	is_prohibited = function(self, from, to, card)
		if from and from:hasSkill("shuanglong") and from:getSlashCount() >= 1 and
		(not(from:getWeapon() and from:getWeapon():getClassName() == "Crossbow")) and to and (not to:hasFlag("shuanglongt")) then
			return card:isKindOf("Slash")
		end
	end,
}

ALTRON:addSkill(shuanglong)
ALTRON:addSkill(shuanglongdis)
ALTRON:addSkill(shuanglongslash)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("#shuanglongp") then skills:append(shuanglongp) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("shuanglong", "#shuanglongdis")
extension:insertRelatedSkills("shuanglong", "#shuanglongslash")

DX = sgs.General(extension, "DX", "OTHERS", 4, true, false)

dxpoint = sgs.CreateTargetModSkill{
	name = "#dxpoint",
	pattern = "Slash",
	extra_target_func = function(self, player)
	if player and player:hasSkill(self:objectName()) and player:getMark("@point") >= 2 then
		return 1
	end
	end,
}

yueguang = sgs.CreateTriggerSkill{
	name = "yueguang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
	if player:getPhase() == sgs.Player_Start then
	    local judge = sgs.JudgeStruct()
		judge.pattern = ".|black"
		judge.good = true
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isGood() then
		    room:broadcastSkillInvoke("yueguang",math.random(1,2))
		    player:gainMark("@point")
			if player:getMark("@point") == 2 then
			    local log = sgs.LogMessage()
				log.from = player
				log.type = "#point"
				log.arg = "#dxpoint"
				room:sendLog(log)
			end
		else
		    room:broadcastSkillInvoke("yueguang",math.random(3,4))
		    player:loseMark("@point")
		end
	end
	end,
}

weibocard = sgs.CreateSkillCard{
	name = "weibo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
        source:loseMark("@point")
		source:addMark("weibo")
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#weibo"
        room:sendLog(log)
	end,
}

weibovs = sgs.CreateViewAsSkill{
    name = "weibo",
    n = 0,
    view_as = function(self, cards)
	if #cards == 0 then
        local acard = weibocard:clone()               
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return player:getMark("@point") >= 1
    end,
}

weibo = sgs.CreateTriggerSkill{
	name = "weibo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.ConfirmDamage,sgs.CardFinished,sgs.EventPhaseStart},
	view_as_skill = weibovs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		local use = data:toCardUse()
	if event == sgs.ConfirmDamage and player:getMark("weibo") > 0 and damage.card:isKindOf("Slash") then
        local x = player:getMark("weibo")
		room:setPlayerMark(player,"weibo",0)
		damage.damage = damage.damage + x
		data:setValue(damage)
		return false
	elseif event == sgs.CardFinished and use.card:isKindOf("Slash") and player:getMark("weibo") > 0 then
	    room:setPlayerMark(player,"weibo",0)
	elseif event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and player:getMark("weibo") > 0 then
	    room:setPlayerMark(player,"weibo",0)
	end
	end,
}

weixingcard = sgs.CreateSkillCard{
	name = "weixing",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
        source:loseMark("@point",2)
		source:addMark("weixing")
		local log = sgs.LogMessage()
        log.from = source
		log.arg = self:objectName()
        log.type = "#weixing"
        room:sendLog(log)
	end,
}

weixingvs = sgs.CreateViewAsSkill{
    name = "weixing",
    n = 0,
    view_as = function(self, cards)
	if #cards == 0 then
        local acard = weixingcard:clone()               
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return player:getMark("@point") >= 2
    end,
}

weixing = sgs.CreateTriggerSkill{
	name = "weixing",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirmed,sgs.CardFinished,sgs.EventPhaseStart},
	view_as_skill = weixingvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if event == sgs.TargetConfirmed and player:getMark("weixing") > 0 and use.card:isKindOf("Slash") then
        room:setPlayerMark(player,"weixing",0)
		local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
		local index = 1
		for _, p in sgs.qlist(use.to) do
			jink_table[index] = 0
		end
		index = index + 1
		local jink_data = sgs.QVariant()
		jink_data:setValue(Table2IntList(jink_table))
		player:setTag("Jink_" .. use.card:toString(), jink_data)
		return false
	elseif event == sgs.CardFinished and use.card:isKindOf("Slash") and player:getMark("weixing") > 0 then
	    room:setPlayerMark(player,"weixing",0)
	elseif event == sgs.EventPhaseStart and (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish) and player:getMark("weixing") > 0 then
	    room:setPlayerMark(player,"weixing",0)
	end
	end,
}

difacard = sgs.CreateSkillCard{
	name = "difa",
	target_fixed = true,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	on_effect = function(self, effect)
	end
}

difavs = sgs.CreateOneCardViewAsSkill{
	name = "difa",
	response_pattern = "@@difa",
	expand_pile = "difa",
	filter_pattern = ".|.|.|difa",
	view_as = function(self, card)
	    local acard = difacard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end
}

difa = sgs.CreateTriggerSkill{
	name = "difa",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged, sgs.AskForRetrial},
	view_as_skill = difavs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card then
				local id = damage.card:getEffectiveId()
				if room:getCardPlace(id) == sgs.Player_PlaceTable then
					if room:askForSkillInvoke(player, self:objectName(), sgs.QVariant("damage")) then
						room:broadcastSkillInvoke("difa")
						player:addToPile("difa",damage.card)
					end
				end
			end
		elseif event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if player:getPile("difa"):length() == 0 or judge.who:objectName() ~= player:objectName() then return false end
			local prompt_list = {
				"@difa-card" ,
				judge.who:objectName() ,
				self:objectName() ,
				judge.reason ,
				string.format("%d", judge.card:getEffectiveId())
			}
			local prompt = table.concat(prompt_list, ":")
			local ai_data = sgs.QVariant()
			ai_data:setValue(judge)
			player:setTag("difa", ai_data)
			local card = room:askForUseCard(player, "@@difa", prompt, -1, sgs.Card_MethodResponse)
			if card then
				room:retrial(card, player, judge, self:objectName())
			end
			player:removeTag("difa")
		end
	end,
}

DX:addSkill(dxpoint)
DX:addSkill(yueguang)
DX:addSkill(weibo)
DX:addSkill(weixing)
DX:addSkill(difa)

GINN = sgs.General(extension, "GINN", "ZAFT", 5, true, false)

laobing = sgs.CreateTriggerSkill
{
	name = "laobing",
	events = {sgs.StartJudge,sgs.FinishRetrial, sgs.FinishJudge},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.StartJudge and room:askForSkillInvoke(player,self:objectName(),data) then
	    room:broadcastSkillInvoke("laobing")
		local suit = room:askForSuit(player,self:objectName())
		if suit then
			local suit_str = sgs.Card_Suit2String(suit)
			local log = sgs.LogMessage()
			log.type = "#ChooseSuit"
			log.from = player
			log.arg = suit_str
			room:sendLog(log)
		    room:setPlayerMark(player,suit_str,1)
		end
	end
	if event == sgs.FinishRetrial and
	(player:getMark("spade") == 1 or player:getMark("heart") == 1 or player:getMark("club") == 1 or player:getMark("diamond") == 1) then
		local judge = data:toJudge()
		local suit_str = judge.card:getSuitString()
		room:addPlayerMark(player, suit_str)
		if player:getMark(suit_str) == 2 then
		    room:setEmotion(player, "judgegood")
			if player:isWounded() then
			    local recover = sgs.RecoverStruct()
				recover.recover = 1
				recover.who = player
				room:recover(player,recover)
			end
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_JUDGEDONE, player:objectName(), self:objectName(), nil)
            room:throwCard(judge.card, reason, nil)
			local ju = sgs.JudgeStruct()
			ju.reason = judge.reason
			ju.who = player
			ju.pattern = judge.pattern
			room:judge(ju)
			room:retrial(ju.card, player, judge, self:objectName())
			room:obtainCard(player, ju.card)
		else
		    room:setEmotion(player, "judgebad")
		    room:setPlayerFlag(player, "laobingfailed")
		end
		    room:setPlayerMark(player,"spade",0)
		    room:setPlayerMark(player,"heart",0)
		    room:setPlayerMark(player,"club",0)
		    room:setPlayerMark(player,"diamond",0)
			return true
		end
		if event == sgs.FinishJudge and player:hasFlag("laobingfailed") then
		    local judge = data:toJudge()
			room:setPlayerFlag(player, "-laobingfailed")
			room:obtainCard(player, judge.card)
			return true
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
	if damage.card and damage.card:isKindOf("Slash") and damage.to:getEquips():length() > 0 and not player:isNude() and
	damage.to:objectName() ~= player:objectName() and not damage.chain and not damage.transfer and
	room:askForSkillInvoke(player,self:objectName(),data) then
	    room:broadcastSkillInvoke("baopo")
	    if room:askForDiscard(player,self:objectName(),1,1,false,true) then
	        room:throwCard(room:askForCardChosen(player, damage.to ,"e",self:objectName()),damage.to,player)
		end
	end
    end,
}

GINN:addSkill(laobing)
GINN:addSkill(baopo)

STRIKE = sgs.General(extension, "STRIKE", "OMNI", 4, true, false)

huanzhuang = sgs.CreateTriggerSkill
{
	name = "huanzhuang",
	events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Start then
			local log = sgs.LogMessage()
			log.type = "#huanzhuangn"
	        if room:askForSkillInvoke(player,self:objectName(),data) then
				room:broadcastSkillInvoke("huanzhuang", math.random(2))
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.good = true
				judge.play_animation = false
				judge.reason = self:objectName()
				judge.who = player
				room:judge(judge)
				room:getThread():delay(0250)
				if judge.card:isBlack() then
					log.type = "#huanzhuangb"
					room:broadcastSkillInvoke("huanzhuang", 5)
				    room:setPlayerMark(player, "huanzhuangb", 1)
				elseif judge.card:isRed() then
					log.type = "#huanzhuangr"
					room:broadcastSkillInvoke("huanzhuang", 4)
				    room:setPlayerMark(player, "huanzhuangr", 1)
				end
		    else
				room:broadcastSkillInvoke("huanzhuang", 3)
		        room:setPlayerMark(player, "huanzhuangn", 1)
		    end
			room:sendLog(log)
		end
	end
    end,
}

huanzhuangeffect = sgs.CreateTriggerSkill
{
	name = "#huanzhuangeffect",
	events = {sgs.EventPhaseStart, sgs.SlashMissed, sgs.ConfirmDamage},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
	if event == sgs.EventPhaseStart then
	    if player:getPhase() == sgs.Player_Finish then
		    if player:getMark("huanzhuangn") > 0 then
				room:notifySkillInvoked(player, "huanzhuang")
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = "huanzhuang"
				room:sendLog(log)
			    player:drawCards(1)
			end
			room:setPlayerMark(player, "huanzhuangb", 0)
			room:setPlayerMark(player, "huanzhuangr", 0)
			room:setPlayerMark(player, "huanzhuangn", 0)
		end
	elseif event == sgs.SlashMissed then
		local effect = data:toSlashEffect()
		if player:getMark("huanzhuangb") > 0 and effect.to:canDiscard(player, "h") and room:askForSkillInvoke(effect.to, "huanzhuang", sgs.QVariant("throw:"..player:objectName())) then
			room:throwCard(room:askForCardChosen(effect.to, effect.from, "h", self:objectName(), false, sgs.Card_MethodDiscard), player, effect.to)
		end
	elseif event == sgs.ConfirmDamage then
		local damage = data:toDamage()
		if damage.chain or damage.transfer or (not damage.by_user) then return false end
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("huanzhuangb") > 0 then
			room:notifySkillInvoked(player, "huanzhuang")
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = "huanzhuang"
			room:sendLog(log)
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
    end,
}

huanzhuangd = sgs.CreateAttackRangeSkill{
	name = "#huanzhuangd",
	extra_func = function(self, player, include_weapon)
		if player:hasSkill("huanzhuang") and player:getMark("huanzhuangr") > 0 then
			return 1
		end
	end,
}

xiangzhuan = sgs.CreateTriggerSkill
{
	name = "xiangzhuan",
	events = {sgs.DamageForseen},
    on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") and damage.card:isBlack() and not player:getEquips():isEmpty() and player:canDiscard(player, "e") and room:askForSkillInvoke(player, self:objectName(), data) then
	    local card = room:askForCardChosen(player, player, "e", self:objectName(), false, sgs.Card_MethodDiscard)
		if card then
			if player:getGeneralName() == "STRIKE" then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			elseif player:getGeneralName() == "AEGIS" then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			end
			room:throwCard(card, player, player)
			room:notifySkillInvoked(player, self:objectName())
			room:setEmotion(player, "skill_nullify")
			local log = sgs.LogMessage()
			log.type = "#xiangzhuan"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
	        return true
		end
	end
    end,
}

STRIKE:addSkill(huanzhuang)
STRIKE:addSkill(huanzhuangeffect)
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
		room:throwCard(room:askForCardChosen(effect.from, effect.to, "e", self:objectName(), false, sgs.Card_MethodDiscard), effect.to, effect.from)
	end
}

jiechivs = sgs.CreateViewAsSkill
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

jiechi = sgs.CreateTriggerSkill
{
	name = "jiechi",
	events = {sgs.PreCardUsed},
	view_as_skill = jiechivs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getSkillName() == self:objectName() then
			if use.to:first():getGeneralName() == "STRIKE" or use.to:first():getGeneralName() == "FREEDOM" then
				room:broadcastSkillInvoke(self:objectName(), 3)
			else
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			end
			return true
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
		room:setEmotion(effect.from, "juexin")
		effect.from:loseMark("@juexin")
		effect.from:throwAllHandCards()
		room:setPlayerMark(effect.to, "@2887", 1)
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
	events = {sgs.PreCardUsed},
	frequency = sgs.Skill_Limited,
	view_as_skill = juexinvs,
	limit_mark = "@juexin",
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:getSkillName() == self:objectName() then
			if use.to:first():getGeneralName() == "STRIKE" then
				room:broadcastSkillInvoke(self:objectName(), 2)
				room:getThread():delay(1500)
				room:broadcastSkillInvoke(self:objectName(), 1)
			else
				room:broadcastSkillInvoke(self:objectName(), 1)
			end
			return true
		end
	end,
}

juexineffect = sgs.CreateTriggerSkill
{
	name = "#juexineffect",
	events = {sgs.TurnStart},
	global = true,
	can_trigger = function(self,player)
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.TurnStart and player:getMark("@2887") > 0 then
	    room:setPlayerMark(player,"@2887",0)
	    local judge = sgs.JudgeStruct()
		judge.pattern = ".|^spade"
		judge.good = false
		judge.reason = self:objectName()
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
		    room:loseHp(player,2)
			local selfplayer = room:findPlayerBySkillName("juexin")
			if selfplayer:isAlive() then
				room:killPlayer(selfplayer)
			end
		end
	end
	end,
}

AEGIS:addSkill(jiechi)
AEGIS:addSkill(juexin)
AEGIS:addSkill(juexineffect)
AEGIS:addSkill("xiangzhuan")

BUSTER = sgs.General(extension, "BUSTER", "ZAFT", 4, true, false)

shuangqiangvs = sgs.CreateViewAsSkill
{
	name = "shuangqiang",
	n = 1,
	view_filter = function(self, selected, to_select)
		if not (to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard")) then return false end
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(to_select:getEffectiveId())
		slash:deleteLater()
		return slash:isAvailable(sgs.Self)
	end,
	view_as = function(self, cards)
	    local card = cards[1]
		if #cards == 1 then
			local acard = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber()) 
			acard:addSubcard(card:getId())
			acard:setSkillName("shuangqiang")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Play
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
	if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "shuangqiang" and not damage.chain and not damage.transfer then
		local subcard = sgs.Sanguosha:getCard(damage.card:getSubcards():first())
	    if subcard:isKindOf("EquipCard") and damage.to:getEquips():length() > 0 then
		    room:throwCard(room:askForCardChosen(player, damage.to, "e", self:objectName(), false, sgs.Card_MethodDiscard), damage.to, player)
		elseif subcard:isKindOf("TrickCard") and not damage.to:isKongcheng() then
	        room:throwCard(room:askForCardChosen(player, damage.to, "h", self:objectName(), false, sgs.Card_MethodDiscard), damage.to, player)
		end
	end
	end,
}

zuzhuangvs = sgs.CreateViewAsSkill
{
	name = "zuzhuang",
	n = 2,
	view_filter = function(self, selected, to_select)
		if not (to_select:isKindOf("EquipCard") or to_select:isKindOf("TrickCard")) then return false end
		if #selected == 0 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		elseif #selected == 1 then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(to_select:getEffectiveId())
			slash:deleteLater()
			if selected[1]:isKindOf("EquipCard") then
				return to_select:isKindOf("TrickCard") and slash:isAvailable(sgs.Self)
			elseif selected[1]:isKindOf("TrickCard") then
				return to_select:isKindOf("EquipCard") and slash:isAvailable(sgs.Self)
			end
		end
	end,
	view_as = function(self, cards)
		if #cards == 2 then
			local acard = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1) 
			acard:addSubcard(cards[1])
			acard:addSubcard(cards[2])
			acard:setSkillName("zuzhuang")
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player) and player:getPhase() == sgs.Player_Play
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
	if damage.card and damage.card:isKindOf("Slash") and damage.card:getSkillName() == "zuzhuang" and not damage.chain and not damage.transfer then
		local pattern = {}
		if damage.to:isNude() then return false end
		if damage.to:getEquips():length() > 0 then
			table.insert(pattern, "zze")
		end
		if not damage.to:isKongcheng() then
			table.insert(pattern, "zzh")
		end
		local choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), sgs.QVariant(damage.to:objectName()))
	    if choice == "zze" then
		    damage.to:throwAllEquips()
		elseif choice == "zzh" then
	        damage.to:throwAllHandCards()
		end
	end
	end,
}

BUSTER:addSkill(shuangqiang)
BUSTER:addSkill(zuzhuang)

DUEL_AS = sgs.General(extension, "DUEL_AS", "ZAFT", 4, true, false)

sijuevs = sgs.CreateViewAsSkill
{
	name = "sijue",
	n = 1,
	view_filter = function(self, selected, to_select)
        return to_select:isBlack() and to_select:isKindOf("BasicCard")
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
	events = {sgs.TargetSpecified},
	view_as_skill = sijuevs,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
	if use.card and use.card:isKindOf("Duel") and use.card:getSkillName() == self:objectName() then
	    for _,p in sgs.qlist(use.to) do
			p:drawCards(1)
		end
	end
	end,
}

pojia = sgs.CreateTriggerSkill
{
	name = "pojia",
	events = {sgs.Damaged, sgs.DamageForseen},
	frequency = sgs.Skill_Limited,
	limit_mark = "@pojia",
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
	if event == sgs.Damaged and player:getMark("@pojia") > 0 and player:getEquips():length() > 0 and damage.from and room:askForSkillInvoke(player, self:objectName(), data) then
	    room:broadcastSkillInvoke(self:objectName())
		player:loseMark("@pojia")
		room:doSuperLightbox("DUEL_AS", self:objectName())
		player:throwAllEquips()
	    for i=1, 2, 1 do
		    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		    duel:setSkillName("pojiacard")
			local use = sgs.CardUseStruct()
            use.from = player
            use.to:append(damage.from)
            use.card = duel
            room:useCard(use)
		end
	elseif event == sgs.DamageForseen and damage.card and damage.card:isKindOf("Duel") and damage.card:getSkillName() == "pojiacard" then
	    return true
	end
	end,
}

DUEL_AS:addSkill(sijue)
DUEL_AS:addSkill(pojia)

BLITZ = sgs.General(extension, "BLITZ", "ZAFT", 4, true, false)

yinxian = sgs.CreateTriggerSkill
{
	name = "yinxian",
	events = {sgs.CardResponded, sgs.ConfirmDamage, sgs.TargetSpecified, sgs.CardFinished},
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event == sgs.CardResponded then
		local card = data:toCardResponse().m_card
		if card:isKindOf("Jink") and player:getMark("@yinxian") == 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName(), math.random(1, 3))
			room:setPlayerMark(player, "@yinxian", 1)
			local log = sgs.LogMessage()
			log.type = "#EnterYinxian"
			log.from = player
			room:sendLog(log)
			room:changeHero(player, "BLITZ_Y", false, false, player:getGeneralName() ~= "BLITZ", false)
		end
	elseif event == sgs.ConfirmDamage then
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			damage.nature = sgs.DamageStruct_Thunder
			data:setValue(damage)
			return false
		end
	elseif event == sgs.TargetSpecified then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			local jink_table = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
			local index = 1
			for _, p in sgs.qlist(use.to) do
				jink_table[index] = 0
				index = index + 1
			end
			local jink_data = sgs.QVariant()
			jink_data:setValue(Table2IntList(jink_table))
			player:setTag("Jink_" .. use.card:toString(), jink_data)
			return false
		end
	elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:getMark("@yinxian") > 0 then
			room:broadcastSkillInvoke(self:objectName(), math.random(4, 6))
			room:setPlayerMark(player, "@yinxian", 0)
			local log = sgs.LogMessage()
			log.type = "#RemoveYinxian"
			log.from = player
			room:sendLog(log)
			room:changeHero(player, "BLITZ", false, false, player:getGeneralName() ~= "BLITZ_Y", false)
		end
	end
	end,
}

yinxiand = sgs.CreateDistanceSkill{
	name = "#yinxiand",
	correct_func = function(self, from, to)
		if to:hasSkill("yinxian") and to:getMark("@yinxian") > 0 then
			return 1
		else
			return 0
		end
	end
}

zhuanjin = sgs.CreateTriggerSkill
{
	name = "zhuanjin",
	events = {sgs.GameStart, sgs.Dying},
	frequency = sgs.Skill_Limited,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("@zhuanjin") == 0 then
				player:gainMark("@zhuanjin")
			end
		elseif event == sgs.Dying then
			local dying = data:toDying()
			if dying.who:objectName() ~= player:objectName() and player:getMark("@zhuanjin") > 0 and room:askForSkillInvoke(player,self:objectName(),data) then
				if dying.who:getGeneralName() == "AEGIS" or dying.who:getGeneralName() == "JUSTICE" then
					room:broadcastSkillInvoke(self:objectName(), 2)
				else
					room:broadcastSkillInvoke(self:objectName(), 1)
				end
				player:loseMark("@zhuanjin")
				room:doSuperLightbox("BLITZ", self:objectName())
				--room:setPlayerProperty(dying.who, "hp", sgs.QVariant(1))
				room:recover(dying.who, sgs.RecoverStruct(player, nil, 1 - dying.who:getHp()))
				dying.who:drawCards(player:getLostHp() + dying.who:getLostHp())
				local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
				slash:setSkillName("zhuanjincard")
				if dying.damage.from and dying.damage.from:isAlive() and not player:isProhibited(player, slash) then
					local use = sgs.CardUseStruct()
					use.from = dying.damage.from
					use.to:append(player)
					use.card = slash
					room:useCard(use)
				end
			end
		end
	end
}

BLITZ:addSkill(yinxian)
BLITZ:addSkill(yinxiand)
BLITZ:addSkill(zhuanjin)
extension:insertRelatedSkills("yinxian", "#yinxiand")

BLITZ_Y = sgs.General(extension, "BLITZ_Y", "ZAFT", 4, true, true, true)--海市蜃楼特效

BLITZ_Y:addSkill("yinxian")
BLITZ_Y:addSkill("#yinxiand")
BLITZ_Y:addSkill("zhuanjin")

FREEDOM = sgs.General(extension, "FREEDOM", "ORB", 3, true, false)

helie = sgs.CreateTriggerSkill{
	name = "helie",
	events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and room:askForSkillInvoke(player, self:objectName(), data) then
			if player:getGeneralName() == "FREEDOM" then
				room:broadcastSkillInvoke(self:objectName(), math.random(1, 2))
			elseif player:getGeneralName() == "JUSTICE" then
				room:broadcastSkillInvoke(self:objectName(), math.random(3, 4))
			elseif player:getGeneralName() == "PROVIDENCE" then
				room:broadcastSkillInvoke(self:objectName(), math.random(5, 6))
			end
			player:throwAllHandCards()
			player:drawCards(player:getMaxHp())
		end
	end,
}

jiaoxie = sgs.CreateTriggerSkill{
	name = "jiaoxie",
	events = {sgs.EnterDying},
	can_trigger = function(self, player)
		return true
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.damage and dying.damage.from and dying.damage.from:objectName() ~= dying.who:objectName() then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
				local target
				if dying.damage.from:objectName() == p:objectName() then
					target = dying.who
				elseif dying.who:objectName() == p:objectName() then
					target = dying.damage.from
				end
				if target == nil then return false end
				local skill_list = {}
				for _,skill in sgs.qlist(target:getVisibleSkillList()) do
					if (not table.contains(skill_list, skill:objectName())) and (not skill:isAttachedLordSkill())
						and skill:getFrequency() ~= sgs.Skill_Limited and skill:getFrequency() ~= sgs.Skill_Wake
						and skill:objectName() ~= "wzpoint" then
						table.insert(skill_list, skill:objectName())
					end
				end
				if #skill_list > 0 and room:askForSkillInvoke(p, self:objectName(), data) then
					local choice = room:askForChoice(p, self:objectName(), table.concat(skill_list, "+"), data)
					if choice then
						room:broadcastSkillInvoke(self:objectName())
						room:doSuperLightbox("FREEDOM", choice)
						room:detachSkillFromPlayer(target, choice)
					end
				end
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
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:addPlayerMark(player, "zhongzi")
			player:gainMark("@seed")
			room:setEmotion(player, "zhongzi")
			room:broadcastSkillInvoke(self:objectName(), 1)
			room:broadcastSkillInvoke(self:objectName(), 2)
			--room:setPlayerProperty(player, "hp", sgs.QVariant(2))
			room:recover(player, sgs.RecoverStruct(player, nil, 2 - player:getHp()))
			room:detachSkillFromPlayer(player, "jiaoxie")
			room:acquireSkill(player, "qishe")
		end
	end,
}

qishe = sgs.CreateViewAsSkill{
	name = "qishe",
	n = 0,
	view_filter = function(self, selected, to_select)
		return false
	end,
	view_as = function(self, cards)
		if #cards == 0 then
			local card = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
			card:addSubcards(sgs.Self:getHandcards())
			card:setSkillName(self:objectName())
			return card
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return (not player:isKongcheng()) and sgs.Slash_IsAvailable(player)
	end,
}

qishes = sgs.CreateTargetModSkill{
	name = "#qishes",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("qishe") and card:getSkillName() == "qishe" then
			return card:subcardsLength() - 1
		end
	end,
	distance_limit_func = function(self, player, card)
		if player and player:hasSkill("qishe") and card:getSkillName() == "qishe" then
			return 998
		end
	end
}

qishea = sgs.CreateTriggerSkill
{
	name = "#qishea",
	events = {sgs.PreCardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and use.card:getSkillName() == "qishe" then
			room:broadcastSkillInvoke("qishe")
			room:setEmotion(player, "qishe")
			room:getThread():delay(2000)
			room:broadcastSkillInvoke("gdsbgm", 1)
			return true
		end
	end,
}

FREEDOM:addSkill(helie)
FREEDOM:addSkill(jiaoxie)
FREEDOM:addSkill(zhongzi)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("qishe") then skills:append(qishe) end
if not sgs.Sanguosha:getSkill("#qishes") then skills:append(qishes) end
if not sgs.Sanguosha:getSkill("#qishea") then skills:append(qishea) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("qishe", "#qishes")
extension:insertRelatedSkills("qishe", "#qishea")
FREEDOM:addRelateSkill("qishe")

JUSTICE = sgs.General(extension, "JUSTICE", "ORB", 4, true, false)

shouwangvs = sgs.CreateZeroCardViewAsSkill
{
	name = "shouwang",
	view_as = function(self, cards)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		peach:setSkillName(self:objectName())
		return peach
	end,
	enabled_at_play = function(self, player)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
		return peach:isAvailable(player) and player:getMaxHp() > 0 and player:getMark("Global_PreventPeach") == 0
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and player:getMaxHp() > 0 and player:getMark("Global_PreventPeach") == 0
	end
}

shouwang = sgs.CreateTriggerSkill
{
	name = "shouwang",
	events = {sgs.PreCardUsed},
	view_as_skill = shouwangvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Peach") and use.card:getSkillName() == "shouwang" then
			room:loseMaxHp(player)
		end
	end,
}

zhongzij = sgs.CreateTriggerSkill
{
	name = "zhongzij",
	events = {sgs.MaxHpChanged},
	frequency = sgs.Skill_Wake,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getMaxHp() == 1 and player:getMark("@seedj") == 0 then
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:addPlayerMark(player, "zhongzij")
			player:gainMark("@seedj")
			room:setEmotion(player, "zhongzij")
			room:broadcastSkillInvoke("zhongzi", 1)
			room:broadcastSkillInvoke(self:objectName())
			local log = sgs.LogMessage()
			log.type = "#GainMaxHp"
			log.from = player
			log.arg = 3 - player:getMaxHp()
			room:sendLog(log)
			room:setPlayerProperty(player, "maxhp", sgs.QVariant(3))
			room:detachSkillFromPlayer(player, "shouwang")
			room:acquireSkill(player, "huiwu")
			room:getThread():delay(4000)
		end
	end,
}

huiwu = sgs.CreateTriggerSkill
{
	name = "huiwu",
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play and not player:hasFlag("huiwu") and not player:isKongcheng() then
			if use.card:isBlack() then
				local can_invoke = false
				for _,p in sgs.qlist(use.to) do
					if p:getEquips():length() > 0 then
						can_invoke = true
					end
				end
				if can_invoke and room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerFlag(player, "huiwu")
					room:broadcastSkillInvoke(self:objectName())
					player:throwAllHandCards()
					for _,q in sgs.qlist(use.to) do
						room:throwCard(room:askForCardChosen(player, q, "e", self:objectName()), q, player)
					end
				end
			elseif use.card:isRed() then
				if room:askForSkillInvoke(player, self:objectName(), data) then
					room:setPlayerFlag(player, "huiwu")
					room:broadcastSkillInvoke(self:objectName())
					player:throwAllHandCards()
					room:useCard(use)
				end
			end
		end
	end,
}

JUSTICE:addSkill("helie")
JUSTICE:addSkill(shouwang)
JUSTICE:addSkill(zhongzij)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("huiwu") then skills:append(huiwu) end
sgs.Sanguosha:addSkills(skills)
JUSTICE:addRelateSkill("huiwu")

CFR = sgs.General(extension, "CFR", "OMNI", 3, true, false)

wenshencard = sgs.CreateSkillCard{
	name = "wenshen",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		local pattern = {}
		if sgs.Analeptic_IsAvailable(source) then
			table.insert(pattern, "analeptic")
		end
	    if sgs.Slash_IsAvailable(source) then
			table.insert(pattern, "slash")
		end
		local choice = room:askForChoice(source, self:objectName(), table.concat(pattern, "+"))
		if choice then
			room:setPlayerProperty(source, "wenshen", sgs.QVariant(choice))
			room:askForUseCard(source, "@@wenshen", "@wenshen:"..choice)
			room:setPlayerProperty(source, "wenshen", sgs.QVariant())
		end
	end
}

wenshenvs = sgs.CreateViewAsSkill{
	name = "wenshen",
	n = 1,
	response_or_use = true,
	view_filter = function(self, selected, to_select)
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
		if sgs.Self:property("wenshen"):toString() == "slash" then
			if sgs.Self:getSlashCount() > 0 and not sgs.Self:canSlashWithoutCrossbow() and sgs.Self:getWeapon() and sgs.Self:getWeapon():getClassName() == "Crossbow" then
				return to_select:isKindOf("EquipCard") and not (to_select:isEquipped() and to_select:objectName() == "crossbow")
			end
		end
		return to_select:isKindOf("EquipCard")
	end,
	view_as = function(self, cards)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			if #cards == 0 then
				local acard = wenshencard:clone()
				acard:setSkillName(self:objectName())
				return acard
			end
		else
			if #cards == 1 then
				local acard
				if pattern == "@@wenshen" then
					local name = sgs.Self:property("wenshen"):toString()
					if name then
						acard = sgs.Sanguosha:cloneCard(name, cards[1]:getSuit(), cards[1]:getNumber())
					end
				elseif pattern == "slash" then
					acard = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
				else
					acard = sgs.Sanguosha:cloneCard("analeptic", cards[1]:getSuit(), cards[1]:getNumber())
				end
				acard:addSubcard(cards[1])
				acard:setSkillName(self:objectName())
				return acard
			end
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		return sgs.Analeptic_IsAvailable(player) or sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@wenshen" or string.find(pattern, "analeptic") or (pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE)
	end
}

wenshen = sgs.CreateTriggerSkill
{
	name = "wenshen",
	events = {sgs.PreCardUsed},
	view_as_skill = wenshenvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:getSkillName() == "wenshen" and use.card:isKindOf("SkillCard") then
			return true
		end
	end
}

jinduan = sgs.CreateTriggerSkill
{
	name = "jinduan",
	events = {sgs.TargetConfirming},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:isRed() and not use.card:isKindOf("SkillCard") and not use.card:isKindOf("DelayedTrick")
			and use.to:contains(player) and use.from:objectName() ~= player:objectName() and room:alivePlayerCount() > 2 then
			local players = room:getOtherPlayers(player)
			players:removeOne(use.from)
			for _,p in sgs.qlist(players) do
				if p:isProhibited(p, use.card) then
					players:removeOne(p)
				end
			end
			if not players:isEmpty() then
				if not use.card:isKindOf("GlobalEffect") and not use.card:isKindOf("Peach") then
					room:setPlayerFlag(player, "jinduan")
				end
				local target = room:askForPlayerChosen(player, players, self:objectName(), "@jinduan", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:doAnimate(1, player:objectName(), target:objectName())
					local log1 = sgs.LogMessage()
					log1.type = "$CancelTarget"
					log1.from = use.from
					log1.arg = use.card:objectName()
					log1.to:append(player)
					room:sendLog(log1)
					local log2 = sgs.LogMessage()
					log2.type = "#BecomeTarget"
					log2.from = target
					log2.card_str = use.card:toString()
					room:sendLog(log2)
					use.to:removeOne(player)
					use.to:append(target)
					room:sortByActionOrder(use.to)
					data:setValue(use)
					room:getThread():trigger(sgs.TargetConfirming, room, target, data)
				end
				room:setPlayerFlag(player, "-jinduan")
			end
		end
	end
}

liesha = sgs.CreateTriggerSkill
{
	name = "liesha",
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
	    local use = data:toCardUse()
		if use.card and use.card:isKindOf("Slash") and room:askForSkillInvoke(player, self:objectName(), data) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(1)
		end
	end
}

CFR:addSkill(wenshen)
CFR:addSkill(jinduan)
CFR:addSkill(liesha)

PROVIDENCE = sgs.General(extension, "PROVIDENCE", "ZAFT", 4, true, false)

longqi = sgs.CreateTriggerSkill{
	name = "longqi",
	events = {sgs.CardResponded},
	on_trigger = function(self, event, player, data)
		local card = data:toCardResponse().m_card
		local room = player:getRoom()
		if card and card:isKindOf("Jink") then
			local invoked = false
			while true do
				local players = room:getOtherPlayers(player)
				for _,p in sgs.qlist(players) do
					if p:isKongcheng() then
						players:removeOne(p)
					end
				end
				if players:isEmpty() then break end
				local cn = card:getNumber()
				room:setPlayerMark(player, "longqi_ai", cn)
				local target = room:askForPlayerChosen(player, players, self:objectName(), "@longqi:"..cn, true, true)
				if target then
					local id = room:askForCardChosen(player, target, "h", self:objectName(), true, sgs.Card_MethodDiscard)
					if id then
						room:setPlayerMark(player, "longqi_ai", 0)
						if not invoked then
							invoked = true
							room:broadcastSkillInvoke(self:objectName())
						end
						local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE, player:objectName(), target:objectName(), self:objectName(), "")
						local to_throw = sgs.Sanguosha:getCard(id)
						room:throwCard(to_throw, reason, target, player)
						if cn == 0 then break end
						local idn = to_throw:getNumber()
						if idn == cn then
							local d = sgs.DamageStruct()
							d.from = player
							d.to = target
							d.damage = 1
							room:damage(d)
							break
						elseif math.abs(idn-cn) > 1 then
							break
						end
					else
						break
					end
				else
					break
				end
			end
		end
	end
}

chuangshi = sgs.CreateTriggerSkill
{
	name = "chuangshi",
	events = {sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
	    local damage = data:toDamage()
		if damage.from and damage.from:isAlive() and damage.from:objectName() ~= player:objectName() and damage.damage >= player:getHp() then
			room:broadcastSkillInvoke(self:objectName())
			room:loseMaxHp(player)
			local d = sgs.DamageStruct()
			if player:isAlive() then
				d.from = player
			end
			d.to = damage.from
			d.damage = damage.damage
			room:damage(d)
		end
	end
}

PROVIDENCE:addSkill("helie")
PROVIDENCE:addSkill(longqi)
PROVIDENCE:addSkill(chuangshi)

IMPULSE = sgs.General(extension, "IMPULSE", "ZAFT", 4, true, false)

daohe = sgs.CreateTriggerSkill{
	name = "daohe",
	events = {sgs.EventPhaseStart},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and room:askForSkillInvoke(player, self:objectName(), data) then
			local pattern = {"meiying", "jianyingg", "jiying"}
			local choice = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), data)
			if choice then
				--room:broadcastSkillInvoke(self:objectName())
				room:setPlayerMark(player, "@"..choice, 1)
				local log = sgs.LogMessage()
				log.type = "#daohe"
				log.from = player
				log.arg = choice
				log.arg2 = ":"..choice
				room:sendLog(log)
				if player:getMark("@emeng") > 0 then
					table.removeOne(pattern, choice)
					local choice2 = room:askForChoice(player, self:objectName(), table.concat(pattern, "+"), data)
					if choice2 then
						--room:broadcastSkillInvoke(self:objectName())
						room:setPlayerMark(player, "@"..choice2, 1)
						local log = sgs.LogMessage()
						log.type = "#daohe"
						log.from = player
						log.arg = choice2
						log.arg2 = ":"..choice2
						room:sendLog(log)
					end
				end
			end
		end
	end
}

daohemark = sgs.CreateTriggerSkill{
	name = "#daohemark",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			if data:toPhaseChange().to == sgs.Player_NotActive then
				room:setPlayerMark(player, "@meiying", 0)
				room:setPlayerMark(player, "@jianyingg", 0)
				room:setPlayerMark(player, "@jiying", 0)
				room:setPlayerMark(player, "meiyingadd", 0)
			end
		end
	end
}

meiying = sgs.CreateTriggerSkill
{
	name = "meiying",
	events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
	global = true,
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getMark("@meiying") > 0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "meiyingslash")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") and player:hasFlag("meiyingslash") then
				room:setPlayerFlag(player, "-meiyingslash")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasFlag("meiyingslash") then
				room:setPlayerFlag(player, "-meiyingslash")
				--room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player, "meiyingadd")
			end
		end
	end,
}

meiyingslash = sgs.CreateAttackRangeSkill{
	name = "#meiyingslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@meiying") > 0 then
			return 1
		end
	end,
}

meiyingslash2 = sgs.CreateTargetModSkill{
	name = "#meiyingslash2",
	pattern = "Slash",
	residue_func = function(self, player)
		if player and player:getMark("@meiying") > 0 and player:getMark("meiyingadd") > 0 then
			return player:getMark("meiyingadd")
		else
			return 0
		end
	end
}

jianyingg = sgs.CreateTriggerSkill
{
	name = "jianyingg",
	events = {sgs.CardUsed, sgs.Damage, sgs.CardFinished},
	global = true,
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getMark("@jianyingg") > 0
	end,
	on_trigger=function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				room:setPlayerFlag(player, "jianyinggslash")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card:isKindOf("Slash") and player:hasFlag("jianyinggslash") then
				room:setPlayerFlag(player, "-jianyinggslash")
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:hasFlag("jianyinggslash") then
				room:setPlayerFlag(player, "-jianyinggslash")
				if room:askForSkillInvoke(player, self:objectName(), data) then
					--room:broadcastSkillInvoke(self:objectName())
					room:drawCards(player, 1)
				end
			end
		end
	end,
}

jianyinggslash = sgs.CreateAttackRangeSkill{
	name = "#jianyinggslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@jianyingg") > 0 then
			return 1
		end
	end,
}

jiying = sgs.CreateTriggerSkill
{
	name = "jiying",
	events = {sgs.ConfirmDamage},
	global = true,
	can_trigger = function(self, player)
		return player and player:isAlive() and player:getMark("@jiying") > 0
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.damage >= damage.to:getHp() and room:askForSkillInvoke(player, self:objectName(), data) then
			--room:broadcastSkillInvoke(self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

jiyingslash = sgs.CreateAttackRangeSkill{
	name = "#jiyingslash",
	extra_func = function(self, player, include_weapon)
		if player and player:getMark("@jiying") > 0 then
			return 2
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
		if player:getMark("@emeng") > 0 then return false end
		if damage.from and (not player:inMyAttackRange(damage.from)) and damage.card and damage.card:isKindOf("Slash") then
			room:broadcastSkillInvoke(self:objectName())
			room:setEmotion(player, "emeng")
			room:notifySkillInvoked(player, self:objectName())
			local log = sgs.LogMessage()
			log.type = "#TriggerSkill"
			log.from = player
			log.arg = self:objectName()
			room:sendLog(log)
			room:setPlayerMark(player, "emeng", 1)
			player:gainMark("@emeng")
		end
	end
}

IMPULSE:addSkill(daohe)
IMPULSE:addSkill(daohemark)
IMPULSE:addSkill(emeng)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("meiying") then skills:append(meiying) end
if not sgs.Sanguosha:getSkill("#meiyingslash") then skills:append(meiyingslash) end
if not sgs.Sanguosha:getSkill("#meiyingslash2") then skills:append(meiyingslash2) end
if not sgs.Sanguosha:getSkill("jianyingg") then skills:append(jianyingg) end
if not sgs.Sanguosha:getSkill("#jianyinggslash") then skills:append(jianyinggslash) end
if not sgs.Sanguosha:getSkill("jiying") then skills:append(jiying) end
if not sgs.Sanguosha:getSkill("#jiyingslash") then skills:append(jiyingslash) end
sgs.Sanguosha:addSkills(skills)
extension:insertRelatedSkills("daohe", "#daohemark")
extension:insertRelatedSkills("meiying", "#meiyingslash")
extension:insertRelatedSkills("meiying", "#meiyingslash2")
extension:insertRelatedSkills("jianyingg", "#jianyinggslash")
extension:insertRelatedSkills("jiying", "#jiyingslash")
IMPULSE:addRelateSkill("meiying")
IMPULSE:addRelateSkill("jianyingg")
IMPULSE:addRelateSkill("jiying")

SP_DESTINY = sgs.General(extension, "SP_DESTINY", "ZAFT", 4, true, true)

shanshuocard = sgs.CreateSkillCard{
	name = "shanshuo",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:addToPile("&yi", self)
	end
}

shanshuovs = sgs.CreateViewAsSkill{
    name = "shanshuo",
    n = 998,
	view_filter = function(self, selected, to_select)
		return true
	end,
    view_as = function(self, cards)
	if #cards > 0 then
        local acard = shanshuocard:clone()
		for _,card in pairs(cards) do
			acard:addSubcard(card)
		end
        acard:setSkillName(self:objectName())
        return acard
	end
    end,
    enabled_at_play = function(self,player)
        return false
    end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@shanshuo"
	end
}

shanshuo = sgs.CreateTriggerSkill{
	name = "shanshuo",
	events = {sgs.EventPhaseEnd},
	view_as_skill = shanshuovs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play and (not player:isNude()) then
			room:askForUseCard(player, "@@shanshuo", "@shanshuo:"..self:objectName())
		end
	end
}

shanshuodistance = sgs.CreateDistanceSkill{
    name = "#shanshuodistance",
    correct_func = function(self, from, to)
		if from and from:hasSkill("shanshuo") and from:getPile("&yi"):length() > 0 then
			return -(from:getPile("&yi"):length())
		end
	end
}

xingzhuivs = sgs.CreateZeroCardViewAsSkill{
    name = "xingzhui",
    view_as = function(self)
	    local pattern = sgs.Self:property("xzuse"):toString()
		local acard = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, -1)
		acard:setSkillName(self:objectName())
		return acard
    end,
    enabled_at_play = function(self,player)
        return false
    end,
	enabled_at_response = function(self, player, pattern)
		return pattern == "@@xingzhui"
	end
}

xingzhui = sgs.CreateTriggerSkill{
	name = "xingzhui",
	events = {sgs.EventPhaseStart},
	view_as_skill = xingzhuivs,
	can_trigger = function(self, player)
	    return true
	end,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local allplayers = room:findPlayersBySkillName(self:objectName())
		if player:getPhase() == sgs.Player_Start then
			for _,selfplayer in sgs.qlist(allplayers) do
				local yi = selfplayer:getPile("&yi")
				if yi:length() > 0 and room:askForSkillInvoke(selfplayer, self:objectName(), data) then
					local samecolor = true
					if yi:length() > 1 then
						for i=1, yi:length()-1, 1 do
							if not sgs.Sanguosha:getCard(yi:at(0)):sameColorWith(sgs.Sanguosha:getCard(yi:at(i))) then
								samecolor = false
								break
							end
						end
					end
					selfplayer:clearOnePrivatePile("&yi")
					local xzbasic = {"slash", "peach"}
					local xztrick = {"snatch", "dismantlement", "collateral", "ex_nihilo", "duel", "amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
					if not (Set(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
						table.insert(xzbasic, 2, "thunder_slash")
						table.insert(xzbasic, 2, "fire_slash")
						table.insert(xzbasic, "analeptic")
						table.insert(xztrick, "fire_attack")
						table.insert(xztrick, "iron_chain")
					end
					local pattern = xzbasic
					if not samecolor then
						pattern = xztrick
					end
					for _,patt in ipairs(pattern) do
						local poi = sgs.Sanguosha:cloneCard(patt, sgs.Card_NoSuit, 0)
						if not poi:isAvailable(player) then
							table.removeOne(pattern, patt)
						end
					end
					local choice = room:askForChoice(selfplayer, self:objectName(), table.concat(pattern, "+"), data)
					if choice then
						if choice == "peach" or choice == "analeptic" or choice == "ex_nihilo" or choice == "amazing_grace" or
						choice == "savage_assault" or choice == "archery_attack" or choice == "god_salvation" then
							local use = sgs.CardUseStruct()
							local card = sgs.Sanguosha:cloneCard(choice, sgs.Card_NoSuit, -1)
							card:setSkillName(self:objectName())
							use.card = card
							use.from = selfplayer
							room:useCard(use)
						else
							room:setPlayerProperty(selfplayer, "xzuse", sgs.QVariant(choice))
							room:askForUseCard(selfplayer, "@@xingzhui", "@xingzhui:"..choice)
							room:setPlayerProperty(selfplayer, "xzuse", sgs.QVariant())
						end
					end
				end
			end
		end
	end
}

SP_DESTINY:addSkill(shanshuo)
SP_DESTINY:addSkill(shanshuodistance)
SP_DESTINY:addSkill(xingzhui)
extension:insertRelatedSkills("shanshuo", "#shanshuodistance")

EXIA_R = sgs.General(extension, "EXIA_R", "CB", 4, true, false)

liejian = sgs.CreateTriggerSkill{
	name = "liejian",
	events = {sgs.TargetSpecified},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			if use.card:getSuit() == sgs.Card_Spade then
				if player:getWeapon() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					--room:broadcastSkillInvoke(self:objectName(), 1)
					room:throwCard(player:getWeapon():getRealCard(), player, player)
				end
			elseif use.card:getSuit() == sgs.Card_Heart then
				if player:getArmor() then
					room:sendCompulsoryTriggerLog(player, self:objectName())
					--room:broadcastSkillInvoke(self:objectName(), 2)
					room:throwCard(player:getArmor():getRealCard(), player, player)
				end
			elseif use.card:getSuit() == sgs.Card_Club then
				local invoked = false
				for _,p in sgs.qlist(use.to) do
					if not p:isKongcheng() then
						if not invoked then
							invoked = true
							room:sendCompulsoryTriggerLog(player, self:objectName())
							--room:broadcastSkillInvoke(self:objectName(), 3)
						end
						local id = room:askForCardChosen(player, p, "h", self:objectName())
						room:throwCard(id, p, player)
					end
				end
			elseif use.card:getSuit() == sgs.Card_Diamond then
				room:sendCompulsoryTriggerLog(player, self:objectName())
				--room:broadcastSkillInvoke(self:objectName(), 4)
				local jink_list = sgs.QList2Table(player:getTag("Jink_" .. use.card:toString()):toIntList())
				for i = 0, use.to:length() - 1, 1 do
					if jink_list[i + 1] == 1 then
						jink_list[i + 1] = 2
					end
				end
				local jink_data = sgs.QVariant()
				jink_data:setValue(Table2IntList(jink_list))
				player:setTag("Jink_" .. use.card:toString(), jink_data)
			end
		end
	end
}

duzhan = sgs.CreateOneCardViewAsSkill{
	name = "duzhan",
	response_or_use = true,
	view_filter = function(self, card)
		local usereason = sgs.Sanguosha:getCurrentCardUseReason()
		if usereason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return not card:isEquipped()
		elseif (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE) or (usereason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE) then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return not card:isEquipped()
			else
				return card:isEquipped()
			end
		else
			return false
		end
	end,
	view_as = function(self, card)
		if card:isEquipped() then
			local jink = sgs.Sanguosha:cloneCard("jink", card:getSuit(), card:getNumber())
			jink:addSubcard(card)
			jink:setSkillName(self:objectName())
			return jink
		else
			local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
			slash:addSubcard(card)
			slash:setSkillName(self:objectName())
			return slash
		end
		return nil
	end,
	enabled_at_play = function(self, player)
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if not p:inMyAttackRange(player) then
				return false
			end
		end
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self, player, pattern)
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if not p:inMyAttackRange(player) then
				return false
			end
		end
		return (pattern == "slash") or (pattern == "jink")
	end
}

EXIA_R:addSkill(liejian)
EXIA_R:addSkill(duzhan)

REBORNS_CANNON = sgs.General(extension, "REBORNS_CANNON", "OTHERS", 4, true, dlc, dlc)
REBORNS_GUNDAM = sgs.General(extension, "REBORNS_GUNDAM", "OTHERS", 4, true, true, dlc)
if dlc then
	local file = assert(io.open(gdata, "r"))
	local t = file:read()
	if t then
		t = tonumber(t:split("=")[2])
		if t == 5 and sgs.Sanguosha:translate("REBORNS_GUNDAM") == "REBORNS_GUNDAM" then
			sgs.Alert("累计5场游戏——你获得新机体：再生高达！")
		end
		if t >= 5 then
			REBORNS_CANNON = sgs.General(extension, "REBORNS_CANNON", "OTHERS", 4, true, false)
			REBORNS_GUNDAM = sgs.General(extension, "REBORNS_GUNDAM", "OTHERS", 4, true, true)
		end
	end
	file:close()
end

jidongcard = sgs.CreateSkillCard{
	name = "jidong",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		if source:getGeneralName() == "REBORNS_CANNON" then
			room:broadcastSkillInvoke("jidong", math.random(3, 4))
			room:changeHero(source, "REBORNS_GUNDAM", false, false, false, true)
		else
			room:broadcastSkillInvoke("jidong", math.random(1, 2))
			room:changeHero(source, "REBORNS_CANNON", false, false, false, true)
		end
	end,
}

jidongvs = sgs.CreateViewAsSkill{
	name = "jidong",
	n = 1,
	view_filter = function(self, selected, to_select)
		if sgs.Self:hasUsed("#reborns_transam") then
			return false
		else
			return #selected == 0
		end
	end,
	view_as = function(self, cards)
		if #cards == 1 or sgs.Self:hasUsed("#reborns_transam") then
			local acard = jidongcard:clone()
			if #cards == 1 then
				acard:addSubcard(cards[1])
			end
			acard:setSkillName("jidong")
			return acard
		end
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#jidong")) or (player:hasUsed("#reborns_transam"))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

jidong = sgs.CreateTriggerSkill{-- ZY奆神的技能卡静音黑科技
	name = "jidong",
	events = {sgs.PreCardUsed},
	view_as_skill = jidongvs,
	on_trigger = function(self, event, player, data)
		if data:toCardUse().card:getSkillName() == "jidong" then return true end
	end
}

fengongcard = sgs.CreateSkillCard{
	name = "fengong",
	target_fixed = false,
	will_throw = true,
	filter = function(self, targets, to_select, player)
		return #targets < 2 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local card = room:askForCard(effect.to, "jink", "@fengong", sgs.QVariant(), sgs.Card_MethodResponse, nil, false, self:objectName(), false)
		if not card then
			room:damage(sgs.DamageStruct(self:objectName(), effect.from, effect.to))
		end
	end,
}

fengong = sgs.CreateOneCardViewAsSkill{
	name = "fengong",
	filter_pattern = "ThunderSlash,FireSlash",
	view_as = function(self, card)
	    local acard = fengongcard:clone()
		acard:addSubcard(card)
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return (not player:hasUsed("#fengong")) or (player:hasUsed("#reborns_transam"))
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

zaishengcard = sgs.CreateSkillCard{
	name = "zaisheng",
	target_fixed = true,
	will_throw = true,
	on_use = function(self, room, source, targets)
		local n = 0
		local subcard = self:subcardsLength()
		while n < subcard do
			local ids = room:getNCards(1, false)
			local move = sgs.CardsMoveStruct()
			move.card_ids = ids
			move.to = source
			move.to_place = sgs.Player_PlaceTable
			move.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, source:objectName(), self:objectName(), nil)
			room:moveCardsAtomic(move, true)
			room:getThread():delay(500)
			if sgs.Sanguosha:getCard(ids:at(0)):isKindOf("BasicCard") then
				n = n + 1
				room:obtainCard(source, ids:at(0))
			else
				room:throwCard(ids:at(0), nil)
			end
		end
	end,
}

zaisheng = sgs.CreateViewAsSkill{
	name = "zaisheng",
	n = 998,
	view_filter = function(self, selected, to_select)
		return true
	end,
	view_as = function(self, cards)
		if #cards > 0 then
			local acard = zaishengcard:clone()
			for _,card in pairs(cards) do
				acard:addSubcard(card)
			end
			acard:setSkillName(self:objectName())
			return acard
		end
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zaisheng") and not player:isNude()
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

REBORNS_TRANSAMcard = sgs.CreateSkillCard{
	name = "reborns_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@reborns_transam")
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
	end,
}

REBORNS_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "reborns_transam",
	view_as = function(self)
	    local acard = REBORNS_TRANSAMcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@reborns_transam") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

REBORNS_TRANSAM = sgs.CreateTriggerSkill{
	name = "reborns_transam",
	frequency = sgs.Skill_Limited,
	view_as_skill = REBORNS_TRANSAMvs,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

REBORNS_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#reborns_transammark",
	events = {sgs.GameStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			if player:getMark("@reborns_transam") == 0 then
				player:gainMark("@reborns_transam")
			end
		else
		
			if data:toPhaseChange().to == sgs.Player_NotActive then --Clear mask
				room:setPlayerMark(player, "drank", 0)
			end
			
		end
	end
}

REBORNS_CANNON:addSkill(jidong)
REBORNS_CANNON:addSkill(fengong)
REBORNS_CANNON:addSkill(REBORNS_TRANSAMmark)
REBORNS_GUNDAM:addSkill("jidong")
REBORNS_GUNDAM:addSkill(zaisheng)
REBORNS_GUNDAM:addSkill(REBORNS_TRANSAM)
REBORNS_GUNDAM:addSkill("#reborns_transammark")

HARUTE = sgs.General(extension, "HARUTE", "CB", 4, true, dlc, dlc)
if dlc then
	local file = assert(io.open(gdata, "r"))
	local t = file:read()
	if t then
		t = tonumber(t:split("=")[2])
		if t == 10 and sgs.Sanguosha:translate("HARUTE") == "HARUTE" then
			sgs.Alert("累计10场游戏——你获得新机体：哈鲁特！")
		end
		if t >= 10 then
			HARUTE = sgs.General(extension, "HARUTE", "CB", 4, true, false)
		end
	end
	file:close()
end
HARUTE:setGender(sgs.General_Neuter)

feijianvs = sgs.CreateOneCardViewAsSkill{
	name = "feijian",
	response_or_use = true,
	view_filter = function(self, card)
		local suits = {}
		for _,id in sgs.qlist(sgs.Self:getPile("jian")) do
			local suit = sgs.Sanguosha:getCard(id):getSuitString()
			if not table.contains(suits, suit) then
				table.insert(suits, suit)
			end
		end
		if not table.contains(suits, card:getSuitString()) then return false end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card:getEffectiveId())
			slash:deleteLater()
			return slash:isAvailable(sgs.Self)
		end
		return true
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:addSubcard(card:getId())
		slash:setSkillName(self:objectName())
		return slash
	end,
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and not player:isNude() and not player:getPile("jian"):isEmpty()
	end, 
	enabled_at_response = function(self, player, pattern)
		return pattern == "slash" and not player:isNude() and not player:getPile("jian"):isEmpty()
	end
}

feijian = sgs.CreateTriggerSkill{
	name = "feijian",
	events = {sgs.GameStart},
	view_as_skill = feijianvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		player:addToPile("jian", room:getNCards(4))
	end,
}

feijianslash = sgs.CreateTargetModSkill{
	name = "#feijianslash",
	pattern = "Slash",
	extra_target_func = function(self, player, card)
		if player and player:hasSkill("feijian") and card:getSkillName() == "feijian" then
			return 1
		end
	end,
}

liuyanvs = sgs.CreateOneCardViewAsSkill{
	name = "liuyan",
	expand_pile = "jian",
	filter_pattern = ".|.|.|jian",
	view_as = function(self, card)
		local peach = sgs.Sanguosha:cloneCard("peach", card:getSuit(), card:getNumber())
		peach:setSkillName(self:objectName())
		peach:addSubcard(card:getId())
		return peach
	end,
	enabled_at_play = function(self, player)
		local peach = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
		peach:deleteLater()
		return peach:isAvailable(player) and player:getMark("@MARUT") > 0 and not player:getPile("jian"):isEmpty()
	end,
	enabled_at_response = function(self, player, pattern)
		return string.find(pattern, "peach") and player:getMark("@MARUT") > 0 and not player:getPile("jian"):isEmpty() and player:getMark("Global_PreventPeach") == 0
	end
}

liuyan = sgs.CreateTriggerSkill{
	name = "liuyan",
	events = {sgs.EventPhaseStart, sgs.PreCardUsed},
	frequency = sgs.Skill_Wake,
	view_as_skill = liuyanvs,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getMark("@MARUT") == 0 and player:getPhase() == sgs.Player_Start and player:getHp() <= 2 then
				room:setPlayerFlag(player, "skip_anime")
				room:notifySkillInvoked(player, self:objectName())
				room:broadcastSkillInvoke(self:objectName(), 1)
				room:getThread():delay(4500)
				room:setEmotion(player, "liuyan")
				local log = sgs.LogMessage()
				log.type = "#TriggerSkill"
				log.from = player
				log.arg = self:objectName()
				room:sendLog(log)
				player:gainMark("@MARUT")
				room:setPlayerMark(player, "liuyan", 1)
				room:loseMaxHp(player)
				player:drawCards(6)
			end
		elseif event == sgs.PreCardUsed then
			if data:toCardUse().card:getSkillName() == "liuyan" then
				room:broadcastSkillInvoke(self:objectName(), math.random(2, 5))
				return true
			end
		end
	end,
}

HARUTE_TRANSAMcard = sgs.CreateSkillCard{
	name = "harute_transam",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		source:loseMark("@harute_transam")
		room:setPlayerMark(source, "harute_transammark", 1)
		room:doLightbox("image=image/animate/TRANS-AM.png", 1500)
		
		if source:getMark("drank") == 0 then --Mask
			room:addPlayerMark(source, "drank")
			source:setMark("drank", 0)
		end
		
	end,
}

HARUTE_TRANSAMvs = sgs.CreateZeroCardViewAsSkill{
	name = "harute_transam",
	view_as = function(self)
	    local acard = HARUTE_TRANSAMcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@harute_transam") > 0
	end,
	enabled_at_response = function(self, player, pattern)
		return false
	end,
}

HARUTE_TRANSAM = sgs.CreateTriggerSkill{
	name = "harute_transam",
	frequency = sgs.Skill_Limited,
	limit_mark = "@harute_transam",
	view_as_skill = HARUTE_TRANSAMvs,
	events = {sgs.NonTrigger},
	on_trigger = function(self, event, player, data)
	end
}

HARUTE_TRANSAMslash = sgs.CreateTargetModSkill{
	name = "#harute_transamslash",
	pattern = "Slash",
	distance_limit_func = function(self, player)
		if player and player:hasUsed("#harute_transam") then
			return 998
		end
	end,
	residue_func = function(self, player)
		if player and player:hasUsed("#harute_transam") then
			return 3
		else
			return 0
		end
	end
}

HARUTE_TRANSAMmark = sgs.CreateTriggerSkill{
	name = "#harute_transammark",
	events = {sgs.EventPhaseStart, sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Draw and player:getMark("harute_transammark") > 0 then
				room:setPlayerMark(player, "harute_transammark", 0)
				player:skip(sgs.Player_Draw)
				return true
			end
		else
		
			if data:toPhaseChange().to == sgs.Player_NotActive then --Clear mask
				room:setPlayerMark(player, "drank", 0)
			end
			
		end
	end
}

HARUTE:addSkill(feijian)
HARUTE:addSkill(feijianslash)
extension:insertRelatedSkills("feijian", "#feijianslash")
HARUTE:addSkill(liuyan)
HARUTE:addSkill(HARUTE_TRANSAM)
HARUTE:addSkill(HARUTE_TRANSAMslash)
HARUTE:addSkill(HARUTE_TRANSAMmark)
extension:insertRelatedSkills("harute_transam", "#harute_transamslash")

ELSQ = sgs.General(extension, "ELSQ", "CB", 3, true, false)

function RongheMove(ids, movein, player)
	local room = player:getRoom()
	if movein then
		local move = sgs.CardsMoveStruct(ids, nil, player, sgs.Player_PlaceTable, sgs.Player_PlaceSpecial,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, player:objectName(), "ronghe", ""))
		move.to_pile_name = "&ronghe"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	else
		local move = sgs.CardsMoveStruct(ids, player, nil, sgs.Player_PlaceSpecial, sgs.Player_PlaceTable,
			sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, player:objectName(), "ronghe", ""))
		move.from_pile_name = "&ronghe"
		local moves = sgs.CardsMoveList()
		moves:append(move)
		local _player = sgs.SPlayerList()
		_player:append(player)
		room:notifyMoveCards(true, moves, false, _player)
		room:notifyMoveCards(false, moves, false, _player)
	end
end

ronghecard = sgs.CreateSkillCard{
	name = "ronghe",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select, player)
		return to_select:objectName() ~= player:objectName() and (not to_select:isKongcheng())
		and to_select:getHp() > player:getHp() and #targets < 1
	end,
	on_effect = function(self, effect)
		local room = effect.from:getRoom()
		local ids = effect.to:handCards()
		RongheMove(ids, true, effect.from)
		room:setPlayerProperty(effect.from, "ronghe", sgs.QVariant(table.concat(sgs.QList2Table(ids), "+")))
		room:setTag("Dongchaee", sgs.QVariant(effect.to:objectName()))
		room:setTag("Dongchaer", sgs.QVariant(effect.from:objectName()))
	end
}

ronghe = sgs.CreateZeroCardViewAsSkill{
	name = "ronghe",
	view_as = function()
	    local acard = ronghecard:clone()
		acard:setSkillName("ronghe")
		return acard
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#ronghe")
	end
}

rongheclear = sgs.CreateTriggerSkill{
	name = "#rongheclear",
	events = {sgs.TurnStart, sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local list = player:property("ronghe"):toString():split("+")
			if #list > 0 then
				RongheMove(Table2IntList(list), false, player)
			end
			room:setTag("Dongchaee", sgs.QVariant())
			room:setTag("Dongchaer", sgs.QVariant())
			room:setPlayerProperty(player, "ronghe", sgs.QVariant())
		else
			local move = data:toMoveOneTime()
			if move.from and move.from_places:contains(sgs.Player_PlaceHand) and move.from:objectName() == room:getTag("Dongchaee"):toString() then
				local list = player:property("ronghe"):toString():split("+")
				if #list > 0 then
					local to_remove = sgs.IntList()
					for _,l in pairs(list) do
						if move.card_ids:contains(tonumber(l)) then
							to_remove:append(tonumber(l))
						end
					end
					RongheMove(to_remove, false, player)
					for _,id in sgs.qlist(to_remove) do
						table.removeOne(list, tostring(id))
					end
					local pattern = sgs.QVariant()
					if #list > 0 then
						pattern = sgs.QVariant(table.concat(list, "+"))
					end
					room:setPlayerProperty(player, "ronghe", pattern)
				end
			elseif move.to and move.to_place == sgs.Player_PlaceHand and move.to:objectName() == room:getTag("Dongchaee"):toString() then
				local list = player:property("ronghe"):toString():split("+")
				local to_add = sgs.IntList()
				for _,id in sgs.qlist(move.card_ids) do
					if not table.contains(list, tostring(id)) then
						table.insert(list, tostring(id))
						to_add:append(id)
					end
				end
				RongheMove(to_add, true, player)
				local pattern = sgs.QVariant(table.concat(list, "+"))
				room:setPlayerProperty(player, "ronghe", pattern)
			end
		end
	end
}

lijie = sgs.CreateTriggerSkill{
	name = "lijie",
	events = {sgs.Damaged},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if damage.from and (not damage.from:isKongcheng()) and player:objectName() ~= damage.from:objectName()
			and room:askForSkillInvoke(player, self:objectName(), data) then
			local id = room:askForCardChosen(player, damage.from, "h", self:objectName())
			local card = sgs.Sanguosha:getCard(id)
			room:throwCard(card, damage.from, player)
			if card:getSuit() == sgs.Card_Heart then
				room:recover(player, sgs.RecoverStruct(player))
				room:recover(damage.from, sgs.RecoverStruct(player))
			end
		end
	end
}

ELSQ:addSkill(ronghe)
ELSQ:addSkill(rongheclear)
ELSQ:addSkill(lijie)

SBS = sgs.General(extension, "SBS", "OTHERS")

jieneng = sgs.CreateTriggerSkill{
	name = "jieneng",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if use.card and (not use.card:isVirtualCard() or use.card:subcardsLength() > 0) and use.card:isKindOf("Slash") and use.to
			and use.to:contains(player) and room:askForSkillInvoke(player, self:objectName(), data) then
			local judge = sgs.JudgeStruct()
			judge.pattern = ".|red"
			judge.good = true
			judge.reason = self:objectName()
			judge.who = player
			room:judge(judge)
			if judge.card:isRed() then
				player:addToPile("neng", use.card)
				room:setEmotion(player, "skill_nullify")
				local log = sgs.LogMessage()
				log.type = "#SkillNullify"
				log.from = player
				log.arg = self:objectName()
				log.arg2 = use.card:objectName()
				room:sendLog(log)
				use.to:removeOne(player)
				data:setValue(use)
			end
		end
	end
}

jienengh = sgs.CreateMaxCardsSkill{
	name = "#jienengh",
	extra_func = function(self, player)
		local len = player:getPile("neng"):length()
		if len > 0 then
			return -(len)
		end
	end
}

shinengcard = sgs.CreateSkillCard{
	name = "shineng",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		room:setEmotion(source, "shineng")
		room:getThread():delay(5200)
		source:loseMark("@shineng")
		local neng = source:getPile("neng")
		room:setPlayerMark(source, "neng_buff", neng:length())
		local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		card:addSubcards(neng)
		room:obtainCard(source, card)
	end
}

shinengvs = sgs.CreateZeroCardViewAsSkill{
	name = "shineng",
	view_as = function(self)
	    local acard = shinengcard:clone()
		acard:setSkillName(self:objectName())
		return acard
	end,
	enabled_at_play = function(self, player)
		return player:getMark("@shineng") > 0 and (not player:getPile("neng"):isEmpty())
	end
}

shineng = sgs.CreateTriggerSkill{
	name = "shineng",
	frequency = sgs.Skill_Limited,
	limit_mark = "@shineng",
	view_as_skill = shinengvs,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_Play and player:getMark("neng_buff") > 0 then
			room:setPlayerMark(player, "neng_buff", 0)
		end
	end
}

shinengr = sgs.CreateAttackRangeSkill{
	name = "#shinengr",
	extra_func = function(self, player, include_weapon)
		local mark = player:getMark("neng_buff")
		if player and mark > 0 then
			return mark
		end
	end
}

shinengt = sgs.CreateTargetModSkill{
	name = "#shinengt",
	residue_func = function(self, from)
		local mark = from:getMark("neng_buff")
		if from and mark > 0 then
			return mark
		else
			return 0
		end
	end
}

rg = sgs.CreateTriggerSkill{
	name = "rg",
	frequency = sgs.Skill_Limited,
	limit_mark = "@rg",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start and player:getMark("@rg") > 0 and room:askForSkillInvoke(player, self:objectName(), data) then
			room:setEmotion(player, "rg")
			room:getThread():delay(4200)
			room:setPlayerMark(player, "@shineng", 0)
			player:loseMark("@rg")
			player:clearOnePrivatePile("neng")
			room:handleAcquireDetachSkills(player, "-jieneng|-shineng|tiequan")
			room:filterCards(player, player:getCards("he"), false)
		end
	end
}

tiequan = sgs.CreateTriggerSkill{
	name = "tiequan",
	events = {sgs.ConfirmDamage},
	priority = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:objectName() ~= damage.to:objectName() then
			room:sendCompulsoryTriggerLog(player, self:objectName())
			damage.damage = damage.damage + 1
			data:setValue(damage)
		end
	end
}

tiequanf = sgs.CreateFilterSkill{
	name = "#tiequanf",
	view_filter = function(self, card)
		return card:isKindOf("Jink") and math.mod(card:getNumber(), 2) == 1
	end,
	view_as = function(self, card)
		local slash = sgs.Sanguosha:cloneCard("slash", card:getSuit(), card:getNumber())
		slash:setSkillName("tiequan")
		local wrap = sgs.Sanguosha:getWrappedCard(card:getId())
		wrap:takeOver(slash)
		return wrap
	end
}

SBS:addSkill(jieneng)
SBS:addSkill(jienengh)
SBS:addSkill(shineng)
SBS:addSkill(shinengr)
SBS:addSkill(shinengt)
SBS:addSkill(rg)
local skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("tiequan") then skills:append(tiequan) end
if not sgs.Sanguosha:getSkill("#tiequanf") then skills:append(tiequanf) end
sgs.Sanguosha:addSkills(skills)
SBS:addRelateSkill("tiequan")
extension:insertRelatedSkills("jieneng", "#jienengh")
extension:insertRelatedSkills("shineng", "#shinengr")
extension:insertRelatedSkills("shineng", "#shinengt")
extension:insertRelatedSkills("tiequan", "#tiequanf")

sgs.LoadTranslationTable{
	["gaoda"] = "高达杀",
	["EFSF"] = "地球联邦",
	["SLEEVE"] = "带袖的",
	["OMNI"] = "连合",
	["ZAFT"] = "扎多",
	["ORB"] = "奥布",
	["CB"] = "天人",
	["OTHERS"] = "其他",
	["@point"] = "点数",
	["gdsvoice"] = "通信员",
	["seshia"] = "塞西娅",
	["meiling"] = "美玲",
	["#RemoveEquipArea"] = "%from 失去了%arg区",
	["#gdsrecord"] = "%from 的出击次数为 %arg 次<br><font color='orange'><b>极限解放</b></font>模式——启动！<br><font color='orange'><b>（技能效果提升一阶）</b></font>",
	["map"] = "M炮",
	[":map"] = "<font color='red'><b>地图炮</b></font>，出牌阶段，对敌方发动大型攻击！（无伤害来源）<br><b>镭射炮</b>：令任意名其他角色受到2点雷电伤害。<br><b>创世纪</b>：令任意名其他角色失去2点体力。",
	["#map"] = "%from 发动了 <font color='red'><b>地图炮</b></font>：%arg",
	["map1"] = "镭射炮",
	["map2"] = "创世纪",
	["#BGM"] = "%arg",
	["BGM0"] = "♪ ☆Divine Act -The EXTREME-MAXI BOOST-",
	["BGM1"] = "♪ FINAL MISSION~QUANTUM BURST",
	["BGM2"] = "♪ Coupling Mode",
	["BGM3"] = "♪ SALLY <出擊>",
	["BGM4"] = "♪ 宇宙海賊クロスボーンバンガード戦闘テーマ",
	["BGM5"] = "♪ 俺のこの手が光って念るぅ！",
	["BGM6"] = "♪ 明镜止水",
	["BGM7"] = "♪ ガンダバダガンダバダ",
	["BGM8"] = "♪ 出撃！インパルス",
	["BGM9"] = "♪ UNICORN",
	["BGM10"] = "♪ 翔ベ！フリーダム",
	["BGM11"] = "♪ 思春期を殺した少年の翼",
	["BGM12"] = "♪ LAST IMPRESSION",
	["BGM13"] = "♪ 戦闘部队",
	["BGM14"] = "♪ DECISIVE BATTLE",
	["BGM15"] = "♪ Superior Attack",
	["BGM16"] = "♪ GX Dashes Out",
	["BGM17"] = "♪ 正義と自由",
	["BGM18"] = "♪ 悪の3兵器",
	["BGM19"] = "♪ 立ち上がれ！怒りよ",
	["BGM20"] = "♪ FIGHT",
	["BGM21"] = "♪ GUNDAM BUILD FIGHTERS",
	
	["IIVS"] = "辉勇面",
	["#IIVS"] = "极限全力",
	["~IIVS"] = "レオス！！帰ってきてください…お願いっ…！！",
	["designer:IIVS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IIVS"] = "雷奥斯·阿莱",
	["illustrator:IIVS"] = "wch5621628",
	["yuexian"] = "越限",
	[":yuexian"] = "<b>[1]</b>出牌阶段，你可以增加<b>1</b>点数激活<b><font color='orange'>“日蚀”</font></b>、<b><font color='orange'>“异化”</font></b>或<b><font color='orange'>“神圣”</font></b>，时限直到你的下回合开始前。\
	\
	<b>{3}点数特效</b>：当你的点数达致<b>3</b>时，点数清零，下回合不可发动<b>“越限”</b>。\
	\
	<img src=\"image/mark/@rishi.png\">：<b><font color='orange'>激活技</font></b>，你使用的【杀】或非延时类锦囊牌可额外指定一个目标且无距离限制。\
	<img src=\"image/mark/@yihua.png\">：<b><font color='orange'>激活技</font></b>，当其他角色对你使用非延时类锦囊牌结算后，你可以摸一张牌，然后将一张【杀】当火【杀】对其使用。\
	<img src=\"image/mark/@shensheng.png\">：<b><font color='orange'>激活技</font></b>，当你成为【杀】的目标后，你可以亮出牌堆顶的三张牌，你依次使用或获得之。",
	["rishi"] = "日蚀",
	[":rishi"] = "<b><font color='orange'>激活技</font></b>，你使用的【杀】或非延时类锦囊牌可额外指定一个目标且无距离限制。",
	["yihua"] = "异化",
	[":yihua"] = "<b><font color='orange'>激活技</font></b>，当其他角色对你使用非延时类锦囊牌结算后，你可以摸一张牌，然后将一张【杀】当火【杀】对其使用。",
	["#yihua"] = "请将一张【杀】当火【杀】对其使用，若已激活“日蚀”，可额外指定一个目标且无距离限制。",
	["shensheng"] = "神圣",
	[":shensheng"] = "<b><font color='orange'>激活技</font></b>，当你成为【杀】的目标后，你可以亮出牌堆顶的三张牌，你依次使用或获得之。",
	["#shensheng"] = "请选择【%src】的目标，若已激活“日蚀”，可额外指定一个目标且无距离限制；或按取消获得此牌。",
	["~shensheng"] = "选择目标→确定",
	["ssuse"] = "装载此装备牌",
	["ssobtain"] = "获得此装备牌",
	["#point"] = "%from 发动了<b><font color='orange'>点数特效</font></b>：%arg",
	["#IIVSp"] = "点数清零，下回合不可发动<b>“越限”</b>。",
	["$yuexian1"] = "エクリプス·フェース！",
	["$yuexian2"] = "ゼノン·フェース！",
	["$yuexian3"] = "アイオス·フェース！",
	["$rishi"] = "全ての人類の希望を…この一撃に！",
	["$yihua"] = "パイルピリオド！",
	["$shensheng"] = "アリス·ファンネル！",
	
	["UNICORN"] = "独角兽",
	["UNICORN_NTD"] = "毁灭模式",
	["#UNICORN"] = "可能性之兽",
	["~UNICORN"] = "御免…オードリー…",
	["~UNICORN_NTD"] = "御免…オードリー…",
	["designer:UNICORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:UNICORN"] = "巴纳吉·林克斯",
	["illustrator:UNICORN"] = "wch5621628",
	["shenshou"] = "神兽",
	[":shenshou"] = "当你使用一张<font color='red'><b>红色</b></font>的【杀】指定一名角色为目标后，你可以令其交给你一张<font color='red'><b>红色</b></font>牌，否则此【杀】不可被【闪】响应。",
	["@@shenshou"] = "请交给 %src 一张<font color='red'><b>红色</b></font>牌，否则此【杀】不可被【闪】响应",
	["NTD"] = "NT-D",
	[":NTD"] = "<img src=\"image/mark/@NTD.png\"><b><font color='green'>觉醒技</font></b>，当你成为一张非延时类锦囊牌的目标时，若你的体力不多于2，你须减1点体力上限终止此牌结算，展示你当前手牌，其中每有一张<font color='red'><b>红色</b></font>牌，你回复1点体力或摸一张牌，并获得技能<b>“毁灭”</b>（当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'><b>红色</b></font>手牌终止此牌结算，并视为你使用此牌）。",
	["@NTD"] = "NT-D",
	["ntddraw"] = "摸一张牌",
	["ntdrecover"] = "回复 1 点体力",
	["quanwu"] = "全武",
	[":quanwu"] = "<img src=\"image/mark/@linguang.png\"><b><font color='green'>觉醒技</font></b>，准备阶段开始时，若你装备区的牌数不小于3，且已发动<b>“NT-D”</b>，将武将牌更换为<b><font color='green'>“彩虹的彼方 – FA UNICORN”</font></b>。",
	["huimie"] = "毁灭",
	[":huimie"] = "当你成为一张非延时类锦囊牌的目标时，你可以弃置一张<font color='red'><b>红色</b></font>手牌终止此牌结算，并视为你使用此牌。",
	["huimiecard"] = "毁灭",
	["@huimie"] = "请弃置一张<font color='red'><b>红色</b></font>手牌终止【%src】结算",
	["~huimie"] = "选择目标→确定",
	["#huimie"] = "请选择【%src】的目标",
	["$shenshou"] = "（Beam Magnum）",
	["$NTD"] = "（NT-D Activated）",
	["$huimie1"] = "信じるんだ!自分の成すべきと思ったことを…!",
	["$huimie2"] = "人の心を知るものなら、ガンダム!俺に力を貸せ!",
	["$quanwu"] = "人の未来は…人が創るものだろ!!",
	
	["FA_UNICORN"] = "FA独角兽",
	["#FA_UNICORN"] = "彩虹的彼方",
	["~FA_UNICORN"] = "御免…オードリー…",
	["designer:FA_UNICORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:FA_UNICORN"] = "巴纳吉·林克斯",
	["illustrator:FA_UNICORN"] = "wch5621628",
	["zhonggong"] = "重攻",
	[":zhonggong"] = "出牌阶段限一次，你可以失去装备区的一个位置，然后对一名其他角色造成1点伤害。",
	["qingzhuang"] = "轻装",
	[":qingzhuang"] = "<b>锁定技</b>，若你没有装备区：你与其他角色的距离-2，<font color='red'><b>红色</b></font>【杀】对你无效。",
	["qingzhuang_redslash"] = "<font color='red'><b>红色</b></font>杀",
	["linguang"] = "磷光",
	[":linguang"] = "<img src=\"image/mark/@linguang.png\"><font color='red'><b>限定技</b></font>，出牌阶段，你可以：回复1点体力，并将所有其他角色的武将牌翻面。若如此做，你的装备牌视为【杀】，你失去装备区。",
	["@linguang"] = "磷光",
	["#linguangfilter"] = "磷光",
	["$zhonggong1"] = "パージする!",
	["$zhonggong2"] = "装備、切り離すぞ!",
	["$qingzhuang"] = "サイコ…フィールド",
	["$linguang"] = "俺の声に応えろ! ユニコーン!",
	
	["KSHATRIYA"] = "刹帝利",
	["#KSHATRIYA"] = "四枚羽根",
	["~KSHATRIYA"] = "姫様、申し訳ありません…。\
マリーダ・クルス、ここまでです…",
	["designer:KSHATRIYA"] = "wch5621628 & Sankies & NOS7IM",
	["cv:KSHATRIYA"] = "玛莉妲·库鲁斯",
	["illustrator:KSHATRIYA"] = "wch5621628",
	["qingyu"] = "青羽",
	[":qingyu"] = "弃牌阶段弃牌后，你可以将被弃置的牌中所有：\
♠牌当一张【南蛮入侵】使用。\
<font color='red'>♥</font>牌当一张【万箭齐发】使用。\
♣牌当一张【过河拆桥】使用。\
<font color='red'>♦</font>牌当一张【顺手牵羊】使用。",
    ["#qingyu3"] = "请选择【过河拆桥】的目标，可额外指定至多X个（X为你当前装备区的牌数）",
    ["#qingyu4"] = "请选择【顺手牵羊】的目标，可额外指定至多X个（X为你当前装备区的牌数）",
	["~qingyu"] = "选择目标→确定",
    ["siyi"] = "四翼",
	[":siyi"] = "当你使用一张非延时类锦囊牌时，你可以额外或减少指定至多X个目标（X为你当前装备区的牌数）。",
	["#siyi1"] = "请选择要减少的目标（至多X个目标，X为你当前装备区的牌数）",
	["#siyi2"] = "请选择要减少的目标（至多X个目标，X为你当前装备区的牌数）",
	["~siyi"] = "选择目标→确定",
	["$siyilog"] = "%from 取消了 %to 为目标角色",
	["$qingyu1"] = "行けっ、ファンネル!",
	["$qingyu2"] = "ファンネル!",
	["$qingyu3"] = "ファンネル達!",
	["$qingyu4"] = "光の中に消えろ!",
	["$siyi1"] = "ならばこれ、受けてみるか!",
	["$siyi2"] = "お前だけは…落とす!",
	["$siyi3"] = "この機体の実力…その魂に刻め!",
	["$siyi4"] = "光…全てを焼き尽くす、浄化の光…",
	
	["SINANJU"] = "新安洲",
	["#SINANJU"] = "赤色彗星再临",
	["~SINANJU"] = "まさか…こんな可能性がっ…!",
	["designer:SINANJU"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SINANJU"] = "弗尔·伏朗托",
	["illustrator:SINANJU"] = "Sankies",
	["xiaya"] = "夏亚",
	[":xiaya"] = "你可以将一张<font color='red'><b>红色</b></font>牌当【闪】使用或打出。",
	["zaishi"] = "再世",
	[":zaishi"] = "摸牌阶段摸牌时，你可以放弃摸牌，然后展示你的手牌，你重复摸牌，直到你拥有<font color='red'><b>三张红色</b></font>手牌。",
	["wangling"] = "亡灵",
	[":wangling"] = "当你受到一次伤害时，你可以失去一项其他技能并防止此伤害，然后视为你对伤害来源使用一张【杀】。",
	["$xiaya1"] = "当たらなければどうという事はない!",
	["$xiaya2"] = "この程度では落とされんよ!",
	["$xiaya3"] = "見事と言いたいところだが、まだ甘い",
	["$zaishi1"] = "これは、ニュータイプを否定した人類への報いだ!",
	["$zaishi2"] = "これが光を見た者の思いと知れ!",
	["$wangling1"] = "これが、赤い彗星の再来とはな…",
	["$wangling2"] = "私が君を殺す",
	
	["ReZEL"] = "里歇尔",
	["#ReZEL"] = "联邦精锐",
	["~ReZEL"] = "",
	["designer:ReZEL"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ReZEL"] = "诺姆队长",
	["illustrator:ReZEL"] = "Sankies",
	["duilie"] = "队列",
	[":duilie"] = "准备阶段开始时，你可以进行一次判定，根据判定牌获得相应效果，直到你的下回合开始前：\
<b>单数</b>：你使用点数为<b>单数</b>的牌时无距离限制。\
<b>双数</b>：点数为<b>双数</b>的牌对你无效。\
<b>黑色</b>：当你使用一张<b>黑色</b>牌时，你可以弃置目标角色的一张牌。\
<b><font color='red'>红色</font></b>：当你成为一张<b><font color='red'>红色</font></b>牌的目标后，你可以摸一张牌。",
	["#duiliee"] = "队列",
	["duilie:draw"] = "你是否发动“%dest”摸一张牌？",
	["duilie:throw"] = "你是否发动“%dest”弃置 %src 的一张牌？",
    ["#duilieA"] = "%from 获得效果：\
<font color='yellow'>你使用点数为<b>单数</b>的牌时无距离限制</font>",
	["#duilieB"] = "%from  获得效果：\
<font color='yellow'>点数为<b>双数</b>的牌对你无效</font>",
	["#duilieC"] = "%from  获得效果：\
<font color='yellow'>当你使用一张</font><b><font color='black'>黑色</font></b><font color='yellow'>牌时，你可以弃置目标角色的一张牌</font>",
	["#duilieD"] = "%from  获得效果：\
<font color='yellow'>当你成为一张</font><b><font color='red'>红色</font></b><font color='yellow'>牌的目标后，你可以摸一张牌</font>",
	["#duilieBe"] = "%from 的技能 %arg 被触发，点数为<b>双数</b>的牌对其无效",
	["zhihui"] = "指挥",
	[":zhihui"] = "当你发动“队列”后，你可以令你攻击范围内的一名其他角色共享你的效果。",
	["@@zhihui"] = "请选择攻击范围内的一名其他角色共享“队列”",
	
	["DELTA_PLUS"] = "德尔塔+",
	["#DELTA_PLUS"] = "时代的反抗者",
	["~DELTA_PLUS"] = "みんなで俺を否定するのか…!",
	["designer:DELTA_PLUS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DELTA_PLUS"] = "利迪·马瑟纳斯",
	["illustrator:DELTA_PLUS"] = "wch5621628",
	["xiezhan"] = "协战",
	[":xiezhan"] = "出牌阶段，你可以将一张装备牌置于你攻击范围内的一名其他角色的装备区里，视为其对你选择的另一名角色使用一张<b><font color='red'>红色</font></b>【杀】。",
	["xiezhancard"] = "协战",
	["tupo"] = "突破",
	[":tupo"] = "出牌阶段限一次，你可以视为使用一张【借刀杀人】，若目标角色选择不使用【杀】：你须装备此武器并视为你使用一张【杀】，结算后你失去1点体力。",
	["#tuporecord"] = "突破",
	["tupocard"] = "突破",
	["$xiezhan1"] = "変形機構を試す。こらえてくれよ!",
	["$xiezhan2"] = "やっぱ俺は、人型よりもこっちだね",
	["$xiezhan3"] = "お前の打撃力と俺の機動力。2つを合わせてヤツの土手っ腹をブチ抜く!",
	["$tupo1"] = "こいつだって、Z計画の名残なんだ!",
	["$tupo2"] = "箱の犠牲になる人間は、俺一人で十分だ!",
	
	["BANSHEE"] = "黑独角兽",
	["#BANSHEE"] = "报丧妖女",
	["~BANSHEE"] = "私は…ガンダム?",
	["designer:BANSHEE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BANSHEE"] = "普路十二",
	["illustrator:BANSHEE"] = "wch5621628",
	["mengshi"] = "猛狮",
	[":mengshi"] = "当你使用一张黑色的【杀】指定一名角色为目标后，你可以将其装备区里的一张牌置于其手牌，若如此做，你于此回合内使用【杀】的额外次数上限+1。",
	["#mengshislash"] = "猛狮",
	["ntdtwo"] = "NT-D",
	[":ntdtwo"] = "<img src=\"image/mark/@NTD2.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以：减1点体力上限，展示你当前手牌，每有一张黑色牌，视为你使用一张【过河拆桥】，并获得技能<b>“报丧”</b>（当你成为一张非延时类锦囊牌的目标时，你可以将一张黑色手牌当【乐不思蜀】或【兵粮寸断】使用，并终止此牌结算）",
	["@NTD2"] = "NT-D",
	["@ntdtwo"] = "请选择【过河拆桥】的目标角色",
	["~ntdtwo"] = "选择目标→确定",
	["baosang"] = "报丧",
	[":baosang"] = "当你成为一张非延时类锦囊牌的目标时，你可以将一张黑色手牌当【乐不思蜀】或【兵粮寸断】使用，并终止此牌结算。",
	["@baosang"] = "请选择【%src】的目标角色",
	["~baosang"] = "选择一张黑色手牌→选择目标→确定",
	["$mengshi1"] = "敵は全て焼き払う",
	["$mengshi2"] = "障害となる存在は破壊する",
	["$mengshi3"] = "立ちはだかるつもりか!",
	["$ntdtwo1"] = "この光は、憎しみの光!",
	["$ntdtwo2"] = "バンシィ…憎しみを流し込めぇ!!",
	["$ntdtwo3"] = "私を救ってくれる光…誰にも奪わせはしない!",
	["$baosang1"] = "灼いてやる! 苦しむがいい!",
	["$baosang2"] = "何も感じない人間などに!",
	["$baosang3"] = "誰にも邪魔はさせない。お前の腹も切り裂いてやる…!",
	
	["NORN"] = "黑独角兽N",
	["#NORN"] = "命运女神",
	["~NORN"] = "",
	["designer:NORN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:NORN"] = "利迪·马瑟纳斯",
	["illustrator:NORN"] = "wch5621628",
	["shenshi"] = "神狮",
	[":shenshi"] = "出牌阶段结束时，你可以将一至三张手牌明置于一名其他角色的手牌里，称为<b>“破”</b>。其他角色的结束阶段开始时，若其拥有<b>“破”</b>，你对其造成1点伤害，将其所有<b>“破”</b>置入弃牌堆。",
	["shenshipile"] = "选择“破”",
	["shenshihand"] = "选择其他手牌",
	["@shenshi"] = "请将一至三张手牌明置于一名其他角色的手牌里",
	["~shenshi"] = "选择手牌→选择目标→确定",
	["po"] = "破",
	["ntdthree"] = "NT-D",
	[":ntdthree"] = "<img src=\"image/mark/@NTD3.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以：减1点体力上限，展示你当前手牌，每有一张黑色牌，视为你使用一张【过河拆桥】，并获得技能<b>“诅咒”</b>（当你使用或被使用黑色【杀】时，你可以令此【杀】视为【决斗】）",
	["@NTD3"] = "NT-D",
	["@ntdthree"] = "请选择【过河拆桥】的目标角色",
	["~ntdthree"] = "选择目标→确定",
	["zuzhou"] = "诅咒",
	[":zuzhou"] = "当你使用或被使用黑色【杀】时，你可以令此【杀】视为【决斗】。",
	["xuanguang"] = "炫光",
	[":xuanguang"] = "<img src=\"image/mark/@xuanguang.png\"><font color='green'><b>觉醒技</b></font>，当你处于濒死状态时，且已发动<b>“NT-D”</b>，你失去装备区，失去技能<b>“神狮”</b>和<b>“诅咒”</b>，体力回复至1点，并获得以下效果：你的装备牌视为【桃】，没有装备的角色防止属性伤害。",
	["@xuanguang"] = "炫光",
	["#xuanguangfilter"] = "炫光",
	["#xuanguang"] = "%from 没有装备，触发“%arg”效果，防止了属性伤害",
	
	["PHENEX"] = "不死鸟",
	["#PHENEX"] = "金之不死鸟",
	["~PHENEX"] = "",
	["designer:PHENEX"] = "wch5621628 & Sankies & NOS7IM",
	["cv:PHENEX"] = "",
	["illustrator:PHENEX"] = "wch5621628",
	["shenniao"] = "神鸟",
	[":shenniao"] = "出牌阶段限一次，你可以弃置两张基本牌，令一至两名其他角色的所有装备效果无效，直到你的下回合开始前。",
	["$shenniaolog"] = "%from 对 %to 发动了“%arg”，%to 的 %card 效果无效",
	
	["EX_S"] = "EX-S",
	["#EX_S"] = "精灵的意志",
	["~EX_S"] = "",
	["designer:EX_S"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EX_S"] = "",
	["illustrator:EX_S"] = "wch5621628",
	["fanshe"] = "反射",
	[":fanshe"] = "出牌阶段限一次，你可以亮出牌堆顶的一张牌，若为<b><font color='red'>红色</font></b>，将其置于一名其他角色的武将牌上，称为<b><font color='red'>“INCOM”</font></b>，本回合你使用的牌由<b><font color='red'>“INCOM”</font></b>角色计算距离，且视为<b><font color='red'>“INCOM”</font></b>角色使用（你为伤害来源）。结束阶段开始时，你获得<b><font color='red'>“INCOM”</font></b>。",
	["@fanshe"] = "请将<b><font color='red'>“INCOM”</font></b>置于一名其他角色的武将牌上",
	[":ALICE"] = "当你受到一次伤害时，你可以观看牌堆顶的三张牌，若其中有两张相同花色的牌，你亮出之。你获得其中一张牌，将另一张牌交给伤害来源并防止此伤害。",
	["@ALICE-obtain"] = "请选择一张你获得的牌",
	["@ALICE-give"] = "请选择一张 %src 获得的牌",
	
	["WZ"] = "飞翼零式",
	["#WZ"] = "零式之翼",
	["~WZ"] = "俺は…俺は…俺は、俺は死なない…!",
	["designer:WZ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:WZ"] = "希罗·尤",
	["illustrator:WZ"] = "Sankies",
	["wzpoint"] = "点数特效",
	[":wzpoint"] = "<b>{X}</b>出牌阶段，你可以花费所有点数，然后摸等量张牌。",
	["feiyi"] = "飞翼",
	[":feiyi"] = "<b>锁定技</b>，若你的体力为2或更少，你使用【杀】时无距离限制；若你的体力为1，你于出牌阶段可以额外使用一张【杀】。",
	["liuxing"] = "流星",
	[":liuxing"] = "<b>[1]</b>你可以增加<b>1</b>点数，将两张手牌当【杀】使用，使用时进行一次判定，若为<font color='red'><b>红色</b></font>，此牌造成的伤害+1。",
	["lingshi"] = "零式",
	[":lingshi"] = "准备阶段开始时，若你的点数为3，你可以观看牌堆顶的三张牌，并以任意顺序置于牌堆顶。",
	["$wzpoint1"] = "完全に破壊する",
	["$wzpoint2"] = "逃がしはしない",
	["$wzpoint3"] = "ガンダムは宇宙には必要だ…! 宇宙を守るため、俺は戦う!",
	["$wzpoint4"] = "やはり…ガンダムの敵はガンダムか!",
	["$liuxing1"] = "排除開始",
	["$liuxing2"] = "フォーメーションを寸断する",
	["$liuxing3"] = "ターゲット、ロックオン…",
	["$liuxing4"] = "殲滅する",
	["$liuxing5"] = "逃れる事は出来ない!",
	["$lingshi1"] = "行くぞ、ゼロ!",
	["$lingshi2"] = "ゼロよ、俺を導いてくれ",
	["$lingshi3"] = "俺にははっきり見える、俺の敵が!",
	["$lingshi4"] = "コードZ.E.R.O.、ゼロシステム発動…!",
	["$lingshi5"] = "ウイングゼロが見せた未来から、俺が選んだのはこれだ!",
	["$lingshi6"] = "未来は視えている筈だ!",
	["$lingshi7"] = "ゼクス!強者などどこにもいない!人類全てが弱者なんだ!俺もお前も弱者なんだ!",
	["$lingshi8"] = "（Zero System）",
	
	["EPYON"] = "艾比安",
	["#EPYON"] = "恶魔的獠牙",
	["~EPYON"] = "リリーナ…なんとしても生き抜いてくれ。\
	さらばだ、我が妹!",
	["designer:EPYON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:EPYON"] = "米利亚尔特·匹斯克拉福特",
	["illustrator:EPYON"] = "Sankies",
	["qishi"] = "骑士",
	[":qishi"] = "<b>锁定技</b>，你的【南蛮入侵】、【万箭齐发】及【火攻】均视为【杀】；你的攻击范围始终为1。",
	["mosu"] = "魔速",
	[":mosu"] = "当一名其他角色于其回合内对你造成一次伤害后，你可以令当前回合立即结束，然后你进行一个额外的回合，此回合内，你与其距离视为1。",
	["cishi"] = "次式",
	[":cishi"] = "当你于出牌阶段杀死一名角色时，你可以：摸两张牌，你在此阶段内使用【杀】时无次数限制。",
	["$qishi1"] = "私なりの騎士道、貫かせてもらう!",
	["$qishi2"] = "この刃、受けてみろ!",
	["$qishi3"] = "弱者を作り出すのは強者だ!",
	["$mosu1"] = "この戦いに何の意味がある…?どんな意味が有るというのだ!!",
	["$mosu2"] = "この距離はエピオンの間合いだ!",
	["$mosu3"] = "エピオンの真の力…見せてやろう!",
	["$mosu4"] = "私はここだぁあ!",
	["$mosu5"] = "所詮は血塗られた運命、今更この罪から免れようとは思わん‼",
	["$mosu6"] = "必要ないのだ! 宇宙にとって貴様は!",
	["$mosu7"] = "決着をつけるぞ、ヒイロ!",
	["$cishi1"] = "この機体の能力、分かっていないようだな!",
	["$cishi2"] = "ゼロシステム…私に本当の敵を見せろ!",
	["$cishi3"] = "エピオン…未来を見せてくれ",
	["$cishi4"] = "行け! エピオン! 私に未来を見せるのだ!",
	["$cishi5"] = "ゼロシステムの力…最大限まで引き出す!",
	
	["WZC"] = "飞翼零式改",
	["#WZC"] = "纯白之翼",
	["~WZC"] = "任務…完了…自爆する",
	["designer:WZC"] = "wch5621628 & Sankies & NOS7IM",
	["cv:WZC"] = "希罗·尤",
	["illustrator:WZC"] = "Sankies",
    ["shuangpao"] = "双炮",
	[":shuangpao"] = "出牌阶段限一次，你可以失去1点体力，若如此做，你本回合使用【杀】对距离1以外的目标角色造成的伤害+1。",
	["#shuangpao"] = "%from 发动了“%arg”，本回合使用【杀】对距离1以外的目标角色造成的伤害+1。",
	["ew_lingshi"] = "零式",
	["@ew_lingshi"] = "零式",
	[":ew_lingshi"] = "<img src=\"image/mark/@ew_lingshi.png\"><b><font color='red'>限定技</font></b>，当你没有手牌时失去体力后，你可以观看牌堆顶的十张牌，将其中任意数量的牌以任意顺序置于牌堆顶，你获得其余的牌，然后将你的武将牌翻面。",
	["$shuangpao1"] = "排除開始",
	["$shuangpao2"] = "フォーメーションを寸断する",
	["$shuangpao3"] = "ターゲット、ロックオン…",
	["$shuangpao4"] = "殲滅する",
	["$ew_lingshi1"] = "行くぞ、ゼロ!",
	["$ew_lingshi2"] = "ゼロよ、俺を導いてくれ",
	["$ew_lingshi3"] = "俺にははっきり見える、俺の敵が!",
	["$ew_lingshi4"] = "コードZ.E.R.O.、ゼロシステム発動…!",
	["$ew_lingshi5"] = "ウイングゼロが見せた未来から、俺が選んだのはこれだ!",
	["$ew_lingshi6"] = "未来は視えている筈だ!",
	["$ew_lingshi7"] = "ゼクス!強者などどこにもいない!人類全てが弱者なんだ!俺もお前も弱者なんだ!",
	["$ew_lingshi8"] = "（Zero System）",
	["$ew_lingshi9"] = "零式、（哪咤）、引导我吧！",
	
	["DSH"] = "地狱死神改",
	["#DSH"] = "月下的死神",
	["~DSH"] = "くっそぉ~、結構な仕事だったぜ",
	["designer:DSH"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DSH"] = "迪奥·麦克斯维尔",
	["illustrator:DSH"] = "Sankies",
	["yindun"] = "隐遁",
	[":yindun"] = "结束阶段开始时，你可以摸一张牌，然后将你的武将牌翻面；当你的武将牌背面朝上时，你不能成为【杀】的目标。",
	["ansha"] = "暗杀",
	[":ansha"] = "当一名其他角色于其弃牌阶段弃置牌后，若你的武将牌背面朝上，你可以弃置一张牌并将你的武将牌翻至正面朝上，然后令其失去1点体力。",
	["$yindun1"] = "行くぜぇ!",
	["$yindun2"] = "俺と一緒に、地獄行くぜぇ!",
	["$ansha1"] = "死ぬぜぇ……俺を見たやつは、みんな死んじまうぞぉ!",
	["$ansha2"] = "オラオラ、死神様のお通りだぁー!",
	
	["HAC"] = "重武装改",
	["#HAC"] = "小丑之泪",
	["~HAC"] = "始めるか、俺の自爆ショーを…",
	["designer:HAC"] = "wch5621628 & Sankies & NOS7IM",
	["cv:HAC"] = "多洛华·巴顿",
	["illustrator:HAC"] = "Sankies",
	["gelin"] = "格林",
	[":gelin"] = "游戏开始时，你将牌堆顶的十张牌移出游戏，称为<b>“弹”</b>；你可以将一张<b>“弹”</b>当【杀】、两张“弹”当【闪】使用或打出。",
	["dan"] = "弹",
	["saoshe"] = "扫射",
	[":saoshe"] = "<b>锁定技</b>，当你于出牌阶段计算你使用【杀】的次数限制时，每名目标角色独立计算。",
	["$gelin1"] = "后方支援交给我吧",
	["$gelin2"] = "歼灭敌机!",
	
	["SANDROCK"] = "沙漠改",
	["#SANDROCK"] = "沙漠之双镰",
	["~SANDROCK"] = "これ以上は戦えない…",
	["designer:SANDROCK"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SANDROCK"] = "卡托鲁·拉贝巴·温纳",
	["illustrator:SANDROCK"] = "Sankies",
	["shuanglian"] = "双镰",
	["shuangliancard"] = "双镰",
	[":shuanglian"] = "当你使用【杀】时，你可以弃置一张【闪】，令攻击范围内的一名其他角色打出一张【闪】，否则你对其造成1点伤害；当你使用或打出【闪】时，你可以将你的武将牌翻面，视为对一个目标使用一张【杀】。",
	["shuanglian:slash"] = "你想发动技能“双镰”吗?<br>当你使用【杀】时，你可以弃置一张【闪】，令攻击范围内的一名其他角色打出一张【闪】，否则你对其造成1点伤害。",
	["shuanglian:jink"] = "你想发动技能“双镰”吗?<br>当你使用或打出【闪】时，你可以将你的武将牌翻面，视为对一个目标使用一张【杀】。",
	["@@shuanglianjink"] = "请弃置一张【闪】",
	["@@shuanglianjinktar"] = "请选择攻击范围内的一名其他角色",
	["@@shuanglianjinkres"] = "请打出一张【闪】，否则受到1点伤害",
	["@@shuanglianslashtar"] = "请选择一名【杀】的目标角色",
	["zaizhan"] = "再战",
	[":zaizhan"] = "<img src=\"image/mark/@zaizhan.png\"><b><font color='red'>限定技</font></b>，结束阶段开始时，你可以将你的武将牌翻面，令至多X名角色各摸一张牌并依次进行一个额外的回合。（X为你已损失的体力值）",
	["@zaizhan"] = "再战",
	["#zaizhan"] = "请选择至多X名角色（可选自己），X为你已损失的体力值",
	["~zaizhan"] = "选择目标角色→确定",
	["$shuanglian1"] = "僕は…戦争を凌ぐ平和を信じる! 平和を望む心を信じる!!",
	["$shuanglian2"] = "力を貸してくれ! サンドロック!",
	["$zaizhan1"] = "僕達の出番だ、サンドロック!",
	["$zaizhan2"] = "サンドロック、僕達の戦いを始めよう",
	
	["ALTRON"] = "双头龙改",
	["#ALTRON"] = "哪咤之魂",
	["~ALTRON"] = "哪咤，在暗夜中沉睡吧",
	["designer:ALTRON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ALTRON"] = "张五飞",
	["illustrator:ALTRON"] = "Sankies",
	["shuanglong"] = "双龙",
	["shuanglong1"] = "双龙",
	["shuanglong2"] = "双龙",
	[":shuanglong"] = "出牌阶段限一次，你可以与一名其他角色拼点。若你赢，你与其距离始终为1；你无视其防具；你对其使用【杀】时无次数限制。直到回合结束。若你没赢，你可以将场上的一张装备牌置于一名角色的装备区里。",
	["shuanglong_movefrom"] = "请选择一名拥有装备的角色",
	["shuanglong_moveto"] = "请选择一名获得【%src】角色",
	["$shuanglong1"] = "我知道，你是邪恶！",
	["$shuanglong2"] = "正义……正义由我来决定！",
	["$shuanglong3"] = "我是……士兵们和人们的代言者！",
	["$shuanglong4"] = "我是要打倒你士兵，为了所有而战斗！",
	["$shuanglong5"] = "谁都不能……把我停止！",
	
	["#DX"] = "月色下的恶魔",
	["~DX"] = "だめぇ!",
	["designer:DX"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DX"] = "卡洛德·兰 & 蒂法·雅蒂尔",
	["illustrator:DX"] = "Sankies",
	["yueguang"] = "月光",
	[":yueguang"] = "<b>锁定技</b>，准备阶段开始时，你须进行一次判定，若为<b>黑色</b>，你增加1点数，若为<font color='red'><b>红色</b></font>，你减少1点数。\
	\
	<b>{≥2}点数特效</b>：若你的点数<b>≥2</b>，你使用【杀】时可额外指定一名目标角色。",
	["weibo"] = "微波",
	[":weibo"] = "<b>[↓1]</b>出牌阶段，你可以花费<b>1</b>点数令你本回合使用的下一张【杀】造成的伤害+1。",
	["#weibo"] = "%from 发动了“%arg”，本回合使用的下一张【杀】造成的伤害+1。",
	["weixing"] = "卫星",
	[":weixing"] = "<b>[↓2]</b>出牌阶段，你可以花费<b>2</b>点数令你本回合使用的下一张【杀】不可被【闪】响应。",
	["#weixing"] = "%from 发动了“%arg”，本回合使用的下一张【杀】不可被【闪】响应。",
	["difa"] = "蒂法",
	[":difa"] = "你可以将对你造成伤害的牌置于你的武将牌上；在你的判定牌生效前，你可以打出此牌代替之。",
	["difa:damage"] = "你是否发动“蒂法”，将对你造成伤害的牌置于你的武将牌上？",
	["@difa-card"] = "请发动“%dest”来修改 %src 的 %arg 判定",
	["~difa"] = "选择一张“蒂法”→点击确定",
	["#dxpoint"] = "你使用【杀】时可额外指定一名目标角色。",
	["$yueguang1"] = "見えた!",
	["$yueguang2"] = "月が見えた!",
	["$yueguang3"] = "ええい、エネルギー消す?",
	["$yueguang4"] = "チャージに時間がかかるのかよ!",
	["$weibo1"] = "行けぇ!",
	["$weibo2"] = "死なせるもんかぁーっ!!",
	["$weibo3"] = "わかってたまるかぁー!!",
	["$weibo4"] = "世界を滅ぼされてたまるかぁー!!",
	["$weixing1"] = "俺もう、ニュータイプに…?",
	["$weixing2"] = "これがお前達の求めていた戦争か!?",
	["$weixing3"] = "たとえ地球がメチャメチャになっても、ティファの事守ってみせる",
	["$difa1"] = "ガロード…あなたに力を",
	["$difa2"] = "私達を守って",
	["$difa3"] = "あきらめないで、希望はあります",
	["$difa4"] = "ガロード…私を見て",
	
	["GINN"] = "米基尔基恩",
	["#GINN"] = "黄昏的魔弹",
	["~GINN"] = "可恶……脱出！",
	["designer:GINN"] = "wch5621628 & Sankies & NOS7IM",
	["cv:GINN"] = "米基尔·艾曼",
	["illustrator:GINN"] = "Sankies",
	["laobing"] = "老兵",
	[":laobing"] = "当你进行判定前，你可以声明一种花色，若该次判定牌的花色与你声明的相同，你可以回复1点体力并重新进行判定；若花色不同，你获得判定牌。",
	["baopo"] = "爆破",
	[":baopo"] = "当你使用【杀】对目标角色造成一次伤害后，你可以弃置一张牌，然后弃置其装备区里的一张牌。",
	["$laobing1"] = "哼……很容易呢",
	["$laobing2"] = "好……前进！",
	["$baopo1"] = "来吧~击落吧！",
	["$baopo2"] = "将你击破吧！",
	
	["STRIKE"] = "突击",
	["#STRIKE"] = "觉醒的利刃",
	["huanzhuang"] = "换装",
	[":huanzhuang"] = "准备阶段开始时，你可以进行一次判定，你可以获得相应效果直到回合结束：\
<b><font color='black'>黑色</font></b>：你使用【杀】造成的伤害+1、被目标角色的【闪】抵消时，其可以弃置你一张手牌。\
<b><font color='red'>红色</font></b>：你的攻击范围+1。\
<b>不判定</b>：结束阶段开始时，你摸一张牌。",
	["huanzhuang:throw"] = "你是否弃置来源一张手牌？",
	["#huanzhuangn"] = "<b>空装：<font color='yellow'>结束阶段开始时，你摸一张牌</font></b>",
	["#huanzhuangb"] = "<b>剑装：<font color='yellow'>你使用【杀】造成的伤害+1、被目标角色的【闪】抵消时，其可以弃置你一张手牌</font></b>",
	["#huanzhuangr"] = "<b>炮装：<font color='yellow'>你的攻击范围+1</font></b>",
	["xiangzhuan"] = "相转",
	[":xiangzhuan"] = "当你受到黑色【杀】造成的伤害时，你可以弃置装备区里的一张牌防止此伤害。",
	["#xiangzhuan"] = "%from 的“%arg”效果被触发，防止了<b><font color='black'>黑色</font></b>【杀】造成的伤害",
	["~STRIKE"] = "軍人でもない僕が、\
勝てるわけがないんだ!",
	["designer:STRIKE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:STRIKE"] = "基拉·大和",
	["illustrator:STRIKE"] = "Sankies",
	["$huanzhuang1"] = "パック、換装を!",
	["$huanzhuang2"] = "ストライカーパックを換装します!",
	["$huanzhuang3"] = "エールストライカーを!",
	["$huanzhuang4"] = "ランチャーストライカーを!",
	["$huanzhuang5"] = "ソードストライカーを!",
	["$xiangzhuan1"] = "気持ちだけで、一体何が守れるって言うんだ!",
	["$xiangzhuan2"] = "もう僕達を、放っておいてくれぇぇっ!",
	
	["AEGIS"] = "神盾",
	["#AEGIS"] = "闪光的一刻",
	["jiechi"] = "劫持",
	[":jiechi"] = "出牌阶段，你可以弃置一张手牌，然后弃置一名其他角色装备区里的一张牌。",
    ["juexin"] = "决心",
	["@juexin"] = "决心",
	[":juexin"] = "<img src=\"image/mark/@juexin.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以弃置所有手牌并指定一名其他角色，该角色于其回合开始前进行一次判定，若不为♠，该角色失去2点体力，然后你死亡。",
    ["~AEGIS"] = "……尼哥路！",
	["designer:AEGIS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:AEGIS"] = "亚斯兰·察拉",
	["illustrator:AEGIS"] = "wch5621628",
	["$jiechi1"] = "我说过我要向你开枪！",
	["$jiechi2"] = "向他开枪…这次一定要！",
	["$jiechi3"] = "向基拉开枪…这次一定要！",
	["$juexin1"] = "我…要向你开枪！",
	["$juexin2"] = "基拉！",
	["$xiangzhuan3"] = "停下来！快停止这场战斗。",
	["$xiangzhuan4"] = "无论如何都要动手的话，我就要把你杀了。",
	
	["BUSTER"] = "暴风",
	["#BUSTER"] = "决意的炮火",
	["shuangqiang"] = "双枪",
	[":shuangqiang"] = "出牌阶段，你可以将一张装备牌或锦囊牌当【杀】使用，对目标角色造成伤害后：若为前者，你弃置其装备区里的一张牌；后者，你获得其一张手牌。",
    ["zuzhuang"] = "组装",
	[":zuzhuang"] = "出牌阶段，你可以将一张装备牌和一张锦囊牌当【杀】使用，对目标角色造成伤害后：你弃置其装备区里的所有牌，或你弃置其所有手牌。",
    ["zze"] = "弃置其装备区里的所有牌",
	["zzh"] = "弃置其所有手牌",
	["~BUSTER"] = "嘁…界限高度么？",
	["designer:BUSTER"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BUSTER"] = "迪亚卡·艾尔斯曼",
	["illustrator:BUSTER"] = "wch5621628",
	["$shuangqiang1"] = "（口哨声）…又一个！",
	["$shuangqiang2"] = "GREAT！",
	["$zuzhuang1"] = "我不会让你在此再上前！",
	["$zuzhuang2"] = "快从这里离开，大天使号！",
	
	["DUEL_AS"] = "决斗AS",
	["#DUEL_AS"] = "战意的疤痕",
	["sijue"] = "死决",
	[":sijue"] = "出牌阶段，你可以将一张黑色基本牌当【决斗】使用，你以此法指定一名角色为目标后，该角色摸一张牌。",
    ["pojia"] = "破甲",
	["@pojia"] = "破甲",
	["pojiacard"] = "破甲",
	[":pojia"] = "<img src=\"image/mark/@pojia.png\"><b><font color='red'>限定技</font></b>，当你受到伤害后，你可以弃置你装备区里的所有牌（至少一张），视为对伤害来源使用两张【决斗】，并防止此【决斗】对你造成的伤害。",
    ["~DUEL_AS"] = "痛い…!痛い痛いぃ!!!",
	["designer:DUEL_AS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:DUEL_AS"] = "伊撒古·玖尔",
	["illustrator:DUEL_AS"] = "wch5621628",
	["$sijue1"] = "この一撃、受けてみろ!",
	["$sijue2"] = "イザーク様をなめるなよ!",
	["$pojia1"] = "さぁ、見せてやるぞ! コーディネーターの力を!",
	["$pojia2"] = "もう好き勝手はさせんぞ! 貴様ら!",
	
	["BLITZ"] = "迅雷",
	["#BLITZ"] = "消失的高达",
	["yinxian"] = "隐现",
	["@yinxian"] = "海市蜃楼",
	[":yinxian"] = "当你使用或打出【闪】时，你可以进入<b>“海市蜃楼”</b>状态。当你使用【杀】结算后，解除<b>“海市蜃楼”</b>状态。\
<img src=\"image/mark/@yinxian.png\"><b>海市蜃楼</b>：你使用的【杀】具雷电伤害且不可被【闪】响应，其他角色与你的距离+1。",
    ["#EnterYinxian"] = "%from 进入“<b><font color='yellow'>海市蜃楼</font></b>”状态：\
<font color='yellow'>你使用的【杀】具雷电伤害且不可被【闪】响应，其他角色与你的距离+1</font>",
	["#RemoveYinxian"] = "%from 解除“<b><font color='yellow'>海市蜃楼</font></b>”状态",
	["zhuanjin"] = "转进",
	["@zhuanjin"] = "转进",
	["zhuanjincard"] = "转进",
	[":zhuanjin"] = "<img src=\"image/mark/@zhuanjin.png\"><b><font color='red'>限定技</font></b>，当一名其他角色处于濒死状态时，你可以令其体力回复至1点并摸X张牌（X为你与其已损失的体力值和），然后视为伤害来源对你使用一张【杀】。",
    ["~BLITZ"] = "母さん…僕の、ピアノ…",
	["designer:BLITZ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLITZ"] = "尼哥路·阿玛菲",
	["illustrator:BLITZ"] = "wch5621628",
	["BLITZ_Y"] = "迅雷",
	["#BLITZ_Y"] = "消失的高达",
	["~BLITZ_Y"] = "母さん…僕の、ピアノ…",
	["designer:BLITZ_Y"] = "wch5621628 & Sankies & NOS7IM",
	["cv:BLITZ_Y"] = "尼哥路·阿玛菲",
	["illustrator:BLITZ_Y"] = "wch5621628",
	["$yinxian1"] = "ミラージュコロイド!",
	["$yinxian2"] = "僕の姿が、見えないはずです!",
	["$yinxian3"] = "あなたには僕が見えないはずだ!",
	["$yinxian4"] = "ミラージュコロイドを解きます!",
	["$yinxian5"] = "もう隠れる必要はありません!",
	["$yinxian6"] = "ミラージュコロイドを使った高速戦闘…",
	["$zhuanjin1"] = "みんな下がって!ここは僕が!",
	["$zhuanjin2"] = "アスラン下がって!",
	
	["FREEDOM"] = "自由",
	["#FREEDOM"] = "自由之翼",
	["helie"] = "核裂",
	[":helie"] = "出牌阶段开始和结束时，你可以弃置所有手牌，然后摸等同于你体力上限的牌。",
	["jiaoxie"] = "缴械",
	[":jiaoxie"] = "当你使一名其他角色进入濒死状态、或一名其他角色使你进入濒死状态时，你可以令其失去一项技能（不可为限定技或觉醒技）。",
	["zhongzi"] = "种子",
	["@seed"] = "SEED",
	[":zhongzi"] = "<img src=\"image/mark/@seed.png\"><b><font color='green'>觉醒技</font></b>，当你处于濒死状态求桃完毕后，你将体力回复至2点，失去技能<b>“缴械”</b>并获得技能<b>“齐射”</b>（出牌阶段，你可以将所有手牌（至少一张）当火【杀】使用，此【杀】可指定至多X名目标且无距离限制（X为手牌数））。",
	["qishe"] = "齐射",
	[":qishe"] = "出牌阶段，你可以将所有手牌（至少一张）当火【杀】使用，此【杀】可指定至多X名目标且无距离限制（X为手牌数）。",
	["~FREEDOM"] = "僕のせいで、僕のせいで!",
	["designer:FREEDOM"] = "wch5621628 & Sankies & NOS7IM & lulux",
	["cv:FREEDOM"] = "基拉·大和",
	["illustrator:FREEDOM"] = "Sankies",
	["$helie1"] = "想いだけでも、力だけでも…!",
	["$helie2"] = "僕には…やれるだけの力がある!",
	["$jiaoxie1"] = "そんなに死にたいのか!",
	["$jiaoxie2"] = "もうやめるんだー!!",
	["$zhongzi1"] = "（SEED）",
	["$zhongzi2"] = "それでも、守りたいものがあるんだ!",
	["$qishe1"] = "僕は…それでも僕は!",
	["$qishe2"] = "これ以上、僕にさせないでくれ!",
	
	["shouwang"] = "守望",
	[":shouwang"] = "当你需要使用一张【桃】时，你可以减1点体力上限，视为你使用之。",
	["zhongzij"] = "种子",
	[":zhongzij"] = "<img src=\"image/mark/@seedj.png\"><b><font color='green'>觉醒技</font></b>，当你的体力上限为1时，你将体力上限增加至3点，失去技能<b>“守望”</b>并获得技能<b>“挥舞”</b>（出牌阶段限一次，当你使用【杀】结算后，你可以弃置所有手牌（至少一张）：黑色【杀】：弃置目标角色装备区里的一张牌；<font color='red'>红色</font>【杀】：额外结算一次。）",
	["@seedj"] = "SEED",
	["huiwu"] = "挥舞",
	[":huiwu"] = "出牌阶段限一次，当你使用【杀】结算后，你可以弃置所有手牌（至少一张）：黑色【杀】：弃置目标角色装备区里的一张牌；<font color='red'>红色</font>【杀】：额外结算一次。",
	["~JUSTICE"] = "就算是这样，也不会挽回些什么！",
	["JUSTICE"] = "正义",
	["#JUSTICE"] = "正义之剑",
	["designer:JUSTICE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:JUSTICE"] = "亚斯兰·察拉",
	["illustrator:JUSTICE"] = "Sankies",
	["$helie3"] = "军方对这次战斗并没有下达任何命令。",
	["$helie4"] = "这次介入…是我个人的意思。",
	["$shouwang1"] = "在这种地方，怎么可以让你死掉!",
	["$shouwang2"] = "现在请尽快进行维修。",
	["$zhongzij"] = "你们真的要破坏所有东西吗?!",
	["$huiwu1"] = "决一胜负吧!",
	["$huiwu2"] = "你们倒是怎么了?!到底为了什么而战斗?!",
	
	["wenshen"] = "瘟神",
	[":wenshen"] = "你可以将一张装备牌当【酒】或【杀】使用。",
	["@wenshen"] = "请将一张装备牌当【%src】使用",
	["~wenshen"] = "选择一张装备牌→（选择目标）→确定",
	["jinduan"] = "禁断",
	[":jinduan"] = "当其他角色使用<font color='red'>红色</font>牌指定你为目标时，你可以选择另一名其他角色，其代替你成为此牌的目标。",
	["@jinduan"] = "请选择另一名其他角色，代替你成为此牌的目标",
	["liesha"] = "猎杀",
	[":liesha"] = "当你使用一张【杀】时，你可以摸一张牌。",
	["~CFR"] = "あーあ、やっちゃったー…",
	["CFR"] = "瘟神禁断猎杀",
	["#CFR"] = "恶之三兵器",
	["designer:CFR"] = "wch5621628 & Sankies & NOS7IM",
	["cv:CFR"] = "奥尔加·萨布纳克&夏尼·安德拉斯&古朗度·布路",
	["illustrator:CFR"] = "Sankies",
	["$wenshen1"] = "うざいんだよ!",
	["$wenshen2"] = "オラ、いくぜ!",
	["$jinduan1"] = "お前、お前、お前ェッ!!",
	["$jinduan2"] = "ばいばーい",
	["$liesha1"] = "そりゃー、滅殺!!",
	["$liesha2"] = "でりゃー、必殺!!",
	
	["longqi"] = "龙骑",
	["@longqi"] = "请观看一名其他角色的手牌并弃置其中一张<br>【闪】点数=%src<br>弃置点数%src的牌：对其造成1点伤害<br>弃置点数差为1的牌：重复此流程",
	[":longqi"] = "当你使用或打出一张【闪】时，你可以：观看一名其他角色的手牌并弃置其中一张，若此牌与【闪】的点数相同，你对其造成1点伤害；若点数差为1，你可以重复此流程。",
    ["chuangshi"] = "创世",
	[":chuangshi"] = "<b>锁定技</b>，当你受到其他角色造成的伤害时，若伤害不小于你的体力值，你减1点体力上限，然后对伤害来源造成等量伤害。",
	["~PROVIDENCE"] = "扉がっ…! 最後の扉が!",
	["PROVIDENCE"] = "天意",
	["#PROVIDENCE"] = "终末之光",
	["designer:PROVIDENCE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:PROVIDENCE"] = "劳·鲁·克鲁泽",
	["illustrator:PROVIDENCE"] = "wch5621628",
	["$helie5"] = "存分に殺し合うがいい!",
	["$helie6"] = "私を止められはせぬ!!",
	["$longqi1"] = "これが人の夢!人の望み!!人の業!!!",
	["$longqi2"] = "他者より強く!他者より先へ!!他者より上へ!!!",
	["$chuangshi1"] = "自ら育てた闇に喰われて、人は滅ぶとな!",
	["$chuangshi2"] = "もう誰にも止められはしないさ! この宇宙を覆う、憎しみの渦はなぁ!!",
	
	["daohe"] = "氘核",
	[":daohe"] = "准备阶段开始时，你可以获得以下一项效果直到回合结束：\
<img src=\"image/mark/@meiying.png\">：攻击范围+1；当你使用【杀】后没有造成伤害，你可以额外使用一张【杀】。\
<img src=\"image/mark/@jianyingg.png\">：攻击范围+1；当你使用【杀】后没有造成伤害，你可以摸一张牌。\
<img src=\"image/mark/@jiying.png\">：攻击范围+2；当你使用【杀】对一名角色造成伤害时，若伤害不小于其体力值，你可以令此伤害+1。",
	["meiying"] = "魅影",
	["@meiying"] = "魅影",
	[":meiying"] = "攻击范围+1；当你使用【杀】后没有造成伤害，你可以额外使用一张【杀】。",
	["jianyingg"] = "剑影",
	["@jianyingg"] = "剑影",
	[":jianyingg"] = "攻击范围+1；当你使用【杀】后没有造成伤害，你可以摸一张牌。",
	["jiying"] = "疾影",
	["@jiying"] = "疾影",
	[":jiying"] = "攻击范围+2；当你使用【杀】对一名角色造成伤害时，若伤害不小于其体力值，你可以令此伤害+1。",
	["#daohe"] = "%from 获得效果“%arg”：%arg2",
	["emeng"] = "恶梦",
	["@emeng"] = "恶梦",
	[":emeng"] = "<img src=\"image/mark/@emeng.png\"><b><font color='green'>觉醒技</font></b>，当你受到攻击范围外的角色使用【杀】造成的伤害后，将技能<b>“氘核”</b>改为<b>“你可以获得以下两项效果”</b>。",
	["~IMPULSE"] = "",
	["IMPULSE"] = "脉冲",
	["#IMPULSE"] = "新生之鸟",
	["designer:IMPULSE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:IMPULSE"] = "真·飞鸟",
	["illustrator:IMPULSE"] = "Sankies",
	
	["SP_DESTINY"] = "SP命运",
	["#SP_DESTINY"] = "恶魔的契约",
	["~SP_DESTINY"] = "",
	["designer:SP_DESTINY"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SP_DESTINY"] = "真·飞鸟",
	["illustrator:SP_DESTINY"] = "Sankies",
	["shanshuo"] = "闪烁",
	[":shanshuo"] = "出牌阶段结束时，你可以将任意数量的牌至于武将牌上，称为<b>“翼”</b>；你可以在合理的时机使用或打出<b>“翼”</b>；每有一张<b>“翼”</b>，你计算与其他角色的距离便-1。",
	["&yi"] = "翼",
	["@shanshuo"] = "你想发动技能“%src”吗?",
	["~shanshuo"] = "请选择至少一张牌→确定",
	["xingzhui"] = "星坠",
	[":xingzhui"] = "一名角色的准备阶段开始时，你可以将所有<b>“翼”</b>（至少一张）置入弃牌堆，若颜色相同，视为你使用了一张基本牌，若颜色不同，视为你使用了一张非延时类锦囊牌。",
	["@xingzhui"] = "请选择【%src】的目标",
	["~xingzhui"] = "选择目标→确定",
	
	["REBORNS_CANNON"] = "再生加农",
	["#REBORNS_CANNON"] = "原始的变革者",
	["~REBORNS_CANNON"] = "この、人間風情が!",
	["designer:REBORNS_CANNON"] = "wch5621628 & Sankies & NOS7IM",
	["cv:REBORNS_CANNON"] = "利邦兹·阿尔马克",
	["illustrator:REBORNS_CANNON"] = "NOS7IM",
	["jidong"] = "机动",
	[":jidong"] = "出牌阶段限一次，你可以弃置一张牌，将武将牌更换为<b>“再生加农”</b>或<b>“再生高达”</b>。",
	["fengong"] = "奋攻",
	[":fengong"] = "出牌阶段限一次，你可以弃置一张属性【杀】，令一至两名其他角色：打出一张【闪】，否则你对其造成1点伤害。",
	["@fengong"] = "请打出一张【闪】，否则受到1点伤害",
	["$jidong1"] = "リボーンズキャノン!",
	["$jidong2"] = "かわしても僕は構わないんだよ",
	["$jidong3"] = "リボーンズガンダム!",
	["$jidong4"] = "そうとも。この機体こそ、人類を導くガンダムだ!",
	["$fengong1"] = "新しい創造主さ!",
	["$fengong2"] = "この距離は届く!",
	["$fengong3"] = "さようならだ",
	
	["REBORNS_GUNDAM"] = "再生高达",
	["#REBORNS_GUNDAM"] = "变革者的再生",
	["~REBORNS_GUNDAM"] = "この、人間風情が!",
	["designer:REBORNS_GUNDAM"] = "wch5621628 & Sankies & NOS7IM",
	["cv:REBORNS_GUNDAM"] = "利邦兹·阿尔马克",
	["illustrator:REBORNS_GUNDAM"] = "NOS7IM",
	["zaisheng"] = "再生",
	[":zaisheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后重复亮出牌堆顶的牌，若为基本牌，你获得之，直到你以此法获得X张牌（X为你以此法弃置的牌数）。",
	["reborns_transam"] = "TRANS-AM",
	[":reborns_transam"] = "<img src=\"image/mark/@reborns_transam.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以令你于本回合发动<b>“机动”</b>或<b>“奋攻”</b>时无次数限制，且发动<b>“机动”</b>时不需弃牌。",
	["@reborns_transam"] = "TRANS-AM",
	["$zaisheng1"] = "さぁ始めよう。来たるべき未来のために",
	["$zaisheng2"] = "ボクを叩けなかった君達の負けだよ",
	["$zaisheng3"] = "救世主なんだよ僕は",
	["$reborns_transam"] = "トランザム!",
	
	["HARUTE"] = "哈鲁特",
	["#HARUTE"] = "妖天使",
	["~HARUTE"] = "あぁ!アレルヤァ!!マ…マリー!大丈夫か?",
	["designer:HARUTE"] = "wch5621628 & Sankies & NOS7IM",
	["cv:HARUTE"] = "阿路耶/哈路耶·哈帝姆&索玛·皮里斯",
	["illustrator:HARUTE"] = "Sankies",
	["feijian"] = "飞剪",
	[":feijian"] = "游戏开始时，你将牌堆顶的四张牌置于你的武将牌上，称为<b>“剪”</b>。你可以将一张与<b>“剪”</b>相同花色的牌当【杀】使用或打出，你以此法使用【杀】时可额外指定一名目标角色。",
	["jian"] = "剪",
	["liuyan"] = "六眼",
	[":liuyan"] = "<img src=\"image/mark/@MARUT.png\"><b><font color='green'>觉醒技</font></b>，准备阶段开始时，若你的体力为2或更少，你减1点体力上限，摸六张牌，并获得以下效果：你可以将一张<b>“剪”</b>当【桃】使用。",
	["@MARUT"] = "MARUT",
	["harute_transam"] = "TRANS-AM",
	[":harute_transam"] = "<img src=\"image/mark/@harute_transam.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以令你于此阶段：可以额外使用三张【杀】且无距离限制。若如此做，你跳过下一个摸牌阶段。",
	["@harute_transam"] = "TRANS-AM",
	["$feijian1"] = "GNシザービット展開!",
	["$feijian2"] = "断ち切れ!シザービット!",
	["$feijian3"] = "いけよシザービットォ!",
	["$feijian4"] = "GNシザービット展開!",
	["$feijian5"] = "GNシザービット!",
	["$liuyan1"] = "いいか?反射と思考の融合だ!わかってる!了解!いくぜぇえ!!",
	["$liuyan2"] = "これが!超兵の力だァー!!違う!未来を切り開く力だ!!",
	["$liuyan3"] = "もう遅え！それでも行くさ！",
	["$liuyan4"] = "理屈なんかどうでもいい!殺るだけだぁ!!",
	["$liuyan5"] = "てめぇの行為は偽善だ!それでも善だ!!僕はもう、命を見捨てたりしない!!",
	["$harute_transam1"] = "トランザム!",
	["$harute_transam2"] = "トランザム!",
	["$harute_transam3"] = "トランザム!!",
	
	["ELSQ"] = "ELS Q",
	["#ELSQ"] = "和平之桥",
	["~ELSQ"] = "",
	["designer:ELSQ"] = "wch5621628 & Sankies & NOS7IM",
	["cv:ELSQ"] = "刹那·F·塞尔",
	["illustrator:ELSQ"] = "Sankies",
	["ronghe"] = "融合",
	[":ronghe"] = "出牌阶段限一次，你可以指定一名体力比你多且有手牌的角色，其手牌对你可见，且你可以将其使用或打出，直到你的下回合开始前。",
	["&ronghe"] = "融合",
	["lijie"] = "理解",
	[":lijie"] = "当你受到其他角色造成的伤害后，你可以弃置其的一张手牌，若为<font color='red'>♥</font>，你与其各回复1点体力。",
	
	["SBS"] = "星创突击",
	["#SBS"] = "星之创战者",
	["~SBS"] = "",
	["designer:SBS"] = "wch5621628 & Sankies & NOS7IM",
	["cv:SBS"] = "伊织·诚 & 澪司",
	["illustrator:SBS"] = "wch5621628",
	["jieneng"] = "劫能",
	[":jieneng"] = "当你成为【杀】的目标后，你可以进行判定：若为<b><font color='red'>红色</font></b>，你将此【杀】置于武将牌上，称为<b>“能”</b>，且此【杀】对你无效。每有一张<b>“能”</b>，你的手牌上限-1。",
	["neng"] = "能",
	["shineng"] = "释能",
	[":shineng"] = "<img src=\"image/mark/@shineng.png\"><b><font color='red'>限定技</font></b>，出牌阶段，你可以将所有<b>“能”</b>（至少一张）置入手牌，若如此做，此阶段：你的攻击范围和【杀】的额外使用次数均+X。（X为<b>“能”</b>的数量）",
	["@shineng"] = "释能",
	["rg"] = "RG",
	[":rg"] = "<img src=\"image/mark/@rg.png\"><b><font color='red'>限定技</font></b>，准备阶段开始时，你可以失去技能<b>“劫能”</b>和<b>“释能”</b>，并获得技能<b>“铁拳”</b>（<b>锁定技</b>，你对其他角色造成的伤害+1；你的单数【闪】视为【杀】）。",
	["@rg"] = "RG",
	["tiequan"] = "铁拳",
	[":tiequan"] = "<b>锁定技</b>，你对其他角色造成的伤害+1；你的单数【闪】视为【杀】。",
}