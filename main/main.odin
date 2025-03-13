package main

import shader "../shaders"
import sapp "../sokol-odin/sokol/app"
import sg "../sokol-odin/sokol/gfx"
import shelpers "../sokol-odin/sokol/helpers"
import types "../types"
import "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:math/linalg"
import stbi "vendor:stb/image"


default_context: runtime.Context
ROTATION_SPEED :: 90

Globals :: struct {
	shader:        sg.Shader,
	pipeline:      sg.Pipeline,
	vertex_buffer: sg.Buffer,
	index_buffer:  sg.Buffer,
	image:         sg.Image,
	sampler:       sg.Sampler,
	rotation:      f32,
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
					shader.ATTR_main_pos = {format = .FLOAT3},
					shader.ATTR_main_col = {format = .FLOAT4},
					shader.ATTR_main_uv = {format = .FLOAT2},
				},
			},
			index_type = .UINT16,
		},
	)

	Vec2 :: [2]f32
	Vec3 :: [3]f32

	Vertex_Data :: struct {
		pos: Vec3,
		col: sg.Color,
		uv:  Vec2,
	}

	indices := []u16{0, 1, 2, 1, 2, 3}

	WHITE :: sg.Color{1, 1, 1, 1}

	vertices := []Vertex_Data {
		{pos = {-0.3, -0.3, 0}, col = WHITE, uv = {0, 0}},
		{pos = {0.3, -0.3, 0}, col = WHITE, uv = {1, 0}},
		{pos = {-0.3, 0.3, 0}, col = WHITE, uv = {0, 1}},
		{pos = {0.3, 0.3, 0}, col = WHITE, uv = {1, 1}},
	}

	g.vertex_buffer = sg.make_buffer({data = sg_range(vertices)})
	g.index_buffer = sg.make_buffer({data = sg_range(indices), type = .INDEXBUFFER})

	w, h: i32
	pixels := stbi.load("./assets/BRICK_1A.PNG", &w, &h, nil, 4)
	assert(pixels != nil)

	g.image = sg.make_image(
		{
			width = w,
			height = h,
			pixel_format = .RGBA8,
			data = {subimage = {0 = {0 = {ptr = pixels, size = uint(w * h * 4)}}}},
		},
	)
	g.sampler = sg.make_sampler({})

	stbi.image_free(pixels)
}

frame_cb :: proc "c" () {
	context = default_context

	dt := f32(sapp.frame_duration())
	g.rotation += linalg.to_radians(ROTATION_SPEED * dt)

	p: types.Mat4 = linalg.matrix4_perspective_f32(70, sapp.widthf() / sapp.heightf(), 0.001, 1000)
	m :=
		linalg.matrix4_translate_f32({0.0, 0.0, -1.5}) *
		linalg.matrix4_from_yaw_pitch_roll_f32(g.rotation, 0.0, 0.0)

	sg.begin_pass({swapchain = shelpers.glue_swapchain()})

	vs_params := shader.Vs_Params {
		mvp = p * m,
	}

	sg.apply_pipeline(g.pipeline)
	sg.apply_bindings(
		{
			vertex_buffers = {0 = g.vertex_buffer},
			index_buffer = g.index_buffer,
			images = {shader.IMG_tex = g.image},
			samplers = {shader.SMP_smp = g.sampler},
		},
	)

	sg.apply_uniforms(shader.UB_vs_params, sg_range(&vs_params))
	sg.draw(0, 6, 1)

	sg.end_pass()
	sg.commit()
}

cleanup_cb :: proc "c" () {
	context = default_context

	sg.destroy_image(g.image)
	sg.destroy_sampler(g.sampler)
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

sg_range :: proc {
	sg_range_from_struct,
	sg_range_from_slices,
}

sg_range_from_struct :: proc(s: ^$T) -> sg.Range where intrinsics.type_is_struct(T) {
	return {ptr = s, size = size_of(T)}
}

sg_range_from_slices :: proc(s: []$T) -> sg.Range {
	return {ptr = raw_data(s), size = len(s) * size_of(s[0])}
}
