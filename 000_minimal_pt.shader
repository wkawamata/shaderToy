// Minimal Path Tracer @ Shadertoy

float rnd(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

float sphere(vec3 ro, vec3 rd) {
    vec3 oc = ro;
    float b = dot(oc, rd);
    float c = dot(oc, oc) - 1.0;
    float h = b*b - c;
    if (h < 0.0) return -1.0;
    return -b - sqrt(h);
}

vec3 hemisphere(vec3 n, vec2 uv) {
    float a = 6.2831 * rnd(uv);
    float z = rnd(uv + 1.3);
    float r = sqrt(1.0 - z*z);
    vec3 u = normalize(cross(abs(n.x)>0.1?vec3(0,1,0):vec3(1,0,0), n));
    vec3 v = cross(n, u);
    return normalize(r*cos(a)*u + r*sin(a)*v + z*n);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5*iResolution.xy) / iResolution.y;
    
    vec3 ro = vec3(0,0,3);  // カメラ位置
    vec3 rd = normalize(vec3(uv, -1)); //  例ベクトル

    vec3 col = vec3(0.0);
    float t = sphere(ro, rd);
    if (t > 0.0) {
        vec3 hit = ro + t*rd;
        vec3 n = normalize(hit);
        vec3 newDir = hemisphere(n, fragCoord.xy);
        col = max(dot(n, newDir), 0.0) * vec3(1.0, 0.6, 0.3); // 赤みのある球
    }

    col = pow(col, vec3(1.0/2.2)); // ガンマ補正
    fragColor = vec4(col, 1.0);
}
