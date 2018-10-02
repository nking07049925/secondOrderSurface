PShader frag;
float a11, a22, a33; // x² y² z²
float a12, a13, a23; // xy xz yz
float a14, a24, a34; // x  y  z
float a44;           // 1
float boundingCubeSize = 5; //set to zero for none
color surfaceC = color(255);

// Matrix for camera transformations
PMatrix3D camMat;
// Image scale
float camScale = 0.025;


// Lighting variables
PVector lightPos;
boolean directionalLight = false;
color lightC = color(128);
color ambientC = color(128);
float lightIntensity = 1;
color diffuse = color(128), specular = color(256);
float shininess = 50, reflect = 0.5;

float glareForce = 1;
float glarePower = 100;
color glareColor = color(256);

// Scale restraints

float minScale = 0.001;
float maxScale = 0.05;

// Rendering and interface flags

boolean normalColor = false;
boolean iterateValues = true;

PImage skybox;

PGraphics render;

void setup() {
  fullScreen(P2D);
  //size(1920, 1080, P2D);
  
  render = createGraphics(width, height, P2D);
  frag = loadShader("frag.glsl");
  skybox = loadImage("skybox.png");
  frag.set("skybox", skybox);
  camMat = new PMatrix3D();

  fill(255);
  noStroke();

  lightPos = new PVector(-1000, 800, 2200);

  if (!iterateValues) {
    a11 = 1; // x²
    a22 = -1; // y²
    a33 = 1; // z²
  
    a12 = 0; // xy
    a13 = 0; // xz
    a23 = 0; // yz
  
    a14 = 0; // x
    a24 = 1; // y
    a34 = 0; // z
  
    a44 = -1; // 1
  
    a12 /= 2f;
    a13 /= 2f;
    a23 /= 2f;
    a14 /= 2f;
    a24 /= 2f;
    a34 /= 2f;
  }
}

float degY = PI/6;
float degX = 0;

void draw() {
  // Calculating the camera matrix
  camMat.reset();
  camMat.rotateY(-degX);
  camMat.rotateX(-degY);
  camMat.translate(0, 0, 500);
  
  if (iterateValues)
    updateValues();
    
  // Passing variables from the sketch to the shader
  setShader();
  // Rendering the scene
  render.beginDraw();
  render.shader(frag);
  render.beginShape(); 
  render.vertex(0, 0);
  render.vertex(width, 0);
  render.vertex(width, height);
  render.vertex(0, height);
  render.endShape();
  render.endDraw();
  // Rendering the result onto the sketch
  image(render, 0, 0);
}

float camSpeedCoeff = 0.05;

void mouseDragged() {
  float yDiff = mouseY - pmouseY;
  float xDiff = mouseX - pmouseX;
  if (mouseButton == LEFT) {
    degY += yDiff * sqrt(camScale) * camSpeed;
    if (degY > HALF_PI) degY = HALF_PI;
    if (degY < -HALF_PI) degY = -HALF_PI;
    degX += xDiff * sqrt(camScale) * camSpeed;
  }
}

float scrollSpeed = 0.001;

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  camScale += e * scrollSpeed;
  if (camScale < minScale) camScale = minScale;
  if (camScale > maxScale) camScale = maxScale;
}

void setShader() {
  PMatrix3D surface = new PMatrix3D(
    a11, a12, a13, a14, 
    a12, a22, a23, a24, 
    a13, a23, a33, a34, 
    a14, a24, a34, a44
    );
  frag.set("surfaceMat", surface);
  frag.set("cubeSize", boundingCubeSize);
  PVector camPos = new PVector(0, 0, 0);
  camPos = camMat.mult(camPos, camPos);
  frag.set("camPos", PVector.mult(camPos, camScale));
  frag.set("camDist", camPos.mag());
  frag.set("camRot", camMat, true);
  frag.set("normCol", normalColor);
  frag.set("surfaceColor", red(surfaceC)/255f, green(surfaceC)/255f, blue(surfaceC)/255f);
  frag.set("ambientColor", red(ambientC)/255f, green(ambientC)/255f, blue(ambientC)/255f);
  frag.set("lightColor", red(lightC)/255f, green(lightC)/255f, blue(lightC)/255f);
  frag.set("lightPos", lightPos.x, lightPos.y, lightPos.z, directionalLight ? 0.0 : 1.0);
  frag.set("lightIntensity", lightIntensity);
  frag.set("diffuse", red(diffuse)/255f, green(diffuse)/255f, blue(diffuse)/255f);
  frag.set("shininess", shininess);
  frag.set("specular", red(specular)/255f, green(specular)/255f, blue(specular)/255f);
  frag.set("reflectivity", reflect);
  frag.set("glarePower", glarePower);
  frag.set("glareForce", glareForce);
  frag.set("glareColor", red(glareColor)/255f, green(glareColor)/255f, blue(glareColor)/255f);
}

// You can have some dependencies of the surface coefficients overtime here
float offset = 0;

void updateValues() {
  offset += 0.01;

  a11 = 1 + sin(deg); // x²
  a22 = 1 + sin(deg + 1); // y²
  a33 = 1 + sin(deg + 2); // z²

  a12 = 1 + sin(deg + 3); // xy
  a13 = 1 + sin(deg + 4); // xz
  a23 = 1 + sin(deg + 5); // yz

  a14 = 1 + sin(deg + 6); // x
  a24 = 1 + sin(deg + 7); // y
  a34 = 1 + sin(deg + 8); // z

  a44 = 1 + sin(deg + 9); // 1
}
