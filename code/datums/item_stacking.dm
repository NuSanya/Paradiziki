GLOBAL_DATUM_INIT(item_stack_manager, /datum/item_stack_manager, new)

#define MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT 50

/**
 * Item stack manager used for reducing client lag
 * on rendering a lot of items in a single tile.
 */
/datum/item_stack_manager
	/// List that contains stack groups
	var/list/stack_groups = list()

/datum/item_stack_manager/Destroy(force)
	stack_groups = null
	return ..()

/**
 * Adds stacks to a turf if the requirements are met, and adds an item to a stack if one exists.
 */
/datum/item_stack_manager/proc/handle_turf_stacking(turf/target_turf, obj/item/item)
	var/obj/item_stack/stack = locate() in target_turf
	if(stack)
		stack.add_item(item)
		return

	// Not going to count only items for optimization purposes
	if(length(target_turf.contents) < MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT)
		return

	add_stack_to_turf(target_turf)

/// Initializes a stack on a turf
/datum/item_stack_manager/proc/add_stack_to_turf(turf/target_turf)
	// Checks for existing groups on adjacent turfs
	for(var/turf/adjacent_turf as anything in target_turf.AdjacentTurfs(cardinal_only = TRUE))
		var/obj/item_stack/stack = locate() in adjacent_turf
		if(!stack)
			continue

		var/datum/item_stack_group/existing_group = stack.group
		existing_group.add_stack(target_turf)
		return

	var/datum/item_stack_group/group = new
	stack_groups += group
	group.add_stack(target_turf)

#undef MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT


/**
 * Item stack container for managing nearby stacks as one.
 */
/datum/item_stack_group
	var/list/occupied_stack_turfs = list()

/datum/item_stack_group/Destroy()
	QDEL_LIST(occupied_stack_turfs)
	GLOB.item_stack_manager -= src
	return ..()

/// Add a stack to a tile and cache it
/// Also returns the created stack
/datum/item_stack_group/proc/add_stack(turf/target_turf)
	var/obj/item_stack/stack = new(target_turf, src)
	occupied_stack_turfs[target_turf] = stack
	return stack

/**
 * Adds an item to a stack in the group
 *
 * Checks for how many overlays are used in a stack, and if its too many,
 * tries to expand, and if it can't, just adds to any random stack while not overlaying it.
 */
/datum/item_stack_group/proc/add_item_to_group(obj/item/item, obj/item_stack/preferred_stack)
	if(preferred_stack && (length(preferred_stack.overlays) < (MAX_ATOM_OVERLAYS - 1)))
		preferred_stack.__add_item(item)
		return

	// Attempt to find a stack with not too many overlays to add onto
	for(var/turf/turf as anything in occupied_stack_turfs)
		var/obj/item_stack/stack = occupied_stack_turfs[turf]
		if(length(stack.overlays) < (MAX_ATOM_OVERLAYS - 1))
			stack.__add_item(item)
			return

	// If we couldn't find one, try to find an adjacent atom to make a stack on and add to that
	var/turf/expand_turf = try_expand()
	if(expand_turf)
		var/obj/item_stack/stack = occupied_stack_turfs[expand_turf]
		stack.__add_item(item)
		return

	// Otherwise just do the preferred one or a random
	var/obj/item_stack/random_stack = preferred_stack ? preferred_stack : occupied_stack_turfs[rand(1, length(occupied_stack_turfs))]
	random_stack.__add_item(item)

/// Tries to expand the group to a single new turf. Returns new turf.
/// Splits contained items between two stacks, the found one and the searched from.
/datum/item_stack_group/proc/try_expand()
	var/list/used_turfs = assoc_to_keys(occupied_stack_turfs)
	for(var/turf/turf as anything in used_turfs)
		// Just incase check both turf and the stack related to the turf
		if(QDELETED(turf) || QDELETED(occupied_stack_turfs[turf]))
			continue

		for(var/turf/adjacent_turf as anything in turf.AdjacentTurfs(cardinal_only = TRUE))
			if(adjacent_turf in used_turfs)
				continue

			// Not ours, so begin to merge groups
			if(locate(/obj/item_stack) in adjacent_turf)
				//merge_groups() nusanya TODO
				return

			if(adjacent_turf.density)
				continue

			var/obj/item_stack/stack = add_stack(adjacent_turf)
			split_between_two(stack, occupied_stack_turfs[turf])
			return adjacent_turf

