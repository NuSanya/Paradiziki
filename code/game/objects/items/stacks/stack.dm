/* Stack type objects!
 * Contains:
 *		Stacks
 *		Recipe datum
 *		Recipe list datum
 */

/*
 * Stacks
 */
/obj/item/stack
	origin_tech = "materials=1"
	/// Whether this stack is a `/cyborg` subtype or not.
	var/is_cyborg = FALSE
	/// The storage datum that will be used with this stack. Used only with `/cyborg` type stacks.
	var/datum/robot_energy_storage/source
	/// Which `robot_energy_storage` to choose when this stack is created in cyborgs. Used only with `/cyborg` type stacks.
	var/energy_type
	/// Related to above. Determines what stack will actually be put in machine when using cyborg stacks on construction to avoid spawning those on deconstruction.
	var/cyborg_construction_stack
	/// How much energy using 1 sheet from the stack costs. Used only with `/cyborg` type stacks.
	var/cost = 1
	/// A list of recipes buildable with this stack.
	var/list/recipes = list()
	/// The singular name of this stack.
	var/singular_name
	/// The current amount of this stack.
	var/amount = 1
	var/to_transfer = 0
	/// The maximum amount of this stack. Also see stack recipes initialisation, param "max_res_amount" must be equal to this max_amount
	var/max_amount = 50
	/// The path and its children that should merge with this stack, defaults to src.type.
	var/merge_type
	/// The type of table that is made when applying this stack to a frame.
	var/table_type
	/// Whether this stack can't stack with subtypes.
	var/parent_stack = FALSE
	/// The weight class the stack has at amount > 2/3rds of max_amount
	var/full_w_class = WEIGHT_CLASS_NORMAL
	/// for icons when inserted in protolathe
	var/protolathe_name

/obj/item/stack/Initialize(mapload, new_amount, merge = TRUE)

	if(new_amount != null)
		amount = new_amount

	while(amount > max_amount)
		amount -= max_amount
		new type(loc, max_amount, FALSE)

	if(!merge_type)
		merge_type = type

	. = ..()
	if(merge)
		for(var/obj/item/stack/item_stack in loc)
			if(item_stack == src)
				continue
			if(can_merge(item_stack))
				INVOKE_ASYNC(src, PROC_REF(merge_without_del), item_stack)
				// we do not want to qdel during initialization, so we just check whether or not we're a 0 count stack and let the hint handle deletion
				if(is_zero_amount(FALSE))
					return INITIALIZE_HINT_QDEL

	update_weight()
	update_icon()

	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)


/obj/item/stack/hitby(atom/movable/hitting, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum)
	if(can_merge(hitting, inhand = TRUE))
		merge(hitting)
	. = ..()

/obj/item/stack/examine(mob/user)
	. = ..()
	if(!in_range(user, src))
		return

	if(is_cyborg)
		if(singular_name)
			. += "There is enough energy for [get_amount()] [singular_name]\s."
			return

		. += "There is enough energy for [get_amount()]."
		return

	. += "There are [amount] [singular_name? singular_name : name]\s in the stack."
	. += span_notice("Alt-click to take a custom amount.")

/obj/item/stack/proc/add(newamount)
	if(is_cyborg)
		source.add_charge(newamount * cost)
		return
	amount += newamount
	update_icon()
	update_weight()

	if(!isstorage(loc))
		return

	var/obj/item/storage/container = loc
	addtimer(CALLBACK(container, TYPE_PROC_REF(/obj/item/storage, drop_overweight)), 0)


/obj/item/storage/proc/drop_overweight()
	if(QDELETED(src))
		return

	for(var/obj/item/stack/item_stack in contents)
		if(item_stack.is_cyborg)
			continue

		if(item_stack.w_class <= max_w_class)
			continue

		var/drop_loc = get_turf(src)
		item_stack.pixel_x = pixel_x
		item_stack.pixel_y = pixel_y
		item_stack.forceMove(drop_loc)
		var/mob/holder = usr

		if(!holder)
			continue

		to_chat(holder, span_warning("[item_stack] exceeds [src] weight limits and drops to [drop_loc]"))

