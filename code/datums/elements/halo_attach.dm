/// a simple halo attach element (for cult and his grace)
/datum/element/halo_attach


/datum/element/halo_attach/Attach(mob/living/carbon/target)
	. = ..()

	if(!istype(target))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(target, COMSIG_MOB_HALO_GAINED, PROC_REF(on_halo_gained), override = TRUE)


/datum/element/halo_attach/Detach(datum/target)
	. = ..()
	UnregisterSignal(target, COMSIG_MOB_HALO_GAINED)


///signal called by the stat of the target changing
/datum/element/halo_attach/proc/on_halo_gained(mob/living/carbon/target)
	SIGNAL_HANDLER

	target.remove_overlay(HALO_LAYER)
	var/mutable_appearance/new_halo_overlay

	if(iscultist(target) && SSticker.mode.cult_ascendant)
		var/istate = pick("halo1", "halo2", "halo3", "halo4", "halo5", "halo6")
		new_halo_overlay = mutable_appearance('icons/effects/32x64.dmi', istate, -HALO_LAYER)
	else if(isclocker(target) && SSticker.mode.crew_reveal)
		new_halo_overlay = mutable_appearance('icons/effects/32x64.dmi', "haloclock", -HALO_LAYER)
	else if(is_graceascended(target))
		new_halo_overlay = mutable_appearance('icons/effects/32x64.dmi', "toolbox_halo", -HALO_LAYER) //placeholder sprite, change
	else
		return

	new_halo_overlay.appearance_flags |= RESET_TRANSFORM
	target.overlays_standing[HALO_LAYER] = new_halo_overlay
	target.apply_overlay(HALO_LAYER)


