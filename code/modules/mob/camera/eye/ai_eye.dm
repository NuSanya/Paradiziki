/mob/camera/eye/ai
	name = "Inactive AI Eye"
	icon = 'icons/mob/ai.dmi'
	icon_state = "eye"
	var/mob/living/silicon/ai/ai = null

/mob/camera/eye/ai/Initialize(mapload, owner_name, camera_origin, mob/living/user)
	. = ..()
	ai = user
	if(is_ai_eye(ai.eyeobj))
		stack_trace("Tried to create an AI Eye for [user], but there is one already assigned")
		return INITIALIZE_HINT_QDEL
	name = "[owner_name] (AI Eye)"

/// Ensures that the user's perspective is on this eye (instead of, for example, a mech or hologram eye) and
/// updates parallax
/mob/camera/eye/ai/set_loc(T)
	..()
	user.reset_perspective(src)
	update_parallax_contents()

/// Cancels the camera's follow target if tracking has stopped, and lights up nearby lights if the AI has
/// "Toggle Camera Lights" enabled
/mob/camera/eye/ai/relaymove(mob/user, direct)
	..()
	if(!ai.tracking)
		ai.camera_follow = null
	if(ai.camera_light_on)
		ai.light_cameras()
