// Camera mob, used by AI camera and blob.

/mob/camera
	name = "camera mob"
	density = FALSE
	move_force = INFINITY
	move_resist = INFINITY
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	see_in_dark = 8
	invisibility = 101  // No one can see us
	sight = SEE_SELF
	move_on_shuttle = FALSE

/mob/camera/Initialize(mapload)
	. = ..()
	ADD_TRAIT(src, TRAIT_GODMODE, UNIQUE_TRAIT_SOURCE(src))

/mob/camera/Destroy()
	REMOVE_TRAIT(src, TRAIT_GODMODE, UNIQUE_TRAIT_SOURCE(src))
	return ..()

/mob/camera/experience_pressure_difference(flow_x, flow_y)
	return // Immune to gas flow.

/mob/camera/forceMove(atom/destination)
	var/oldloc = loc
	loc = destination
	Moved(oldloc, NONE)

/mob/camera/move_up()
	set name = "Подняться"
	set category = STATPANEL_IC

	if(zMove(UP, z_move_flags = ZMOVE_FEEDBACK))
		to_chat(src, span_notice("Вы двигаетесь вверх."))

/mob/camera/move_down()
	set name = "Опуститься"
	set category = STATPANEL_IC

	if(zMove(DOWN, z_move_flags = ZMOVE_FEEDBACK))
		to_chat(src, span_notice("Вы двигаетесь вниз."))

/mob/camera/zMove(dir, turf/target, z_move_flags = NONE)
	. = ..()
	if(.)
		set_loc(loc)

/mob/camera/can_z_move(direction, turf/start, turf/destination, z_move_flags = NONE, mob/living/rider)
	z_move_flags |= ZMOVE_IGNORE_OBSTACLES  //cameras do not respect these FLOORS you speak so much of
	return ..()
