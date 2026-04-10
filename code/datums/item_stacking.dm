GLOBAL_DATUM_INIT(item_stack_manager, /datum/item_stack_manager, new)

/// Global proc wrapper for item stack manager main handler
#define ITEM_STACK_MANAGER_HANDLER(item) (GLOB.item_stack_manager.handle_turf_stacking(item))

/// Minimum amount of movables on a turf required for a stack to appear
#define MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT 80
/// How many items should a stack include (or lesser) to be qdeled, must be lesser than the define above by a good margin
#define ITEM_STACK_QDEL_THRESHOLD 60
/// How many overlays can a stack have at once
/// 2 extra overlays for acid/fire overlays
#define ITEM_STACK_OVERLAY_LIMIT (MAX_ATOM_OVERLAYS - 3)
/// What layer is used for stack item overlays
#define ITEM_STACK_ITEM_OVERLAY_LAYER (FLOAT_LAYER + 1)

/**
 * Item stack manager used for reducing client lag
 * on rendering a lot of items in a single tile.
 *
 * Currently used on:
 * * Item init
 * * Item move
 * * Item dropped
 */
/datum/item_stack_manager
	/// Associative list that contains turfs  as keys to stacks as values
	var/list/turf_to_stack = list()

/datum/item_stack_manager/Destroy(force)
	QDEL_LIST_ASSOC(turf_to_stack)
	return ..()

/**
 * Main manager proc
 *
 * Adds an item to a stack if one exists,
 * or creates a new stack on an item turf.
 *
 * Returns TRUE if we successfully added an item to a stack, or created a new stack.
 * Returns FALSE otherwise.
 */
/datum/item_stack_manager/proc/handle_turf_stacking(obj/item/item)
	if(!item || !istype(item))
		return FALSE

	if(!istype(item.loc, /turf))
		return FALSE

	var/turf/item_turf = item.loc
	// If we have a stack assigned to the item turf, put the item into that stack
	var/atom/movable/item_stack/stack = turf_to_stack[item_turf]
	if(stack)
		stack.add_item(item)
		return TRUE

	// Otherwise, attempt to create a new stack
	return attempt_add_stack_to_turf(item_turf)

/**
 * Creates a stack on a given turf
 *
 * Checks for enough contents in a turf before creating a stack.
 *
 * Returns FALSE if the turf didnt have enough contents.
 * Returns TRUE otherwise.
 */
/datum/item_stack_manager/proc/attempt_add_stack_to_turf(turf/target_turf)
	if(length(target_turf.contents) < MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT)
		return FALSE

	var/atom/movable/item_stack/stack = new(target_turf)
	turf_to_stack[target_turf] = stack
	return TRUE

/**
 * Removes a stack from a turf
 *
 * Returns TRUE on success, FALSE otherwise
 */
/datum/item_stack_manager/proc/remove_stack_from_turf(turf/target_turf)
	if(!target_turf)
		return FALSE

	var/atom/movable/item_stack/stack = turf_to_stack[target_turf]
	if(!stack)
		return FALSE

	turf_to_stack -= target_turf
	qdel(stack)

	return TRUE


// The stack object itself. Uses overlays to show what items are held inside.
/atom/movable/item_stack
	name = "a bunch of items"
	desc = "Куча всяких предметов."
	anchored = TRUE
	/// What mutables are currently used in overlays. Format: Item UID() -> Mutable
	var/list/used_mutables = list()
	/// Lazylist queue of items UIDs that couldn't be overlayed due to the limit.
	var/list/overlay_items_queue
	/// Assoc lazylist of items UIDs currently burning
	var/list/burning_items
	/// Assoc lazylist of items UIDs currently on acid
	var/list/acid_items
	/// Does the stack have burning overlay already applied?
	var/burning_overlay_applied = FALSE
	/// Does the stack have acid overlay already applied?
	var/acid_overlay_applied = FALSE

