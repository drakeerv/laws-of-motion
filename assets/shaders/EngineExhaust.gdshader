shader_type spatial;

uniform float model_height = 1.0;
uniform float dissolve_start : hint_range(0.0, 1.0) = 0.001;
uniform float dissolve_length : hint_range(0.0, 1.0) = 1.0;
uniform float gradient_bias : hint_range(0.1, 5.0) = 1.0;
uniform float noise_speed = 1.0;
uniform float noise_strength = 0.3;
uniform float stretch_factor = 0.1;
uniform vec3 flame_color = vec3(1.0, 0.5, 0.0);
uniform vec3 inner_color = vec3(1.0, 0.8, 0.4);
uniform float emission_strength = 2.0;
uniform sampler2D noise_texture;

uniform float throttle : hint_range(0.0, 1.0) = 1.0;
uniform float idle_emission : hint_range(0.0, 1.0) = 0.2;
uniform float idle_noise : hint_range(0.0, 1.0) = 0.5;

varying float vert_height;
varying vec2 v_uv;

vec3 neon(float value, vec3 color, vec3 inner) {
    float ramp = clamp(value, 0.0, 1.0);
    vec3 output_color = vec3(0.0);
    ramp = ramp * ramp;
    output_color += pow(color, vec3(4.0)) * ramp;
    ramp = ramp * ramp;
    output_color += inner * ramp;
    ramp = ramp * ramp;
    output_color += vec3(1.0) * ramp;
    return output_color * emission_strength;
}

void vertex() {
    vert_height = (VERTEX.y + (model_height / 2.0)) / model_height;
    v_uv = UV;
}

void fragment(){
    // Modify noise speed and strength based on throttle
    float current_noise_speed = noise_speed * mix(idle_noise, 1.0, throttle);
    float current_noise_strength = noise_strength * mix(idle_noise, 1.0, throttle);
    
    vec2 time_offset = vec2(TIME * current_noise_speed * 0.1, TIME * current_noise_speed);
    vec2 base_uv = v_uv;
    base_uv = fract(base_uv + time_offset);
    
    // Enhanced noise sampling with three layers
    vec2 stretched_uv1 = vec2(base_uv.x * stretch_factor, base_uv.y * 2.0);
    vec2 stretched_uv2 = vec2(base_uv.x * stretch_factor * 1.5, base_uv.y * 1.5);
    vec2 stretched_uv3 = vec2(base_uv.x * stretch_factor * 0.75, base_uv.y * 2.5);
    
    stretched_uv1 = fract(stretched_uv1);
    stretched_uv2 = fract(stretched_uv2);
    stretched_uv3 = fract(stretched_uv3);
    
    float noise_value = (
        texture(noise_texture, stretched_uv1).r * 0.5 +
        texture(noise_texture, stretched_uv2).r * 0.3 +
        texture(noise_texture, stretched_uv3).r * 0.2
    ) * current_noise_strength;
    
    float gradient_height = vert_height - dissolve_start;
    gradient_height *= 1.0 / (dissolve_length * mix(0.5, 1.0, throttle));
    gradient_height = clamp(pow(gradient_height, gradient_bias) + noise_value, 0.0, 1.0);

    // Add strength falloff at the end
    float strength_factor = 1.0 - smoothstep(0.0, 1.0, gradient_height);
    
    ALPHA = mix(1.0, 0.0, gradient_height) * strength_factor;
    float current_emission = emission_strength * mix(idle_emission, 1.0, throttle) * strength_factor;
    vec3 color = neon(pow(ALPHA, gradient_height), flame_color, inner_color) * current_emission;
    ALBEDO = color;
    EMISSION = color;
}