/** Checks whether this stack can merge itself into another stack.
 *
 * Arguments:
 * - [check][/obj/item/stack]: The stack to check for mergeability.
 * - [inhand][boolean]: Whether or not the stack to check should act like it's in a mob's hand.
 */
/obj/item/stack/proc/can_merge(obj/item/stack/check, inhand = FALSE)
	if(QDELETED(src) || QDELETED(check))
		return FALSE
	// We don't only use istype here, since that will match subtypes, and stack things that shouldn't stack
	if(!istype(check, merge_type))
		return FALSE
	if(amount <= 0 || check.amount <= 0) // no merging empty stacks that are in the process of being qdel'd
		return FALSE
	if(is_cyborg) // No merging cyborg stacks into other stacks
		return FALSE
	if(ismob(loc) && !inhand) // no merging with items that are on the mob
		return FALSE
	if(check.throwing)	// no merging for items in middle air
		return FALSE
	if(ismachinery(loc)) // no merging items in machines that aren't both in componentparts
		var/obj/machinery/machine = loc
		if(!(src in machine.component_parts) || !(check in machine.component_parts))
			return FALSE
	return TRUE

/obj/item/stack/attack_self(mob/user)
	ui_interact(user)

/obj/item/stack/attack_self_tk(mob/user)
	ui_interact(user)

/obj/item/stack/attack_tk(mob/user)
	if(user.stat || !isturf(loc))
		return
	// Allow remote stack splitting, because telekinetic inventory managing
	// is really cool
	if(!(src in user.tkgrabbed_objects))
		return ..()

	var/obj/item/stack/material = split(user, 1)
	material.attack_tk(user)
	if(src && user.machine == src)
		ui_interact(user)

/obj/item/stack/attack_hand(mob/user)
	if(!user.is_in_inactive_hand(src) && get_amount() > 1)
		..()
		return

	change_stack(user, 1)
	if(src && user.machine == src)
		ui_interact(user)

/obj/item/stack/attackby(obj/item/thing, mob/user, params)
	if(!can_merge(thing, TRUE))
		return ..()

	var/obj/item/stack/material = thing
	do_pickup_animation(user)
	if(!merge(material))
		return ..()
	to_chat(user, span_notice("Your [material.name] stack now contains [material.get_amount()] [material.singular_name]\s."))
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/item/stack/use(used, check = TRUE)
	if(check && is_zero_amount(TRUE))
		return FALSE

	if(is_cyborg)
		return source.use_charge(used * cost)

	if(amount < used)
		return FALSE

	amount -= used
	if(check && is_zero_amount(TRUE))
		return TRUE

	update_icon()
	update_weight()
	return TRUE

/// Signal handler for connect_loc element. Called when a movable enters the turf we're currently occupying. Merges if possible.
/obj/item/stack/proc/on_entered(datum/source, atom/movable/arrived, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	// Edge case. This signal will also be sent when src has entered the turf. Don't want to merge with ourselves.
	if(arrived == src)
		return

	on_movable_entered_occupied_turf(arrived)

/obj/item/stack/proc/on_movable_entered_occupied_turf(atom/movable/arrived)
	if(can_merge(arrived, inhand = FALSE))
		INVOKE_ASYNC(src, PROC_REF(merge), arrived)

/obj/item/stack/click_alt(mob/user)
	if(!istype(user) || user.incapacitated())
		to_chat(user, span_warning("You can't do that right now!"))
		return NONE

	if(!in_range(src, user) || !ishuman(usr) || amount < 1 || is_cyborg)
		return NONE

	// Get amount from user
	var/min = 0
	var/max = get_amount()
	var/stackmaterial = tgui_input_number(user, "How many sheets do you wish to take out of this stack? (Max: [max])", "Stack Split", max_value = max, min_value = min)
	if(isnull(stackmaterial))
		return CLICK_ACTION_BLOCKING

	if(!Adjacent(user, 1))
		return CLICK_ACTION_BLOCKING

	change_stack(user, stackmaterial)
	to_chat(user, span_notice("You take [stackmaterial] sheets out of the stack."))
	return CLICK_ACTION_SUCCESS

/obj/item/stack/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/stack/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "StackCraft", name)
		ui.set_autoupdate(FALSE)
		ui.open()

/obj/item/stack/ui_data(mob/user)
	var/list/data = list()
	data["amount"] = get_amount()
	return data

