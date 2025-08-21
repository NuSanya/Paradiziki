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

	obj_damage = 70
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

/mob/living/simple_animal/hostile/bingle/ComponentInitialize()
	AddComponent( \
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
	add_traits(bingle_traits, INNATE_TRAIT)

/mob/living/simple_animal/hostile/bingle/Destroy()
	LAZYREMOVE(GLOB.bingle_mobs, src)
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

	melee_damage_lower = 10
	melee_damage_upper = 15
	var/pit_spawner = /datum/action/innate/bingle/spawn_hole

/mob/living/simple_animal/hostile/bingle/lord/Initialize(mapload)
	. = ..()
	var/datum/action/innate/bingle/spawn_hole/makehole = new pit_spawner(src)
	makehole.Grant(src)

/mob/living/simple_animal/hostile/bingle/Life(seconds_between_ticks, times_fired)
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/bingle/lord/Life(seconds_between_ticks, times_fired)
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/bingle/proc/evolve()
	var/mob/living/simple_animal/hostile/bingle/bongle = src
	bongle.maxHealth = 160
	bongle.health = 160
	bongle.obj_damage = 100
	bongle.melee_damage_lower = 10
	bongle.melee_damage_upper = 10
	bongle.armour_penetration = 0

/mob/living/simple_animal/hostile/bingle/update_icon()
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

/mob/living/simple_animal/hostile/bingle/lord/update_icon()
	. = ..()
	if(a_intent == INTENT_HARM)
		icon_state = "binglelord_combat"
	else
		icon_state = "binglelord"

/mob/living/simple_animal/hostile/bingle/death(gibbed)
	. = ..()

	var/list/possible_chems = list(
		/datum/reagent/smoke_powder,
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

	// Pick 3-5 random chemicals and create smoke with each
	var/chemicals_to_use = rand(3, 5)
	for(var/i = 1 to chemicals_to_use)
		var/chemical_type = pick(possible_chems)
		do_chem_smoke(
			range = 2,
			holder = src,
			location = get_turf(src),
			reagent_type = chemical_type,
			reagent_volume = rand(5, 15),
			log = TRUE
		)
	if(!gibbed)
		src.gib()

/mob/living/simple_animal/hostile/bingle/lord/death(gibbed)
	. = ..()

	var/list/possible_chems = list(
		/datum/reagent/smoke_powder,
		/datum/reagent/plasma,
		/datum/reagent/space_drugs,
		/datum/reagent/methamphetamine,
		/datum/reagent/histamine,
		/datum/reagent/consumable/nutriment,
		/datum/reagent/water,
		/datum/reagent/consumable/ethanol
	)

	// Pick 10-15 random chemicals and create smoke with each
	var/chemicals_to_use = rand(10, 15)
	for(var/i = 1 to chemicals_to_use)
		var/chemical_type = pick(possible_chems)
		do_chem_smoke(
			range = 2,
			holder = src,
			location = get_turf(src),
			reagent_type = chemical_type,
			reagent_volume = rand(5, 15),
			log = TRUE
		)
	if(!gibbed)
		src.gib()
