function Auxiliary.NonTuner(f,a,b,c)
	return	function(target)
				return target:IsNotTuner() and (not f or f(target,a,b,c))
			end
end
--Synchro monster, m-n tuners + m-n monsters
function Auxiliary.AddSynchroProcedure(c,...)
	--parameters (f1,min1,max1,f2,min2,max2,sub1,sub2,req1,reqct1,req2,reqct2,reqm)
	if c.synchro_type==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.synchro_type=1
		mt.synchro_parameters={...}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(Auxiliary.SynCondition(...))
	e1:SetTarget(Auxiliary.SynTarget(...))
	e1:SetOperation(Auxiliary.SynOperation)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
end
function Auxiliary.SynchroCheckFilterChk(c,f1,f2,sub1,sub2)
	local te=c:GetCardEffect(EFFECT_SYNCHRO_CHECK)
	if not te then return false end
	local f=te:GetValue()
	local reset=false
	if f(te,c) then
		reset=true
	end
	local res=(c:IsSynchroType(TYPE_TUNER) and (not f1 or f1(c))) or not f2 or f2(c) or (sub1 and sub1(c)) or (sub2 and sub2(c))
	if reset then
		Duel.AssumeReset()
	end
	return res
end
function Auxiliary.TunerFilter(c,f1,sub1)
	return (c:IsSynchroType(TYPE_TUNER) and (not f1 or f1(c))) or (sub1 and sub1(c))
end
function Auxiliary.NonTunerFilter(c,f2,sub2)
	return not f2 or f2(c) or (sub2 and sub2(c))