/atom/movable/item_stack/Initialize(mapload)
	. = ..()
	add_items_on_init()
	RegisterSignal(src, COMSIG_ATOM_EXITED, PROC_REF(on_exited))

/atom/movable/item_stack/Destroy(force)
	QDEL_LIST_ASSOC_VAL(used_mutables)
	UnregisterSignal(src, COMSIG_ATOM_EXITED) // before remove_items_on_destroy for optimization
	remove_items_on_destroy()
	return ..()

/// Removes all items from src to turf and cleans up signals
/atom/movable/item_stack/proc/remove_items_on_destroy()
	var/turf/our_turf = get_turf(src)
	while(length(contents))
		var/obj/item/item = contents[length(contents)]
		unregister_item_signals(item)
		item.forceMove(our_turf)

/// Wrapper for signal registering on item insertion
/atom/movable/item_stack/proc/register_item_signals(obj/item/item)
	RegisterSignal(item, COMSIG_QDELETING, PROC_REF(remove_item))
	RegisterSignal(item, COMSIG_CLICK_CTRL, PROC_REF(on_item_ctrl_click))
	RegisterSignal(item, COMSIG_OBJ_ACID_PROCESSING, PROC_REF(on_item_acid_process))
	RegisterSignal(item, COMSIG_OBJ_EXTINGUISH, PROC_REF(on_item_extinguish))

/// Wrapper for signal unregistering on item removal
/atom/movable/item_stack/proc/unregister_item_signals(obj/item/item)
	UnregisterSignal(item, list(COMSIG_QDELETING, COMSIG_CLICK_CTRL, COMSIG_OBJ_ACID_PROCESSING, COMSIG_OBJ_EXTINGUISH))

/**
 * Adds an item to this stack
 *
 * Checks for amount of overlays used, and if the limit is not met,
 * adds an item to the overlay queue. Otherwise adds it immediately
 *
 * Handles insertion of burning items.
 */
/atom/movable/item_stack/proc/add_item(obj/item/item)
	register_item_signals(item)
	item.forceMove(src)

	handle_burning_overlay(item)

	if(length(overlays) >= ITEM_STACK_OVERLAY_LIMIT)
		LAZYADD(overlay_items_queue, item.UID())
		return

	add_item_overlay(item)

/**
 * Removes an item from this stack
 *
 * Checks for amount of items in stack, and if its lesser than ITEM_STACK_QDEL_THRESHOLD,
 * removes the stack entirely.
 *
 * Handles removal of burning items.
 * After removing an item queues other items to get overlayed.
 */
/atom/movable/item_stack/proc/remove_item(obj/item/item)
	unregister_item_signals(item)
	remove_item_overlay(item)

	if(length(contents) <= ITEM_STACK_QDEL_THRESHOLD)
		GLOB.item_stack_manager.remove_stack_from_turf(get_turf(src))
		return

	handle_burning_overlay(item)
	handle_acid_overlay(item)
	add_items_overlays_from_queue()

/// Adds an item to the stack overlays
/atom/movable/item_stack/proc/add_item_overlay(obj/item/item)
	var/mutable_appearance/item_appearance = new(item)
	item_appearance.layer = ITEM_STACK_ITEM_OVERLAY_LAYER
	used_mutables[item.UID()] = item_appearance
	add_overlay(item_appearance)

/// Removes an item from the stack overlays or overlay queue
/atom/movable/item_stack/proc/remove_item_overlay(obj/item/item)
	var/item_uid = item.UID()
	var/mutable_appearance/item_appearance = used_mutables[item_uid]
	// If not found, item must be in the queue
	if(!item_appearance)
		LAZYREMOVE(overlay_items_queue, item_uid)
		return

	cut_overlay(item_appearance)
	qdel(item_appearance)
	used_mutables -= item_uid

