/obj/item/stack/sheet
	name = "sheet"
	w_class = WEIGHT_CLASS_NORMAL
	full_w_class = WEIGHT_CLASS_NORMAL
	force = 5
	throwforce = 5
	max_amount = 50
	throw_speed = 1
	throw_range = 3
	attack_verb = list("ударил")
	var/perunit = MINERAL_MATERIAL_AMOUNT
	var/sheettype = null //this is used for girders in the creation of walls/false walls
	var/point_value = 0 //turn-in value for the gulag stacker - loosely relative to its rarity.

	var/created_window = null		//apparently glass sheets don't share a base type for glass specifically, so each had to define these vars individually
	var/full_window = null			//moving the var declaration to here so this can be checked cleaner until someone is willing to make them share a base type properly
	usesound = 'sound/items/deconstruct.ogg'
	toolspeed = 1
	var/wall_allowed = TRUE	//determines if sheet can be used in wall construction or not.

	lefthand_file = 'icons/mob/inhands/sheet_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/sheet_righthand.dmi'

/obj/item/stack/sheet/attack(mob/living/carbon/target, mob/living/user, params, def_zone, skip_attack_anim = FALSE)
	if(user.a_intent <> INTENT_HELP)
		return ..()
	if(!ishuman(target))
		return ..()
	if(!isgolem(target))
		return ..()

	. = ATTACK_CHAIN_PROCEED
	var/obj/item/organ/external/bodypart = target.get_organ(check_zone(def_zone))
	if(bodypart.is_robotic())
		balloon_alert(user, "конечность роботическая!")
		return .
	if(bodypart.open != ORGAN_CLOSED)
		balloon_alert(user, "конечность вскрыта!")
		return .

	var/datum/species/golem/target_species = target.dna.species
	if(!istype(src, target_species.skinned_type))
		balloon_alert(user, "требуется другой материал!")
		return .

	if(!get_amount())
		balloon_alert(user, "недостаточно материала!")
		return .
	if(!use(target_species.amount_required_for_heal))
		balloon_alert(user, "недостаточно материала!")
		return .

	if(target == user)
		user.visible_message(
			span_notice("[user] начина[pluralize_ru(user.gender, "ет", "ют")] лечить свои раны на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."),
			span_notice("Вы начинаете лечить раны на своей [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."),
		)
		if(!do_after(user, target_species.self_heal_delay, target, DA_IGNORE_USER_LOC_CHANGE))
			return .

	heal_golem(target, user, bodypart, target_species.material_heal)
	target.UpdateDamageIcon()

/obj/item/stack/sheet/proc/heal_golem(mob/living/carbon/human/target, mob/living/user, obj/item/organ/external/bodypart, var/heal_amount)
	heal_message(target, user, bodypart)
	var/remheal = max(0, heal_amount * 2 - (bodypart.brute_dam + bodypart.burn_dam)) // Maxed with 0 since heal_damage let you pass in a negative value
	var/nremheal = remheal
	var/should_update_health = FALSE
	var/update_damage_icon = NONE
	var/bodypart_damage_was = bodypart.brute_dam + bodypart.burn_dam
	update_damage_icon |= bodypart.heal_damage(heal_amount, heal_amount, updating_health = FALSE)
	if(bodypart.brute_dam + bodypart.burn_dam != bodypart_damage_was)
		should_update_health = TRUE
	var/list/achildlist
	if(LAZYLEN(bodypart.children))
		achildlist = bodypart.children.Copy()
	var/parenthealed = FALSE
	while(remheal > 0) // Don't bother if there's not enough leftover heal
		var/obj/item/organ/external/bodypart_child
		if(LAZYLEN(achildlist))
			bodypart_child = pick_n_take(achildlist) // Pick a random children and then remove it from the list
		else if(bodypart.parent && !parenthealed) // If there's a parent and no healing attempt was made on it
			bodypart_child = bodypart.parent
			parenthealed = TRUE
		else
			break // If the organ have no child left and no parent / parent healed, break
		if(bodypart_child.is_robotic() || bodypart_child.open) // Ignore robotic or open limb
			continue
		else if(!bodypart_child.brute_dam && !bodypart_child.burn_dam) // Ignore undamaged limb
			continue
		nremheal = max(0, remheal - (bodypart_child.brute_dam + bodypart_child.burn_dam)) // Deduct the healed damage from the remain
		var/damage_was = bodypart_child.brute_dam + bodypart_child.burn_dam
		update_damage_icon |= bodypart_child.heal_damage(remheal, remheal, updating_health = FALSE)
		if(bodypart.brute_dam + bodypart.burn_dam != damage_was)
			should_update_health = TRUE
		remheal = nremheal
		heal_message(target, user, bodypart_child)
	if(should_update_health)
		target.updatehealth("[name] heal")
	if(update_damage_icon)
		target.UpdateDamageIcon()

/obj/item/stack/sheet/proc/heal_message(mob/living/carbon/human/target, mob/living/user, obj/item/organ/external/bodypart)
	if(user == target)
		user.visible_message(span_green("[user] залечива[pluralize_ru(user.gender, "ет", "ют")] раны на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."), \
							span_green("Вы залечиваете раны на своей [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."))
	else
		user.visible_message(span_green("[user] залечива[pluralize_ru(user.gender, "ет", "ют")] раны [target] на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."), \
							span_green("Вы залечиваете раны [target] на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."))
