// Shadertoy: Simple Path Tracer with Floor
//　光源と影を追加したシンプルなパストレーサー
#define PI 3.14159265359

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// 球
float sphereIntersect(vec3 ro, vec3 rd, vec3 c, float r) {
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float c0 = dot(oc, oc) - r * r;
    float h = b*b - c0;
    if(h < 0.0) return -1.0;
    return -b - sqrt(h);
}

// 無限床
float planeIntersect(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    float denom = dot(n, rd);
    if(abs(denom) < 1e-6) return -1.0;
    float t = dot(p - ro, n) / denom;
    return t > 0.0 ? t : -1.0;
}

// 光源（小さな天井の板）との交差
float rectLightIntersect(vec3 ro, vec3 rd, vec3 lp, vec2 size, out vec3 normal) {
    normal = vec3(0,-1,0); // 下向き
    float denom = dot(normal, rd);
    if(abs(denom) < 1e-6) return -1.0;
    float t = dot(lp - ro, normal) / denom;
    if(t <= 0.0) return -1.0;
    vec3 hit = ro + rd * t;
    vec3 local = hit - lp;
    if(abs(local.x) <= size.x*0.5 && abs(local.z) <= size.y*0.5) {
        return t;
    }
    return -1.0;
}

// 半球サンプリング
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
    vec3 col = vec3(0.0);
    vec3 throughput = vec3(1.0);

    for(int bounce = 0; bounce < 5; bounce++) {
        float ts = sphereIntersect(ro, rd, vec3(0,0,0), 1.0);
        float tp = planeIntersect(ro, rd, vec3(0,-1,0), vec3(0,1,0));
        vec3 nLight;
        float tl = rectLightIntersect(ro, rd, vec3(0,5,0), vec2(2.0,2.0), nLight);

        float t = 1e9;
        vec3 normal;
        vec3 hitColor = vec3(0.0);
        bool hitLight = false;

        if(ts > 0.0 && ts < t) {
            t = ts;
            normal = normalize((ro + rd * t) - vec3(0,0,0));
            hitColor = vec3(1.0, 0.9, 0.7);
        }
        if(tp > 0.0 && tp < t) {
            t = tp;
            normal = vec3(0,1,0);
            hitColor = vec3(0.7);
        }
        if(tl > 0.0 && tl < t) {
            t = tl;
            hitLight = true;//光源に直接ヒット
        }

        if(t >= 1e9) break; // ヒットなし

        vec3 hitPos = ro + rd * t;

        // 光源に直接ヒットしたら終了（放射寄与を加算）
        if(hitLight) {
            col += throughput * vec3(15.0); // 光源の強さ
            break;
        }

        // 直接照明の計算（シャドウレイ）
        vec3 lightPos = vec3(0,5,0) + vec3(rand(seed)*2.0-1.0, 0, rand(seed+1.0)*2.0-1.0);
        vec3 toLight = lightPos - hitPos;
        float distLight = length(toLight);
        vec3 ldir = normalize(toLight);

        // 遮蔽判定
        bool shadowed = false;
        float ts2 = sphereIntersect(hitPos + normal*0.001, ldir, vec3(0,0,0), 1.0);
        float tp2 = planeIntersect(hitPos + normal*0.001, ldir, vec3(0,-1,0), vec3(0,1,0));
        if((ts2 > 0.0 && ts2 < distLight) || (tp2 > 0.0 && tp2 < distLight)) {
            shadowed = true;
        }

        if(!shadowed) {
            float ndotl = max(dot(normal, ldir), 0.0);
            col += throughput * hitColor * vec3(15.0) * ndotl / (distLight*distLight);
        }

        // 次のバウンスへ
        ro = hitPos + normal * 0.001;
        rd = randomHemisphere(normal, seed + float(bounce));
        throughput *= hitColor * 0.8;
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0,0,8);
    vec3 ta = vec3(0,0,0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + ww);

    vec3 col = vec3(0.0);
    for (int i = 0; i < 32; i++) {
        col += radiance(ro, rd, fragCoord.xy + float(i)*vec2(1.123,3.456));
    }
    col /= 32.0;

    col = pow(col, vec3(1.0/2.2));
    fragColor = vec4(col,1.0);
}

