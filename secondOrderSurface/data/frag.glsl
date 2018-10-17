#ifdef GL_ES
	precision mediump float;
	precision mediump int;
#endif

// pi constant
const float PI = 3.14159265359;
const float EPS = 1e-2;
const int MAX_REFLECT = 5;

struct Intersection {
	bool found;
	vec3 pos;
};

// matrix representing the second order surface
uniform mat4 surfaceMat;
uniform float matDet;
// bounding box size (set to 0 for no bounding box)
uniform float cubeSize;
// color of the surface
uniform vec3 surfaceColor;

uniform vec3 ambientColor;

uniform vec3 lightColor;
// point light position, if w is 0 then it's a directional light
uniform vec4 lightPos;
uniform float lightIntensity;

// Light variables
uniform vec3 diffuse;
uniform vec3 specular;
uniform float shininess;
uniform float reflectivity;
//uniform float opacity;
//uniform float refractCoeff;

uniform float glareForce;
uniform float glarePower;
uniform vec3 glareColor;

// distance from the camera to the (0,0,0) point
// precalculated in the sketch so it's not recalculated for each fragment
uniform float camDist;
// matrix representing the rotation of camera direction
uniform mat3 camRot;
// vector representing camera's position
uniform vec3 camPos;
// draw color of the normal flag
uniform bool normCol;

// sampler2D containing the skybox image
uniform sampler2D skybox;

// Processing vector representing the screen dimensions
uniform vec4 viewport;


// getting the color from a panoramic background image using a directional vector
vec3 getSkybox(vec3 dir) {
	// cartesian to spherical
	float sqrtXZ = sqrt(dir.x * dir.x + dir.z * dir.z);
	vec2 angles = vec2(atan(-dir.z, dir.x) + PI,
  	atan(-dir.y, sqrtXZ) + 0.5 * PI);
	// normalizing coords
	vec2 texPos = angles / vec2(2.0 * PI, PI);
	return texture2D(skybox, texPos).xyz;
}

// Checking if a point is within a bounding box
bool inCube(vec3 pos) {
	if (cubeSize == 0.0) return true;
	return all(lessThan(abs(pos), vec3(cubeSize)));
} 

// calculating the closest intersection point
Intersection findPos(vec3 p, vec3 d) {
	// A ray can be represented as p + dt = g where p is the starting position, d the direction
	// and t is variable and g is an arbitray point on the ray

	// At the same time G*A*Gtr = 0 is the matrix representation 
	// of surface of the second order equation, where G is a row vector (g.x g.y g.z 1),
	// Gtr is the transpose of G and A is the matrix of surface coefficients

	/*
	 *     A equals to    | same coefficients in a more canonical form
	 *   a11 a12 a13 a14  |    a11 x² + a22 y² + a33 z² + 
	 *   a12 a22 a23 a24  |    + 2 a12 xy + 2 a13 xz + 2 a23 yz + 
	 *   a13 a23 a33 a34  |    + 2 a14 x + 2 a24 y + 2 a34 z + a44 = 0
	 *   a14 a24 a34 a44  |  
	 */

	Intersection res;
	res.found = false;
	res.pos = vec3(0.0);

	vec4 P1 = vec4(p, 1.0);
	vec4 D0 = vec4(d, 0.0);
	vec4 P1A = P1 * surfaceMat;
	vec4 D0A = D0 * surfaceMat;
	float a = dot(D0A, D0);
	float b = dot(P1A, D0) + dot(D0A, P1);
	float c = dot(P1A, P1);
	// calculating the discriminant
	float D = b * b - 4.0 * a * c;
	// no intersections

	if (D < 0.0) return res;

	if (a == 0.0) {
		if (b != 0.0) {
			float t = -c / b;
			res.pos = p + d*t;
		} else return res;
	} else {
		D = sqrt(D);
		float a2 = a * 2.0;
		float t1 = (-b - D) / a2;
		float t2 = (-b + D) / a2;
		
		// Finding the closest intersection that is in front of the camera
		// and within the bounding box

		if (t1 >= 0.0 && t2 >= 0.0) {

    	// If both points are in front of the camera we find the closest one
			if (t1 > t2) {
				float temp = t1;
				t1 = t2;
				t2 = temp;
			}

			vec3 pos1 = p + d*t1;
			vec3 pos2 = p + d*t2;

			// and check if it's within the bounding box, if not we take the further one

			if (inCube(pos1))
				res.pos = pos1;
			else if (inCube(pos2))
				res.pos = pos2;
			else return res;

		} else {

			float t = 0.0;
			if (t2 >= 0.0) t = t2;
			else if (t1 >= 0.0) t = t1;
			else return res;

			vec3 pos = p + d*t;
			if (inCube(pos))
				res.pos = pos;
			else return res;	

		}
	}

	res.found = true;
	return res;
}

// Calculate the normal
vec3 findNorm(vec3 p) {
	vec4 P = vec4(p, 1.0);
	vec4 N = P * surfaceMat;
	return normalize(N.xyz);
}

// Calculate the color of the normal
vec3 normToColor(vec3 norm) {
	return (norm + vec3(1.0)) * 0.5;
}

