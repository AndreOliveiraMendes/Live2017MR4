--Odd-eyes Venom Dragon
--fixed by MLD
function c511009587.initial_effect(c)
	--fusion material
	c:EnableReviveLimit()
	aux.AddFusionProcMix(c,true,true,16178681,41209827)
	--pendulum summon
	aux.EnablePendulumAttribute(c,false)
	--no damage
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_FIELD)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCode(EVENT_PRE_BATTLE_DAMAGE)
	e1:SetOperation(c511009587.op)
	c:RegisterEffect(e1)
	--material
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCondition(c511009587.effcon)
	e2:SetOperation(c511009587.regop)
	c:RegisterEffect(e2)
	--atk
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetDescription(aux.Stringid(900787,0))
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1)
	e3:SetCondition(c511009587.atkcon)
	e3:SetTarget(c511009587.atktg)
	e3:SetOperation(c511009587.atkop)
	c:RegisterEffect(e3)
	--effect
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(10032958,0))
	e4:SetCategory(CATEGORY_DISABLE)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1)
	e4:SetTarget(c511009587.distg)
	e4:SetOperation(c511009587.disop)
	c:RegisterEffect(e4)
	--pendulum
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(90036274,0))
	e5:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e5:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e5:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_DESTROYED)
	e5:SetTarget(c511009587.pentg)
	e5:SetOperation(c511009587.penop)
	c:RegisterEffect(e5)
end
function c511009587.op(e,tp,eg,ep,ev,re,r,rp)
	if ep==tp and e:GetHandler():GetFlagEffect(511009587)==0 then
		e:GetHandler():RegisterFlagEffect(511009587,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,0,1)
		Duel.ChangeBattleDamage(tp,0)
	end
end
function c511009587.effcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=c:GetMaterial()
	return c:GetSummonType()==SUMMON_TYPE_FUSION and g:FilterCount(Card.IsPreviousLocation,nil,LOCATION_ONFIELD)==g:GetCount()
end
function c511009587.regop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RegisterFlagEffect(511009588,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,0,1)
end
function c511009587.atkcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():GetFlagEffect(511009588)~=0
end
function c511009587.atktg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
end
function c511009587.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
		local atk=0
		local tc=g:GetFirst()
		while tc do
			if tc:GetAttack()>0 then
				atk=atk+tc:GetAttack()
			end
			tc=g:GetNext()
		end
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+0x1ff0000+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
function c511009587.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local c=e:GetHandler()
	if c:IsHasEffect(511009518) then
		e:SetProperty(0)
	else
		e:SetProperty(EFFECT_FLAG_CARD_TARGET)
	end
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and aux.disfilter1(chkc) end
	if chk==0 then
		if c:IsHasEffect(511009518) then
			local g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)
			return g:FilterCount(aux.disfilter1,nil)==g:GetCount()
		else
			return Duel.IsExistingTarget(aux.disfilter1,tp,0,LOCATION_MZONE,1,nil)
		end
	end
	local g
	if c:IsHasEffect(511009518) then
		g=Duel.GetMatchingGroup(Card.IsFaceup,tp,0,LOCATION_MZONE,nil)	
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
		g=Duel.SelectTarget(tp,aux.disfilter1,tp,0,LOCATION_MZONE,1,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,g:GetCount(),0,0)
end
function c511009587.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetFirstTarget()
	local g=Group.CreateGroup()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		if c:IsHasEffect(511009518) then
			g=Duel.GetMatchingGroup(aux.disfilter1,tp,0,LOCATION_MZONE,nil)
		elseif tg and tg:IsRelateToEffect(e) and tg:IsFaceup() and not tg:IsDisabled() then
			g:AddCard(tg)
		end
		local tc=g:GetFirst()
		while tc do
			local code=tc:GetOriginalCode()
			local e2=Effect.CreateEffect(c)
			e2:SetType(EFFECT_TYPE_SINGLE)
			e2:SetCode(EFFECT_DISABLE)
			e2:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e2)
			local e3=Effect.CreateEffect(c)
			e3:SetType(EFFECT_TYPE_SINGLE)
			e3:SetCode(EFFECT_DISABLE_EFFECT)
			e3:SetValue(RESET_TURN_SET)
			e3:SetReset(RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e3)
			c:CopyEffect(code,RESET_EVENT+0x1fe0000+RESET_PHASE+PHASE_END,1)
			tc=g:GetNext()
		end
	end
end
function c511009587.filter(c,e,tp)
	return (c:GetSequence()==6 or c:GetSequence()==7) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function c511009587.pentg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chkc then return chkc:IsLocation(LOCATION_SZONE) and chkc:IsControler(tp) and c511009587.filter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(c511009587.filter,tp,LOCATION_SZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,c511009587.filter,tp,LOCATION_SZONE,0,1,1,nil,e,tp)
	local g2=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g2,g2:GetCount(),0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,0)
end
function c511009587.penop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetFirstTarget()
	if tg and tg:IsRelateToEffect(e) then
		if Duel.SpecialSummon(tg,0,tp,tp,false,false,POS_FACEUP)>0 and c:IsRelateToEffect(e) then
			if Duel.MoveToField(c,tp,tp,LOCATION_SZONE,POS_FACEUP,true) then
				Duel.BreakEffect()
				local g=Duel.GetMatchingGroup(aux.TRUE,tp,0,LOCATION_MZONE,nil)
				if Duel.Destroy(g,REASON_EFFECT)>0 then
					local dg=Duel.GetOperatedGroup()
					local atk=0
					local tc=dg:GetFirst()
					while tc do
						if tc:IsPreviousPosition(POS_FACEUP) then
							atk=atk+tc:GetPreviousAttackOnField()
						end
						tc=dg:GetNext()
					end
					Duel.Damage(1-tp,atk,REASON_EFFECT)
				end
			end
		end
	end
end
