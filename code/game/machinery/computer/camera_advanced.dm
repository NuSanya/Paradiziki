/obj/machinery/computer/camera_advanced
	name = "advanced camera console"
	desc = "Используется для доступа к различным камерам, установленным на станции."
	icon_screen = "cameras"
	icon_keyboard = "security_key"
	var/mob/camera/eye/eyeobj
	var/mob/living/carbon/human/current_user = null
	var/list/networks = list("SS13")
	var/datum/action/innate/camera_off/off_action = new
	var/datum/action/innate/camera_jump/jump_action = new
	var/datum/action/innate/camera_multiz_up/move_up_action = new
	var/datum/action/innate/camera_multiz_down/move_down_action = new
	var/list/actions = list()

/obj/machinery/computer/camera_advanced/proc/CreateEye()
	eyeobj = new /mob/camera/eye/syndicate(loc, name, src, current_user)
	give_eye_control(current_user)

/obj/machinery/computer/camera_advanced/proc/GrantActions(mob/living/user)
	if(off_action)
		off_action.target = user
		off_action.Grant(user)
		actions += off_action

	if(jump_action)
		jump_action.target = user
		jump_action.Grant(user)
		actions += jump_action

	if(move_up_action)
		move_up_action.target = user
		move_up_action.Grant(user)
		actions += move_up_action

	if(move_down_action)
		move_down_action.target = user
		move_down_action.Grant(user)
		actions += move_down_action

/obj/machinery/computer/camera_advanced/proc/RemoveActions()
	if(!istype(current_user))
		return
	for(var/V in actions)
		var/datum/action/A = V
		A.Remove(current_user)
	actions.Cut()

/obj/machinery/computer/camera_advanced/proc/remove_eye_control(mob/living/user)
	if(!istype(user) || user != current_user)
		return
	RemoveActions()
	eyeobj.release_control()
	current_user = null
	remove_eye_control(user)
	playsound(src, 'sound/machines/terminal_off.ogg', 25, 0)

/obj/machinery/computer/camera_advanced/check_eye(mob/user)
	if((stat & (NOPOWER|BROKEN)) || (!Adjacent(user) && !user.has_unlimited_silicon_privilege) || !user.has_vision() || user.incapacitated())
		user.unset_machine()

/obj/machinery/computer/camera_advanced/Destroy()
	if(current_user)
		current_user.unset_machine()
	QDEL_NULL(eyeobj)
	QDEL_LIST(actions)
	return ..()

/obj/machinery/computer/camera_advanced/on_unset_machine(mob/M)
	if(M == current_user)
		remove_eye_control(M)

/obj/machinery/computer/camera_advanced/attack_hand(mob/user)
	if(current_user)
		to_chat(user, "The console is already in use!")
		return
	if(!iscarbon(user))
		return
	if(..())
		return
	user.set_machine(src)

	if(!eyeobj)
		CreateEye()
	else
		give_eye_control(user)
		eyeobj.set_loc(get_turf(eyeobj.loc))


/obj/machinery/computer/camera_advanced/proc/give_eye_control(mob/user)
	eyeobj.give_control(user)
	GrantActions(user)

/datum/action/innate/camera_off
	name = "Закрыть обзор камеры"
	button_icon_state = "camera_off"

/datum/action/innate/camera_off/Activate()
	if(!target || !iscarbon(target))
		return
	var/mob/living/carbon/C = target
	var/mob/camera/eye/syndicate/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/console = remote_eye.origin
	console.remove_eye_control(target)

/datum/action/innate/camera_jump
	name = "Переключиться на камеру"
	button_icon_state = "camera_jump"

/datum/action/innate/camera_jump/Activate()
	if(!target || !iscarbon(target))
		return
	var/mob/living/carbon/C = target
	var/mob/camera/eye/syndicate/remote_eye = C.remote_control
	var/obj/machinery/computer/camera_advanced/origin = remote_eye.origin

	var/list/L = list()

	for(var/obj/machinery/camera/cam in GLOB.cameranet.cameras)
		L.Add(cam)

	camera_sort(L)

	var/list/T = list()

	for(var/obj/machinery/camera/netcam in L)
		var/list/tempnetwork = netcam.network&origin.networks
		if(length(tempnetwork))
			T[text("[][]", netcam.c_tag, (netcam.can_use() ? null : " (Deactivated)"))] = netcam


	playsound(origin, 'sound/machines/terminal_prompt.ogg', 25, FALSE)
	var/camera = tgui_input_list(target, "Choose which camera you want to view", "Cameras", T)
	var/obj/machinery/camera/final = T[camera]
	playsound(origin, SFX_TERMINAL_TYPE, 25, FALSE)
	if(final)
		playsound(origin, 'sound/machines/terminal_prompt_confirm.ogg', 25, FALSE)
		remote_eye.set_loc(get_turf(final))
		C.overlay_fullscreen("flash", /atom/movable/screen/fullscreen/flash/noise)
		C.clear_fullscreen("flash", 3) //Shorter flash than normal since it's an ~~advanced~~ console!
	else
		playsound(origin, 'sound/machines/terminal_prompt_deny.ogg', 25, FALSE)

/datum/action/innate/camera_multiz_up
	name = "На этаж выше"
	button_icon_state = "move_up"

/datum/action/innate/camera_multiz_up/Activate()
	if(!owner || !isliving(owner))
		return
	var/mob/camera/eye/syndicate/remote_eye = owner.remote_control
	if(remote_eye.zMove(UP))
		to_chat(owner, span_notice("Вы поднимаетесь выше."))
	else
		to_chat(owner, span_notice("Не удалось подняться!"))

/datum/action/innate/camera_multiz_down
	name = "На этаж ниже"
	button_icon_state = "move_down"

/datum/action/innate/camera_multiz_down/Activate()
	if(!owner || !isliving(owner))
		return
	var/mob/camera/eye/syndicate/remote_eye = owner.remote_control
	if(remote_eye.zMove(DOWN))
		to_chat(owner, span_notice("Вы опускаетесь ниже."))
	else
		to_chat(owner, span_notice("Не удалось опуститься!"))