// Calculating the light
vec3 calcLight(vec3 pos, vec3 norm, vec3 camDir, vec3 lightDir) {
	
	// Ambient light
	vec3 col = surfaceColor * ambientColor * (1.0 - reflectivity);

	// Reflected light from the light source
	vec3 reflDir = reflect(-lightDir, norm);

	// Checking for shadows by running a ray from the position to the light source
	Intersection selfInter = findPos(pos + EPS * norm, lightDir);
	vec3 light = vec3(0.0);

	// If we are not shadowed, use phong model to calulate the light
  if (!selfInter.found) {
		light += diffuse * max( dot(lightDir, norm), 0.0);
		light += specular * pow( max( dot(reflDir, camDir), 0.0), shininess);
	}

	return col + light * lightColor * lightIntensity;
}

// Skybox calculation with additional glare from the light source so it's position is visible
vec3 getSkyboxWithGlare(vec3 rayDir) {
	vec3 col = getSkybox(rayDir);
	vec3 camLightDir = normalize(lightPos.w > 0.0 ? lightPos.xyz - camPos : -lightPos.xyz);
	vec3 normRayDir = normalize(rayDir);
	vec3 light = glareForce * glareColor * pow( max( dot(camLightDir, normRayDir), 0.0), glarePower);
	return col + vec3(light);
}

vec3 trace(vec3 rayPos, vec3 rayDir) {
	// The main intersection
	Intersection inter = findPos(rayPos, rayDir);

	// Simplified calculation for when the surface is not reflective

	if (reflectivity == 0.0) {
		if (inter.found) {
			// Position on the surface
			vec3 pos = inter.pos;
			// Normal in the position
			vec3 norm = findNorm(pos);
			// Vector from the position to the camera
			vec3 camDir = normalize(-rayDir);
			// Normal reorientation so it's always facing in the right direction
			norm *= sign(dot(camDir, norm));

			// If the material is normals, no further calculations required
			if (normCol)
				return normToColor(norm);

			// Vector from the position to the light source
			vec3 lightDir = normalize(lightPos.w > 0.0 ? lightPos.xyz - pos : -lightPos.xyz);

			// Returning the calculated light
			return calcLight(pos, norm, camDir, lightDir);
		}
	} else {
		// Calculation with MAX_REFLECT reflections, set to 1 for the reflection to go into skybox
		// without intersecting the surface

		// Color sum
		vec3 col = vec3(0.0);
		// Flag for getting out of the loop early
		bool left = false;
		// Float value that represents the decrease in brightness of the Nth reflection
		float reflectMult = 1.0;
		// Current ray direction, altered each reflection
		vec3 curDir = rayDir;

    // Repeating until we hit the max count or didn't find an interesection with the surface
		for (int i = 0; i < MAX_REFLECT && !left; i++) {
			// If we find an intersection, light for current one is calculated
			if (inter.found) {
				// Current position on the surface
				vec3 pos = inter.pos;
				// Current normal
				vec3 norm = findNorm(pos);
				// Reverse direction
				vec3 revDir = normalize(-curDir);
				norm *= sign(dot(revDir, norm));
				// Vector from current position to the light source
				vec3 lightDir = normalize(lightPos.w > 0.0 ? lightPos.xyz - pos : -lightPos.xyz);

				// Calculating current light with the amount of reflections taken into account
				col += reflectMult * calcLight(pos, norm, revDir, lightDir);

				// Calculating the direction of the reflected ray
				vec3 viewRefl = reflect(curDir, norm);
				// Calculating the intersection of the reflected ray
				if (i < MAX_REFLECT - 1)
					inter = findPos(pos + EPS * norm, viewRefl);
				// Updating the reflection coeffecient
				reflectMult *= reflectivity;
				// Updating the direction
				curDir = viewRefl;
			} else {
				left = true;
				// Getting the last reflection
				col += reflectMult * getSkyboxWithGlare(curDir);
			}
		}

		// If we went through all reflections without exiting prematurely, calculating the skybox
		if (!left) col += reflectMult * getSkyboxWithGlare(curDir);

		// Returning the resulting color
		return col;
	}

	// If there are no intersections, skybox is returned
	return getSkyboxWithGlare(rayDir);
}

void main() {
	vec3 screenDir = vec3(gl_FragCoord.xy - viewport.zw * 0.5, -camDist);
	// Samples
	vec3 samples[5];
	int i = 0;
	samples[i++] = screenDir + vec3( 0.4, 0.1, 0.0);
	samples[i++] = screenDir + vec3(-0.4, -0.1, 0.0);
	samples[i++] = screenDir + vec3( 0.1,-0.4, 0.0);
	samples[i++] = screenDir + vec3(-0.1, 0.4, 0.0);
	samples[i++] = screenDir;
	// Color stack
	vec3 sum = vec3(0.0);
	for (int i = 0; i < samples.length(); i++) 
		sum += trace(camPos, samples[i] * camRot);
	// The result is interpolated color
	gl_FragColor = vec4(sum / float(samples.length()), 1.0);
	//gl_FragColor = vec4(trace(camPos, screenDir * camRot), 1.0);
}
