class Slider {
  float posX, posY;
  float width, height;
  float value;
  boolean pressed = false;
  
  float lineH1, lineH2;
  String text;
  float textX, textY;
  int textAlignment;
  
  int stepAmount = 0;

  Slider(float x, float y, float w, float val) {
    posX = x;
    posY = y;
    width = w;
    height = 30;
    value = val;
    
    lineH1 = height*0.5;
    lineH2 = height*0.1;
    
    text = "";
    textAlignment = CENTER;
  }

  Slider(float x, float y, float w) {
    this(x, y, w, 0);
  }

  boolean inside(float x, float y) {
    return abs(x - posX) <= width/2 + height/2 && abs(y - posY) <= height/2;
  }

  void press(float x, float y) {
    if (inside(x, y)) {
      calcValue(x);
      pressed = true;
    }
  }

  void release() {
    pressed = false;
  }

  void update(float x, float y) {
    if (pressed) {
      calcValue(x);
    }
  }
  
  private void calcValue(float x) {
    value = constrain((x-posX)/width*2, -1, 1);
    if (stepAmount > 0)
      value = 1f*round(value*stepAmount)/stepAmount;
  }
  
  void setSteps(int steps) {
    stepAmount = steps;
  }

  boolean in = false;

  void display() {
    stroke(128);
    strokeWeight(lineH1);
    line(posX - width/2, posY, posX + width/2, posY);
    strokeWeight(lineH2);
    stroke(80);
    line(posX, posY - lineH1/2 + lineH2, posX, posY + lineH1/2 - lineH2);
    stroke(0);
    line(posX - width/2, posY, posX + width/2, posY);
    fill(pressed?200:255);
    ellipse(posX + width*value/2, posY, height, height);
    textAlign(textAlignment, CENTER);
    textSize(height);
    fill(0);
    text(text, textX, textY - height*0.2);
  }
  
  void addText(String text, float x, float y, int align) {
    this.text = text;
    textX = x;
    textY = y;
    textAlignment = align;
  }
  
  void addText(String text, float x, float y) {
    this.text = text;
    textX = x;
    textY = y;
  }
}

class SliderManager {
  ArrayList<Slider> sliders = new ArrayList<Slider>();
  float posX, posY;
  float leftPos, rightPos;
  float width, height;
  boolean hidden;
  boolean moveOut, moveIn;
  float desPos;

  float barWidth;

  int startFrame;
  int frameAmount = 10;
  
  boolean pressed = false;

  SliderManager(float y, float w, float h) {
    desPos = posX = 0;
    posY = y;
    width = w;
    height = h;
    hidden = true;
    barWidth = width*0.06;
    leftPos = -width/2;
    rightPos = width/2;
  }
  
  void addSlider(Slider slider) {
    sliders.add(slider);
  }

  void addSlider(float x, float y, float w) {
    sliders.add(new Slider(x, y, w));
  }
  
  void addSlider(float x, float y, float w, float val) {
    sliders.add(new Slider(x, y, w, val));
  }

  void display() {
    if (!hidden)
      posX = rightPos;
    else {
      int t = frameCount - startFrame;
      float k = 0;
      if (moveIn) k = -1;
      if (moveOut) k = 1;
      float start = moveIn?rightPos:leftPos;
      float v = 2*(rightPos - leftPos)/frameAmount;
      float a = (rightPos - leftPos)/sq(frameAmount);
      posX = start + k * t*(v - a*t);
      if (t == frameAmount) {
        if (moveOut) hidden = false;
        moveIn = false;
        moveOut = false;
      }
    }

    pushMatrix();
    translate(posX, posY);
    stroke(128);
    strokeWeight(3);
    fill(180);
    rect(0, 0, width, height);
    stroke(60);
    fill(220);
    rect(width/2+barWidth/2, 0, barWidth, height);
    for (int i = 0; i < sliders.size(); i++)
      sliders.get(i).display();
    popMatrix();
  }

  void moveOut() {
    startFrame = frameCount;
    moveOut = true;
  }

  void moveIn() {
    startFrame = frameCount;
    hidden = true;
    moveIn = true;
  }

  void press(float x, float y) {
    pressed = x < width && abs(y - posY) < height/2;
    
    if (hidden && inBar(x,y))
      moveOut();
    
    if (!hidden && inBar(x, y))
      moveIn();

    if (!hidden)
      for (int i = 0; i < sliders.size(); i++)
        sliders.get(i).press(x - posX, y - posY);
  }
  
  boolean inBar(float x, float y) {
    if (hidden)
      return x < barWidth && abs(y - posY) < height/2;
    else
      return abs(x - posX - width/2 - barWidth/2) < barWidth/2 && abs(y - posY) < height/2; 
  }

  void release() {
    pressed = false;
    if (!hidden)
      for (int i = 0; i < sliders.size(); i++)
        sliders.get(i).release();
  }

  void update(float x, float y) {
    if (!hidden)
      for (int i = 0; i < sliders.size(); i++)
        sliders.get(i).update(x - posX, y - posY);
  }
  
  float getValue(int i) {
    return sliders.get(i).value;
  }
  
  void setSteps(int steps) {
    for (int i = 0; i < sliders.size(); i++)
        sliders.get(i).setSteps(steps);
  }
}
