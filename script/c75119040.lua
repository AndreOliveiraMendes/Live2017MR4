--ティンダングル・アキュート・ケルベロス 
--Tindangle Acute Cerberus
function c75119040.initial_effect(c)
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x10b),3,3)
	--atk
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(c75119040.atkcon)
	e1:SetValue(3000)
	c:RegisterEffect(e1)	
	--atk
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetValue(c75119040.atkval)
	c:RegisterEffect(e2)
	--special summon
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(75119040,0))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(c75119040.spcon)
	e3:SetTarget(c75119040.sptg)
	e3:SetOperation(c75119040.spop)
	c:RegisterEffect(e3)
end
function c75119040.filter(c)
	return c:IsFaceup() and c:IsCode(94365540)
end
function c75119040.atkcon(e,c)
	if c==nil then return true end
	if Duel.GetLocationCount(c:GetControler(),LOCATION_MZONE)<=0 then return false end
	return Duel.GetMatchingGroup(Card.IsSetCard,c:GetControler(),LOCATION_GRAVE,0,nil,0x10b):GetClassCount(Card.GetCode)>=3
	and Duel.IsExistingMatchingCard(c75119040.filter,e:GetHandlerPlayer(),LOCATION_GRAVE,0,1,nil)
end
function c75119040.atkfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x10b) 
end
function c75119040.atkval(e,c)
	local lg=c:GetLinkedGroup():Filter(c75119040.atkfilter,nil)
	return lg:GetCount()*600
end
function c75119040.spcon(e,tp,eg,ep,ev,re,r,rp)
	return aux.gbspcon(e,tp,eg,ep,ev,re,r,rp)
		and e:GetHandler():GetBattledGroupCount()>0
end
function c75119040.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanSpecialSummonMonster(tp,75119041,0x10b,0x4011,0,0,1,RACE_FIEND,ATTRIBUTE_DARK)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOKEN,nil,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,0)
end
function c75119040.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	if not Duel.IsPlayerCanSpecialSummonMonster(tp,75119041,0x10b,0x4011,0,0,1,RACE_FIEND,ATTRIBUTE_DARK) then return end
	local token=Duel.CreateToken(tp,75119041)
	Duel.SpecialSummon(token,0,tp,tp,false,false,POS_FACEUP)
end
