// Shadertoy: Simple Path Tracer with Floor
//　床を追加したシンプルなパストレーサー
#define PI 3.14159265359

float rand(vec2 co) {
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// 球との交差
float sphereIntersect(vec3 ro, vec3 rd, vec3 c, float r) {
    vec3 oc = ro - c;
    float b = dot(oc, rd);
    float c0 = dot(oc, oc) - r * r;
    float h = b*b - c0;
    if(h < 0.0) return -1.0;
    return -b - sqrt(h);
}

// 床との交差 (y = -1)
// p 床の位置 n 床の法線
float planeIntersect(vec3 ro, vec3 rd, vec3 p, vec3 n) {
    float denom = dot(n, rd);
    if(abs(denom) < 1e-6) return -1.0; // 平行
    float t = dot(p - ro, n) / denom;
    return t > 0.0 ? t : -1.0;
}

// ランダム半球方向
vec3 randomHemisphere(vec3 n, vec2 seed) {
    float u = rand(seed);
    float v = rand(seed + 1.0);
    float theta = 2.0 * PI * u;
    float phi = acos(v); // バグ修正済み
    vec3 dir = vec3(sin(phi) * cos(theta), sin(phi) * sin(theta), cos(phi));
    vec3 up = abs(n.y) < 0.99 ? vec3(0,1,0) : vec3(1,0,0);
    vec3 udir = normalize(cross(up, n));
    vec3 vdir = cross(n, udir);
    return normalize(udir * dir.x + vdir * dir.y + n * dir.z);
}

vec3 radiance(vec3 ro, vec3 rd, vec2 seed) {
    vec3 col = vec3(1.0);
    for(int i = 0; i < 5; i++) {
        // 球と床の交差を両方計算
        float ts = sphereIntersect(ro, rd, vec3(0,0,0), 1.0);
        float tp = planeIntersect(ro, rd, vec3(0,-1,0), vec3(0,1,0));

        // 一番近い交差を選択
        float t = -1.0;
        vec3 normal;
        vec3 hitColor;

        if(ts > 0.0 && (tp < 0.0 || ts < tp)) {
		   // 球にヒット。床にはヒットしないか、球に先にヒット。
            t = ts; //ヒット位置
            normal = normalize((ro + rd * t) - vec3(0,0,0));//ヒット位置の法線
            hitColor = vec3(1.0, 0.9, 0.7); // 球の色
        }
        else if(tp > 0.0) {
		   // 床にヒット。球にはヒットしないか、に床先にヒット。
            t = tp; //ヒット位置
            normal = vec3(0,1,0);//ヒット位置の法線
            hitColor = vec3(0.7, 0.7, 0.7); // 床の色
        }

        if(t < 0.0) break; // 何もヒットしなければ終了

        // 衝突点を新しいレイの出発点に半球方向にランダムにレイ生成
        vec3 hit = ro + rd * t;
        ro = hit + normal * 0.001;
        rd = randomHemisphere(normal, seed + float(i));

        // エネルギー減衰 & ヒットした物体の色反映
        col *= hitColor * 0.8;
    }
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    // カメラ設定
    vec3 ro = vec3(0,0,3);
    vec3 ta = vec3(0,0,0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + ww);

    vec3 col = vec3(0.0);
    for (int i = 0; i < 16; i++) {
        col += radiance(ro, rd, fragCoord.xy + float(i));
    }
    col /= 16.0;

    // ガンマ補正
    col = pow(col, vec3(1.0/2.2));
    fragColor = vec4(col,1.0);
}
