extends Node

const SIZEOF_VECTOR3 := 4 * 3
const TRIANGLE_VERTICES: PackedVector3Array = [
	Vector3( 0.0,  0.1, 0.0),
	Vector3(-0.1, -0.1, 0.0),
	Vector3( 0.1, -0.1, 0.0)
]

@export var vertex_shader_file: RDShaderFile = null
@export var fragment_shader_file: RDShaderFile = null

enum BufferType { STORAGE, UNIFORM, VERTEX, INDEX }
@export var try_buffer_address_offset := false
@export var try_buffer_type := BufferType.STORAGE

var rd: RenderingDevice = null

var shader := RID()
var pipeline := RID()

var vertex_format := 0
var triangle_vertex_buffer := RID()
var vertex_array := RID()

var storage_buffer := RID()
var storage_buffer_address := 0

var uniform_buffer := RID()
var uniform_buffer_address := 0

var vertex_buffer := RID()
var vertex_buffer_address := 0

var index_buffer := RID()
var index_buffer_address := 0

func _ready() -> void:
	assert(vertex_shader_file)
	assert(fragment_shader_file)
	
	rd = RenderingServer.get_rendering_device()
	
	if not rd.has_feature(RenderingDevice.SUPPORTS_BUFFER_ADDRESS):
		printerr("Buffer address not supported by the GPU")
		set_process(false)
		return
	
	if true: #Vertex format
		var attributes := []
		
		if true:
			var attribute := RDVertexAttribute.new()
			attribute.frequency = RenderingDevice.VERTEX_FREQUENCY_VERTEX
			attribute.format = RenderingDevice.DATA_FORMAT_R32G32B32_SFLOAT
			attribute.stride = SIZEOF_VECTOR3
			attribute.offset = 0
			attributes.push_back(attribute)
		
		vertex_format = rd.vertex_format_create(attributes)
	
	if true: #Vertex buffer
		var bytes := TRIANGLE_VERTICES.to_byte_array()
		triangle_vertex_buffer = rd.vertex_buffer_create(bytes.size(), bytes)
	
	if true: #Vertex array
		vertex_array = rd.vertex_array_create(TRIANGLE_VERTICES.size(), vertex_format, [triangle_vertex_buffer])
	
	if true: #Shader
		var bundle := RDShaderSPIRV.new()
		bundle.bytecode_vertex = vertex_shader_file.get_spirv().bytecode_vertex
		bundle.bytecode_fragment = fragment_shader_file.get_spirv().bytecode_fragment
		shader = rd.shader_create_from_spirv(bundle)
	
	if true: #Pipeline
		var framebuffer_format := rd.screen_get_framebuffer_format()
		var primitive := RenderingDevice.RENDER_PRIMITIVE_TRIANGLES
		
		var rasterization := RDPipelineRasterizationState.new()
		var multisample := RDPipelineMultisampleState.new()
		var depth := RDPipelineDepthStencilState.new()
		var blend := RDPipelineColorBlendState.new()
		blend.attachments = [RDPipelineColorBlendStateAttachment.new()]
		
		pipeline = rd.render_pipeline_create(shader, framebuffer_format, vertex_format, primitive, rasterization, multisample, depth, blend)
	
	
	var vertex_colors: PackedColorArray = [
			Color(1, 0, 0, 1),
			Color(0, 1, 0, 1),
			Color(0, 0, 1, 1),
			
			Color(1, 1, 0, 1),
			Color(0, 1, 1, 1),
			Color(1, 0, 1, 1),
		]
	
	if true: #Storage Buffer
		var bytes := vertex_colors.to_byte_array()
		storage_buffer = rd.storage_buffer_create(bytes.size(), bytes, RenderingDevice.STORAGE_BUFFER_USAGE_SHADER_DEVICE_ADDRESS)
		storage_buffer_address = rd.buffer_get_device_address(storage_buffer)
	
	if true: #Uniform Buffer
		var bytes := vertex_colors.to_byte_array()
		uniform_buffer = rd.uniform_buffer_create(bytes.size(), bytes, true)
		uniform_buffer_address = rd.buffer_get_device_address(uniform_buffer)
	
	if true: #Vertex Buffer
		var bytes := vertex_colors.to_byte_array()
		vertex_buffer = rd.vertex_buffer_create(bytes.size(), bytes, false, true)
		vertex_buffer_address = rd.buffer_get_device_address(vertex_buffer)
	
	if true: #Index Buffer
		var bytes := vertex_colors.to_byte_array()
		index_buffer = rd.index_buffer_create(bytes.size() / 4, RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, bytes, false, true)
		index_buffer_address = rd.buffer_get_device_address(index_buffer)

func _process(delta: float) -> void:
	var bytes := PackedByteArray()
	if true:
		var buffer_address := 0
		match try_buffer_type:
			BufferType.STORAGE:
				buffer_address = storage_buffer_address
			BufferType.UNIFORM:
				buffer_address = uniform_buffer_address
			BufferType.VERTEX:
				buffer_address = vertex_buffer_address
			BufferType.INDEX:
				buffer_address = index_buffer_address
		var offset := 4 * 4 * 3 if try_buffer_address_offset else 0
		
		bytes.resize(16)
		bytes.encode_u64(0, buffer_address + offset)
	
	var dlist := rd.draw_list_begin_for_screen()
	rd.draw_list_bind_render_pipeline(dlist, pipeline)
	rd.draw_list_bind_vertex_array(dlist, vertex_array)
	rd.draw_list_set_push_constant(dlist, bytes, bytes.size())
	rd.draw_list_draw(dlist, false, 1)
	rd.draw_list_end()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		rd.free_rid(shader)
		rd.free_rid(triangle_vertex_buffer)
		rd.free_rid(storage_buffer)
		rd.free_rid(uniform_buffer)
		rd.free_rid(vertex_buffer)
		rd.free_rid(index_buffer)
