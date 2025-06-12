class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  float maxSpeed;
  color particleColor;
  
  Particle(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(0.5, 1.5));
    acceleration = new PVector(0, 0);
    lifespan = particleLifespan;
    maxSpeed = particleSpeed;
    
    if (x >= 0 && x < sourceImage.width && y >= 0 && y < sourceImage.height) {
      int loc = int(x) + int(y) * sourceImage.width;
      if (loc >= 0 && loc < sourceImage.pixels.length) {
        particleColor = sourceImage.pixels[loc];
      } else {
        particleColor = color(255);
      }
    } else {
      particleColor = color(255);
    }
  }
  
  void update() {
    float noiseVal = noise(position.x * noiseScale, position.y * noiseScale, frameCount * 0.005);
    float angle = map(noiseVal, 0, 1, 0, TWO_PI * 2);
    
    PVector noiseForce = PVector.fromAngle(angle);
    noiseForce.mult(0.1);
    
    PVector edgeForce = edgeDetectionForce();
    edgeForce.mult(edgeAttraction);
    
    acceleration.add(noiseForce);
    acceleration.add(edgeForce);
    
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    
    acceleration.mult(0);
    
    lifespan -= 0.5;
    
    if (position.x < 0) position.x = width;
    if (position.x > width) position.x = 0;
    if (position.y < 0) position.y = height;
    if (position.y > height) position.y = 0;
  }
  
  PVector edgeDetectionForce() {
    int x = constrain(int(position.x), 0, sourceImage.width - 1);
    int y = constrain(int(position.y), 0, sourceImage.height - 1);
    int loc = x + y * sourceImage.width;
    
    PVector force = new PVector(0, 0);
    
    if (loc >= 0 && loc < sourceImage.pixels.length) {
      for (int offsetY = -1; offsetY <= 1; offsetY++) {
        for (int offsetX = -1; offsetX <= 1; offsetX++) {
          int newX = x + offsetX;
          int newY = y + offsetY;
          
          if (newX >= 0 && newX < sourceImage.width && newY >= 0 && newY < sourceImage.height) {
            int newLoc = newX + newY * sourceImage.width;
            color c = sourceImage.pixels[newLoc];
            float b = brightness(c);
            
            if (b < lineThreshold) {
              PVector direction = new PVector(offsetX, offsetY);
              direction.normalize();
              direction.mult(map(b, 0, lineThreshold, 1.0, 0.1));
              force.add(direction);
            }
          }
        }
      }
    }
    
    return force;
  }
  
  void display() {
    stroke(red(particleColor), green(particleColor), blue(particleColor), lifespan);
    strokeWeight(1);
    point(position.x, position.y);
    
    for (Particle other : particles) {
      float d = PVector.dist(position, other.position);
      if (d > 0 && d < 15) {
        float alpha = map(d, 0, 15, 100, 0) * (lifespan / particleLifespan);
        stroke(red(particleColor), green(particleColor), blue(particleColor), alpha);
        line(position.x, position.y, other.position.x, other.position.y);
      }
    }
  }
  
  boolean isDead() {
    return lifespan < 0;
  }
}
