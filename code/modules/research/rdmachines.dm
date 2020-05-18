//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:33

//All devices that link into the R&D console fall into thise type for easy identification and some shared procs.

//	TODO - Leshana - Remove these.  Just so it compiles for now.
/obj/machinery/r_n_d
	var/list/materials = list()		// Materials this machine can accept.
	var/list/hidden_materials = list()	// Materials this machine will not display, unless it contains them. Must be in the materials list as well.


/obj/machinery/rnd
	name = "R&D Device"
	icon = 'icons/obj/machines/research_vr.dmi' //VOREStation Edit - Replaced with Eris sprites
	density = TRUE
	anchored = TRUE
	use_power = USE_POWER_IDLE
	var/datum/wires/rnd/wires = null
	var/busy = FALSE
	var/hacked = FALSE
	var/console_link = TRUE		//allow console link.
	var/requires_console = TRUE
	var/disabled = FALSE
	var/obj/machinery/computer/rdconsole/linked_console
	var/obj/item/loaded_item = null //the item loaded inside the machine (currently only used by experimentor and destructive analyzer)


/obj/machinery/rnd/proc/reset_busy()
	busy = FALSE

/obj/machinery/rnd/Initialize()
	. = ..()
	wires = new /datum/wires/rnd(src)

/obj/machinery/rnd/Destroy()
	QDEL_NULL(wires)
	return ..()

/obj/machinery/rnd/update_icon()
	. = ..()
	icon_state = panel_open ? "[initial(icon_state)]_t" : initial(icon_state)

/obj/machinery/rnd/attackby(obj/item/O, mob/user)
	if(busy)
		to_chat(user, "<span class='warning'>[src] is busy right now.</span>")
		return TRUE
	if(default_deconstruction_screwdriver(user, O))
		if(linked_console)
			disconnect_console()
		return
	if(default_deconstruction_crowbar(user, O))
		return
	if(default_part_replacement(user, O))
		return
	if(panel_open && is_wire_tool(O))
		wires.Interact(user)
		return TRUE
	if(reagents && O.is_open_container())
		return FALSE // inserting reagents into the machine
	// TODO - Do I need to check for borgs putting module items inside?
	if(Insert_Item(O, user))
		return TRUE
	if(OnAttackBy(O, user))
		return TRUE
	else
		return ..()

// Let children with materials override this to forward attackbys.
/obj/machinery/rnd/proc/OnAttackBy(obj/item/O, mob/user)
	return

//to disconnect the machine from the r&d console it's linked to
/obj/machinery/rnd/proc/disconnect_console()
	linked_console = null

//proc used to handle inserting items or reagents into rnd machines
/obj/machinery/rnd/proc/Insert_Item(obj/item/I, mob/user)
	return

//whether the machine can have an item inserted in its current state.
/obj/machinery/rnd/proc/is_insertion_ready(mob/user)
	if(panel_open)
		to_chat(user, "<span class='warning'>You can't load [src] while it's opened!</span>")
		return FALSE
	if(disabled)
		to_chat(user, "<span class='warning'>The insertion belts of [src] won't engage!</span>")
		return FALSE
	if(requires_console && !linked_console)
		to_chat(user, "<span class='warning'>[src] must be linked to an R&D console first!</span>")
		return FALSE
	if(busy)
		to_chat(user, "<span class='warning'>[src] is busy right now.</span>")
		return FALSE
	if(stat & BROKEN)
		to_chat(user, "<span class='warning'>[src] is broken.</span>")
		return FALSE
	if(stat & NOPOWER)
		to_chat(user, "<span class='warning'>[src] has no power.</span>")
		return FALSE
	if(loaded_item)
		to_chat(user, "<span class='warning'>[src] is already loaded.</span>")
		return FALSE
	return TRUE

//we eject the loaded item when deconstructing the machine
/obj/machinery/rnd/dismantle()
	if(loaded_item)
		loaded_item.forceMove(drop_location())
		loaded_item = null
	return ..()

// Evidently we use power and show animations when stuff is inserted.
/obj/machinery/rnd/proc/AfterMaterialInsert(item_inserted, id_inserted, amount_inserted)
	var/stack_name
	if(istype(item_inserted, /obj/item/weapon/ore/bluespace_crystal))
		stack_name = "bluespace"
		use_power_oneoff(SHEET_MATERIAL_AMOUNT / 10)
	else
		var/obj/item/stack/S = item_inserted
		stack_name = S.name
		use_power_oneoff(min(1000, (amount_inserted / 100)))
	add_overlay("protolathe_[stack_name]")
	addtimer(CALLBACK(src, /atom/proc/cut_overlay, "protolathe_[stack_name]"), 10)
