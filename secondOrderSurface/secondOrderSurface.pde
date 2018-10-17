PShader frag;

int valueAmount = 10;
float[] values = new float[valueAmount];

final int a11 = 0, a22 = 1, a33 = 2;
final int a12 = 3, a13 = 4, a23 = 5;
final int a14 = 6, a24 = 7, a34 = 8;
final int a44 = 9;

String[] valueNames = {"x²", "y²", "z²", "xy", "xz", "yz", "x", "y", "z", "1"};

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
float shininess = 50, reflect = 0.0;

float glareForce = 1;
float glarePower = 100;
color glareColor = color(256);

// Scale restraints

float minScale = 0.001;
float maxScale = 0.05;

// Rendering and interface flags

boolean normalColor = false;
boolean iterateValues = false;

PImage skybox;

PGraphics render;

void setup() {
  //fullScreen(P2D);
  size(1800, 1000, P2D);
  //size(640,640,P2D);
  
  render = createGraphics(width, height, P2D);
  frag = loadShader("frag.glsl");
  skybox = loadImage("skybox.jpg");
  frag.set("skybox", skybox);
  camMat = new PMatrix3D();

  fill(255);
  noStroke();
  rectMode(CENTER);

  lightPos = new PVector(-1000, 800, 2200);

  if (!iterateValues) {
    values[a11] = 1; // x²
    values[a22] = 0; // y²
    values[a33] = 0; // z²
  
    values[a12] = 0; // xy
    values[a13] = 0; // xz
    values[a23] = 0; // yz
  
    values[a14] = 0; // x
    values[a24] = 0; // y
    values[a34] = 0; // z
  
    values[a44] = 0; // 1
  }
  
  sm = new SliderManager(height/2, width/4, height*2/3);
  float sliderHeight = sm.height*0.9/valueAmount; 
  float sliderWidth = sm.width*0.7;
  for (int i = 0; i < valueAmount; i++) {
    float posY = (i - valueAmount/2f + 0.5)*sliderHeight;
    float posX = -sliderHeight/2;
    Slider slider = new Slider(posX, posY, sliderWidth, values[i]);
    slider.addText(valueNames[i], sliderWidth/2, posY, LEFT);
    sm.addSlider(slider);
  }
  sm.setSteps(0);
}

float degY = PI/6;
float degX = 0;

SliderManager sm;

void draw() {
  // Calculating the camera matrix
  camMat.reset();
  camMat.rotateY(-degX);
  camMat.rotateX(-degY);
  camMat.translate(0, 0, max(width,height));
  
  if (iterateValues)
    updateValues();
  else 
    readValuesFromSliders(sm);
    
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
  
  
  sm.update(mouseX, mouseY);
  sm.display();
}

float camSpeedCoeff = 0.02;

void mouseDragged() {
  float yDiff = mouseY - pmouseY;
  float xDiff = mouseX - pmouseX;
  if (mouseButton == LEFT && !sm.pressed) {
    degY += yDiff * sqrt(camScale) * camSpeedCoeff;
    if (degY > HALF_PI) degY = HALF_PI;
    if (degY < -HALF_PI) degY = -HALF_PI;
    degX += xDiff * sqrt(camScale) * camSpeedCoeff;
  }
}

void mousePressed() {
  sm.press(mouseX, mouseY);
}

void mouseReleased() {
  sm.release();
}

float scrollSpeed = 1e-3;

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  camScale += e * scrollSpeed;
  if (camScale < minScale) camScale = minScale;
  if (camScale > maxScale) camScale = maxScale;
}

void setShader() {
  PMatrix3D surface = new PMatrix3D(
    values[a11], values[a12], values[a13], values[a14], 
    values[a12], values[a22], values[a23], values[a24], 
    values[a13], values[a23], values[a33], values[a34], 
    values[a14], values[a24], values[a34], values[a44]
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

void readValuesFromSliders(SliderManager sm) {
  for (int i = 0; i < valueAmount; i++) {
    values[i] = sm.getValue(i);
  }
}

// You can have some dependencies of the surface coefficients overtime here
float offset = 0;

void updateValues() {
  offset += 0.003;

  for (int i = 0; i < valueAmount; i++) {
    values[i] = sin(offset + TWO_PI*i/valueAmount*offset) * 2;
  }
}
