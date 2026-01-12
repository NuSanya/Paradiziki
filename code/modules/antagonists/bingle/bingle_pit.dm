/// Typecache list of things not allowed in bingle holes
GLOBAL_LIST_INIT(bingle_hole_blacklist, typecacheof(list(
	/mob/living/simple_animal/hostile/bingle,
	/obj/effect,
	/obj/projectile,
	/obj/structure/bingle_hole,
	/obj/structure/bingle_pit_overlay,
	/obj/item/stack/spacechips,
	/obj/item/stack/spacecash,
	)
))

/obj/structure/bingle_hole
	name = "bingle pit"
	desc = "Всепоглощающая бездна бесконечных ужасов... и Бинглов."
	gender = FEMALE
	armor = list(MELEE=20, BULLET=20, LASER=75, ENERGY=75, BOMB=75, BIO=100, RAD=100, FIRE=50, ACID=80)
	max_integrity = 500
	icon = 'icons/mob/bingle/binglepit.dmi'
	icon_state = "binglepit"
	light_color = LIGHT_COLOR_BABY_BLUE
	light_range = 5
	anchored = TRUE
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	/// The bingle pit turf reservation. Used for getting things in and out
	var/datum/turf_reservation/pit_reservation
	/// List of all bingle turfs used in pit reservation
	var/list/inside_pit_turfs = list()
	/// Values of all consumed items combined
	var/item_value_consumed = 0
	/// Current pit size (1x1, 2x2, etc.)
	var/current_pit_size = 1
	/// List of all used pit overlays
	var/list/pit_overlays = list()
	/// Used to compare current and last item values for bingle spawning in processing
	var/last_bingle_spawn_value = 0
	/// We store the component in order to increase it's range later
	var/datum/component/aura_healing/aura_healing
	/// Antag team datum used for sending signals to
	var/datum/team/bingles/bingle_team
	/// Connect loc element
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON = PROC_REF(on_entered),
	)
	/// Cooldown for taking bomb damage - basically a cheat solution to handle it taking damage for each tile from one bomb.
	COOLDOWN_DECLARE(bomb_cooldown)
	/// Have we evolved our current bingles or not
	var/bingles_evolved

/obj/structure/bingle_hole/get_ru_names()
	return list(
		NOMINATIVE = "яма Бинглов",
		GENITIVE = "ямы Бинглов",
		DATIVE = "яме Бинглов",
		ACCUSATIVE = "яму Бинглов",
		INSTRUMENTAL = "ямой Бинглов",
		PREPOSITIONAL = "яме Бинглов"
	)

/obj/structure/bingle_hole/Initialize(mapload)
	..()
	bingle_team = GLOB.antagonist_teams[/datum/team/bingles]
	if(!bingle_team)
		bingle_team = new
	SEND_SIGNAL(bingle_team, COMSIG_BINGLE_HOLE_INITIALIZED, src)
	START_PROCESSING(SSbingle_pit, src)
	AddElement(/datum/element/connect_loc, loc_connections)
	return INITIALIZE_HINT_LATELOAD

/obj/structure/bingle_hole/ComponentInitialize()
	. = ..()
	aura_healing = AddComponent( \
		/datum/component/aura_healing, \
		range = 3, \
		simple_heal = 5, \
		limit_to_trait = TRAIT_HEALS_FROM_BINGLE_HOLES, \
		healing_color = COLOR_BLUE_LIGHT, \
		requires_visibility = FALSE, \
	)

/obj/structure/bingle_hole/LateInitialize()
	pit_reservation = SSmapping.lazy_load_template(LAZY_TEMPLATE_KEY_BINGLE_PIT, TRUE) // Separate insides for different holes
	log_game("Bingle Pit Template loaded.")

/obj/structure/bingle_hole/Destroy()
	QDEL_NULL(aura_healing)
	QDEL_LIST(pit_overlays)
	STOP_PROCESSING(SSbingle_pit, src)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(eject_bingle_pit_contents), get_turf(src), current_pit_size, pit_reservation)
	bingle_team = null
	pit_reservation = null
	inside_pit_turfs = null
	return ..()