/// Proc called to apply overlays from items in queue (overlay_items_queue)
/atom/movable/item_stack/proc/add_items_overlays_from_queue()
	if(!LAZYLEN(overlay_items_queue))
		return

	var/list/overlay_items_queue_cached = overlay_items_queue
	while(LAZYLEN(overlay_items_queue_cached))
		if(length(overlays) >= ITEM_STACK_OVERLAY_LIMIT)
			return

		var/item_uid = overlay_items_queue_cached[LAZYLEN(overlay_items_queue_cached)]
		LAZYREMOVE(overlay_items_queue_cached, item_uid)

		var/obj/item/item = locateUID(item_uid)
		add_item_overlay(item)

/// Proc used on init to insert all existing items on turf into src
/atom/movable/item_stack/proc/add_items_on_init()
    var/turf/our_turf = get_turf(src)
    var/list/items_to_move = our_turf.contents.Copy()
    for(var/obj/item/item in items_to_move)
        add_item(item)

/// Signal proc called on item exiting the stack
/atom/movable/item_stack/proc/on_exited(datum/source, atom/movable/departed, atom/newLoc)
	SIGNAL_HANDLER
	remove_item(departed)

// Inserts an item if possible into the stack
/atom/movable/item_stack/attackby(obj/item/item, mob/user, params)
	. = ..()
	if(ATTACK_CHAIN_CANCEL_CHECK(.))
		return

	if(user.a_intent != INTENT_HELP)
		return ATTACK_CHAIN_PROCEED

	if(!user.drop_item_ground(item))
		user.balloon_alert(user, "застряло в руке")
		return ATTACK_CHAIN_BLOCKED_ALL

	user.balloon_alert(user, "убрано в кучу")
	add_item(item)
	return ATTACK_CHAIN_BLOCKED_ALL

/**
 * Signal proc called on inside item getting ctrl-clicked
 *
 * First forceMove the item we are trying to pull into an adjacent free turf,
 * then check if we can actually pull it, and if we can, start pulling.
 * Otherwise, forceMove it back to the stack.
 */
/atom/movable/item_stack/proc/on_item_ctrl_click(obj/item/item, mob/living/user)
	SIGNAL_HANDLER
	if(!isliving(user))
		return

	var/turf/user_turf = get_turf(user)
	var/turf/stack_turf = get_turf(src)
	var/turf/output_turf = (user_turf == stack_turf) ? pick(stack_turf.AdjacentTurfs(TRUE)) : user_turf
	if(!output_turf)
		user.balloon_alert(user, "не вытащить!")
		return

	item.forceMove(output_turf)
	if(!(item.can_be_pulled(user, force = user.pull_force)))
		item.forceMove(src)
		return

	remove_item(item)
	INVOKE_ASYNC(user, TYPE_PROC_REF(/mob/living, pulled), item)

// Calls the lootpanel on this stack
/atom/movable/item_stack/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	user.client.loot_panel.open(src)

// Allows items from within to be picked up in the lootpanel
/atom/movable/item_stack/allow_click()
	return TRUE

/**
 * Handles applying and removing burning overlay of this stack.
 *
 * We handle burning overlay by looking on insertion, fire_act success on src fire_act, removal and extinguish.
 * Item parameter is optional
 */
/atom/movable/item_stack/proc/handle_burning_overlay(obj/item/item)
	if(item)
		var/item_uid = item.UID()
		var/item_resistances = item.resistance_flags
		if((item.loc == src) && (item_resistances & ON_FIRE))
			LAZYSET(burning_items, item_uid, TRUE)
		else
			LAZYREMOVE(burning_items, item_uid)

	if(!LAZYLEN(burning_items))
		cut_overlay(GLOB.fire_overlay)
		burning_overlay_applied = FALSE
		return

	if(burning_overlay_applied)
		return

	burning_overlay_applied = TRUE
	add_overlay(GLOB.fire_overlay)

/**
 * Handles applying and removing acid overlay of this stack.
 *
 * We handle acid overlay by looking on removal and acid_processing.
 * Item parameter is optional
 */
