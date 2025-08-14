// Shadertoy: Simple Path Tracer
// https://www.shadertoy.com/new

#define PI 3.14159265359

// ランダム生成（フレームとピクセル位置に基づく）
float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// 球との交差判定
float sphereIntersect(vec3 ro, vec3 rd, vec3 c, float r) {
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float c0 = dot(oc, oc) - r * r;
    float h = b*b - c0;
    if(h < 0.0) return -1.0;
    return -b - sqrt(h);
}

// ランダムな半球方向ベクトル
vec3 randomHemisphere(vec3 n, vec2 seed) {
    float u = rand(seed);
    float v = rand(seed + 1.0);
    float theta = 2.0 * PI * u;
    float phi = acos(v);
    vec3 dir = vec3(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi));
    vec3 up = abs(n.y) < 0.99 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 udir = normalize(cross(up, n));
    vec3 vdir = cross(n, udir);
    return normalize(udir * dir.x + vdir * dir.y + n * dir.z);
}

vec3 radiance(vec3 ro, vec3 rd, vec2 seed) {
    vec3 col = vec3(1.0);
    for(int i = 0; i < 3; i++) {
        float t = sphereIntersect(ro, rd, vec3(0,0,0), 1.0);
        if(t < 0.0) break;

        vec3 hit = ro + rd * t;
        vec3 normal = normalize(hit - vec3(0,0,0));
        ro = hit + normal * 0.001;
        rd = randomHemisphere(normal, seed + float(i));

        col *= 0.8; // エネルギー減衰
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    
    // カメラ
    vec3 ro = vec3(0,0,3); // 原点より少し後ろ
    vec3 ta = vec3(0,0,0); // 注視点
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + ww);

    vec3 col = vec3(0.0);
    for (int i = 0; i < 8; i++) {
        col += radiance(ro, rd, fragCoord.xy + float(i));
    }
    col /= 8.0;

    // ガンマ補正
    col = pow(col, vec3(1.0/2.2));
    fragColor = vec4(col,1.0);
}
