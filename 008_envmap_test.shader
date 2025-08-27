
#iChannel0 "file://texture/DaySkyHDRI059A_1K-TONEMAPPED.jpg"

#define PI 3.14159265359

// -------------------- Direction to Equirectangular UV --------------------
vec2 dirToUV2(vec3 dir) {
    dir = normalize(dir);
    // 水平角: -PI〜PI → 0〜1
    float u = atan(dir.z, dir.x) / (2.0 * PI) + 0.5;
    // 垂直角: -PI/2〜PI/2 → 0〜1
    float v = asin(clamp(dir.y, -1.0, 1.0)) / PI + 0.5;
    return vec2(u, v);
}

vec3 skyColorEnvmap(vec3 rd) {
    vec2 uv = dirToUV2(normalize(rd));
    return texture(iChannel0, uv).rgb; // equirectangular env map
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uvScreen = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 ro = vec3(0,0,0);
    vec3 rd = normalize(vec3(uvScreen, 1.0)); // カメラ前方
    vec3 col = skyColorEnvmap(rd); // 環境マップそのまま
    fragColor = vec4(col,1.0);
}

