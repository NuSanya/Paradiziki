/mob/living/simple_animal/hostile/bingle
	name = "bingle"
	real_name = "bingle"
	desc = "Забавный синенький чувачок."
	speak_emote = list("визжит", "хнычет", "булькает", "тыдынькает")
	icon = 'icons/mob/bingle/bingles.dmi'
	icon_state = "bingle"
	icon_living = "bingle"
	icon_dead = "bingle"

	pass_flags = PASSTABLE

	maxHealth = 100
	health = 100
	pressure_resistance = 100

	obj_damage = 50
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	melee_damage_lower = 5
	melee_damage_upper = 5

	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE

	attacktext = "бинглует"
	attack_sound = 'sound/effects/blobattack.ogg'
	butcher_results = null

	var/evolved = FALSE
	var/static/list/bingle_traits = list(
		TRAIT_HEALS_FROM_BINGLE_HOLES,
		TRAIT_BINGLE,
	)

	var/stamina_damage = 50

	// everything death related
	var/reagents_amount_min = 3
	var/reagents_amount_max = 5
	var/reagent_min = 20
	var/reagent_max = 30
	var/smoke_range = 2

/mob/living/simple_animal/hostile/bingle/ComponentInitialize()
	AddComponent( \
		/datum/component/animal_temperature, \
		maxbodytemp = INFINITY, \
		minbodytemp = 0, \
	)

/mob/living/simple_animal/hostile/bingle/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		visual_effect_icon = ATTACK_EFFECT_BITE
	..()

/mob/living/simple_animal/hostile/bingle/Initialize(mapload)
	. = ..()
	LAZYADD(GLOB.bingle_mobs, src)
	RegisterSignal(src, BINGLE_EVOLVE, PROC_REF(evolve))
	RegisterSignal(src, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	add_traits(bingle_traits, INNATE_TRAIT)

/mob/living/simple_animal/hostile/bingle/Destroy()
	LAZYREMOVE(GLOB.bingle_mobs, src)
	UnregisterSignal(src, BINGLE_EVOLVE)
	UnregisterSignal(src, COMSIG_LIVING_DEATH)
	remove_traits(bingle_traits, INNATE_TRAIT)
	return ..()

/mob/living/simple_animal/hostile/bingle/AttackingTarget()
	if(!..())
		return

	if(!isliving(target))
		return

	var/mob/living/living = target
	living.AdjustStuttering(10 SECONDS, bound_upper = 10 SECONDS)
	living.AdjustConfused(5 SECONDS, bound_upper = 5 SECONDS)
	living.apply_damage(stamina_damage, STAMINA)
	SEND_SIGNAL(living, COMSIG_LIVING_MINOR_SHOCK)


/mob/living/simple_animal/hostile/bingle/mind_initialize()
	. = ..()
	if(!(mind.has_antag_datum(/datum/antagonist/bingle)))
		mind.add_antag_datum(/datum/antagonist/bingle)

/mob/living/simple_animal/hostile/bingle/lord
	name = "bingle lord"
	real_name = "bingle lord"
	desc = "A rather large funny lil blue guy."
	icon = 'icons/mob/bingle/binglelord.dmi'
	icon_state = "binglelord"
	icon_living = "binglelord"
	icon_dead = "binglelord"

	maxHealth = 200
	health = 200

	melee_damage_lower = 10
	melee_damage_upper = 15
	var/pit_spawner = /obj/effect/proc_holder/spell/bingle/spawn_hole

	reagents_amount_min = 10
	reagents_amount_max = 15
	reagent_min = 50
	reagent_max = 75
	smoke_range = 7

	stamina_damage = 80

/mob/living/simple_animal/hostile/bingle/lord/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_MOB_MIND_INITIALIZED, PROC_REF(add_hole_spawner))

/mob/living/simple_animal/hostile/bingle/lord/proc/add_hole_spawner()
	SIGNAL_HANDLER

	mind.AddSpell(new pit_spawner(null))
	UnregisterSignal(src, COMSIG_MOB_MIND_INITIALIZED)

/mob/living/simple_animal/hostile/bingle/Life(seconds_between_ticks, times_fired)
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/bingle/lord/Life(seconds_between_ticks, times_fired)
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/bingle/proc/evolve()
	icon_state = "bingle_armored"
	maxHealth = 200
	health = 200
	obj_damage = 100
	melee_damage_lower = 15
	melee_damage_upper = 15
	armour_penetration = 10
	evolved = TRUE