end
function Auxiliary.SynCondition(f1,min1,max1,f2,min2,max2,sub1,sub2,req1,reqct1,req2,reqct2,reqm)
	return	function(e,c,smat,mg)
				if c==nil then return true end
				if c:IsType(TYPE_PENDULUM) and c:IsFaceup() then return false end
				local tp=c:GetControler()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				local lv=c:GetLevel()
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local g
				local mgchk
				if mg then
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
					mgchk=true
				else
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
					mgchk=false
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				if g:IsExists(Auxiliary.SynchroCheckFilterChk,1,nil,f1,f2,sub1,sub2) then
					--if there is a monster with EFFECT_SYNCHRO_CHECK (Genomix Fighter/Mono Synchron)
					local g2=g:Clone()
					if not mgchk then
						local thg=g2:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
						local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
						for thc in aux.Next(thg) do
							local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
							local val=te:GetValue()
							local ag=hg:Filter(function(mc) return val(te,mc,c) end,nil) --tuner
							g2:Merge(ag)
						end
					end
					local res=(not smat or g2:IsContains(smat)) 
						and g2:IsExists(Auxiliary.SynchroCheckP31,1,nil,g2,Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup(),f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
					local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
					aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
					Duel.AssumeReset()
					return res
				else
					--no race change
					local tg
					local ntg
					if mgchk then
						tg=g:Filter(Auxiliary.TunerFilter,nil,f1,sub1)
						ntg=g:Filter(Auxiliary.NonTunerFilter,nil,f2,sub2)
					else
						tg=g:Filter(Auxiliary.TunerFilter,nil,f1,sub1)
						ntg=g:Filter(Auxiliary.NonTunerFilter,nil,f2,sub2)
						local thg=tg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
						thg:Merge(ntg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO))
						local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
						for thc in aux.Next(thg) do
							local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
							local val=te:GetValue()
							local thag=hg:Filter(function(mc) return Auxiliary.TunerFilter(mc,f1,sub1) and val(te,mc,c) end,nil) --tuner
							local nthag=hg:Filter(function(mc) return Auxiliary.NonTunerFilter(mc,f2,sub2) and val(te,mc,c) end,nil) --non-tuner
							tg:Merge(thag)
							ntg:Merge(nthag)
						end
					end
					local lv=c:GetLevel()
					local res=(not smat or tg:IsContains(smat) or ntg:IsContains(smat)) 
						and tg:IsExists(Auxiliary.SynchroCheckP41,1,nil,tg,ntg,Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup(),min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
					local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
					aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
					return res
				end
				return false
			end
end
function Auxiliary.SynchroCheckP31(c,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	local res
	local rg=Group.CreateGroup()
	if c:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
		for i=1,#teg do
			local te=teg[i]
			local val=te:GetValue()
			local tg=g:Filter(function(mc) return val(te,mc) end,nil)
			rg=tg:Filter(function(mc) return not Auxiliary.TunerFilter(mc,f1,sub1) and not Auxiliary.NonTunerFilter(mc,f2,sub2) end,nil)
		end
	end
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg1=g:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			rg:Merge(sg1)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if not mgchk then
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for i=1,#teg do
				local te=teg[i]
				local tgchk=te:GetTarget()
				local res,trg,ntrg2=tgchk(te,c,sg,g,g,tsg,ntsg)
				--if not res then return false end
				if res then
					rg:Merge(trg)
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
		g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
		for tc in aux.Next(g2) do
			local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(eff) do
				if te:GetTarget()(te,nil,sg,g,g,tsg,ntsg) then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
	end
	g:Sub(rg)
	tsg:AddCard(c)
	sg:AddCard(c)
	if tsg:GetCount()<min1 then
		res=g:IsExists(Auxiliary.SynchroCheckP31,1,sg,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	elseif tsg:GetCount()<max1 then
		res=g:IsExists(Auxiliary.SynchroCheckP31,1,sg,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk) 
			or (tsg:IsExists(Auxiliary.TunerFilter,tsg:GetCount(),nil,f1,sub1) and (not req1 or tsg:IsExists(req1,reqct1,nil,tp)) 
				and g:IsExists(Auxiliary.SynchroCheckP32,1,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk))
	else
		res=tsg:IsExists(Auxiliary.TunerFilter,tsg:GetCount(),nil,f1,sub1) and (not req1 or tsg:IsExists(req1,reqct1,nil,tp)) 
			and g:IsExists(Auxiliary.SynchroCheckP32,1,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	end
	g:Merge(rg)
	tsg:RemoveCard(c)
	sg:RemoveCard(c)
	if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
		Duel.AssumeReset()
	end
	return res
end
function Auxiliary.SynchroCheckP32(c,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	local res
	local rg=Group.CreateGroup()
	if c:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
		for i=1,#teg do
			local te=teg[i]
			local val=te:GetValue()
			local tg=g:Filter(function(mc) return val(te,mc) end,nil)
			rg=tg:Filter(function(mc) return not Auxiliary.NonTunerFilter(mc,f2,sub2) end,nil)
		end
	end
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg2=g:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			rg:Merge(sg2)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if not mgchk then
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for i=1,#teg do
				local te=teg[i]
				local tgchk=te:GetTarget()
				local res,trg2,ntrg2=tgchk(te,c,sg,Group.CreateGroup(),g,tsg,ntsg)
				--if not res then return false end
				if res then
					rg:Merge(ntrg2)
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
		g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
		for tc in aux.Next(g2) do
			local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(eff) do
				if te:GetTarget()(te,nil,sg,Group.CreateGroup(),g,tsg,ntsg) then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
	end
	g:Sub(rg)
	ntsg:AddCard(c)
	sg:AddCard(c)
	if ntsg:GetCount()<min2 then
		res=g:IsExists(Auxiliary.SynchroCheckP32,1,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	elseif ntsg:GetCount()<max2 then
		res=g:IsExists(Auxiliary.SynchroCheckP32,1,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk) 
			or ((not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
				and ntsg:IsExists(Auxiliary.NonTunerFilter,ntsg:GetCount(),nil,f2,sub2) and (not smat or sg:IsContains(smat)) 
				and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil)) 
				and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,sc,tp))
	else
		res=(not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
			and ntsg:IsExists(Auxiliary.NonTunerFilter,ntsg:GetCount(),nil,f2,sub2)
			and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
			and (not smat or sg:IsContains(smat))  and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,sc,tp)
	end
	g:Merge(rg)
	ntsg:RemoveCard(c)
	sg:RemoveCard(c)
	if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
		Duel.AssumeReset()
	end
	return res
end
function Auxiliary.SynchroCheckP41(c,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	local res
	local trg=Group.CreateGroup()
	local ntrg=Group.CreateGroup()
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg1=tg:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			local sg2=ntg:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			trg:Merge(sg1)
			ntrg:Merge(sg2)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if not mgchk then
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(teg) do
				local tgchk=te:GetTarget()
				local res,trg2,ntrg2=tgchk(te,c,sg,tg,ntg,tsg,ntsg)
				--if not res then return false end
				if res then
					trg:Merge(trg2)
					ntrg:Merge(ntrg2)
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
		g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
		for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(eff) do
				if te:GetTarget()(te,nil,sg,tg,ntg,tsg,ntsg) then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
	end
	tg:Sub(trg)
	ntg:Sub(ntrg)
	tsg:AddCard(c)
	sg:AddCard(c)
	if tsg:GetCount()<min1 then
		res=tg:IsExists(Auxiliary.SynchroCheckP41,1,sg,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	elseif tsg:GetCount()<max1 then
		res=tg:IsExists(Auxiliary.SynchroCheckP41,1,sg,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk) 
			or ((not req1 or tsg:IsExists(req1,reqct1,nil,tp)) and ntg:IsExists(Auxiliary.SynchroCheckP42,1,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk))
	else
		res=(not req1 or tsg:IsExists(req1,reqct1,nil,tp)) 
			and ntg:IsExists(Auxiliary.SynchroCheckP42,1,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	end
	tg:Merge(trg)
	ntg:Merge(ntrg)
	tsg:RemoveCard(c)
	sg:RemoveCard(c)
	return res
end
function Auxiliary.SynchroCheckP42(c,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	local res
	local ntrg=Group.CreateGroup()
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg2=ntg:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			ntrg:Merge(sg2)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if not mgchk then
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for i=1,#teg do
				local te=teg[i]
				local tgchk=te:GetTarget()
				local res,trg2,ntrg2=tgchk(te,c,sg,Group.CreateGroup(),ntg,tsg,ntsg)
				--if not res then return false end
				if res then
					ntrg:Merge(ntrg2)
					hanchk=true
					break
				end
				if not hanchk then return false end
			end
		end
		g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
		for tc in aux.Next(g2) do
			local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(eff) do
				if te:GetTarget()(te,nil,sg,Group.CreateGroup(),ntg,tsg,ntsg) then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
	end
	ntg:Sub(ntrg)
	ntsg:AddCard(c)
	sg:AddCard(c)
	if ntsg:GetCount()<min2 then
		res=ntg:IsExists(Auxiliary.SynchroCheckP42,1,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk)
	elseif ntsg:GetCount()<max2 then
		res=ntg:IsExists(Auxiliary.SynchroCheckP42,1,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,sc,tp,smat,pg,mgchk) 
			or ((not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
				and (not smat or sg:IsContains(smat)) and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil)) 
				and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,sc,tp))
	else
		res=(not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
			and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
			and (not smat or sg:IsContains(smat))  and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,sc,tp)
	end
	ntg:Merge(ntrg)
	ntsg:RemoveCard(c)
	sg:RemoveCard(c)
	return res
end
function Auxiliary.SynchroCheckLabel(c,label)
	return c:IsHasEffect(EFFECT_HAND_SYNCHRO) and c:GetCardEffect(EFFECT_HAND_SYNCHRO):GetLabel()==label
end
function Auxiliary.SynchroCheckHand(c,sg)
	if not c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then return false end
	local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
	for _,te in ipairs(teg) do
		if sg:IsExists(Auxiliary.SynchroCheckLabel,1,c,te:GetLabel()) then return false end
	end
	return true
end
function Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,sc,tp)
	if sg:IsExists(Auxiliary.SynchroCheckHand,1,nil,sg) then return false end
	--[[for c in aux.Next(sg) do
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for _,te in ipairs(teg) do
				if te:GetTarget()(te,c,sg,Group.CreateGroup(),Group.CreateGroup(),tsg,ntsg) then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
	end]]
	local lvchk=false
	if sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM) then
		local g=sg:Filter(Card.IsHasEffect,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM)
		for tc in aux.Next(g) do
			local teg={tc:GetCardEffect(EFFECT_SYNCHRO_MATERIAL_CUSTOM)}
			for _,te in ipairs(teg) do
				local op=te:GetOperation()
				local ok,tlvchk=op(te,tg,ntg,sg,lv,sc,tp)
				if not ok then return false end
				lvchk=lvchk or tlvchk
			end
		end
	end
	return (lvchk or sg:CheckWithSumEqual(Card.GetSynchroLevel,lv,sg:GetCount(),sg:GetCount(),sc))
	and ((sc:IsLocation(LOCATION_EXTRA) and Duel.GetLocationCountFromEx(tp,tp,sg,sc)>0)
		or (not sc:IsLocation(LOCATION_EXTRA) and (Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or sg:IsExists(Auxiliary.FConditionCheckF,nil,tp))))
end
function Auxiliary.SynTarget(f1,min1,max1,f2,min2,max2,sub1,sub2,req1,reqct1,req2,reqct2,reqm)
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
				local sg=Group.CreateGroup()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				local lv=c:GetLevel()
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local mgchk
				local g
				if mg then
					mgchk=true
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
				else
					mgchk=false
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				local tg
				local ntg
				if mgchk then
					tg=g:Filter(Auxiliary.TunerFilter,nil,f1,sub1)
					ntg=g:Filter(Auxiliary.NonTunerFilter,nil,f2,sub2)
				else
					tg=g:Filter(Auxiliary.TunerFilter,nil,f1,sub1)
					ntg=g:Filter(Auxiliary.NonTunerFilter,nil,f2,sub2)
					local thg=tg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
					thg:Merge(ntg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO))
					local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
					for thc in aux.Next(thg) do
						local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
						local val=te:GetValue()
						local thag=hg:Filter(function(mc) return Auxiliary.TunerFilter(mc,f1,sub1) and val(te,mc,c) end,nil) --tuner
						local nthag=hg:Filter(function(mc) return Auxiliary.NonTunerFilter(mc,f2,sub2) and val(te,mc,c) end,nil) --non-tuner
						tg:Merge(thag)
						ntg:Merge(nthag)
					end
				end
				local lv=c:GetLevel()
				if g:IsExists(Auxiliary.SynchroCheckFilterChk,1,nil,f1,f2,sub1,sub2) then
					local tsg=Group.CreateGroup()
					local ntsg=Group.CreateGroup()
					local tune=true
					local g2=Group.CreateGroup()
					while ntsg:GetCount()<max2 do
						local cancel=false
						if tune then
							cancel=not mgchk and Duel.GetCurrentChain()<=0 and tsg:GetCount()==0
							local g3=ntg:Filter(Auxiliary.SynchroCheckP32,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							g2=g:Filter(Auxiliary.SynchroCheckP31,sg,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g3:GetCount()>0 and tsg:GetCount()>=min1 and tsg:IsExists(Auxiliary.TunerFilter,tsg:GetCount(),nil,f1,sub1) and (not req1 or tsg:IsExists(req1,reqct1,nil,tp)) then
								g2:Merge(g3)
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
							local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
							if not tc then
								if tsg:GetCount()>=min1 and tsg:IsExists(Auxiliary.TunerFilter,tsg:GetCount(),nil,f1,sub1) and (not req1 or tsg:IsExists(req1,reqct1,nil,tp))
									and ntg:Filter(Auxiliary.SynchroCheckP32,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk):GetCount()>0 then tune=false
								else
									return false
								end
							end
							if not sg:IsContains(tc) then
								if g3:IsContains(tc) then
									ntsg:AddCard(tc)
									tune = false
								else
									tsg:AddCard(tc)
								end
								sg:AddCard(tc)
								if tc:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
									local teg={tc:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
									for i=1,#teg do
										local te=teg[i]
										local tg=g:Filter(function(mc) return te:GetValue()(te,mc) end,nil)
									end
								end
							else
								tsg:RemoveCard(tc)
								sg:RemoveCard(tc)
								if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
									Duel.AssumeReset()
								end
							end
							if g:FilterCount(Auxiliary.SynchroCheckP31,sg,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)==0 or tsg:GetCount()>=max2 then
								tune=false
							end
						else
							if (ntsg:GetCount()>=min2 and (not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
								and ntsg:IsExists(Auxiliary.NonTunerFilter,ntsg:GetCount(),nil,f2,sub2)
								and (not smat or sg:IsContains(smat)) and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil)) 
								and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,c,tp)) or (not mgchk and Duel.GetCurrentChain()<=0) then
									cancel=true
							end
							g2=g:Filter(Auxiliary.SynchroCheckP32,sg,g,tsg,ntsg,sg,f2,sub2,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g2:GetCount()==0 then break end
							local g3=g:Filter(Auxiliary.SynchroCheckP31,sg,g,tsg,ntsg,sg,f1,sub1,f2,sub2,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g3:GetCount()>0 and ntsg:GetCount()==0 and tsg:GetCount()<max1 then
								g2:Merge(g3)
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
							local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
							if not tc then
								if ntsg:GetCount()>=min2 and (not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp)) 
									and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
									and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,c,tp) then break end
								return false
							end
							if not tsg:IsContains(tc) then
								if not sg:IsContains(tc) then
									ntsg:AddCard(tc)
									sg:AddCard(tc)
									if tc:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
										local teg={tc:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
										for i=1,#teg do
											local te=teg[i]
											local tg=g:Filter(function(mc) return te:GetValue()(te,mc) end,nil)
										end
									end
								else
									ntsg:RemoveCard(tc)
									sg:RemoveCard(tc)
									if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
										Duel.AssumeReset()
									end
								end
							elseif ntsg:GetCount()==0 then
								tune=true
								tsg:RemoveCard(tc)
								sg:RemoveCard(tc)
							end
						end
					end
					Duel.AssumeReset()
				else
					local tsg=Group.CreateGroup()
					local ntsg=Group.CreateGroup()
					local tune=true
					local g2=Group.CreateGroup()
					while ntsg:GetCount()<max2 do
						cancel=false
						if tune then
							cancel=not mgchk and Duel.GetCurrentChain()<=0 and tsg:GetCount()==0
							local g3=ntg:Filter(Auxiliary.SynchroCheckP42,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							g2=tg:Filter(Auxiliary.SynchroCheckP41,sg,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g3:GetCount()>0 and tsg:GetCount()>=min1 and (not req1 or tsg:IsExists(req1,reqct1,nil,tp)) then
								g2:Merge(g3)
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
							local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
							if not tc then
								if tsg:GetCount()>=min1 and (not req1 or tsg:IsExists(req1,reqct1,nil,tp))
									and ntg:Filter(Auxiliary.SynchroCheckP42,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk):GetCount()>0 then tune=false
								else
									return false
								end
							else
								if not sg:IsContains(tc) then
									if g3:IsContains(tc) then
										ntsg:AddCard(tc)
										tune = false
									else
										tsg:AddCard(tc)
									end
									sg:AddCard(tc)
								else
									tsg:RemoveCard(tc)
									sg:RemoveCard(tc)
								end
							end
							if tg:FilterCount(Auxiliary.SynchroCheckP41,sg,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)==0 or tsg:GetCount()>=max1 then
								tune=false
							end
						else
							if ntsg:GetCount()>=min2 and (not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp))
								and (not smat or sg:IsContains(smat)) and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
								and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,c,tp) then cancel=true
							end
							g2=ntg:Filter(Auxiliary.SynchroCheckP42,sg,ntg,tsg,ntsg,sg,min2,max2,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g2:GetCount()==0 then break end
							local g3=tg:Filter(Auxiliary.SynchroCheckP41,sg,tg,ntg,tsg,ntsg,sg,min1,max1,min2,max2,req1,reqct1,req2,reqct2,reqm,lv,c,tp,smat,pg,mgchk)
							if g3:GetCount()>0 and ntsg:GetCount()==0 and tsg:GetCount()<max1 then
								g2:Merge(g3)
							end
							Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
							local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
							if not tc then
								if ntsg:GetCount()>=min2 and (not req2 or ntsg:IsExists(req2,reqct2,nil,tp)) and (not reqm or sg:IsExists(reqm,1,nil,tp))
									and (pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
									and Auxiliary.SynchroCheckP43(tsg,ntsg,sg,lv,c,tp) then break end
								return false
							end
							if not tsg:IsContains(tc) then
								if not sg:IsContains(tc) then
									ntsg:AddCard(tc)
									sg:AddCard(tc)
								else
									ntsg:RemoveCard(tc)
									sg:RemoveCard(tc)
								end
							elseif ntsg:GetCount()==0 then
								tune=true
								tsg:RemoveCard(tc)
								sg:RemoveCard(tc)
							end
						end
					end
				end
				local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				if sg then
					sg:KeepAlive()
					e:SetLabelObject(sg)
					return true
				else return false end
			end
end
Auxiliary.SynchroSend=0
function Auxiliary.SynOperation(e,tp,eg,ep,ev,re,r,rp,c,smat,mg)
	local g=e:GetLabelObject()
	c:SetMaterial(g)
	if Auxiliary.SynchroSend==1 then
		Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO+REASON_RETURN)
	elseif Auxiliary.SynchroSend==2 then
		Duel.Remove(g,POS_FACEUP,REASON_MATERIAL+REASON_SYNCHRO)
	elseif Auxiliary.SynchroSend==3 then
		Duel.Remove(g,POS_FACEDOWN,REASON_MATERIAL+REASON_SYNCHRO)
	elseif Auxiliary.SynchroSend==4 then
		Duel.SendtoHand(g,nil,REASON_MATERIAL+REASON_SYNCHRO)
	elseif Auxiliary.SynchroSend==5 then
		Duel.SendtoDeck(g,nil,2,REASON_MATERIAL+REASON_SYNCHRO)
	elseif Auxiliary.SynchroSend==6 then
		Duel.Destroy(g,REASON_MATERIAL+REASON_SYNCHRO)
	else
		Duel.SendtoGrave(g,REASON_MATERIAL+REASON_SYNCHRO)
	end
	g:DeleteGroup()
end

--Synchro monster, Majestic
function Auxiliary.AddMajesticSynchroProcedure(c,f1,cbt1,f2,cbt2,f3,cbt3,...)
	--parameters: function, can be tuner, required materials (by 2s, functions + number)
	if c.synchro_type==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.synchro_type=2
		mt.synchro_parameters={f1,cbt1,f2,cbt2,f3,cbt3,...}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(Auxiliary.MajesticSynCondition(f1,cbt1,f2,cbt2,f3,cbt3,...))
	e1:SetTarget(Auxiliary.MajesticSynTarget(f1,cbt1,f2,cbt2,f3,cbt3,...))
	e1:SetOperation(Auxiliary.SynOperation)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
end
function Auxiliary.MajesticSynchroCheck1(c,g,sg,card1,card2,card3,lv,sc,tp,smat,pg,f1,cbt1,f2,cbt2,f3,cbt3,...)
	local res
	local rg=Group.CreateGroup()
	if c:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
		for i=1,#teg do
			local te=teg[i]
			local val=te:GetValue()
			local tg=g:Filter(function(mc) return val(te,mc) end,nil)
		end
	end
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg1=g:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			rg:Merge(sg1)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
		local hanchk=false
		for i=1,#teg do
			local te=teg[i]
			local tgchk=te:GetTarget()
			local res,trg,ntrg2=tgchk(te,c,sg,g,g,sg,sg)
			--if not res then return false end
			if res then
				rg:Merge(trg)
				hanchk=true
				break
			end
		end
		if not hanchk then return false end
	end
	g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
		local hanchk=false
		for _,te in ipairs(eff) do
			if te:GetTarget()(te,nil,sg,g,g,sg,sg) then
				hanchk=true
				break
			end
		end
		if not hanchk then return false end
	end
	g:Sub(rg)
	sg:AddCard(c)
	if not card1 then
		card1=c
	elseif not card2 then
		card2=c
	else
		card3=c
	end
	if sg:GetCount()<3 then
		res=g:IsExists(Auxiliary.MajesticSynchroCheck1,1,sg,g,sg,card1,card2,card3,lv,sc,tp,smat,pg,f1,cbt1,f2,cbt2,f3,cbt3,...)
	else
		res=(pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
			and (not smat or sg:IsContains(smat)) and Auxiliary.MajesticSynchroCheck2(sg,card1,card2,card3,lv,sc,tp,f1,cbt1,f2,cbt2,f3,cbt3,...)
	end
	g:Merge(rg)
	sg:RemoveCard(c)
	if card3 then
		card3=nil
	elseif card2 then
		card2=nil
	else
		card1=nil
	end
	if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
		Duel.AssumeReset()
	end
	return res
end
function Auxiliary.MajesticSynchroCheck2(sg,card1,card2,card3,lv,sc,tp,f1,cbt1,f2,cbt2,f3,cbt3,...)
	if sg:IsExists(Auxiliary.SynchroCheckHand,1,nil,sg) then return false end
	--[[local c=sg:GetFirst()
	while c do
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for i=1,#teg do
				local te=teg[i]
				local tgchk=te:GetTarget()
				local res=tgchk(te,c,sg,Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup())
				--if not res then return false end
				if res then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
		c=sg:GetNext()
	end]]
	local t={...}
	local funs={}
	funs[0]={} --number of those
	funs[1]={} --required functions
	for i,v in ipairs(t) do
		table.insert(funs[i%2],v)
	end
	local tunechk=false
	if not f1(card1) or not f2(card2) or not f3(card3) then return false end
	if cbt1 and card1:IsSynchroType(TYPE_TUNER) then tunechk=true end
	if cbt2 and card2:IsSynchroType(TYPE_TUNER) then tunechk=true end
	if cbt3 and card3:IsSynchroType(TYPE_TUNER) then tunechk=true end
	if not tunechk then return false end
	local lvchk=false
	if #funs[0]>0 then
		for i=1,#funs[0] do
			if not sg:IsExists(funs[1][i],funs[0][i],nil) then return false end
		end
	end
	if sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM) then
		local g=sg:Filter(Card.IsHasEffect,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM)
		for tc in aux.Next(g) do
			local teg={tc:GetCardEffect(EFFECT_SYNCHRO_MATERIAL_CUSTOM)}
			for _,te in ipairs(teg) do
				local op=te:GetOperation()
				local ok,tlvchk=op(te,Group.CreateGroup(),Group.CreateGroup(),sg,lv,sc,tp)
				if not ok then return false end
				lvchk=lvchk or tlvchk
			end
		end
	end
	if not lvchk and not sg:CheckWithSumEqual(Card.GetSynchroLevel,lv,sg:GetCount(),sg:GetCount(),sc) then return false end
	if sc:IsLocation(LOCATION_EXTRA) then
		return Duel.GetLocationCountFromEx(tp,tp,sg,sc)>0
	else
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 or sg:IsExists(Auxiliary.FConditionCheckF,nil,tp)
	end
end
function Auxiliary.MajesticSynCondition(f1,cbt1,f2,cbt2,f3,cbt3,...)
	local t={...}
	return	function(e,c,smat,mg)
				if c==nil then return true end
				local tp=c:GetControler()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				local lv=c:GetLevel()
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local g
				local mgchk
				if mg then
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
					mgchk=true
				else
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
					mgchk=false
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				if not mgchk then
					local thg=g:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
					local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
					for thc in aux.Next(thg) do
						local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
						local val=te:GetValue()
						local ag=hg:Filter(function(mc) return val(te,mc,c) end,nil) --tuner
						g:Merge(ag)
					end
				end
				local res=(not smat or g:IsContains(smat)) 
					and g:IsExists(Auxiliary.MajesticSynchroCheck1,1,nil,g,Group.CreateGroup(),card1,card2,card3,lv,c,tp,smat,pg,f1,cbt1,f2,cbt2,f3,cbt3,table.unpack(t))
				local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				Duel.AssumeReset()
				return res
			end
end
function Auxiliary.MajesticSynTarget(f1,cbt1,f2,cbt2,f3,cbt3,...)
	local t={...}
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
				local sg=Group.CreateGroup()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				local lv=c:GetLevel()
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local mgchk
				local g
				if mg then
					mgchk=true
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
				else
					mgchk=false
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				if not mgchk then
					local thg=g:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
					local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
					for thc in aux.Next(thg) do
						local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
						local val=te:GetValue()
						local ag=hg:Filter(function(mc) return val(te,mc,c) end,nil)
						g:Merge(ag)
					end
				end
				local lv=c:GetLevel()
				local card1=nil
				local card2=nil
				local card3=nil
				local cancel=not mgchk and Duel.GetCurrentChain()<=0
				while sg:GetCount()<3 do
					local g2=g:Filter(Auxiliary.MajesticSynchroCheck1,sg,g,sg,card1,card2,card3,lv,c,tp,smat,pg,f1,cbt1,f2,cbt2,f3,cbt3,table.unpack(t))
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
					local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
					if not tc then return false end
					if not sg:IsContains(tc) then
						sg:AddCard(tc)
						if tc:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
							local teg={tc:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
							for i=1,#teg do
								local te=teg[i]
								local tg=g:Filter(function(mc) return te:GetValue()(te,mc) end,nil)
							end
						end
						if not card1 then
							card1=tc
						elseif not card2 then
							card2=tc
						else
							card3=tc
						end
					else
						local rem=false
						if card3 and tc==card3 then
							card3=nil
							rem=true
						elseif not card3 and card2 and tc==card2 then
							card2=nil
							rem=true
						elseif not card3 and not card2 and card1 and tc==card1 then
							card1=nil
							rem=true
						end
						if rem then
							sg:RemoveCard(tc)
							if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
								Duel.AssumeReset()
							end
						end
					end
				end
				Duel.AssumeReset()
				local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				if sg then
					sg:KeepAlive()
					e:SetLabelObject(sg)
					return true
				else return false end
			end
end

--Dark Synchro monster
function Auxiliary.AddDarkSynchroProcedure(c,f1,f2,plv,nlv,...)
	--functions, default/dark wave level, reqm
	if c.synchro_type==nil then
		local code=c:GetOriginalCode()
		local mt=_G["c" .. code]
		mt.synchro_type=3
		mt.synchro_parameters={f1,f2,plv,nlv,...}
	end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE+EFFECT_FLAG_IGNORE_IMMUNE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(Auxiliary.DarkSynCondition(f1,f2,plv,nlv,...))
	e1:SetTarget(Auxiliary.DarkSynTarget(f1,f2,plv,nlv,...))
	e1:SetOperation(Auxiliary.SynOperation)
	e1:SetValue(SUMMON_TYPE_SYNCHRO)
	c:RegisterEffect(e1)
end
function Auxiliary.DarkSynchroCheck1(c,g,sg,card1,card2,plv,nlv,sc,tp,smat,pg,f1,f2,...)
	local res
	local rg=Group.CreateGroup()
	if c:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
		for i=1,#teg do
			local te=teg[i]
			local val=te:GetValue()
			local tg=g:Filter(function(mc) return val(te,mc) end,nil)
		end
	end
	--c has the synchro limit
	if c:IsHasEffect(73941492+TYPE_SYNCHRO) then
		local eff={c:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if sg:IsExists(Auxiliary.TuneMagFilter,1,c,f,f:GetValue()) then return false end
			local sg1=g:Filter(function(c) return not Auxiliary.TuneMagFilterFus(c,f,f:GetValue()) end,nil)
			rg:Merge(sg1)
		end
	end
	--A card in the selected group has the synchro lmit
	local g2=sg:Filter(Card.IsHasEffect,nil,73941492+TYPE_SYNCHRO)
	for tc in aux.Next(g2) do
		local eff={tc:GetCardEffect(73941492+TYPE_SYNCHRO)}
		for _,f in ipairs(eff) do
			if Auxiliary.TuneMagFilter(c,f,f:GetValue()) then return false end
		end
	end
	if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
		local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
		local hanchk=false
		for i=1,#teg do
			local te=teg[i]
			local tgchk=te:GetTarget()
			local res,trg,ntrg2=tgchk(te,c,sg,g,g,sg,sg)
			--if not res then return false end
			if res then
				rg:Merge(trg)
				hanchk=true
				break
			end
		end
		if not hanchk then return false end
	end
	g2=sg:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
	for tc in aux.Next(g) do
		local eff={tc:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
		local hanchk=false
		for _,te in ipairs(eff) do
			if te:GetTarget()(te,nil,sg,g,g,sg,sg) then
				hanchk=true
				break
			end
		end
		if not hanchk then return false end
	end
	g:Sub(rg)
	sg:AddCard(c)
	if not card1 then
		card1=c
	else
		card2=c
	end
	if sg:GetCount()<2 then
		res=g:IsExists(Auxiliary.DarkSynchroCheck1,1,sg,g,sg,card1,card2,plv,nlv,sc,tp,smat,pg,f1,f2,...)
	else
		res=(pg:GetCount()<=0 or pg:IsExists(function(mc) return sg:IsContains(mc) end,pg:GetCount(),nil))
			and (not smat or sg:IsContains(smat)) and Auxiliary.DarkSynchroCheck2(sg,card1,card2,plv,nlv,sc,tp,f1,f2,...)
	end
	g:Merge(rg)
	sg:RemoveCard(c)
	if card2 then
		card2=nil
	else
		card1=nil
	end
	if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
		Duel.AssumeReset()
	end
	return res
end
function Auxiliary.DarkSynchroCheck2(sg,card1,card2,plv,nlv,sc,tp,f1,f2,...)
	if sg:IsExists(Auxiliary.SynchroCheckHand,1,nil,sg) then return false end
	--[[local c=sg:GetFirst()
	while c do
		if c:IsHasEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK) then
			local teg={c:GetCardEffect(EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)}
			local hanchk=false
			for i=1,#teg do
				local te=teg[i]
				local tgchk=te:GetTarget()
				local res=tgchk(te,c,sg,Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup(),Group.CreateGroup())
				--if not res then return false end
				if res then
					hanchk=true
					break
				end
			end
			if not hanchk then return false end
		end
		c=sg:GetNext()
	end]]
	local reqm={...}
	if (f1 and not f1(card1)) or (f2 and not f2(card2)) or not card2:IsSynchroType(TYPE_TUNER) or not card2:IsSetCard(0x600) then return false end
	local lvchk=false
	if #reqm>0 then
		for i=1,#reqm do
			if not sg:IsExists(reqm[i],1,nil) then return false end
		end
	end
	if sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM) then
		local g=sg:Filter(Card.IsHasEffect,nil,EFFECT_SYNCHRO_MATERIAL_CUSTOM)
		for tc in aux.Next(g) do
			local teg={tc:GetCardEffect(EFFECT_SYNCHRO_MATERIAL_CUSTOM)}
			for _,te in ipairs(teg) do
				local op=te:GetOperation()
				local ok,tlvchk=op(te,Group.CreateGroup(),Group.CreateGroup(),sg,plv,sc,tp,nlv,card1,card2)
				if not ok then return false end
				lvchk=lvchk or tlvchk
			end
		end
	end
	if sc:IsLocation(LOCATION_EXTRA) then
		if Duel.GetLocationCountFromEx(tp,tp,sg,sc)<=0 then return false end
	else
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 and not sg:IsExists(Auxiliary.FConditionCheckF,nil,tp) then return false end
	end
	if lvchk then return true end
	local ntlv=card1:GetSynchroLevel(sc)
	local ntlv1=bit.band(ntlv,0xffff)
	local ntlv2=bit.rshift(ntlv,16)
	local tlv=card2:GetSynchroLevel(sc)
	local tlv1=bit.band(tlv,0xffff)
	local tlv2=bit.rshift(tlv,16)
	if card1:GetFlagEffect(100000147)>0 then
		return tlv1==nlv-lv1 or tlv2==nlv-ntlv1 or tlv1==nlv-ntlv2 or tlv2==nlv-ntlv2
	else
		return tlv1==plv+ntlv1 or tlv2==plv+ntlv1 or tlv1==plv+ntlv2 or tlv2==plv+ntlv2
	end
end
function Auxiliary.DarkSynCondition(f1,f2,plv,nlv,...)
	local t={...}
	return	function(e,c,smat,mg)
				if c==nil then return true end
				local plv=plv
				local nlv=nlv
				if plv==nil then
					plv=c:GetLevel()
				end
				if nlv==nil then
					nlv=plv
				end
				local tp=c:GetControler()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local g
				local mgchk
				if mg then
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
					mgchk=true
				else
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
					mgchk=false
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				if not mgchk then
					local thg=g:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
					local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
					for thc in aux.Next(thg) do
						local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
						local val=te:GetValue()
						local ag=hg:Filter(function(mc) return val(te,mc,c) end,nil) --tuner
						g:Merge(ag)
					end
				end
				local res=(not smat or g:IsContains(smat)) 
					and g:IsExists(Auxiliary.DarkSynchroCheck1,1,nil,g,Group.CreateGroup(),card1,card2,plv,nlv,c,tp,smat,pg,f1,f2,table.unpack(t))
				local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				Duel.AssumeReset()
				return res
			end
end
function Auxiliary.DarkSynTarget(f1,f2,plv,nlv,...)
	local t={...}
	return	function(e,tp,eg,ep,ev,re,r,rp,chk,c,smat,mg)
				local sg=Group.CreateGroup()
				local pe={Duel.GetPlayerEffect(tp,EFFECT_MUST_BE_SMATERIAL)}
				local pg=Group.CreateGroup()
				local plv=plv
				local nlv=nlv
				if plv==nil then
					plv=c:GetLevel()
				end
				if nlv==nil then
					nlv=plv
				end
				if pe[1] then
					for _,eff in ipairs(pe) do
						pg:AddCard(eff:GetOwner())
					end
				end
				local mgchk
				local g
				if mg then
					mgchk=true
					g=mg:Filter(Card.IsCanBeSynchroMaterial,c,c)
				else
					mgchk=false
					g=Duel.GetMatchingGroup(function(mc) return mc:IsFaceup() and mc:IsCanBeSynchroMaterial(c) end,tp,LOCATION_MZONE,LOCATION_MZONE,c)
				end
				if smat and smat:IsCanBeSynchroMaterial(c) then
					g:AddCard(smat)
				end
				if not mgchk then
					local thg=g:Filter(Card.IsHasEffect,nil,EFFECT_HAND_SYNCHRO)
					local hg=Duel.GetMatchingGroup(Card.IsCanBeSynchroMaterial,tp,LOCATION_HAND+LOCATION_GRAVE,0,c,c)
					for thc in aux.Next(thg) do
						local te=thc:GetCardEffect(EFFECT_HAND_SYNCHRO)
						local val=te:GetValue()
						local ag=hg:Filter(function(mc) return val(te,mc,c) end,nil)
						g:Merge(ag)
					end
				end
				local lv=c:GetLevel()
				local card1=nil
				local card2=nil
				local cancel=not mgchk and Duel.GetCurrentChain()<=0
				while sg:GetCount()<2 do
					local g2=g:Filter(Auxiliary.DarkSynchroCheck1,sg,g,sg,card1,card2,plv,nlv,c,tp,smat,pg,f1,f2,table.unpack(t))
					Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SMATERIAL)
					local tc=Group.SelectUnselect(g2,sg,tp,cancel,cancel)
					if not tc then return false end
					if not sg:IsContains(tc) then
						sg:AddCard(tc)
						if tc:IsHasEffect(EFFECT_SYNCHRO_CHECK) then
							local teg={tc:GetCardEffect(EFFECT_SYNCHRO_CHECK)}
							for i=1,#teg do
								local te=teg[i]
								local tg=g:Filter(function(mc) return te:GetValue()(te,mc) end,nil)
							end
						end
						if not card1 then
							card1=tc
						else
							card2=tc
						end
					else
						local rem=false
						if card2 and tc==card2 then
							card2=nil
							rem=true
						elseif not card2 and card1 and tc==card1 then
							card1=nil
							rem=true
						end
						if rem then
							sg:RemoveCard(tc)
							if not sg:IsExists(Card.IsHasEffect,1,nil,EFFECT_SYNCHRO_CHECK) then
								Duel.AssumeReset()
							end
						end
					end
				end
				Duel.AssumeReset()
				local hg=Duel.GetMatchingGroup(Card.IsHasEffect,tp,LOCATION_HAND+LOCATION_GRAVE,0,nil,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				aux.ResetEffects(hg,EFFECT_HAND_SYNCHRO+EFFECT_SYNCHRO_CHECK)
				if sg then
					sg:KeepAlive()
					e:SetLabelObject(sg)
					return true
				else return false end
			end
end
