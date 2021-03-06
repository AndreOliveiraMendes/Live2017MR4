--Iron Knight of Revolution
function c501000084.initial_effect(c)
	--link summon
	c:EnableReviveLimit()
	aux.AddLinkProcedure(c,c501000084.filter,3)
	--match kill
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_MATCH_KILL)
	e1:SetCondition(c501000084.con)
	c:RegisterEffect(e1)
	--spsummon condition
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e3:SetCode(EFFECT_SPSUMMON_CONDITION)
	e3:SetValue(c501000084.limit)
	c:RegisterEffect(e3)
end
function c501000084.filter(c)
	return c:IsLinkType(TYPE_EFFECT) and c:IsRace(RACE_MACHINE)
end
function c501000084.con(e)
	return e:GetHandler():IsExtraLinked()
end
function c501000084.limit(e,se,sp,st)
	return bit.band(st,SUMMON_TYPE_LINK)==SUMMON_TYPE_LINK
end
