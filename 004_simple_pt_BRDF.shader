// ------------------------------------------
// Path Tracer with Multiple Materials
// ------------------------------------------

#define PI 3.14159265359

struct Material {
    vec3 color;
    float metallic;  // 0 = diffuse, 1 = pure mirror
    float roughness; // 0 = sharp, 1 = very rough
};

struct Sphere {
    vec3 center;
    float radius;
    Material mat;
};

// -------------------- Random --------------------
float rand1(vec3 seed) {
    return fract(sin(dot(seed ,vec3(12.9898,78.233, 37.719))) * 43758.5453);
}

// Cosine-weighted hemisphere sampling
vec3 cosineHemisphere(vec3 n, vec3 seed) {
    float u = rand1(seed + vec3(1.0, 0.0, 0.0));
    float v = rand1(seed + vec3(0.0, 1.0, 0.0));
    float r = sqrt(u);
    float theta = 2.0 * PI * v;
    vec3 sdir, tdir;
    if (abs(n.x) < 0.5) sdir = normalize(cross(n, vec3(1,0,0)));
    else                sdir = normalize(cross(n, vec3(0,1,0)));
    tdir = cross(n, sdir);
    return normalize(sdir * (r*cos(theta)) + tdir * (r*sin(theta)) + n * sqrt(1.0 - u));
}

// -------------------- Geometry --------------------
float sphereIntersect(vec3 ro, vec3 rd, Sphere sph) {
    vec3 oc = ro - sph.center;
    float b = dot(oc, rd);
    float c0 = dot(oc, oc) - sph.radius * sph.radius;
    float h = b*b - c0;
    if(h < 0.0) return -1.0;
    return -b - sqrt(h);
}

bool sceneIntersect(vec3 ro, vec3 rd, out vec3 hitPos, out vec3 normal, out Material mat) {
    float tMin = 1e9;
    bool hit = false;

    // ---- Scene objects ----
    Sphere spheres[3];
    spheres[0] = Sphere(vec3(0,0,0), 1.0, Material(vec3(0.8,0.3,0.3), 0.0, 0.0)); // diffuse red
    spheres[1] = Sphere(vec3(2,0,0), 1.0, Material(vec3(0.3,0.3,0.9), 1.0, 0.1)); // glossy blue metal
    spheres[2] = Sphere(vec3(-2,0,0), 1.0, Material(vec3(0.3,0.8,0.3), 0.0, 0.0)); // diffuse green

    for(int i = 0; i < 3; i++) {
        float t = sphereIntersect(ro, rd, spheres[i]);
        if(t > 0.001 && t < tMin) {
            tMin = t;
            hit = true;
            hitPos = ro + rd * t;
            normal = normalize(hitPos - spheres[i].center);
            mat = spheres[i].mat;
        }
    }
    return hit;
}

// -------------------- Radiance --------------------
vec3 radiance(vec3 ro, vec3 rd, vec2 fragCoord) {
    vec3 col = vec3(0.0);
    vec3 throughput = vec3(1.0);

    for(int bounce = 0; bounce < 8; bounce++) {
        vec3 hitPos, normal;
        Material mat;

        if(!sceneIntersect(ro, rd, hitPos, normal, mat)) {
            // background light
            col += throughput * vec3(0.7, 0.8, 1.0) * 0.2; 
            break;
        }

        // direct light from point light
        vec3 lightPos = vec3(5,5,5);
        vec3 toLight = lightPos - hitPos;
        float distLight = length(toLight);
        vec3 ldir = normalize(toLight);

        // Shadow ray
        vec3 shHitPos, shNormal;
        Material shMat;
        bool shadow = sceneIntersect(hitPos + normal*0.001, ldir, shHitPos, shNormal, shMat) 
                      && length(shHitPos - hitPos) < distLight;

        if(!shadow) {
            float ndotl = max(dot(normal, ldir), 0.0);
            vec3 lightColor = vec3(15.0);
            col += throughput * mat.color * lightColor * ndotl / (distLight*distLight);
        }

        // Choose next direction
        vec3 newDir;
        vec3 seed = hitPos + float(bounce) + vec3(fragCoord, iTime);
        if(mat.metallic > 0.5) {
            vec3 refl = reflect(rd, normal);
            newDir = mix(refl, cosineHemisphere(normal, seed), mat.roughness);
        } else {
            newDir = cosineHemisphere(normal, seed);
        }

        ro = hitPos + normal * 0.001;
        rd = newDir;

        // update throughput (albedo)
        throughput *= mat.color;

        // Russian roulette
        if(bounce > 2) {
            float p = max(throughput.r, max(throughput.g, throughput.b));
            if(rand1(seed) > p) break;
            throughput /= p;
        }
    }
    return col;
}

// -------------------- Main --------------------
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

    vec3 ro = vec3(0,0,5);
    vec3 ta = vec3(0,0,0);
    vec3 ww = normalize(ta - ro);
    vec3 uu = normalize(cross(ww, vec3(0,1,0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + ww);

    vec3 col = vec3(0.0);
    for(int i = 0; i < 4; i++) {
        col += radiance(ro, rd, fragCoord + vec2(float(i)));
    }
    col /= 4.0;

    col = pow(col, vec3(1.0/2.2));
    fragColor = vec4(col, 1.0);
}