/mob/living/simple_animal/hostile/bingle/lord/evolve()
	maxHealth = 300
	health = 300
	obj_damage = 100
	melee_damage_lower = 15
	melee_damage_upper = 20
	armour_penetration = 20
	evolved = TRUE

/mob/living/simple_animal/hostile/bingle/update_icon(updates)
	. = ..()
	if(evolved)
		if(a_intent == INTENT_HARM)
			icon_state = "binglearmored_combat"
		else
			icon_state = "binglearmored"
		return
	else if(a_intent == INTENT_HARM)
		icon_state = "bingle_combat"
	else
		icon_state = "bingle"

/mob/living/simple_animal/hostile/bingle/lord/update_icon(updates)
	. = ..()
	if(a_intent == INTENT_HARM)
		icon_state = "binglelord_combat"
	else
		icon_state = "binglelord"

/mob/living/simple_animal/hostile/bingle/proc/on_death()
	var/list/possible_chems = list(
		/datum/reagent/plasma,
		/datum/reagent/space_drugs,
		/datum/reagent/methamphetamine,
		/datum/reagent/histamine,
		/datum/reagent/consumable/nutriment,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol,
		/datum/reagent/colorful_reagent,
		/datum/reagent/consumable/sugar,
		/datum/reagent/lube,
		/datum/reagent/consumable/sodiumchloride,
		/datum/reagent/consumable/capsaicin,
		/datum/reagent/consumable/frostoil,
		/datum/reagent/medicine/omnizine,
		/datum/reagent/consumable/honey,
		/datum/reagent/clf3,
		/datum/reagent/fluorosurfactant,
		/datum/reagent/consumable/drink/cold/spacemountainwind,
		/datum/reagent/consumable/drink/cold/dr_gibb,
		/datum/reagent/consumable/drink/cold/space_cola,
		/datum/reagent/consumable/drink/coffee,
		/datum/reagent/consumable/drink/tea,
		/datum/reagent/medicine/ephedrine,
		/datum/reagent/medicine/diphenhydramine,
		/datum/reagent/consumable/garlic,
		/datum/reagent/consumable/drink/banana,
		/datum/reagent/iron,
		/datum/reagent/copper,
		/datum/reagent/silver,
		/datum/reagent/gold,
		/datum/reagent/uranium,
		/datum/reagent/medicine/strange_reagent,
		/datum/reagent/acid/facid,
		/datum/reagent/napalm,
		/datum/reagent/thermite,
		/datum/reagent/krokodil,
		/datum/reagent/bath_salts,
		/datum/reagent/aranesp,
		/datum/reagent/consumable/drink/pineapplejuice,
		/datum/reagent/consumable/drink/tomatojuice,
		/datum/reagent/consumable/drink/potato_juice,
		/datum/reagent/consumable/drink/limejuice,
		/datum/reagent/consumable/drink/orangejuice
	)

	var/chemicals_to_use = rand(reagents_amount_min, reagents_amount_max)
	var/datum/reagents/reagents_list = new (reagent_max * reagents_amount_max)
	for(var/i = 1 to chemicals_to_use)
		var/datum/reagent/chemical_type = pick(possible_chems)
		reagents_list.add_reagent(chemical_type.id, rand(reagent_min, reagent_max))

	var/datum/effect_system/fluid_spread/smoke/chem/smoke = new
	smoke.set_up(range = smoke_range, location = loc, carry = reagents_list, silent = TRUE)
	smoke.start()

	gib()

/mob/living/simple_animal/hostile/bingle/lord/on_death()
	var/list/possible_chems = list(
		/datum/reagent/plasma,
		/datum/reagent/space_drugs,
		/datum/reagent/methamphetamine,
		/datum/reagent/histamine,
		/datum/reagent/consumable/nutriment,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol
	)

	var/chemicals_to_use = rand(reagents_amount_min, reagents_amount_max)
	var/datum/reagents/reagents_list = new (reagent_max * reagents_amount_max)
	for(var/i = 1 to chemicals_to_use)
		var/datum/reagent/chemical_type = pick(possible_chems)
		reagents_list.add_reagent(chemical_type.id, rand(reagent_min, reagent_max))

	var/datum/effect_system/fluid_spread/smoke/chem/smoke = new
	smoke.set_up(range = smoke_range, location = loc, carry = reagents_list, silent = TRUE)
	smoke.start()

	gib()
