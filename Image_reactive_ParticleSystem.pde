PImage sourceImage;
ArrayList<Particle> particles = new ArrayList<Particle>();
boolean imageLoaded = false;
float noiseScale = 0.01; 
float particleSpeed = 0.5;
float lineThreshold = 150;
int particleDensity = 3000;
float particleLifespan = 255;
float edgeAttraction = 1.2;

void setup() {
  size(800, 600, P2D);
  background(0);
  
  sourceImage = loadImage("assets/joker_stairs.jpg");
  sourceImage.resize(width, height);
  imageLoaded = true;
  
  initParticles();
}

void draw() {
  fill(0, 10);
  rect(0, 0, width, height);
  
  if (imageLoaded) {
    updateAndDisplayParticles();
    
    if (frameCount % 10 == 0 && particles.size() < particleDensity) {
      addParticles(20);
    }
  }
}

void initParticles() {
  for (int i = 0; i < particleDensity; i++) {
    addParticle();
  }
}

void addParticles(int count) {
  for (int i = 0; i < count; i++) {
    addParticle();
  }
}

void addParticle() {
  int attempts = 0;
  float x, y;
  
  do {
    x = random(width);
    y = random(height);
    attempts++;
    
    if (attempts > 10) break;
    
    int loc = int(x) + int(y) * sourceImage.width;
    if (loc >= 0 && loc < sourceImage.pixels.length) {
      color c = sourceImage.pixels[loc];
      float brightness = brightness(c);
      
      if (brightness < lineThreshold) {
        break;
      }
    }
  } while (attempts < 10);
  
  particles.add(new Particle(x, y));
}

void updateAndDisplayParticles() {
  sourceImage.loadPixels();
  
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    
    if (p.isDead()) {
      particles.remove(i);
    }
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    saveFrame("particle-system-####.png");
  }
  
  if (key == '1') noiseScale *= 0.9;
  if (key == '2') noiseScale *= 1.1;
  
  if (key == '3') particleSpeed *= 0.9;
  if (key == '4') particleSpeed *= 1.1;
  
  if (key == '5') edgeAttraction *= 0.9;
  if (key == '6') edgeAttraction *= 1.1;
  
  if (key == 'r' || key == 'R') {
    particles.clear();
    initParticles();
  }
}

void mousePressed() {
  for (int i = 0; i < 50; i++) {
    Particle p = new Particle(mouseX, mouseY);
    particles.add(p);
  }
}

void mouseDragged() {
  if (frameCount % 3 == 0) {
    Particle p = new Particle(mouseX, mouseY);
    particles.add(p);
  }
}
