package main

import sapp "../sokol-odin/sokol/app"
import sg "../sokol-odin/sokol/gfx"
import shelpers "../sokol-odin/sokol/helpers"
import "base:runtime"
import "core:log"


default_context: runtime.Context

main :: proc() {
	context.logger = log.create_console_logger()
	default_context = context

	log.debug("hello, sokol!")

	sapp.run(
		{
			width = 800,
			height = 600,
			window_title = "Hello Sokol!",
			allocator = sapp.Allocator(shelpers.allocator(&default_context)),
			logger = sapp.Logger(shelpers.logger(&default_context)),
			init_cb = init_cb,
			frame_cb = frame_cb,
			cleanup_cb = cleanup_cb,
			event_cb = event_cb,
		},
	)
}

init_cb :: proc "c" () {
	context = default_context
	sg.setup(
		{
			environment = shelpers.glue_environment(),
			allocator = sg.Allocator(shelpers.allocator(&default_context)),
			logger = sg.Logger(shelpers.logger(&default_context)),
		},
	)
}

frame_cb :: proc "c" () {
	context = default_context

	sg.begin_pass({swapchain = shelpers.glue_swapchain()})
	// TODO: draw

	sg.end_pass()
	sg.commit()
}

cleanup_cb :: proc "c" () {
	context = default_context

	sg.shutdown()
}

event_cb :: proc "c" (ev: ^sapp.Event) {
	context = default_context
	log.debug(ev.type)
}