/obj/item/stack/ui_static_data(mob/user)
	var/list/data = list()
	data["recipes"] = recursively_build_recipes(recipes)
	return data

/obj/item/stack/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return FALSE

	var/mob/living/user = usr
	var/obj/item/stack/material = src
	if(action != "make")
		return
	var/datum/stack_recipe/recipe = locateUID(params["recipe_uid"])
	var/multiplier = text2num(params["multiplier"])
	if(!recipe.try_build(user, material, multiplier))
		return FALSE

	var/obj/result
	result = recipe.do_build(user, material, multiplier, result)
	if(!result)
		return FALSE

	recipe.post_build(user, material, result)
	return TRUE

/**
 * Recursively builds the recipes data for the given list of recipes, iterating through each recipe.
 * If recipe is of type /datum/stack_recipe, it adds the recipe data to the recipes_data list with the title as the key.
 * If recipe is of type /datum/stack_recipe_list, it recursively calls itself, scanning the entire list and adding each recipe to its category.
 */
/obj/item/stack/proc/recursively_build_recipes(list/recipes_to_iterate)
	var/list/recipes_data = list()
	for(var/recipe in recipes_to_iterate)
		if(istype(recipe, /datum/stack_recipe))
			var/datum/stack_recipe/single_recipe = recipe
			recipes_data["[single_recipe.title]"] = build_recipe_data(single_recipe)

		else if(istype(recipe, /datum/stack_recipe_list))
			var/datum/stack_recipe_list/recipe_list = recipe
			recipes_data["[recipe_list.title]"] = recursively_build_recipes(recipe_list.recipes)

	return recipes_data

/obj/item/stack/proc/build_recipe_data(datum/stack_recipe/recipe)
	var/list/data = list()
	var/obj/result = recipe.result_type

	data["uid"] = recipe.UID()
	data["required_amount"] = recipe.req_amount
	data["result_amount"] = recipe.res_amount
	data["max_result_amount"] = recipe.max_res_amount
	data["icon"] = result.icon
	data["icon_state"] = result.icon_state

	// DmIcon cannot paint images. So, if we have grayscale sprite, we need ready base64 image.
	if(recipe.result_image)
		data["image"] = recipe.result_image

	return data

/obj/item/stack/proc/get_amount()
	if(!is_cyborg)
		return amount

	if(!source) // The energy source has not yet been initializied
		return FALSE

	return round(source.energy / cost)

/obj/item/stack/proc/get_max_amount()
	return max_amount

/obj/item/stack/proc/get_amount_transferred()
	return to_transfer

/obj/item/stack/proc/split(mob/user, amount)
	var/obj/item/stack/material = new type(loc, amount)
	material.copy_evidences(src)
	if(isliving(user))
		add_fingerprint(user)
		material.add_fingerprint(user)

	use(amount)
	return material

/obj/item/stack/proc/change_stack(mob/user, amount)
	var/obj/item/stack/material = new type(user, amount, FALSE)
	. = material
	material.copy_evidences(src)
	if(!user.put_in_hands(material, merge_stacks = FALSE))
		material.forceMove(user.drop_location())
	add_fingerprint(user)
	material.add_fingerprint(user)
	do_pickup_animation(user)
	use(amount)
	SStgui.update_uis(src)

/**
 * Returns TRUE if the item stack is the equivalent of a 0 amount item.
 *
 * Also deletes the item if delete_if_zero is TRUE and the stack does not have
 * is_cyborg set to true.
 */
/obj/item/stack/proc/is_zero_amount(delete_if_zero = TRUE)
	if(is_cyborg)
		return source.energy < cost

	if(amount < 1)
		if(delete_if_zero)
			qdel(src)
		return TRUE
	return FALSE

/**
 * Merges as much of src into material as possible.
 *
 * This calls use() without check = FALSE, preventing the item from qdeling itself if it reaches 0 stack size.
 *
 * As a result, this proc can leave behind a 0 amount stack.
 */
