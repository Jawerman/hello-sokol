// continue from [here](https://youtu.be/8ZCxFL6N7zU?t=1507)
package main

import shader "../shaders"
import sapp "../sokol-odin/sokol/app"
import sg "../sokol-odin/sokol/gfx"
import shelpers "../sokol-odin/sokol/helpers"
import types "../types"
import "base:intrinsics"
import "base:runtime"
import "core:log"
import "core:math"
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
	camera:        struct {
		position: types.Vec3,
		target:   types.Vec3,
		look:     types.Vec2,
	},
}

g: ^Globals

main :: proc() {
	context.logger = log.create_console_logger()
	default_context = context


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

	sapp.show_mouse(false)
	sapp.lock_mouse(true)

	g = new(Globals)

	g.camera = {
		position = {0, 0, 2},
		target   = {0, 0, 1},
	}
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


	Vertex_Data :: struct {
		pos: types.Vec3,
		col: sg.Color,
		uv:  types.Vec2,
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

	if key_down[.ESCAPE] {
		sapp.quit()
		return
	}

	dt := f32(sapp.frame_duration())

	update_camera(dt)

	// g.rotation += linalg.to_radians(ROTATION_SPEED * dt)
	p: types.Mat4 = linalg.matrix4_perspective_f32(70, sapp.widthf() / sapp.heightf(), 0.001, 1000)
	m :=
		linalg.matrix4_translate_f32({0.0, 0.0, 0.0}) *
		linalg.matrix4_from_yaw_pitch_roll_f32(g.rotation, 0.0, 0.0)

	v := linalg.matrix4_look_at_f32(g.camera.position, g.camera.target, types.Vec3{0, 1, 0})

	sg.begin_pass({swapchain = shelpers.glue_swapchain()})

	vs_params := shader.Vs_Params {
		mvp = p * v * m,
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

	mouse_move = types.Vec2{0, 0}
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

mouse_move: types.Vec2
key_down: #sparse[sapp.Keycode]bool

event_cb :: proc "c" (ev: ^sapp.Event) {
	context = default_context

	#partial switch ev.type {
	case .MOUSE_MOVE:
		mouse_move += {-ev.mouse_dx, -ev.mouse_dy}
	case .KEY_DOWN:
		key_down[ev.key_code] = true
	case .KEY_UP:
		key_down[ev.key_code] = false
	}
}

MOVE_SPEED :: 3
LOOK_SENSITIVITY :: 0.05

update_camera :: proc(dt: f32) {
	move_input: types.Vec2

	if key_down[.W] do move_input.y = 1
	else if key_down[.S] do move_input.y = -1
	if key_down[.D] do move_input.x = 1
	else if key_down[.A] do move_input.x = -1

	look_input: types.Vec2 = mouse_move * LOOK_SENSITIVITY
	g.camera.look += look_input
	g.camera.look.x = math.wrap(g.camera.look.x, 360)
	g.camera.look.y = math.clamp(g.camera.look.y, -90, 90)

	look_mat := linalg.matrix4_from_yaw_pitch_roll_f32(
		linalg.to_radians(g.camera.look.x),
		linalg.to_radians(g.camera.look.y),
		0,
	)

	forward := (look_mat * types.Vec4{0, 0, -1, 1}).xyz
	right := (look_mat * types.Vec4{1, 0, 0, 1}).xyz

	move_dir := forward * move_input.y + right * move_input.x
	motion := linalg.normalize0(move_dir) * MOVE_SPEED * dt

	g.camera.position += motion
	g.camera.target = g.camera.position + forward
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