/// Splits contained items between two stacks
// nuSanya TODO
/datum/item_stack_group/proc/split_between_two(obj/item_stack/first_stack, obj/item_stack/second_stack)
	return

/// Shows a loot panel consisting of items from stacks nearby the interacted stack and close to user
/datum/item_stack_group/proc/stack_interact(mob/looter, obj/item_stack/stack)
	var/turf/looter_turf = get_turf(looter)
	var/turf/stack_turf = get_turf(stack)

	var/list/looting_turfs = (looter_turf.AdjacentTurfs() + looter_turf) & (stack_turf.AdjacentTurfs(cardinal_only = TRUE) + stack_turf)
	var/list/looting_stacks = list()
	for(var/turf/looting_turf as anything in looting_turfs)
		if(!LAZYACCESS(occupied_stack_turfs, looting_turf))
			continue
		looting_stacks += occupied_stack_turfs[looting_turf]

	looter.client.loot_panel.open(looting_stacks)

/// Removes a stack from the group and deletes the group if there are zero
/datum/item_stack_group/proc/remove_stack(obj/item_stack/stack)
	if(QDELETED(src))
		return

	var/turf/stack_turf = get_turf(stack)
	occupied_stack_turfs -= stack_turf
	if(!length(occupied_stack_turfs))
		qdel(src)


/// How many items should a stack incluse (or lesser) to be qdeled
#define ITEM_STACK_QDEL_THRESHOLD 40

// The stack object itself. Uses overlays to show what items are held inside,
// Handled in groups (/datum/item_stack_group).
/obj/item_stack
	name = "a bunch of items"
	desc = "Куча всяких предметов."
	anchored = TRUE
	/// What mutables are currently used in overlays. Format: Item UID() -> Mutable
	var/list/used_mutables = list()
	/// What group do we belong to?
	var/datum/item_stack_group/group

/obj/item_stack/Initialize(mapload, datum/item_stack_group/assigned_group)
	. = ..()
	if(!assigned_group)
		return qdel(src)

	group = assigned_group
	add_items_on_init()
	RegisterSignal(src, COMSIG_ATOM_EXITED, PROC_REF(on_exited))

/obj/item_stack/Destroy(force)
	QDEL_LIST_ASSOC(used_mutables)
	group.remove_stack(src)
	group = null
	UnregisterSignal(src, COMSIG_ATOM_EXITED)

	var/turf/our_turf = get_turf(src)
	for(var/atom/movable/atom as anything in contents)
		atom.forceMove(our_turf)
	return ..()

/// Proc that is only used by the group. Use add_item()
/obj/item_stack/proc/__add_item(obj/item/item)
	item.forceMove(src)
	if(length(overlays) >= (MAX_ATOM_OVERLAYS - 1))
		return

	var/mutable_appearance/item_appearance = new(item)
	item_appearance.pixel_x = item.pixel_x
	item_appearance.pixel_y = item.pixel_y
	used_mutables[item.UID()] = item_appearance
	add_overlay(item_appearance)
	RegisterSignal(item, COMSIG_QDELETING, PROC_REF(remove_item))

/// Used to add an item to this stack
/obj/item_stack/proc/add_item(obj/item/item)
	group.add_item_to_group(item, src)

/// Proc used on init to insert all existing items into src
/obj/item_stack/proc/add_items_on_init()
    var/turf/our_turf = get_turf(src)
    var/list/items_to_move = our_turf.contents.Copy()  // copy the list
    for(var/obj/item/item in items_to_move)
        if(istype(item, /obj/item_stack))  // don't move other stacks
            continue
        add_item(item)

/// Proc used to remove an item from this stack
/obj/item_stack/proc/remove_item(obj/item/item)
	var/item_uid = item.UID()
	var/mutable_appearance/item_appearance = used_mutables[item_uid]
	cut_overlay(item_appearance)
	used_mutables -= item_uid
	UnregisterSignal(item, COMSIG_QDELETING)

	if(length(contents) <= ITEM_STACK_QDEL_THRESHOLD)
		qdel(src)

/obj/item_stack/proc/on_exited(datum/source, atom/movable/departed, atom/newLoc)
	SIGNAL_HANDLER
	if(!isitem(departed))
		return

	remove_item(departed)

/obj/item_stack/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	group.stack_interact(user, src)

/obj/item_stack/allow_click()
	return TRUE

#undef ITEM_STACK_QDEL_THRESHOLD
