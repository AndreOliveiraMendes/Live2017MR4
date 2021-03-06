--Dowsing Burn
function c511000526.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(c511000526.target)
	e1:SetOperation(c511000526.activate)
	c:RegisterEffect(e1)
end
function c511000526.banfilter(c)
	if not c:IsType(TYPE_MONSTER) or not c:IsAbleToRemove() 
		or not Duel.IsExistingTarget(c511000526.desfilter,0,LOCATION_MZONE,LOCATION_MZONE,1,c,c:GetLevel(),c:GetRace()) then return false end
	if Duel.IsPlayerAffectedByEffect(c:GetControler(),69832741) then
		return c:IsFaceup() and c:IsLocation(LOCATION_MZONE)
	else
		return c:IsLocation(LOCATION_GRAVE)
	end
end
function c511000526.desfilter(c,lv,race)
	return c:IsFaceup() and c:GetLevel()<lv and c:IsRace(race)
end
function c511000526.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(c511000526.banfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,0,0)
end
function c511000526.activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,c511000526.banfilter,tp,0,LOCATION_MZONE+LOCATION_GRAVE,1,1,nil)
	if g:GetCount()>0 and Duel.Remove(g,POS_FACEUP,REASON_EFFECT)>0 then
		local tc=Duel.SelectMatchingCard(tp,c511000526.desfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,g:GetFirst():GetLevel(),g:GetFirst():GetRace())
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