/obj/structure/bingle_hole/examine(mob/user)
	. = ..()
	if(isbingle(user))
		. += span_alert("Внутри находится <b>[item_value_consumed]</b> предмет[DECL_CREDIT(item_value_consumed)]!")
		. += span_notice("Существа смогут упасть туда, если в яме будет минимум <b>[BINGLE_PIT_GROW_VALUE]</b> предмет[declension_ru(BINGLE_PIT_GROW_VALUE, "", "а", "ов")]!")

/obj/structure/bingle_hole/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	if(!pass_info.is_living)
		return TRUE
	if(isbingle(pass_info.requester_ref?.resolve()))
		return TRUE
	if(pass_info.thrown || pass_info.incorporeal_move)
		return TRUE
	if(!pass_info.incapacitated)
		if(!pass_info.gravity)
			return TRUE
		if(pass_info.movement_type & (FLYING | FLOATING))
			return TRUE
	return FALSE

/obj/structure/bingle_hole/attack_animal(mob/living/simple_animal/user)
	if(isbingle(user))
		to_chat(user, span_warning("Вы отказываетесь ломать ваше святилище!"))
		user.balloon_alert(user, "атака невозможна!")
		return TRUE
	return ..()

/obj/structure/bingle_hole/ex_act(severity)
	severity = min(severity, EXPLODE_HEAVY)
	if(!COOLDOWN_FINISHED(src, bomb_cooldown))
		return FALSE
	COOLDOWN_START(src, bomb_cooldown, 2 SECONDS)
	return ..()

/obj/structure/bingle_hole/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	swallow(arrived) // swallow does all the needed checks

/obj/structure/bingle_hole/process(seconds_per_tick)
	// Only spawn a new bingle for each BINGLE_SPAWN_VALUE item value milestone, and only once per milestone
	// Calculate how many bingles should exist based on current item value
	var/target_bingle_count = round(item_value_consumed / BINGLE_SPAWN_VALUE)
	var/current_bingle_count = round(last_bingle_spawn_value / BINGLE_SPAWN_VALUE)

	// If we need more bingles, spawn one
	if(target_bingle_count > current_bingle_count)
		last_bingle_spawn_value = target_bingle_count * BINGLE_SPAWN_VALUE
		INVOKE_ASYNC(src, PROC_REF(spawn_bingle_from_ghost))

	// Pit grows every BINGLE_PIT_GROW_VALUE item value - calculate target size
	var/desired_pit_size = 1 + round(item_value_consumed / BINGLE_PIT_GROW_VALUE)
	desired_pit_size = min(desired_pit_size, BINGLE_PIT_SIZE_GOAL)

	if(desired_pit_size > current_pit_size)
		grow_pit(desired_pit_size)

	if(bingles_evolved)
		return

	if(item_value_consumed < BINGLE_EVOLVE_VALUE)
		return

	bingles_evolved = TRUE
	SEND_SIGNAL(bingle_team, COMSIG_MASS_BINGLE_EVOLVE, src)

/obj/structure/bingle_hole/proc/swallow_mob(mob/living/victim)
	if(!isliving(victim))
		return FALSE
	if(victim.buckled) // you'll fall in once your buddy falls in
		return FALSE
	if(victim.incorporeal_move)
		return FALSE
	if(victim.body_position == STANDING_UP)
		if(!victim.get_gravity(get_turf(victim)))
			return FALSE
		if(victim.movement_type & (FLYING | FLOATING))
			return FALSE

	if(item_value_consumed < BINGLE_PIT_GROW_VALUE)
		var/turf/target = get_edge_target_turf(src, pick(GLOB.alldirs))
		victim.throw_at(target, rand(1, 5), rand(1, 5))
		to_chat(victim, span_warning("Вы не пролезаете в яму!"))
		return FALSE
	victim.add_traits(list(TRAIT_FALLING_INTO_BINGLE_HOLE, TRAIT_NO_TRANSFORM), UNIQUE_TRAIT_SOURCE(src))
	item_value_consumed += get_item_value(victim)
	repair_damage(BINGLE_PIT_LIVING_HEAL_MULTIPLIER * BINGLE_PIT_LIVING_VALUE)
	// Only animate if we're actually swallowing
	animate_falling_into_pit(victim)
	// Delay the actual movement to let animation play
	addtimer(CALLBACK(src, PROC_REF(finish_swallow_mob), victim), 1 SECONDS)
	return TRUE

