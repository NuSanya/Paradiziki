/mob/living/simple_animal/hostile/bingle
	name = "bingle"
	real_name = "bingle"
	desc = "Тёмно-фиолетовое существо, чем-то напоминающее гориллу."
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
	environment_smash = ENVIRONMENT_SMASH_WALLS
	melee_damage_lower = 5
	melee_damage_upper = 5

	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE

	attacktext = "бинглует"
	attack_sound = 'sound/effects/blobattack.ogg'
	butcher_results = null

	/// Flag to check if we are already evolved or not
	var/evolved = FALSE

	/// Static list of all traits used by bingles
	var/static/list/bingle_traits = list(
		TRAIT_HEALS_FROM_BINGLE_HOLES,
	)

	/// Additional stamina damage on attack
	var/stamina_damage = 50

	/// The minimum amount of reagents used on death
	var/reagents_amount_min = 3
	/// The maximum amount of reagents used on death
	var/reagents_amount_max = 5
	/// The minimum units amount of a reagent used on death
	var/reagent_min = 20
	/// The maximum units amount of a reagent used on death
	var/reagent_max = 30
	/// The range of the smoke on death
	var/smoke_range = 2

/mob/living/simple_animal/hostile/bingle/ComponentInitialize()
	AddComponent( \
		/datum/component/animal_temperature, \
		maxbodytemp = INFINITY, \
		minbodytemp = 0, \
	)
	AddComponent(\
		/datum/component/ghost_direct_control, \
		ban_type = ROLE_BINGLE, \
		poll_candidates = FALSE, \
		after_assumed_control = CALLBACK(src, PROC_REF(add_datum_if_not_exist)), \
	)

/mob/living/simple_animal/hostile/bingle/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!no_effect && !visual_effect_icon)
		visual_effect_icon = ATTACK_EFFECT_BITE
	..()

/mob/living/simple_animal/hostile/bingle/Initialize(mapload)
	. = ..()
	LAZYADD(GLOB.bingle_mobs, src)
	RegisterSignal(src, COMSIG_BINGLE_EVOLVE, PROC_REF(evolve))
	RegisterSignal(src, COMSIG_LIVING_DEATH, PROC_REF(on_death))
	add_traits(bingle_traits, INNATE_TRAIT)

/mob/living/simple_animal/hostile/bingle/Destroy()
	LAZYREMOVE(GLOB.bingle_mobs, src)
	UnregisterSignal(src, COMSIG_BINGLE_EVOLVE)
	UnregisterSignal(src, COMSIG_LIVING_DEATH)
	remove_traits(bingle_traits, INNATE_TRAIT)
	return ..()

/mob/living/simple_animal/hostile/bingle/Life(seconds_between_ticks, times_fired)
	. = ..()
	update_icon()

/mob/living/simple_animal/hostile/bingle/proc/on_evolve()
	SIGNAL_HANDLER
	evolve()

/mob/living/simple_animal/hostile/bingle/proc/evolve()
	icon_state = "bingle_armored"
	maxHealth = 200
	health = 200
	obj_damage = 100
	melee_damage_lower = 15
	melee_damage_upper = 15
	armour_penetration = 10
	evolved = TRUE

/mob/living/simple_animal/hostile/bingle/AttackingTarget()
	. = ..()
	if(!.)
		return
	if(!isliving(target))
		return

	var/mob/living/living = target
	living.apply_effects(stutter = 10 SECONDS, confused = 5 SECONDS, stamina = stamina_damage)
	SEND_SIGNAL(living, COMSIG_LIVING_MINOR_SHOCK)

/mob/living/simple_animal/hostile/bingle/proc/on_death()
	SIGNAL_HANDLER
	smoke_on_death()
	gib()

/mob/living/simple_animal/hostile/bingle/proc/smoke_on_death()
	var/list/possible_chems = get_death_chem_list()
	var/chemicals_to_use = rand(reagents_amount_min, reagents_amount_max)
	var/datum/reagents/reagents_list = new (reagent_max * reagents_amount_max)
	for(var/i = 1 to chemicals_to_use)
		var/chem_id = pick(possible_chems)
		reagents_list.add_reagent(chem_id, rand(reagent_min, reagent_max))

	var/datum/effect_system/fluid_spread/smoke/chem/smoke = new
	smoke.set_up(range = smoke_range, location = loc, carry = reagents_list, silent = TRUE)
	smoke.start()

/// Proc used to get a chem list for smoke on death
/mob/living/simple_animal/hostile/bingle/proc/get_death_chem_list()
	return GLOB.standard_chemicals

/mob/living/simple_animal/hostile/bingle/proc/add_datum_if_not_exist()
	if(!(mind.has_antag_datum(/datum/antagonist/bingle)))
		mind.add_antag_datum(/datum/antagonist/bingle, /datum/team/bingles)

/mob/living/simple_animal/hostile/bingle/get_ru_names()
	return list(
		NOMINATIVE = "бингл",
		GENITIVE = "бингла",
		DATIVE = "бинглу",
		ACCUSATIVE = "бингла",
		INSTRUMENTAL = "бинглом",
		PREPOSITIONAL = "бингле"
	)

/mob/living/simple_animal/hostile/bingle/lord
	name = "bingle lord"
	real_name = "bingle lord"
	desc = "Тёмно-фиолетовое существо, чем-то напоминающее гориллу. Этот выглядит больше остальных..."
	icon = 'icons/mob/bingle/binglelord.dmi'
	icon_state = "binglelord"
	icon_living = "binglelord"
	icon_dead = "binglelord"

	maxHealth = 200
	health = 200

	environment_smash = ENVIRONMENT_SMASH_RWALLS
	melee_damage_lower = 10
	melee_damage_upper = 15

	reagents_amount_min = 10
	reagents_amount_max = 15
	reagent_min = 50
	reagent_max = 75
	smoke_range = 7

	stamina_damage = 80

/mob/living/simple_animal/hostile/bingle/lord/Initialize(mapload)
	. = ..()
	var/datum/action/cooldown/bingle/create_hole/hole_action = new
	hole_action.Grant(src)

/mob/living/simple_animal/hostile/bingle/lord/evolve()
	icon_state = "binglelord_armored"
	maxHealth = 300
	health = 300
	obj_damage = 100
	melee_damage_lower = 15
	melee_damage_upper = 20
	armour_penetration = 20

/// Proc used to get a chem list for smoke on death
/mob/living/simple_animal/hostile/bingle/lord/get_death_chem_list()
	return GLOB.blocked_chems

/mob/living/simple_animal/hostile/bingle/lord/get_ru_names()
	return list(
		NOMINATIVE = "лорд бинглов",
		GENITIVE = "лорда бинглов",
		DATIVE = "лорду бинглов",
		ACCUSATIVE = "лорда бинглов",
		INSTRUMENTAL = "лордом бинглов",
		PREPOSITIONAL = "лорде бинглов"
	)
