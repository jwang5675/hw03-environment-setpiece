#version 300 es
precision highp float;

uniform vec2 u_Dimensions; 
uniform vec3 u_Eye, u_Ref, u_Up;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

const float PI = 3.14159265359;
const float TWO_PI = 6.28318530718;
const float fov = 0.7853975; // = 45.0 * 3.14159 / 180.0

const float epsilon = 0.01;

/********************************************** Utility Functions **********************************************/

vec2 sphereToUV(vec3 p) {
    float phi = atan(p.z, p.x);
    if(phi < 0.0) {
        phi += TWO_PI;
    }
    float theta = acos(p.y);
    return vec2(1.0 - phi / TWO_PI, 1.0 - theta / PI);
}

float rand(vec2 pos) {
    return fract(sin(dot(pos.xy ,vec2(12.9898, 78.233))) * 43758.5453);
}

float mod289(float x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 perm(vec4 x) {
    return mod289(((x * 34.0) + 1.0) * x);
}

float cloudsnoise(vec3 p) {
    vec3 a = floor(p);
    vec3 d = p - a;
    d = d * d * (3.0 - 2.0 * d);

    vec4 b = a.xxyy + vec4(0.0, 1.0, 0.0, 1.0);
    vec4 k1 = perm(b.xyxy);
    vec4 k2 = perm(k1.xyxy + b.zzww);

    vec4 c = k2 + a.zzzz;
    vec4 k3 = perm(c);
    vec4 k4 = perm(c + 1.0);

    vec4 o1 = fract(k3 * (1.0 / 41.0));
    vec4 o2 = fract(k4 * (1.0 / 41.0));

    vec4 o3 = o2 * d.z + o1 * (1.0 - d.z);
    vec2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

    return o4.y * d.y + o4.x * (1.0 - d.y);
}

float fbm3(vec3 pos) {
    float amp = 0.5;
    float freq = 5.0;
    float ret = 0.0;
    for(int i = 0; i < 8; i++) {
        ret += cloudsnoise(pos * freq) * amp;
        amp *= .5;
        freq *= 2.;
    }
    return ret;
}

vec2 smoothF(vec2 pos) {
    return pos * pos * (3.0 - 2.0 * pos);
}

float noise(vec2 uv) {
    const float k = 257.0;
    vec4 l  = vec4(floor(uv), fract(uv));
    float u = l.x + l.y * k;
    vec4 v = vec4(u, u + 1.0, u + k, u + k + 1.0);
    v = fract(fract(1.23456789 * v) * v / 0.987654321);
    l.zw = smoothF(l.zw);
    l.x = mix(v.x, v.y, l.z);
    l.y = mix(v.z, v.w, l.z);
    return mix(l.x, l.y, l.w);
}

float fbm(vec2 pos) {
    float amp = 0.5;
    float freq = 5.0;
    float ret = 0.0;
    for(int i = 0; i < 8; i++) {
        ret += noise(pos * freq) * amp;
        amp *= .5;
        freq *= 2.;
    }
    return ret;
}

/********************************************** Start Code for Sky Box **********************************************/

// Sunset palette
const vec3 sunset[5] = vec3[](vec3(255, 229, 119) / 255.0,
                              vec3(254, 192, 81) / 255.0,
                              vec3(255, 137, 103) / 255.0,
                              vec3(253, 96, 81) / 255.0,
                              vec3(57, 32, 51) / 255.0);
// Dusk palette
const vec3 dusk[5] = vec3[](vec3(144, 96, 144) / 255.0,
                            vec3(96, 72, 120) / 255.0,
                            vec3(72, 48, 120) / 255.0,
                            vec3(48, 24, 96) / 255.0,
                            vec3(0, 24, 72) / 255.0);

// Day palette
const vec3 day[5] = vec3[](vec3(236, 241, 240) / 255.0,
                           vec3(216, 224, 233) / 255.0,
                           vec3(188, 209, 220) / 255.0,
                           vec3(160, 198, 221) / 255.0,
                           vec3(108, 175, 209) / 255.0);

// Night palette
const vec3 night[7] = vec3[](vec3(31, 39, 65) / 255.0,
                             vec3(27, 26, 62) / 255.0,
                             vec3(18, 25, 50) / 255.0,
                             vec3(39, 26, 55) / 255.0,
                             vec3(52, 31, 72) / 255.0,
                             vec3(18, 22, 52) / 255.0,
                             vec3(9, 14, 36) / 255.0);

const vec3 sunColor = vec3(255, 255, 190) / 255.0;
const vec3 moonColor = vec3(190, 190, 255) / 255.0;

vec3 xyzToSunset(vec3 xyz) {
    if(xyz.y < 0.5) {
        return sunset[0];
    } else if(xyz.y < 0.55) {
        return mix(sunset[0], sunset[1], (xyz.y - 0.5) / 0.05);
    } else if(xyz.y < 0.6) {
        return mix(sunset[1], sunset[2], (xyz.y - 0.55) / 0.05);
    } else if(xyz.y < 0.65) {
        return mix(sunset[2], sunset[3], (xyz.y - 0.6) / 0.05);
    } else if(xyz.y < 0.75) {
        return mix(sunset[3], sunset[4], (xyz.y - 0.65) / 0.1);
    }
    return sunset[4];
}

vec3 xyzToDusk(vec3 xyz) {
    if(xyz.y < 0.5) {
        return dusk[0];
    } else if(xyz.y < 0.55) {
        return mix(dusk[0], dusk[1], (xyz.y - 0.5) / 0.05);
    } else if(xyz.y < 0.6) {
        return mix(dusk[1], dusk[2], (xyz.y - 0.55) / 0.05);
    } else if(xyz.y < 0.65) {
        return mix(dusk[2], dusk[3], (xyz.y - 0.6) / 0.05);
    } else if(xyz.y < 0.75) {
        return mix(dusk[3], dusk[4], (xyz.y - 0.65) / 0.1);
    }
    return dusk[4];
}

vec3 xyzToDay(vec3 xyz) {
    if(xyz.y < 0.5) {
        return day[0];
    } else if(xyz.y < 0.52) {
        return mix(day[0], day[1], (xyz.y - 0.5) / 0.05);
    } else if(xyz.y < 0.6) {
        return mix(day[1], day[2], (xyz.y - 0.55) / 0.05);
    } else if(xyz.y < 0.65) {
        return mix(day[2], day[3], (xyz.y - 0.6) / 0.05);
    } else if(xyz.y < 0.75) {
        return mix(day[3], day[4], (xyz.y - 0.65) / 0.1);
    }
    return day[4];
}

vec3 xyzToNight(vec3 xyz) {
    if(xyz.y < 0.52) {
        return night[0];
    } else if(xyz.y < 0.55) {
        return mix(night[0], night[1], (xyz.y - 0.52) / 0.03);
    } else if(xyz.y < 0.58) {
        return mix(night[1], night[2], (xyz.y - 0.55) / 0.03);
    } else if(xyz.y < 0.64) {
        return mix(night[2], night[3], (xyz.y - 0.58) / 0.06);
    } else if(xyz.y < 0.67) {
        return mix(night[3], night[4], (xyz.y - 0.64)/ 0.03);
    } else if(xyz.y < 0.8) {
        return mix(night[4], night[5], (xyz.y - 0.67) / 0.13);
    } else if(xyz.y < 0.85) {
        return mix(night[5], night[6], (xyz.y - 0.8) / 0.05);
    }
    return night[6];
}

vec3 getDistortedNightHue(vec3 xyz, vec3 grad) {
    vec3 ret = xyzToNight(xyz + 1.3 * grad);
    if (xyz.y > 0.85) {
        ret = xyzToNight(xyz + 0.3 * grad);
    } else if (xyz.y > 0.75) {
        ret = xyzToNight(xyz + 1.3 * grad);
    } else if (xyz.y > 0.65) {
        ret = xyzToNight(xyz + 0.6 * grad);
    } else if (xyz.y > 0.6 && xyz.y < 0.65) {
        ret = xyzToNight(xyz + 0.5 * grad);
    } else {
        ret = xyzToNight(xyz + 0.4 * grad);
    }
    return ret;
}

vec3 skyBox(vec3 p, vec3 rayDir, inout vec3 cloudColor) {
    vec3 ret;

    // Get the converted UV coordinate
    vec2 uv = sphereToUV(rayDir);
    vec3 xyz = rayDir;

    vec2 uvT2 = uv + vec2(0.00005 * u_Time, -0.0002 * u_Time);
    vec3 xyzT2 = rayDir + vec3(-0.00005 * u_Time, -0.00002 * u_Time, 0.0) * p.y / 300.0;
    float heightField = fbm3(xyz + vec3(0.001 * u_Time));

    vec2 grad = vec2(fbm(uv + vec2(1.0 / u_Dimensions.x, 0.0)) - fbm(uv - vec2(1.0 / u_Dimensions.x, 0.0)),
                      fbm(uv + vec2(0.0, 1.0 / u_Dimensions.y)) - fbm(uv - vec2(0.0, 1.0 / u_Dimensions.y)));
    vec3 grad3D = 0.4 * vec3(fbm3(xyzT2 + vec3(1.0 / u_Dimensions.x, 0.0, 0.0)) - fbm3(xyzT2 - vec3(1.0 / u_Dimensions.x, 0.0, 0.0)),
                             fbm3(xyzT2 + vec3(0.0, 1.0 / u_Dimensions.y, 0.0)) - fbm3(xyzT2 - vec3(0.0, 1.0 / u_Dimensions.y, 0.0)),
                             fbm3(xyzT2 + vec3(0.0, 0.0, 1.0 / u_Dimensions.x)) - fbm3(xyzT2 - vec3(0.0, 0.0, 1.0 / u_Dimensions.x)));

    vec3 distortedSunsetHue = xyzToSunset(xyz + grad3D);
    vec3 distortedDuskHue = xyzToDusk(xyz + grad3D);
    vec3 distortedDayHue = xyzToDay(xyz + grad3D);
    vec3 distortedNightHue = getDistortedNightHue(xyz, grad3D);

    // Add stars to the sky
    if ((grad[0] >= 0.01 || grad[1] >= 0.01) && uv.y > 0.5) {
        if (rand(grad) > 0.98) {
            float multiple = abs(sin((u_Time) / 20.0 + (rand(grad) - 0.98) * 50.0 * PI / 2.0));
            float starBrightnessR = multiple * (mix(distortedNightHue[0] + 0.4, 1.0, (uv.y - 0.5) / 0.2));
            float starBrightnessG = multiple * (mix(distortedNightHue[1] + 0.4, 1.0, (uv.y - 0.5) / 0.2));
            float starBrightnessB = multiple * (mix(distortedNightHue[2] + 0.4, 1.0, (uv.y - 0.5) / 0.2));
            distortedNightHue = vec3(starBrightnessR + 0.4, starBrightnessG + 0.2, starBrightnessB + 0.2);
            distortedDuskHue = distortedNightHue * 0.8;
        }
    }

    vec3 sunDir = normalize(vec3(0.0, cos(u_Time / 175.0), sin(u_Time / 175.0)));
    vec3 moonDir = normalize(vec3(0.0, cos(u_Time / 175.0 + PI), sin(u_Time / 175.0 + PI)));
    float sunSize = 30.0;
    float moonSize = 10.0; 
    float angle = acos(dot(rayDir, sunDir)) * 360.0 / PI;
    float angleMoon = acos(dot(rayDir, moonDir)) * 360.0 / PI;

    vec3 distortedSkyHue;
    vec3 distortedNextHue;
    if (sunDir[1] <= 0.0 && sunDir[2] >= 0.0) {
        // Sunset to night
        cloudColor = mix(sunset[3], night[4], abs(cos(u_Time / 175.0)));
        distortedSkyHue = mix(distortedSunsetHue, distortedNightHue, abs(cos(u_Time / 175.0)));
        distortedNextHue = mix(distortedNightHue, distortedDuskHue, abs(cos(u_Time / 175.0)));
    } else if (sunDir[1] <= 0.0 && sunDir[2] <= 0.0) {
        // Night to sunrise
        cloudColor = mix(night[4], dusk[3], 1.0 - abs(cos(u_Time / 175.0)));
        distortedSkyHue = mix(distortedNightHue, distortedDuskHue, 1.0 - abs(cos(u_Time / 175.0)));
        distortedNextHue = mix(distortedDuskHue, distortedDayHue, 1.0 - abs(cos(u_Time / 175.0)));
    } else if (sunDir[1] >= 0.0 && sunDir[2] <= 0.0) {
        // Sunrise to day
        cloudColor = mix(dusk[3], day[4], abs(cos(u_Time / 175.0)));
        distortedSkyHue = mix(distortedDuskHue, distortedDayHue, abs(cos(u_Time / 175.0)));
        distortedNextHue = mix(distortedDayHue, distortedSunsetHue, abs(cos(u_Time / 175.0)));
    } else {
        // Day to sunset
        cloudColor = mix(day[4], sunset[3], 1.0 - abs(cos(u_Time / 175.0)));
        distortedSkyHue = mix(distortedDayHue, distortedSunsetHue, 1.0 - abs(cos(u_Time / 175.0)));
        distortedNextHue = mix(distortedSunsetHue, distortedNightHue, 1.0 - abs(cos(u_Time / 175.0)));
    }

    // Draw the sun and/or moon
    if(angle < sunSize) {
        if(angle < 7.5) {
            ret = mix(sunColor, cloudColor, heightField * 0.75 * angle / 30.0);
        } else {
            // Sun halo
            vec3 sunBlur = mix(sunColor, distortedSkyHue, (angle - 7.5) / 22.5);
            ret = mix(sunBlur, cloudColor, heightField * 0.75 * angle / 30.0);
        }
    } else if (angleMoon < moonSize) {
        if (angleMoon < 2.5) {
            ret = mix(moonColor, cloudColor, heightField * 0.75 * angleMoon / 10.0);
        } else {
            vec3 moonBlur = mix(moonColor, distortedNextHue, (angleMoon - 2.5) / 7.5);
            ret = mix(moonBlur, cloudColor, heightField * 0.75 * angleMoon / 10.0);
        }
    } else {
        if(angle < 90.0) {
            ret = mix(distortedSkyHue, cloudColor, heightField * 0.75);
        } else if(angle < 180.0) {
            // LERP current sky and next sky
            float t = (angle - 90.0) / 90.0;
            vec3 skyMix = mix(distortedSkyHue, distortedNextHue, t);
            ret = mix(skyMix, cloudColor, heightField * 0.75);
        } else {
            ret = mix(distortedNextHue, cloudColor, heightField * 0.75);
        }
    }
    return ret;
}

/********************************************** Start Code for Water **********************************************/

vec3 applyFog(vec3 rgb, float distance, vec3 fogColor) {
    float fogAmount = 1.0 - exp(-distance * epsilon);
    return mix(rgb, fogColor, fogAmount);
}

// p describes the plane normal = p.xyz and intersect = p.w
float planeIntersect(vec3 ro, vec3 rd, vec4 p){
    return -(dot(ro, p.xyz) + p.w) / dot(rd, p.xyz);
}

float waterFbm(vec2 p) {
    return 0.1 * abs(fbm3(vec3(p, 0.001 * u_Time)) - 0.5);
}

vec3 getWaterNormal(vec2 p, float distToWater, vec3 n) {
    // make water less noise the futher away it is
    float offset = -10.0 * (1.0 - smoothstep(0.0, 100.0, distToWater));
    vec2 dx = vec2(0.1, 0.0);
    vec2 dz = vec2(0.0, 0.1);
    vec2 point = p / 5.0;

    vec3 normal = n;
    normal.x = offset * (waterFbm(point + dx) - waterFbm(point - dx));
    normal.z = offset * (waterFbm(point + dz) - waterFbm(point - dz));
    return normalize(normal);
}

/********************************************** Start Code for SDFs **********************************************/

struct Cube {
    vec3 min;
    vec3 max;
};

vec3 getWoodColor(vec3 p) {
    vec3 darkGrain = vec3(0.40, 0.19, 0);
    vec3 lightGrain = vec3(0.72, 0.39, 0.22);
    float fbm = fract(fbm3(p / 5.0) * 10.0);
    return mix(darkGrain, lightGrain, fbm);
}

float subsurface(vec3 lightDir, vec3 normal, vec3 viewVec, float thickness) {
    vec3 scatteredLightDir = lightDir + normal * 0.2;
    float lightReachingEye = pow(clamp(dot(viewVec, -scatteredLightDir), 0.0, 1.0), 6.0) * 3.0;
    float attenuation = 1.0;
    float totalLight = attenuation * (lightReachingEye) * thickness;
    return totalLight;
}

// Adapted from 460 slides
float rayCubeIntersect(Cube c, vec3 ray_origin, vec3 ray_dir) {
    float tnear = -1000.0;
    float tfar = 1000.0;
    for (int i = 0; i < 3; i++) {
        if (ray_dir[i] == 0.0) {
            if (ray_origin[i] < c.min[i] || ray_origin[i] > c.max[i]) {
                return 1000.0;
            }
        }
        float t0 = (c.min[i] - ray_origin[i]) / ray_dir[i];
        float t1 = (c.max[i] - ray_origin[i]) / ray_dir[i];
        if (t0 > t1) {
            float temp = t0;
            t0 = t1;
            t1 = temp;
        }
        tnear = max(t0, tnear);
        tfar = min(t1, tfar);
    }
    if (tnear > tfar) {
        return 1000.0;
    }
    return tnear;
}

mat4 rotationMatrix(vec3 axis, float radian) {
    axis = normalize(axis);
    float s = sin(radian);
    float c = cos(radian);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

// Primitive SDFs from IQ
float opSubtraction(float d1, float d2) {
    return max(-d1, d2);
}

float opUnion(float d1, float d2) {
    return min(d1, d2); 
}

float opIntersection(float d1, float d2) { 
    return max(d1,d2);
}

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdCylinder(vec3 p, vec3 c) {
    return length(p.xy - c.xy) - c.z;
}

float sdVerticalCapsule(vec3 p, float h, float r) {
    p.y -= clamp(p.y, 0.0, h);
    return length(p) - r;
}

float sdHorizontalCapsule(vec3 p, float h, float r) {
    p.z -= clamp(p.z, 0.0, h);
    return length(p) - r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float sdSail1(vec3 p, float s) {
    // if (p.z < 0.0 || p.y < 0.0) {
    //     return 1.0;
    // }
    float val = length(p) - s;
    return opIntersection(sdBox(p - vec3(0, 1, 1), vec3(1, 1, 1)), val);
}

float sdSail2(vec3 p, float s) {
    // if (p.z > 0.0 || p.y < 0.0) {
    //     return 1.0;
    // }
    float val = length(p) - s;
    return opIntersection(sdBox(p - vec3(0, 1, -1), vec3(1, 1, 1)), val);
}

float sdBoatBaseShape(vec3 p) {
    // Make symmetric over x-axis
    vec3 point = p;
    point.x = abs(point.x);
    
    // Create initial base of boat out of sphere sdf
    float sdfVal = sdSphere(point.xyz - vec3(-4, 3, 0), 6.0);
    
    // Remove a large cylinder over the top portion of the sphere
    // Such that only the bottom arc of the sphere remains
    float cylinder = sdCylinder(point, vec3(0.5, 15, 14.5));
    sdfVal = opSubtraction(cylinder, sdfVal);
    
    // Remove a portion of the bottom sphere arc to make the boat bottom flat
    float bottomCut = p.y + 0.5;
    sdfVal = opSubtraction(bottomCut, sdfVal);
    
    return sdfVal;
}

float sdBoatBase(vec3 p) {
    // Cuts the boat shape by another raised boat shape to make the boat have an inner portion
    return opSubtraction(sdBoatBaseShape(p), sdBoatBaseShape(vec3(p.x, p.y + 0.2, p.z)));
}

float sdBoatSail(vec3 p, inout vec3 color, bool getColor) {
    float longBase = sdVerticalCapsule(p, 10.0, 0.1);
    float shortBase = sdVerticalCapsule(p, 1.5, 0.2);
    float base = opUnion(longBase, shortBase);

    vec3 handlePoint = vec3(p.x, p.y - 1.9, p.z);
    float handleBrace = sdVerticalCapsule(handlePoint, 0.2, 0.17);
    handlePoint = vec3(p.x, p.y - 2.0, p.z);
    float handleArm = sdHorizontalCapsule(handlePoint, 4.0, 0.1);
    float handle = opUnion(handleBrace, handleArm);

    float woodPole = opUnion(base, handle);
    if (getColor && woodPole < epsilon) {
        color = getWoodColor(p);
    }

    vec3 sail1Point = vec3(handlePoint.x * 5.0, (handlePoint.y - 0.2) / 8.0, (handlePoint.z - 0.2) / 4.0);
    float sail1 = sdSail1(sail1Point, 1.0);
    vec3 sail2Point = vec3(handlePoint.x * 5.0, (handlePoint.y + 1.0) / 7.0, (handlePoint.z + 0.5) / 2.0);
    float sail2 = sdSail2(sail2Point, 1.0);
    float sail = opUnion(sail1, sail2);

    if (getColor && sail < epsilon) {
        color = vec3(5);
    }

    return opUnion(woodPole, sail);
}

float sdBoat(vec3 p, inout vec3 color, bool getColor) {
    float boatBase = sdBoatBase(p);
    if (getColor && boatBase < epsilon) {
        color = getWoodColor(p);
    }
    vec3 sailPoint = vec3(p.x, p.y + 0.5, p.z + 0.8);
    float sail = sdBoatSail(sailPoint, color, getColor);
    return opUnion(boatBase, sail);
}

vec3 boatTransform(vec3 p) {
    float angleZ = cos(0.05 * u_Time) * 3.0 / 180.0 * PI;
    mat4 rotZ = rotationMatrix(vec3(0, 0, 1), angleZ);
    vec4 point = rotationMatrix(vec3(0, 1, 0), 0.8 * PI) * vec4(p, 1.0) + vec4(0, -0.7, 0, 1);
    return vec3(rotZ * point);
}

float sceneSdfWithColor(vec3 p, inout vec3 color, bool getColor) {
    vec3 point = boatTransform(p);
    return sdBoat(point, color, getColor);
}

float sceneSdf(vec3 p) {
    vec3 point = boatTransform(p);
    vec3 holder;
    return sdBoat(point, holder, false);
}

// float fiveTapAO(vec3 p, vec3 n) {
//     float aoSum = 0.0;
//     for(float i = 0.0; i < 5.0; ++i) {
//         float coeff = 1.0 / pow(2.0, i);
//         aoSum += coeff * (i * 0.5 - sceneSdf(p + n * i *  0.5));
//     }
//     return 1.0 - 2.0 * aoSum;
// }

vec3 sceneNormal(vec3 p) {
    float dx = 0.1;
    return normalize(vec3(
        sceneSdf(vec3(p.x + dx, p.y, p.z)) - sceneSdf(vec3(p.x - dx, p.y, p.z)),
        sceneSdf(vec3(p.x, p.y + dx, p.z)) - sceneSdf(vec3(p.x, p.y - dx, p.z)),
        sceneSdf(vec3(p.x, p.y, p.z + dx)) - sceneSdf(vec3(p.x, p.y, p.z - dx))
    ));
}

float softShadow(vec3 origin, vec3 dir, float min_t, float k) {
    float res = 1.0;
    float t = min_t;
    for(int i = 0; i < 100; ++i) {
        float m = sceneSdf(origin + t * dir);
        if(m < 0.0001) {
            return 0.0;
        }
        res = min(res, k * m / t);
        t = t + 0.1;
    }
    return res;
}

float shadow(vec3 p) {
    vec3 sun_dir = normalize(vec3(0.0, cos(u_Time / 175.0), sin(u_Time / 175.0)));
    vec3 sun_pos = 100.0 * sun_dir; 
    float sunShadow = clamp(softShadow(p, normalize(sun_pos - p), 0.1, 6.0), 0.0, 1.0);
    if (sun_dir.y < -0.2) {
        sunShadow = mix(sunShadow, 1.0, abs(sun_dir.y + 0.2) / 0.8);
    }

    vec3 moon_dir = normalize(vec3(0.0, cos(u_Time / 175.0 + PI), sin(u_Time / 175.0 + PI)));
    vec3 moon_pos = 100.0 * moon_dir; 
    float moonShadow = clamp(softShadow(p, normalize(moon_pos - p), 0.1, 6.0), 0.0, 1.0);
    if (moon_dir.y < 0.2) {
        moonShadow = mix(moonShadow, 1.0, abs(moon_dir.y - 0.2) / 1.2);
    }

    return 0.5 * sunShadow + 0.5 * moonShadow;
}

vec3 getSailRipple(vec2 p, float distToWater, vec3 n) {
    // make water less noise the futher away it is
    float offset = -10.0;
    vec2 dy = vec2(0.1, 0.0);
    vec2 dz = vec2(0.0, 0.1);
    vec2 point = p;

    vec3 normal = n;
    normal.y = offset * (waterFbm(point + dy) - waterFbm(point - dy));
    normal.z = offset * (waterFbm(point + dz) - waterFbm(point - dz));
    return normalize(normal);
}

vec3 getSailColor(vec3 p) {
    vec3 sailPoint = boatTransform(p);
    vec3 normal;
    if (sailPoint.x < 0.0) {
        normal = getSailRipple(p.xz, 1.0, vec3(-1, 0, 0));
        normal = boatTransform(normal);
    } else {
        normal = getSailRipple(p.xz, 1.0, vec3(1, 0, 0));
        normal = boatTransform(normal);
    }
    normal = normalize(normal);

    vec3 sun_dir = normalize(vec3(0.0, cos(u_Time / 175.0), sin(u_Time / 175.0)));
    vec3 sun_pos = 100.0 * sun_dir;
    vec3 lightDir = normalize(sun_pos - p);
    vec3 viewVec = normalize(u_Eye - p);
    float thickness = 0.1;

    float sunSub = subsurface(lightDir, normal, viewVec, thickness);
    vec3 sunSubColor = 3.0 * vec3(1.0, 0.67, 0.67) * sunSub * vec3(1.0, 0.88, 0.7);

    vec3 moon_dir = normalize(vec3(0.0, cos(u_Time / 175.0 + PI), sin(u_Time / 175.0 + PI)));
    vec3 moon_pos = 100.0 * moon_dir; 
    lightDir = normalize(moon_pos - p);
    float moonSub = subsurface(lightDir, normal, viewVec, thickness);
    vec3 moonSubColor = 2.0 * vec3(0.67, 0.67, 1.0) * moonSub * vec3(0.7, 0.88, 1.0);

    vec3 light_pos = vec3(5, 5, 10);
    vec3 direction = normalize(light_pos - p);
    vec3 naturalSub = 0.1 * vec3(subsurface(direction, normal, viewVec, thickness));

    vec3 color = clamp(vec3(0.4, 0.4, 0.4) + sunSubColor + moonSubColor + naturalSub, 0.0, 1.0);

    light_pos = vec3(4, 20, 4);
    float diffuseTerm = dot(normalize(normal), normalize(direction));
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
    float ambientTerm = mix(0.5, 1.0, sun_dir.y / 2.0 + 0.5);
    float lightIntensity = diffuseTerm + ambientTerm;
    color = clamp(lightIntensity * color, 0.0, 1.0);

    return color;
}

vec3 getLighting(vec3 p, vec3 color) {
    // special case for sails 
    if (color.y == 5.0) {
        return getSailColor(p);
    }
    vec3 light_pos = vec3(4, 20, 4);

    vec3 direction = light_pos - p;
    vec3 normal = sceneNormal(p);

    float diffuseTerm = dot(normalize(normal), normalize(direction));
    diffuseTerm = clamp(diffuseTerm, 0.0, 1.0);
    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;
    float shadowColor = shadow(p);
    return clamp(color.rgb * lightIntensity * shadowColor, 0.0, 1.0);
}

bool rayMarch(vec3 origin, vec3 direction, inout vec3 color) {
    Cube boundingBox;
    boundingBox.min = vec3(-5, -1, -5);
    boundingBox.max = vec3(5, 11, 5);
    float t = rayCubeIntersect(boundingBox, origin, direction);

    while (t < 100.0) {
        vec3 point = origin + t * direction;

        float distance = sceneSdfWithColor(point, color, true);
        if (distance < epsilon) {
            color = getLighting(point, color);
            return true;
        }

        t = t + 0.05;
    }

    return false;
}

/********************************************** Start Code for Main **********************************************/

void main() {
    // Set up Ray Casting
	vec3 u_Right = normalize(cross(u_Ref - u_Eye, u_Up));
	float len = length(u_Ref - u_Eye);
	float aspectRatio = u_Dimensions.x / u_Dimensions.y;
	vec3 v = tan(fov / 2.0) * len * u_Up;
	vec3 h = aspectRatio * tan(fov / 2.0) * len * u_Right;
	vec3 worldPoint = u_Ref + fs_Pos.x * h + fs_Pos.y * v;
	vec3 rayDir = normalize(worldPoint - u_Eye);

    vec3 fogColor;
    vec3 color = vec3(1, 0, 0);  

    // Draw water and sky
	float waterDist = planeIntersect(u_Eye, rayDir, vec4(0, 1, 0, 0));
	if (waterDist > 0.0) {
        // Draws the water
		vec3 point = u_Eye + waterDist * rayDir;
        vec3 normal = getWaterNormal(point.xz, waterDist, vec3(0, 1, 0));
        vec3 reflection = reflect(rayDir, normal);
        vec3 waterColor = vec3(0.7, 0.7, 1.0);

        // Find the color of the water reflection
        vec3 feelerPoint = vec3(point.x, point.y - 2.0, point.z);
        if (!rayMarch(feelerPoint, reflection, color)) {
            // Did not hit sceneSDF, reflects the sky
		    vec3 farClip = point + 1000.0 * reflection;

            color = skyBox(farClip, reflection, fogColor);
            color = applyFog(color, waterDist, fogColor);
        }

        // Accumulates the water refleciton color 
        color = waterColor * color;

        // Adds shadow
        color = clamp(color * shadow(point), 0.0, 1.0);
	} else {
        // Draws the sky
        vec3 farClip = u_Eye + 1000.0 * rayDir;
    	color = skyBox(farClip, rayDir, fogColor);
	}

    rayMarch(u_Eye, rayDir, color); 

    out_Col = vec4(color, 1);
}