/obj/structure/bingle_hole/proc/get_item_value(thing)
	if(isliving(thing))
		return BINGLE_PIT_LIVING_VALUE
	else if(isstack(thing))
		var/obj/item/stack/stack = thing
		return min(stack.amount, BINGLE_PIT_STACK_GAIN_LIMIT)
	return 1

/obj/structure/bingle_hole/proc/swallow_obj(obj/thing)
	if(!isobj(thing))
		return FALSE
	ADD_TRAIT(thing, TRAIT_FALLING_INTO_BINGLE_HOLE, UNIQUE_TRAIT_SOURCE(src))
	item_value_consumed += get_item_value(thing)
	for(var/atom/movable/content as anything in thing.get_all_contents() - thing)
		if(QDELETED(content) || HAS_TRAIT(content, TRAIT_FALLING_INTO_BINGLE_HOLE) || isbrain(content))
			continue
		if(isliving(content) || is_type_in_typecache(content, GLOB.bingle_hole_blacklist))
			content.forceMove(content.drop_location())
		else if(isobj(content))
			item_value_consumed += get_item_value(content)
	// Only animate if we're actually swallowing
	animate_falling_into_pit(thing)
	// Delay the actual movement to let animation play
	addtimer(CALLBACK(src, PROC_REF(finish_swallow_obj), thing), 1 SECONDS)
	return TRUE

/obj/structure/bingle_hole/proc/swallow(atom/movable/item)
	if(QDELETED(src) || QDELETED(item) || item == src)
		return
	if(is_type_in_typecache(item, GLOB.bingle_hole_blacklist))
		return
	if(HAS_TRAIT(item, TRAIT_FALLING_INTO_BINGLE_HOLE) || HAS_TRAIT(item, TRAIT_NO_TRANSFORM))
		return
	if(item.throwing && item.throwing.target_turf != loc) // you can throw things over the pit
		return
	if(swallow_mob(item) || swallow_obj(item))
		item.pulledby?.stop_pulling()
		item.stop_pulling()
		item.unbuckle_all_mobs()

/obj/structure/bingle_hole/proc/animate_falling_into_pit(atom/movable/item)
	var/turf/item_turf = get_turf(item)
	var/turf/pit_turf = get_turf(src)

	if(isnull(item_turf) || isnull(pit_turf))
		return

	// Create visual effects
	playsound(item_turf, 'sound/effects/gravhit.ogg', 50, TRUE)

	var/original_px = item.pixel_x
	var/original_py = item.pixel_y
	var/original_alpha = item.alpha

	// Make the item spin and shrink as it falls toward the center
	var/original_transform = matrix(item.transform)

	// Calculate movement toward pit center
	var/dx = pit_turf.x - item_turf.x
	var/dy = pit_turf.y - item_turf.y

	// Animate the item moving toward pit center while spinning and shrinking
	animate(item, pixel_x = dx * world.icon_size, pixel_y = dy * world.icon_size, transform = turn(original_transform, 360) * 0.3, alpha = 100, time = 0.8 SECONDS, easing = EASE_IN)

	// Final disappear animation
	animate(transform = turn(original_transform, 720) * 0.1, alpha = 0, time = 0.2 SECONDS, easing = EASE_IN)

	// and ensure they animate back to normal afterwards
	animate(pixel_x = original_px, pixel_y = original_py, alpha = original_alpha, transform = original_transform, time = 0.5 SECONDS, easing = EASE_IN)

