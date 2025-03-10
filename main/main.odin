package main

import shader "../shaders"
import sapp "../sokol-odin/sokol/app"
import sg "../sokol-odin/sokol/gfx"
import shelpers "../sokol-odin/sokol/helpers"
import "base:runtime"
import "core:log"


default_context: runtime.Context

Globals :: struct {
	shader:        sg.Shader,
	pipeline:      sg.Pipeline,
	vertex_buffer: sg.Buffer,
	index_buffer:  sg.Buffer,
}

g: ^Globals

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

	g = new(Globals)
	g.shader = sg.make_shader(shader.main_shader_desc(sg.query_backend()))
	g.pipeline = sg.make_pipeline(
		{
			shader = g.shader,
			layout = {
				attrs = {
					shader.ATTR_main_pos = {format = .FLOAT2},
					shader.ATTR_main_col = {format = .FLOAT4},
				},
			},
			index_type = .UINT16,
		},
	)

	Vertex_Data :: struct {
		pos: [2]f32,
		col: sg.Color,
	}

	indices := []u16{0, 1, 2, 1, 2, 3}

	vertices := []Vertex_Data {
		{pos = {-0.3, -0.3}, col = {1, 0, 0, 1}},
		{pos = {0.3, -0.3}, col = {0, 1, 0, 1}},
		{pos = {-0.3, 0.3}, col = {0, 0, 1, 1}},
		{pos = {0.3, 0.3}, col = {0, 0, 1, 1}},
	}

	g.vertex_buffer = sg.make_buffer({data = sg_range(vertices)})
	g.index_buffer = sg.make_buffer({data = sg_range(indices), type = .INDEXBUFFER})
}

frame_cb :: proc "c" () {
	context = default_context

	sg.begin_pass({swapchain = shelpers.glue_swapchain()})

	sg.apply_pipeline(g.pipeline)
	sg.apply_bindings({vertex_buffers = {0 = g.vertex_buffer}, index_buffer = g.index_buffer})

	sg.draw(0, 6, 1)

	sg.end_pass()
	sg.commit()
}

cleanup_cb :: proc "c" () {
	context = default_context

	sg.destroy_buffer(g.vertex_buffer)
	sg.destroy_buffer(g.index_buffer)
	sg.destroy_pipeline(g.pipeline)
	sg.destroy_shader(g.shader)
	free(g)
	sg.shutdown()
}

event_cb :: proc "c" (ev: ^sapp.Event) {
	context = default_context
	log.debug(ev.type)
}

sg_range :: proc(s: []$T) -> sg.Range {
	return {ptr = raw_data(s), size = len(s) * size_of(s[0])}
}
