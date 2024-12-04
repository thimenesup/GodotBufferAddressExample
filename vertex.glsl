#[vertex]
#version 450

#extension GL_EXT_buffer_reference : require

layout (buffer_reference) buffer VertexColors {
	vec4 colors[];
};

layout (push_constant) uniform Constants {
	VertexColors bufferRef;
} constants;

layout (location = 0) in vec3 Vertex;

layout (location = 0) out vec3 Color;

void main() {
	Color = constants.bufferRef.colors[gl_VertexIndex].rgb;
	gl_Position = vec4(Vertex, 1);
}