/obj/structure/bingle_hole/proc/finish_swallow_mob(mob/living/swallowed_mob)
	if(QDELETED(swallowed_mob))
		return

	var/turf/bingle_pit_turf = get_random_bingle_pit_turf()
	if(bingle_pit_turf)
		swallowed_mob.forceMove(bingle_pit_turf)
		swallowed_mob.remove_traits(list(TRAIT_FALLING_INTO_BINGLE_HOLE, TRAIT_NO_TRANSFORM), UNIQUE_TRAIT_SOURCE(src))
	else
		if(swallowed_mob.client || swallowed_mob.mind)
			swallowed_mob.moveToNullspace()
		else
			qdel(swallowed_mob)

/obj/structure/bingle_hole/proc/finish_swallow_obj(obj/swallowed_obj)
	if(QDELETED(swallowed_obj))
		return

	var/turf/bingle_pit_turf = get_random_bingle_pit_turf()
	if(bingle_pit_turf)
		swallowed_obj.forceMove(bingle_pit_turf)
		REMOVE_TRAIT(swallowed_obj, TRAIT_FALLING_INTO_BINGLE_HOLE, UNIQUE_TRAIT_SOURCE(src))
	else
		qdel(swallowed_obj)

/obj/structure/bingle_hole/proc/grow_pit(new_size)
	if(current_pit_size >= new_size)
		return
	var/turf/origin = get_turf(src)
	if(!origin)
		return

	// Calculate coordinates properly for both even and odd sizes
	var/start_coord, end_coord
	if(new_size % 2 == 1) // Odd sizes (1, 3, 5, etc.)
		var/half = (new_size - 1) / 2
		start_coord = -half
		end_coord = half
	else // Even sizes (2, 4, 6, etc.)
		var/half = new_size / 2
		start_coord = -(half - 1)
		end_coord = half

	for(var/dx = start_coord to end_coord)
		for(var/dy = start_coord to end_coord)
			var/turf/T = locate(origin.x + dx, origin.y + dy, origin.z)
			if(!T)
				continue

			var/icon_state_to_use
			if(dx == start_coord)
				if(dy == end_coord)
					icon_state_to_use = "corner_north"      // top left
				else if(dy == start_coord)
					icon_state_to_use = "corner_east"       // bottom left
				else
					icon_state_to_use = "edge_west"         // edge left
			else if(dx == end_coord)
				if(dy == end_coord)
					icon_state_to_use = "corner_west"       // top right
				else if(dy == start_coord)
					icon_state_to_use = "corner_south"      // bottom right
				else
					icon_state_to_use = "edge_east"         // edge right
			// Edges (check single conditions)
			else if(dy == end_coord)
				icon_state_to_use = "edge_north"        // top edge
			else if(dy == start_coord)
				icon_state_to_use = "edge_south"        // bottom edge
			// Center fill
			else
				icon_state_to_use = "filler[rand(1, 4)]"

			var/obj/structure/bingle_pit_overlay/overlay = locate() in T
			if(!overlay)
				overlay = new(T, src)
				pit_overlays += overlay

			if(overlay.parent_pit != src)
				INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(merge_bingle_holes), src, overlay.parent_pit)
				return

			overlay.icon_state = icon_state_to_use

			// If pit is larger than 3x3, consume walls on these tiles
			if(new_size > 3)
				for(var/obj/thing in T)
					if(thing.density && isstructure(thing) && !istype(thing, /obj/structure/bingle_pit_overlay))
						swallow(thing)
				// Remove wall turf itself, if present
				if(iswallturf(T))
					T.dismantle_wall(TRUE)

	var/size_difference = new_size - current_pit_size
	SEND_SIGNAL(src, COMSIG_BINGLE_HOLE_GROW, current_pit_size, new_size)
	current_pit_size = new_size
	aura_healing.range = new_size + 2
	max_integrity += size_difference * BINGLE_PIT_GROW_INTEGRITY_INCREASE
	repair_damage(size_difference * BINGLE_PIT_GROW_INTEGRITY_INCREASE)

/obj/structure/bingle_pit_overlay
	name = "bingle pit"
	desc = "Что-то словно манит вас прыгнуть туда..."
	icon = 'icons/mob/bingle/binglepit.dmi'
	layer = BELOW_OBJ_LAYER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	var/obj/structure/bingle_hole/parent_pit

