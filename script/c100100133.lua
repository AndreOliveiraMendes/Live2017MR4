--Ｓｐ－デッド・シンクロン
function c100100133.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_ATKCHANGE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(c100100133.cost)
	e1:SetTarget(c100100133.target)
	e1:SetOperation(c100100133.operation)
	c:RegisterEffect(e1)
end
function c100100133.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local tc=Duel.GetFieldCard(tp,LOCATION_SZONE,5)
	if chk==0 then return tc and tc:IsCanRemoveCounter(tp,0x91,8,REASON_COST) end	 
	Duel.Hint(HINT_OPSELECTED,1-tp,e:GetDescription())
	tc:RemoveCounter(tp,0x91,8,REASON_COST)	
end
function c100100133.filter1(c,e,tp)
	local lv1=c:GetLevel()
	return c:IsLevelBelow(8) and c:IsType(TYPE_SYNCHRO) and c:IsCanBeSpecialSummoned(e,0,tp,true,false)
		and Duel.IsExistingMatchingCard(c100100133.filter2,to,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil,lv1,tp)
end
function c100100133.filter2(c,lv1,tp)
	local lv2=c:GetLevel()
	if not c:IsAbleToRemove() or not c:IsType(TYPE_TUNER)
		or not Duel.IsExistingMatchingCard(c100100133.filter3,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,c,lv1-lv2) then return false end
	if Duel.IsPlayerAffectedByEffect(c:GetControler(),69832741) then
		return c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
	else
		return c:IsLocation(LOCATION_GRAVE)
	end
end
function c100100133.filter3(c,lv)
	if not c:IsAbleToRemove() or c:GetLevel()~=lv or c:IsType(TYPE_TUNER) then return false end
	if Duel.IsPlayerAffectedByEffect(c:GetControler(),69832741) then
		return c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
	else
		return c:IsLocation(LOCATION_GRAVE)
	end
end
function c100100133.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(c100100133.filter1,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function c100100133.operation(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g1=Duel.SelectMatchingCard(tp,c100100133.filter1,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	local tg1=g1:GetFirst()	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g2=Duel.SelectMatchingCard(tp,c100100133.filter2,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,tg1:GetLevel(),tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g3=Duel.SelectMatchingCard(tp,c100100133.filter3,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil,tg1:GetLevel()-g2:GetFirst():GetLevel())
	g2:Merge(g3)
	Duel.Remove(g2,POS_FACEUP,REASON_EFFECT)
	if tg1 and Duel.SpecialSummonStep(tg1,0,tp,tp,false,false,POS_FACEUP) then
		local e3=Effect.CreateEffect(e:GetHandler())
		e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		e3:SetRange(LOCATION_MZONE)
		e3:SetCode(EVENT_PHASE+PHASE_END)
		e3:SetOperation(c100100133.desop)
		e3:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
		e3:SetCountLimit(1)
		tg1:RegisterEffect(e3)
		Duel.SpecialSummonComplete()
	end
end
function c100100133.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT)
end
