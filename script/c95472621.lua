--大火葬
function c95472621.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_REMOVE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_BECOME_TARGET)
	e1:SetCondition(c95472621.condition)
	e1:SetTarget(c95472621.target)
	e1:SetOperation(c95472621.activate)
	c:RegisterEffect(e1)
end
function c95472621.cfilter(c)
	return c:IsLocation(LOCATION_GRAVE) and c:IsType(TYPE_MONSTER)
end
function c95472621.condition(e,tp,eg,ep,ev,re,r,rp)
	return rp~=tp and eg:IsExists(c95472621.cfilter,1,nil)
end
function c95472621.filter(c)
	if not c:IsType(TYPE_MONSTER) or not c:IsAbleToRemove() then return false end
	if Duel.IsPlayerAffectedByEffect(c:GetControler(),69832741) then
		return c:IsLocation(LOCATION_MZONE)
	else
		return c:IsLocation(LOCATION_GRAVE)
	end
end
function c95472621.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(c95472621.filter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,1,nil) end
	if Duel.IsPlayerAffectedByEffect(e:GetHandlerPlayer(),69832741) then
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,PLAYER_ALL,LOCATION_MZONE)
	else
		Duel.SetOperationInfo(0,CATEGORY_REMOVE,nil,1,PLAYER_ALL,LOCATION_GRAVE)
	end
end
function c95472621.activate(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(c95472621.filter,tp,LOCATION_MZONE+LOCATION_GRAVE,LOCATION_MZONE+LOCATION_GRAVE,nil)
	Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
end
