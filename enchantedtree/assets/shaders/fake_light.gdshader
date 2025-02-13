// Author: Jonathan T. - RakuNana
// Link: https://github.com/RakuNana/Shader-as-Light
// NOTE: Shader automatically converted from Godot Engine 4.4.dev7's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform sampler2D texture_heightmap : hint_default_black, filter_linear_mipmap, repeat_enable;
uniform float heightmap_scale : hint_range(-16.0, 16.0, 0.001);
uniform vec2 heightmap_flip;
uniform int heightmap_min_layers : hint_range(1, 64);
uniform int heightmap_max_layers : hint_range(1, 64);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

//added
//size of influence of the object
uniform float light_size = 5.0;
//Can create a global shader in project settings, then place global in front of var
uniform vec3 light_pos;
//objects position in the world
varying vec3 obj_pos;


void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	//added
	obj_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

}

void fragment() {
	vec2 base_uv = UV;

	{
		// Height: Enabled
		vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT * heightmap_flip.x, -BINORMAL * heightmap_flip.y, NORMAL));
		float depth = 1.0 - texture(texture_heightmap, base_uv).r;
		vec2 ofs = base_uv - view_dir.xy * depth * heightmap_scale * 0.01;
		base_uv = ofs;
	}

	vec4 albedo_tex = texture(texture_albedo, base_uv);

	// Vertex Color Use as Albedo: Enabled
	//If you have vertex colors active , you need to use COLOR
	//albedo_tex *= COLOR;

	//added
	float min_dis = min(length(light_pos - obj_pos), light_size);

	//added, clamps the light influence. Light/Dark balanced
	float light_color =  clamp(light_size - min_dis,.5,2.0);
	//mix the color , texture, and light together

	//flicker
	light_color *= sin(TIME * 15.0) * 0.025 + 0.5;
	ALBEDO = albedo.rgb * albedo_tex.rgb * light_color * COLOR.rgb ;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;


	//Optional, adds a flickering effect to fake light
	//final_color *= sin(TIME * 10.0) * 0.5 + 0.5;
}