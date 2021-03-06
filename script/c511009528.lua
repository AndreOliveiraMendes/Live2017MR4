--Supreme King Servant Dragon Starving Venom
--fixed by MLD
function c511009528.initial_effect(c)
	--fusion summon
	c:EnableReviveLimit()
	aux.AddFusionProcMixN(c,true,true,aux.FilterBoolFunction(Card.IsFusionAttribute,ATTRIBUTE_DARK),2)
	--special summon
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(c511009528.spcon)
	e1:SetOperation(c511009528.spop)
	c:RegisterEffect(e1)
	--atk limit
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTargetRange(0,LOCATION_MZONE)
	e2:SetCode(EFFECT_CANNOT_SELECT_BATTLE_TARGET)
	e2:SetValue(c511009528.atlimit)
	c:RegisterEffect(e2)
	--copy
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(25793414,0))
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(c511009528.cpcon)
	e3:SetTarget(c511009528.cptg)
	e3:SetOperation(c511009528.cpop)
	c:RegisterEffect(e3)
	 --Piercing
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD)
	e4:SetCode(EFFECT_PIERCE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetTargetRange(LOCATION_MZONE,0)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	--spsummon
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(95923441,0))
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e5:SetType(EFFECT_TYPE_QUICK_O)
	e5:SetCode(EVENT_FREE_CHAIN)
	e5:SetHintTiming(0,TIMING_END_PHASE)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCost(c511009528.spcost)
	e5:SetTarget(c511009528.sptg)
	e5:SetOperation(c511009528.spop2)
	c:RegisterEffect(e5)
end
function c511009528.spfilter(c,tp)
	return c:IsControler(1-tp) and c:IsType(TYPE_FUSION) and c:IsSummonType(SUMMON_TYPE_FUSION)
end
function c511009528.cfilter(c)
	return c:IsFaceup() and c:IsCode(13331639)
end
function c511009528.costfilter(c,tp,sg,tc)
	if not c:IsSetCard(0x20f8) then return false end
	sg:AddCard(c)
	local res
	if sg:GetCount()<2 then
		res=Duel.CheckReleaseGroup(tp,c511009528.costfilter,1,sg,tp,sg,tc)
	else
		res=Duel.GetLocationCountFromEx(tp,tp,sg,tc)>0
	end
	sg:RemoveCard(c)
	return res
end
function c511009528.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return eg:IsExists(c511009528.spfilter,1,nil,tp) and Duel.IsExistingMatchingCard(c511009528.cfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.CheckReleaseGroup(tp,c511009528.costfilter,1,nil,tp,Group.CreateGroup(),c) and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,true)
end
function c511009528.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local sg=Group.CreateGroup()
	if Duel.CheckReleaseGroup(tp,c511009528.costfilter,1,nil,tp,sg,c) and e:GetHandler():IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,true) 
		and Duel.SelectYesNo(tp,aux.Stringid(4003,6)) then
		while sg:GetCount()<2 do
			local g=Duel.SelectReleaseGroup(tp,c511009528.costfilter,1,1,sg,tp,sg,c)
			sg:Merge(g)
		end
		Duel.Release(sg,REASON_COST)
		Duel.SpecialSummon(c,SUMMON_TYPE_FUSION,tp,tp,false,true,POS_FACEUP)
		c:CompleteProcedure()
	end
end
function c511009528.atlimit(e,c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION) and c~=e:GetHandler()
end
function c511009528.cpcon(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetTurnPlayer()~=tp then return false end
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE) or ph==PHASE_MAIN2
end
function c511009528.cptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE+LOCATION_GRAVE) and chkc:IsType(TYPE_MONSTER) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,LOCATION_GRAVE+LOCATION_MZONE,LOCATION_GRAVE+LOCATION_MZONE,1,nil,TYPE_MONSTER) 
		and e:GetHandler():GetFlagEffect(511009529)==0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsType,tp,LOCATION_GRAVE+LOCATION_MZONE,LOCATION_GRAVE+LOCATION_MZONE,1,1,nil,TYPE_MONSTER)
end
function c511009528.cpop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and c:IsRelateToEffect(e) and c:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsType(TYPE_TOKEN) then
		local code=tc:GetOriginalCode()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
		if not tc:IsType(TYPE_TRAPMONSTER) then
			c:CopyEffect(code,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,1)
			c:RegisterFlagEffect(511009529,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,0,0)
		end
	end
end
function c511009528.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsAbleToExtraAsCost() end
	Duel.SendtoDeck(e:GetHandler(),nil,0,REASON_COST)
end
function c511009528.spfilter2(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(0x20f8) and c:IsType(TYPE_PENDULUM) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function c511009528.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ect=c29724053 and Duel.IsPlayerAffectedByEffect(tp,29724053) and c29724053[tp]
	if chk==0 then return not Duel.IsPlayerAffectedByEffect(tp,59822133) and (not ect or ect>=2)
		and Duel.GetLocationCountFromEx(tp,tp,e:GetHandler())>1 and e:GetHandler():GetFlagEffect(511009528)==0
		and Duel.IsExistingMatchingCard(c511009528.spfilter2,tp,LOCATION_EXTRA,0,2,nil,e,tp) end
	e:GetHandler():RegisterFlagEffect(511009528,RESET_CHAIN,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_EXTRA)
end
function c511009528.filter(c)
	return c:IsFaceup() and c:IsType(TYPE_FUSION)
end
function c511009528.spop2(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsPlayerAffectedByEffect(tp,59822133) or (ect and ect<2) or Duel.GetLocationCountFromEx(tp)<2 then return end
	local g=Duel.GetMatchingGroup(c511009528.spfilter2,tp,LOCATION_EXTRA,0,nil,e,tp)
	if g:GetCount()>=2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=g:Select(tp,2,2,nil)
		if Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)==0 then return end
		local ag=Duel.GetMatchingGroup(c511009528.filter,tp,0,LOCATION_MZONE,nil)
		local tc=ag:GetFirst()
		while tc do
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_SET_ATTACK_FINAL)
			e2:SetValue(0)
			e2:SetReset(RESET_EVENT+0x1fe0000)
			tc:RegisterEffect(e2)
			tc=ag:GetNext()
		end
	end
end
