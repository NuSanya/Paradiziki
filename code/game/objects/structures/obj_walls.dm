// nuSanya -> rethink this later
/*
 * Structure walls
 *
 * Basically a wall (bad wall), but can be damaged with items, projectiles and etc.
 * You should use this ONLY for the reasons above.
 */
/obj/structure/wall
	name = "wall"
	desc = "A huge chunk of metal used to seperate rooms."
	anchored = TRUE
	icon = 'icons/turf/walls/wall.dmi'
	icon_state = "wall-0"
	base_icon_state = "wall"

	density = TRUE
	obj_flags = BLOCK_Z_IN_DOWN | BLOCK_Z_IN_UP
	opacity = TRUE
	max_integrity = 100

	canSmoothWith = SMOOTH_GROUP_WALLS
	smoothing_groups = SMOOTH_GROUP_WALLS
	smooth = SMOOTH_BITMASK

	/// Mineral this wall is made of
	var/mineral = /obj/item/stack/sheet/metal
	/// Amount of minerals this wall is made of
	var/mineral_amount = 2
	/// What girder "drops" on deconstruction
	var/girder_type = /obj/structure/girder

	/// Can we dismantle this wall with welder?
	var/can_dismantle_with_welder = TRUE
	/// How long does it take to dismantle this wall
	var/slicing_duration = 10 SECONDS

/obj/structure/wall/Initialize(mapload)
	. = ..()
	air_update_turf(1)

/obj/structure/wall/examine_status(mob/user)
	var/healthpercent = (obj_integrity/max_integrity) * 100
	switch(healthpercent)
		if(100)
			. = span_notice("Выглядит полностью целой.")
		if(70 to 99)
			. =  span_warning("Выглядит слегка повреждённой.")
		if(40 to 70)
			. =  span_warning("Выглядит умеренно повреждённой.")
		if(0 to 40)
			. = span_danger("Выглядит сильно повреждённой.")
	if(can_dismantle_with_welder)
		. += span_notice("<br>Использование сварочного инструмента на этой стене позволит вам разрезать её, в конечном итоге удалив внешний слой.")

/obj/structure/wall/ratvar_act()
	new /turf/simulated/wall/clockwork(loc)
	qdel(src)

/obj/structure/wall/narsie_act()
	new /turf/simulated/wall/cult(loc)
	qdel(src)

/obj/structure/wall/Destroy()
	air_update_turf(1)
	return ..()

/obj/structure/wall/attackby(obj/item/I, mob/user, params)
	var/static/list/dismantle_typecache = typecacheof(list(
		/obj/item/gun/energy/plasmacutter,
		/obj/item/pickaxe/drill/diamonddrill,
		/obj/item/pickaxe/drill/jackhammer,
		/obj/item/melee/energy/blade,
		/obj/item/twohanded/required/pyro_claws,
	))
	if(!is_type_in_typecache(I, dismantle_typecache))
		return ..()
	if(!do_after(user, slicing_duration / 2, src, max_interact_count = 1))
		return ..()

	dismantle(user, TRUE)
	return ATTACK_CHAIN_BLOCKED_ALL

/obj/structure/wall/welder_act(mob/user, obj/item/I)
	if(!can_dismantle_with_welder)
		return
	if(!I.use_tool(src, user, slicing_duration, volume = I.tool_volume))
		return
	dismantle(user, TRUE)

/obj/structure/wall/proc/dismantle(mob/user, disassembled = TRUE)
	user.visible_message(span_notice("[user] разбирает стену."), span_warning("Вы разбираете стену."))
	playsound(src, 'sound/items/welder.ogg', 100, TRUE)
	deconstruct(disassembled)

/obj/structure/wall/deconstruct(disassembled = TRUE)
	if(!(obj_flags & NODECONSTRUCT))
		if(disassembled)
			new girder_type(loc)
		if(mineral_amount)
			for(var/i in 1 to mineral_amount)
				new mineral(loc)
	qdel(src)

/obj/structure/wall/rcd_deconstruct_act(mob/living/user, obj/item/rcd/our_rcd)
	. = ..()
	if(!our_rcd.checkResource(5, user))
		user.balloon_alert(user, "недостаточно вещества!")
		playsound(get_turf(our_rcd), 'sound/machines/click.ogg', 50, TRUE)
		return RCD_ACT_FAILED

	user.balloon_alert(user, "разбираем...")
	playsound(get_turf(our_rcd), 'sound/machines/click.ogg', 50, TRUE)
	if(!do_after(user, 4 SECONDS * our_rcd.toolspeed, src, category = DA_CAT_TOOL))
		user.balloon_alert(user, "сбито!")
		return RCD_ACT_FAILED
	if(!our_rcd.useResource(5, user))
		return RCD_ACT_FAILED
	user.balloon_alert(user, "разобрано!")
	playsound(get_turf(our_rcd), our_rcd.usesound, 50, TRUE)
	add_attack_logs(user, src, "Deconstructed structure wall with RCD")
	qdel(src)
	return RCD_ACT_SUCCESSFULL