/obj/item/stack/proc/merge_without_del(obj/item/stack/material)
	// Cover edge cases where multiple stacks are being merged together and haven't been deleted properly.
	// Also cover edge case where a stack is being merged into itself, which is supposedly possible.
	if(QDELETED(material))
		CRASH("Stack merge attempted on qdeleted target stack.")
	if(QDELETED(src))
		CRASH("Stack merge attempted on qdeleted source stack.")
	if(material == src)
		CRASH("Stack attempted to merge into itself.")

	var/transfer = get_amount()
	if(material.is_cyborg)
		transfer = min(transfer, round((material.source.max_energy - material.source.energy) / material.cost))
	else
		transfer = min(transfer, material.max_amount - material.amount)

	if(pulledby)
		pulledby.start_pulling(material)

	material.copy_evidences(src)
	use(transfer, FALSE)
	material.add(transfer)

	return transfer

/**
 * Merges as much of src into material as possible.
 *
 * This proc deletes src if the remaining amount after the transfer is 0.
 */
/obj/item/stack/proc/merge(obj/item/stack/material)
	. = merge_without_del(material)
	is_zero_amount(TRUE)

/**
 * Updates the weight class based on current stack amount
 *
 * Adjusts the item's weight class proportionally to how full the stack is.
 * The weight class decreases as the stack amount decreases, with three tiers:
 * - Below 1/3 capacity: weight class reduced by 2 (minimum: WEIGHT_CLASS_TINY)
 * - Between 1/3 and 2/3 capacity: weight class reduced by 1 (minimum: WEIGHT_CLASS_TINY)
 * - Above 2/3 capacity: uses the full weight class
 */
/obj/item/stack/proc/update_weight()
	if(amount <= (max_amount * (1/3)))
		w_class = clamp(full_w_class-2, WEIGHT_CLASS_TINY, full_w_class)
	else if (amount <= (max_amount * (2/3)))
		w_class = clamp(full_w_class-1, WEIGHT_CLASS_TINY, full_w_class)
	else
		w_class = full_w_class

/**
 * Copies forensic evidence from another stack
 *
 * Transfers all forensic evidence (blood DNA, fingerprints) from one stack
 * to another. Used when creating new stacks from existing ones to preserve
 * investigation evidence.
 *
 * Arguments:
 * * material - The source stack to copy evidence from
 */
/obj/item/stack/proc/copy_evidences(obj/item/stack/material)
	blood_DNA			= material.blood_DNA
	fingerprints		= material.fingerprints
	fingerprintshidden	= material.fingerprintshidden
	fingerprintslast	= material.fingerprintslast

/**
 * Handles stack attack on carbon mobs
 *
 * Special attack handling for stacks when used on carbons with help intent.
 * Used for healing golem-type mobs with appropriate materials.
 */
/obj/item/stack/attack(mob/living/carbon/target, mob/living/user, params, def_zone, skip_attack_anim = FALSE)
	if(user.a_intent != INTENT_HELP)
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

	var/found_material = FALSE
	var/datum/species/golem/target_species = target.dna.species
	for(var/required_type as anything in target_species.suitable_materials_for_heal)
		if(!istype(src, required_type))
			continue
		found_material = TRUE
		break

	if(!found_material)
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

	. |= ATTACK_CHAIN_SUCCESS

	heal_golem(target, user, bodypart, target_species.material_heal)
	target.UpdateDamageIcon()

/**
 * Heals golem limbs using stack material
 *
 * Basically a copy of gauze/ointment mechanics, but heals both brute and burn damages.
 */
/obj/item/stack/proc/heal_golem(mob/living/carbon/human/target, mob/living/user, obj/item/organ/external/bodypart, heal_amount)
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

/**
 * Shows healing message for golem repair
 *
 * Varies depending on if we are healing ourselves, or someone else
 */
/obj/item/stack/proc/heal_message(mob/living/carbon/human/target, mob/living/user, obj/item/organ/external/bodypart)
	if(user == target)
		user.visible_message(span_green("[user] залечива[pluralize_ru(user.gender, "ет", "ют")] раны на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."), \
							span_green("Вы залечиваете раны на своей [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."))
	else
		user.visible_message(span_green("[user] залечива[pluralize_ru(user.gender, "ет", "ют")] раны [target] на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."), \
							span_green("Вы залечиваете раны [target] на [genderize_ru(target.gender, "его", "её", "его", "их")] [bodypart.declent_ru(PREPOSITIONAL)], используя [declent_ru(ACCUSATIVE)]."))
