
/datum/artifact_effect/hurt
	effecttype = I_HURT
	effect_type = 5

/datum/artifact_effect/hurt/DoEffectTouch(var/mob/toucher)
	if(toucher)
		var/weakness = GetAnomalySusceptibility(toucher)
		if(iscarbon(toucher) && prob(weakness * 100))
			var/mob/living/carbon/C = toucher
			to_chat(C, "<span class='warning'>A painful discharge of energy strikes you!</span>")
			C.adjustOxyLoss(rand(5,25) * weakness)
			C.adjustToxLoss(rand(5,25) * weakness)
			C.adjustBruteLoss(rand(5,25) * weakness)
			C.adjustFireLoss(rand(5,25) * weakness)
			C.adjustBrainLoss(rand(5,25) * weakness)
			C.radiation += 25 * weakness
			C.nutrition -= min(50 * weakness, C.nutrition)
			C.Dizzy(6 * weakness)
			C.AdjustKnockdown(6 * weakness)

/datum/artifact_effect/hurt/DoEffectAura()
	if(holder)
		for (var/mob/living/carbon/C in range(src.effectrange,holder))
			var/weakness = GetAnomalySusceptibility(C)
			if(prob(weakness * 100))
				if(prob(10))
					to_chat(C, "<span class='warning'>You feel a painful force radiating from something nearby.</span>")
				C.adjustBruteLoss(1 * weakness)
				C.adjustFireLoss(1 * weakness)
				C.adjustToxLoss(1 * weakness)
				C.adjustOxyLoss(1 * weakness)
				C.adjustBrainLoss(1 * weakness)
				C.updatehealth()

/datum/artifact_effect/hurt/DoEffectPulse()
	if(holder)
		for (var/mob/living/carbon/C in range(effectrange, holder))
			var/weakness = GetAnomalySusceptibility(C)
			if(prob(weakness * 100))
				to_chat(C, "<span class='warning'>A wave of painful energy strikes you!</span>")
				C.adjustBruteLoss(3 * weakness)
				C.adjustFireLoss(3 * weakness)
				C.adjustToxLoss(3 * weakness)
				C.adjustOxyLoss(3 * weakness)
				C.adjustBrainLoss(3 * weakness)
				C.updatehealth()