/atom/movable/item_stack/proc/handle_acid_overlay(obj/item/item)
	if(item)
		var/item_uid = item.UID()
		if((item.loc == src) && (item.acid_level > 0))
			LAZYSET(acid_items, item_uid, TRUE)
		else
			LAZYREMOVE(acid_items, item_uid)

	if(!LAZYLEN(acid_items))
		cut_overlay(GLOB.acid_overlay)
		acid_overlay_applied = FALSE
		return

	if(acid_overlay_applied)
		return

	acid_overlay_applied = TRUE
	add_overlay(GLOB.acid_overlay)

/// Signal proc called on item fire_act
/atom/movable/item_stack/proc/on_item_fire_act(obj/item/source, exposed_temperature, exposed_volume)
	SIGNAL_HANDLER
	handle_burning_overlay(source)

/// Signal proc called on item extinguish
/atom/movable/item_stack/proc/on_item_extinguish(obj/item/source)
	SIGNAL_HANDLER
	handle_burning_overlay(source)

/// Signal proc called on item acid processing
/atom/movable/item_stack/proc/on_item_acid_process(obj/item/source, acid_level)
	SIGNAL_HANDLER
	handle_acid_overlay(source)

// Fuck the person who named this proc by the way
// blob_vore_act all items
/atom/movable/item_stack/blob_vore_act(obj/structure/blob/special/core/voring_core)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.blob_vore_act(voring_core)
		stack_contents -= item
		CHECK_TICK

// blob_act all items
/atom/movable/item_stack/blob_act(obj/structure/blob/attacking_blob)
	. = ..()
	if(!.)
		return

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.blob_act(attacking_blob)
		stack_contents -= item
		CHECK_TICK

// fire_act all items
/atom/movable/item_stack/fire_act(exposed_temperature, exposed_volume)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		if(item.fire_act(exposed_temperature, exposed_volume))
			handle_burning_overlay(item)
		stack_contents -= item
		CHECK_TICK

// water_act all items
/atom/movable/item_stack/water_act(volume, temperature, source, method = REAGENT_TOUCH)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	// Maybe the stack will consist only of items that get deleted on water_act?
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.water_act(volume, temperature, source, method)
		stack_contents -= item
		CHECK_TICK

// Damage the last inserted item
/atom/movable/item_stack/bullet_act(obj/projectile/P, def_zone)
	. = ..()
	if(!.)
		return

	var/obj/item/last_inserted_item = contents[length(contents)]
	return last_inserted_item.bullet_act(P, def_zone)

// ex_act all items
/atom/movable/item_stack/ex_act(severity, target)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.ex_act(severity, target)
		stack_contents -= item
		CHECK_TICK

// emp_act all items
/atom/movable/item_stack/emp_act(severity)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.emp_act(severity)
		stack_contents -= item
		CHECK_TICK

// acid_act all items
/atom/movable/item_stack/acid_act(acidpwr, acid_volume)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.acid_act(acidpwr, acid_volume)
		stack_contents -= item
		CHECK_TICK

// fart_act all items
/atom/movable/item_stack/fart_act(mob/living/user)
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.fart_act(user)
		stack_contents -= item
		CHECK_TICK

// singularity_act all items
/atom/movable/item_stack/singularity_act()
	. = ..()

	// Copying contents since the stack gets qdel() if not enough items are present
	var/list/stack_contents = contents.Copy()
	for(var/obj/item/item as anything in stack_contents)
		item.singularity_act()
		stack_contents -= item
		CHECK_TICK

// Move the stack towards the singularity, mimicing item handling
/atom/movable/item_stack/singularity_pull(obj/singularity/S, current_size)
	. = ..()
	if(current_size >= STAGE_FOUR)
		throw_at(S, 14, 3, spin = 0)
		return

	step_towards(src, S)

#undef MINIMUM_ITEM_STACK_TURF_CONTENTS_REQUIREMENT
#undef ITEM_STACK_QDEL_THRESHOLD
#undef ITEM_STACK_OVERLAY_LIMIT
#undef ITEM_STACK_ITEM_OVERLAY_LAYER
