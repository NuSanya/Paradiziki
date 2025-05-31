GLOBAL_LIST_INIT(halo_overlays, list(
	"cult" = mutable_appearance('icons/effects/32x64.dmi', pick("halo1", "halo2", "halo3", "halo4", "halo5", "halo6"), -HALO_LAYER, appearance_flags = RESET_TRANSFORM),
	"clockwork" = mutable_appearance('icons/effects/32x64.dmi', "haloclock", -HALO_LAYER, appearance_flags = RESET_TRANSFORM),
	"his_grace" = mutable_appearance('icons/effects/32x64.dmi', "toolbox_halo", -HALO_LAYER, appearance_flags = RESET_TRANSFORM),
))

GLOBAL_LIST_INIT(halo_callbacks, list(
	"cult" = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(iscultist_ascended)),
	"clockwork" = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(isclocker_ascended)),
	"his_grace" = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(is_grace_ascended)),
))

/// bespoke halo attach element (for cult and his grace)
/datum/element/halo_attach
	element_flags = ELEMENT_BESPOKE|ELEMENT_DETACH_ON_HOST_DESTROY
	id_arg_index = 2
	var/mutable_appearance/halo_overlay
	// check for valid halo owner
	var/datum/callback/proc_callback


/datum/element/halo_attach/Attach(mob/living/carbon/target, mutable_appearance/overlay, datum/callback/callback)
	. = ..()

	if(!istype(target))
		return ELEMENT_INCOMPATIBLE

	halo_overlay = overlay
	proc_callback = callback

	RegisterSignal(target, COMSIG_MOB_HALO_GAINED, PROC_REF(on_halo_gained), override = TRUE)


/datum/element/halo_attach/Detach(mob/living/carbon/target)
	. = ..()

	target.remove_overlay(HALO_LAYER)
	UnregisterSignal(target, COMSIG_MOB_HALO_GAINED)


///signal called by the stat of the target changing
/datum/element/halo_attach/proc/on_halo_gained(mob/living/carbon/target)
	SIGNAL_HANDLER

	target.remove_overlay(HALO_LAYER)
	if(!proc_callback?.Invoke(target))
		return

	target.overlays_standing[HALO_LAYER] = halo_overlay
	target.apply_overlay(HALO_LAYER)