/obj/structure/bingle_pit_overlay/get_ru_names()
	return list(
		NOMINATIVE = "яма Бинглов",
		GENITIVE = "ямы Бинглов",
		DATIVE = "яме Бинглов",
		ACCUSATIVE = "яму Бинглов",
		INSTRUMENTAL = "ямой Бинглов",
		PREPOSITIONAL = "яме Бинглов"
	)

/obj/structure/bingle_pit_overlay/Initialize(mapload, obj/structure/bingle_hole/parent_pit)
	. = ..()
	if(!parent_pit)
		stack_trace("Bingle pit overlay created without parent pit.")
		qdel(src)
		return
	var/static/list/loc_connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_entered),
		COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZED_ON = PROC_REF(on_entered),
	)
	AddElement(/datum/element/connect_loc, loc_connections)
	src.parent_pit = parent_pit

/obj/structure/bingle_pit_overlay/Destroy()
	parent_pit?.pit_overlays -= src
	parent_pit = null
	return ..()

/obj/structure/bingle_pit_overlay/CanAStarPass(to_dir, datum/can_pass_info/pass_info)
	return parent_pit.CanAStarPass(to_dir, pass_info)

/obj/structure/bingle_pit_overlay/proc/on_entered(datum/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!QDELETED(src))
		parent_pit.on_entered(source, arrived)

/obj/structure/bingle_pit_overlay/ex_act(severity)
	return parent_pit.ex_act(severity)

/obj/structure/bingle_pit_overlay/attackby(obj/item/W, mob/user, params)
	if(parent_pit)
		user.do_attack_animation(src) // hacky but well
		return parent_pit.attackby(W, user, params)

	return ..()

/obj/structure/bingle_pit_overlay/attack_hand(mob/user)
	if(parent_pit)
		return parent_pit.attack_hand(user)

	return ..()

/obj/structure/bingle_pit_overlay/attack_animal(mob/living/simple_animal/user)
	if(isbingle(user))
		to_chat(user, span_warning("Вы отказываетесь ломать ваше святилище!"))
		user.balloon_alert(user, "атака невозможна!")
		return TRUE
	if(parent_pit)
		return parent_pit.attack_animal(user)

	return ..()

/obj/structure/bingle_pit_overlay/take_damage(amount, type, source, flags)
	if(isbingle(source))
		return FALSE // No damage from bingles
	if(parent_pit)
		return parent_pit.take_damage(amount, type, source, flags)

	return ..()

/obj/structure/bingle_pit_overlay/bullet_act(obj/projectile/projectile)
	if(parent_pit)
		return parent_pit.bullet_act(projectile)

	return ..()

/obj/structure/bingle_pit_overlay/examine(mob/user)
	. = ..()
	if(parent_pit && isbingle(user))
		. += span_alert("Внутри находится <b>[parent_pit.item_value_consumed]</b> предмет[DECL_CREDIT(parent_pit.item_value_consumed)]!")
		. += span_notice("Существа смогут упасть туда, если в яме будет минимум <b>[BINGLE_PIT_GROW_VALUE]</b> предмет[declension_ru(BINGLE_PIT_GROW_VALUE, "", "а", "ов")]!")

/// Update the spawn proc to ensure proper tracking
/obj/structure/bingle_hole/proc/spawn_bingle_from_ghost()
	var/image/poll_source = image('icons/mob/bingle/bingles.dmi', "bingle")
	var/list/mob/dead/observer/candidates = SSghost_spawns.poll_candidates("Хотите сыграть за Бингла?", ROLE_BINGLE, TRUE, poll_time = 10 SECONDS, source = poll_source)

	if(!length(candidates))
		return

	var/mob/dead/observer/candidate = pick_n_take(candidates)
	var/turf/spawn_loc = get_turf(src) // Use the pit's location
	if(isnull(spawn_loc))
		return

	var/mob/living/simple_animal/hostile/bingle/bingle = new(spawn_loc, src)
	bingle.possess_by_player(candidate.key)
	bingle.add_datum_if_not_exist()
	if(item_value_consumed >= BINGLE_EVOLVE_VALUE)
		SEND_SIGNAL(bingle, COMSIG_BINGLE_EVOLVE)

	message_admins("[ADMIN_LOOKUPFLW(bingle)] has been made into Bingle (pit spawn).")
	log_game("[key_name(bingle)] was spawned as Bingle by the pit.")

