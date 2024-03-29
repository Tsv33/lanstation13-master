/mob/living/carbon/human/movement_delay()
	if(istype(loc, /turf/space))
		return -1 // It's hard to be slowed down in space by... anything

	if(flying)
		return -1

	var/tally = 0

	var/turf/T = loc
	if(istype(T))
		tally = T.adjust_slowdown(src, tally)

		if(tally == -1)
			return tally

	if(species && species.move_speed_mod)
		tally += species.move_speed_mod

	if(isslimeperson(src))
		if (bodytemperature >= 330.23) // 135 F
			return -1	// slimes become supercharged at high temperatures
		if (bodytemperature < 183.222)
			tally += (283.222 - bodytemperature) / 10 * 1.75
	else if (undergoing_hypothermia())
		tally += 2*undergoing_hypothermia()

	//(/vg/ EDIT disabling for now) handle_embedded_objects() //Moving with objects stuck in you can cause bad times.

	if(reagents.has_reagent(NUKA_COLA))
		tally -= 10

	if((M_RUN in mutations))
		tally -= 10

	var/health_deficiency = (100 - health - halloss)
	if(health_deficiency >= 40)
		tally += (health_deficiency / 25)

	var/hungry = (500 - nutrition)/5 // So overeat would be 100 and default level would be 80
	if (hungry >= 70)
		tally += hungry/50

	if(wear_suit)
		tally += wear_suit.slowdown

	if(shoes)
		tally += shoes.slowdown

	for(var/obj/item/I in held_items)
		if(I.flags & SLOWDOWN_WHEN_CARRIED)
			tally += I.slowdown

	for(var/organ_name in list(LIMB_LEFT_FOOT,LIMB_RIGHT_FOOT,LIMB_LEFT_LEG,LIMB_RIGHT_LEG))
		var/datum/organ/external/E = get_organ(organ_name)
		if(!E || (E.status & ORGAN_DESTROYED))
			tally += 4
		if(E.status & ORGAN_SPLINTED)
			tally += 0.5
		else if(E.status & ORGAN_BROKEN)
			tally += 1.5

	if(pain_shock_stage >= 50)
		tally += 3

	if(M_FAT in src.mutations)
		tally += 1.5

	var/skate_bonus = 0
	var/disease_slow = 0
	for(var/obj/item/weapon/bomberman/dispenser in src)
		disease_slow = max(disease_slow, dispenser.slow)
		skate_bonus = max(skate_bonus, dispenser.speed_bonus)//if the player is carrying multiple BBD for some reason, he'll benefit from the speed bonus of the most upgraded one
	tally = tally - skate_bonus + (6 * disease_slow)

	if(reagents.has_reagent(HYPERZINE))
		if(isslimeperson(src))
			tally *= 2
		else
			tally -= 10

	if(reagents.has_reagent(FROSTOIL) && isslimeperson(src))
		tally *= 5

	return max((tally+config.human_delay), -1) //cap at -1 as the 'fastest'

/mob/living/carbon/human/Process_Spacemove(var/check_drift = 0)
	//Can we act
	if(restrained())
		return 0

	//Do we have a working jetpack
	if(istype(back, /obj/item/weapon/tank/jetpack))
		var/obj/item/weapon/tank/jetpack/J = back
		if(((!check_drift) || (check_drift && J.stabilization_on)) && (!lying) && (J.allow_thrust(0.01, src)))
			inertia_dir = 0
			return 1
//		if(!check_drift && J.allow_thrust(0.01, src))
//			return 1

	//If no working jetpack then use the other checks
	return ..()


/mob/living/carbon/human/Process_Spaceslipping(var/prob_slip = 5)
	//If knocked out we might just hit it and stop.  This makes it possible to get dead bodies and such.
	if(stat)
		prob_slip = 0 // Changing this to zero to make it line up with the comment, and also, make more sense.

	//Do we have magboots or such on if so no slip
	if(CheckSlip() < 0)
		prob_slip = 0

	//Check hands and mod slip
	for(var/i = 1 to held_items.len)
		var/obj/item/I = held_items[i]

		if(!I)
			prob_slip -= 2
		else if(I.w_class <= W_CLASS_SMALL)
			prob_slip -= 1

	prob_slip = round(prob_slip)
	return(prob_slip)

/mob/living/carbon/human/Move(NewLoc, Dir = 0, step_x = 0, step_y = 0, glide_size_override = 0)
	var/old_z = src.z

	. = ..()

	/*if(status_flags & FAKEDEATH)
		return 0*/

	if(.)
		if (old_z != src.z)
			crewmonitor.queueUpdate(old_z)
		crewmonitor.queueUpdate(src.z)

		if(shoes && istype(shoes, /obj/item/clothing/shoes))
			var/obj/item/clothing/shoes/S = shoes
			S.step_action()

		if(wear_suit && istype(wear_suit, /obj/item/clothing/suit))
			var/obj/item/clothing/suit/SU = wear_suit
			SU.step_action()

		for(var/obj/item/weapon/bomberman/dispenser in src)
			if(dispenser.spam_bomb)
				dispenser.attack_self(src)

/mob/living/carbon/human/CheckSlip()
	. = ..()
	if(. && shoes && shoes.clothing_flags & NOSLIP)
		. = (istype(shoes, /obj/item/clothing/shoes/magboots) ? -1 : 0)
	return .

/mob/living/carbon/human/handle_footstep(var/turf/T, var/turf/NT)
	if(..())
		if(T.footstep_sounds["human"])
			var/S = pick(T.footstep_sounds["human"])
			if(S)
				if(m_intent == "run")
					if(!(step_count % 2)) //every other turf makes a sound
						return

				var/range = -(world.view - 2)
				if(m_intent == "walk")
					range -= 0.333
				if(!shoes)
					range -= 0.333

				var/volume = 90
				if(m_intent == "walk")
					volume -= 55
				if(!shoes)
					volume -= 70

				if(istype(shoes, /obj/item/clothing/shoes))
					var/obj/item/clothing/shoes/footwear = shoes
					if(footwear.silence_steps)
						return //silent

				if(!has_organ("l_foot") && !has_organ("r_foot"))
					return //no feet no footsteps

				if(locked_to || lying || throwing)
					return //people flying, lying down or sitting do not step

				if(!has_gravity(src))
					if(step_count % 3) //this basically says, every three moves make a noise
						return //1st - none, 1%3==1, 2nd - none, 2%3==2, 3rd - noise, 3%3==0

				if(species.silent_steps)
					return //species is silent

				playsound(T, S, volume, 1, range)
				return