/obj/structure/bingle_hole/proc/get_random_bingle_pit_turf()
	if(!length(inside_pit_turfs))
		for(var/turf/simulated/floor/indestructible/bingle/floor in pit_reservation?.reserved_turfs)
			if(!floor.is_blocked_turf())
				inside_pit_turfs += floor

	if(length(inside_pit_turfs)) // Incase we haven't loaded the pit yet
		return pick(inside_pit_turfs)

/area/misc/bingle_pit
	name = "Яма Бинглов"
	area_flags = UNIQUE_AREA
	has_gravity = TRUE
	requires_power = FALSE

/**
 * Proc used to eject everything from inside from bingle hole
 *
 * Range can be specified to spread out objects (to lessen client render lag)
 */
/proc/eject_bingle_pit_contents(turf/target_turf, range = 1, datum/turf_reservation/pit_reservation)
	if(!target_turf)
		return
	var/list/turfs_in_range = RANGE_TURFS(range, target_turf)
	// We dont use area since there are separate locations for separate holes. Instead, we check reservation turfs saved from template loading
	for(var/turf/turf as anything in pit_reservation?.reserved_turfs)
		for(var/atom/movable/thing in turf)
			if(QDELETED(thing))
				continue
			var/turf/eject_to = pick(turfs_in_range)
			thing.forceMove(eject_to)
			thing.SpinAnimation(5, 1)
			CHECK_TICK

	qdel(pit_reservation)

/**
 * Proc used to merge bingle holes
 *
 * Reassigns all bingle mobs to the kept hole,
 * Moves all items from the turf reservation to the kept one,
 * Sums up some variables,
 * and finally deletes the to be removed hole.
 */
/proc/merge_bingle_holes(obj/structure/bingle_hole/first_hole, obj/structure/bingle_hole/second_hole)
	STOP_PROCESSING(SSbingle_pit, first_hole) // Prevent them from growing while merging
	STOP_PROCESSING(SSbingle_pit, second_hole)
	var/obj/structure/bingle_hole/hole_to_keep
	var/obj/structure/bingle_hole/hole_to_destroy
	if(first_hole.current_pit_size >= second_hole.current_pit_size)
		hole_to_keep = first_hole
		hole_to_destroy = second_hole
	else
		hole_to_keep = second_hole
		hole_to_destroy = first_hole

	// Reassign bingles of to remove hole to the kept one
	if(LAZYACCESS(GLOB.bingles_by_hole, hole_to_destroy.UID()))
		for(var/mob/living/simple_animal/hostile/bingle/bingle as anything in GLOB.bingles_by_hole[hole_to_destroy.UID()])
			LAZYADDASSOCLIST(GLOB.bingles_by_hole, hole_to_keep.UID(), bingle)
			bingle.spawn_hole = hole_to_keep
		GLOB.bingles_by_hole -= hole_to_destroy.UID()

	// Move everything from the destroyed hole to the new one
	for(var/turf/turf as anything in hole_to_destroy.pit_reservation?.reserved_turfs)
		for(var/atom/movable/thing in turf)
			if(QDELETED(thing))
				continue
			var/turf/eject_to = hole_to_keep.get_random_bingle_pit_turf()
			thing.forceMove(eject_to)

	// Some var sums
	hole_to_keep.last_bingle_spawn_value += hole_to_destroy.last_bingle_spawn_value
	hole_to_keep.item_value_consumed += hole_to_destroy.item_value_consumed

	START_PROCESSING(SSbingle_pit, hole_to_keep)
	qdel(hole_to_destroy)
