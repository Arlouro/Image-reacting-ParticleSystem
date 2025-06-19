import processing.sound.*;
PImage img;
PGraphics revealMask, glowLayer, trailLayer;
SoundFile music;
Amplitude amp;
Particle[] particles;
FFT fft;
int bands = 512;
float[] spectrum = new float[bands];

int currentIndex = 0;

// Asset arrays for 12 compositions
String[] images = {
  "abandoned_house.jpg", "chernobyl_chimney.jpg", "chernobyl_cleaning.jpg", "chernobyl_cleaning_2.jpg",
  "iceland_aurora.jpg", "iceland_beach.jpg", "joker_sit.jpg", "joker_smile.jpg",
  "joker_stairs.jpg", "iceland_volcano.jpg", "iceland_glacier.jpg", "iceland_waterfall.jpg"
};

String[] audioFiles = {
  "elevation.mp3", "12_hours_before.mp3", "bridge_of_death.mp3", "the_door.mp3",
  "ascent.mp3", "bathroom_dance.mp3", "its_showtime.mp3", "into_warmer_air.mp3",
  "call_me_joker.mp3", "a_deal_with_chaos.mp3", "lidur.mp3", "folk_faer_andlit.mp3"
};

String[] compositionNames = {
  "Elevation", "12 Hours Before", "Bridge of Death", "Finale",
  "Ascent", "Building the Ship", "Under the Surface", "Orbital",
  "Heyr Himnasmiður", "Liminal", "Erupting Light", "Fólk fær andlit"
};

float smoothedLevel = 0;
float bassLevel = 0, midLevel = 0, trebleLevel = 0;
int particleCount;
ParticleType currentType;
ImageField imgField;

// Enhanced visual parameters
float globalBrightness = 1.0;
float glowIntensity = 0.8;
float trailLength = 0.9;
color[] compositionPalette;
float beatThreshold = 0.3;
boolean beatDetected = false;
int beatTimer = 0;

enum ParticleType {
  ELEVATION, INDUSTRIAL, DECAY, FINALE, ASCENT, ORGANIC, PSYCHOLOGICAL, ORBITAL,
  SACRED, LIMINAL, VOLCANIC, FOLK
}

ArrayList<PVector> strategicPoints = new ArrayList<PVector>();
float colorChangeThreshold = 120;

color[][] palettes = {
  {color(135, 206, 235), color(255, 255, 255), color(173, 216, 230), color(176, 196, 222)},
  {color(255, 69, 0), color(105, 105, 105), color(255, 140, 0), color(169, 169, 169)},
  {color(107, 142, 35), color(139, 69, 19), color(85, 107, 47), color(160, 82, 45)},
  {color(138, 43, 226), color(255, 215, 0), color(75, 0, 130), color(255, 165, 0)},
  {color(255, 215, 0), color(255, 140, 0), color(255, 165, 0), color(255, 69, 0)},
  {color(34, 139, 34), color(0, 128, 0), color(50, 205, 50), color(124, 252, 0)},
  {color(220, 20, 60), color(139, 0, 0), color(255, 0, 0), color(128, 0, 0)},
  {color(25, 25, 112), color(72, 61, 139), color(123, 104, 238), color(147, 112, 219)},
  {color(255, 215, 0), color(255, 255, 255), color(255, 248, 220), color(255, 228, 181)},
  {color(255, 20, 147), color(0, 255, 255), color(186, 85, 211), color(64, 224, 208)},
  {color(255, 0, 0), color(255, 69, 0), color(255, 140, 0), color(255, 165, 0)},
  {color(139, 69, 19), color(34, 139, 34), color(210, 180, 140), color(107, 142, 35)}
};

void setup() {
  size(1280, 720, P2D);

  img = loadImage("assets/" + images[currentIndex]);
  img.resize(width/2, height/2);
  music = new SoundFile(this, "assets/" + audioFiles[currentIndex]);

  revealMask = createGraphics(width, height, P2D);
  glowLayer = createGraphics(width, height, P2D);
  trailLayer = createGraphics(width, height, P2D);

  revealMask.beginDraw(); revealMask.background(0); revealMask.endDraw();
  glowLayer.beginDraw(); glowLayer.background(0); glowLayer.endDraw();
  trailLayer.beginDraw(); trailLayer.background(0); trailLayer.endDraw();

  amp = new Amplitude(this);
  fft = new FFT(this, bands);
  amp.input(music);
  fft.input(music);

  setCompositionStyle();
  findStrategicPoints();

  particles = new Particle[particleCount];
  for (int i = 0; i < particleCount; i++) {
    particles[i] = new Particle(currentType);
  }

  imgField = new ImageField(img, 8);

  music.play();
  frameRate(30);

  println("Playing: " + compositionNames[currentIndex]);
}

void setCompositionStyle() {
  ParticleType[] types = {
    ParticleType.ELEVATION, ParticleType.INDUSTRIAL, ParticleType.DECAY, ParticleType.FINALE,
    ParticleType.ASCENT, ParticleType.ORGANIC, ParticleType.PSYCHOLOGICAL, ParticleType.ORBITAL,
    ParticleType.SACRED, ParticleType.LIMINAL, ParticleType.VOLCANIC, ParticleType.FOLK
  };
  int[] counts = {75, 100, 75, 125, 87, 75, 87, 75, 62, 75, 100, 75};
  currentType = types[currentIndex];
  particleCount = counts[currentIndex];
  compositionPalette = palettes[currentIndex];
}

void findStrategicPoints() {
  strategicPoints.clear();
  if (img == null) return;
  img.loadPixels();
  int step = 20;
  for (int y = step; y < img.height-step; y += step) {
    for (int x = step; x < img.width-step; x += step) {
      color c = img.pixels[y * img.width + x];
      color cR = img.pixels[y * img.width + (x+step)];
      color cD = img.pixels[(y+step) * img.width + x];
      float dR = colorDist(c, cR);
      float dD = colorDist(c, cD);
      if (dR > colorChangeThreshold || dD > colorChangeThreshold) {
        float sx = map(x, 0, img.width, 0, width);
        float sy = map(y, 0, img.height, 0, height);
        strategicPoints.add(new PVector(sx, sy));
      }
    }
  }
}

float colorDist(color a, color b) {
  float dr = red(a) - red(b);
  float dg = green(a) - green(b);
  float db = blue(a) - blue(b);
  return sqrt(dr*dr + dg*dg + db*db);
}

void draw() {
  float level = amp.analyze();
  smoothedLevel = lerp(smoothedLevel, level, 0.1);

  beatDetected = smoothedLevel > beatThreshold;
  if (beatDetected) beatTimer = 10;
  if (beatTimer > 0) beatTimer--;

  fft.analyze(spectrum);
  bassLevel = 0; midLevel = 0; trebleLevel = 0;
  int bassEnd = bands/8, midStart = bassEnd, midEnd = bands/2, trebleStart = midEnd;
  for (int i = 0; i < bassEnd; i++) bassLevel += spectrum[i];
  for (int i = midStart; i < midEnd; i++) midLevel += spectrum[i];
  for (int i = trebleStart; i < bands; i++) trebleLevel += spectrum[i];
  bassLevel /= (bassEnd);
  midLevel /= (midEnd - midStart);
  trebleLevel /= (bands - trebleStart);

  globalBrightness = lerp(globalBrightness, 0.7 + smoothedLevel * 0.8, 0.05);

  background(0);

  trailLayer.beginDraw();
  trailLayer.fill(0, 255 * (1.0 - trailLength));
  trailLayer.noStroke();
  trailLayer.rect(0, 0, width, height);
  trailLayer.endDraw();

  revealMask.beginDraw();
  revealMask.noStroke();
  revealMask.fill(0, 20 + int(bassLevel * 20));
  revealMask.rect(0, 0, width, height);
  revealMask.endDraw();

  glowLayer.beginDraw();
  glowLayer.clear();
  glowLayer.endDraw();

  for (int i = 0; i < particleCount; i++) {
    Particle p = particles[i];
    p.update(smoothedLevel, bassLevel, midLevel, trebleLevel);
    p.drawTrail(trailLayer);
    p.drawGlow(glowLayer);
    p.display();

    if (p.isTracing) {
      revealMask.beginDraw();
      revealMask.fill(255, 60 + int(p.energy * 195));
      revealMask.noStroke();
      float glowSize = p.size * (2 + p.energy * 3);
      revealMask.ellipse(p.pos.x, p.pos.y, glowSize, glowSize);
      revealMask.endDraw();
    }
  }

  // Draw trail layer with additive blending
  tint(255, 180);
  blendMode(ADD);
  image(trailLayer, 0, 0);

  // Draw glow layer with screen blending
  tint(255, int(glowIntensity * 255));
  blendMode(SCREEN);
  //image(glowLayer, 0, 0);

  // Reset blend mode and draw main image
  blendMode(BLEND);
  tint(255, int(globalBrightness * 255));
  image(img, 0, 0, width, height);

  // Apply reveal mask with multiply blend
  tint(255, 255);
  blendMode(MULTIPLY);
  image(revealMask, 0, 0);

  // Final glow pass for extra brilliance
  blendMode(SCREEN);
  tint(255, int(glowIntensity * 100));
  image(glowLayer, 0, 0);

  blendMode(BLEND);
  noTint();

  // Beat flash effect
  if (beatTimer > 0) {
    fill(255, 255, 255, map(beatTimer, 0, 10, 0, 30));
    rect(0, 0, width, height);
  }

  if (keyPressed && key == 'd') {
    for (PVector pt : strategicPoints) {
      fill(255, 0, 0, 150);
      ellipse(pt.x, pt.y, 4, 4);
    }
  }
}

class Particle {
  PVector pos, vel, target, prevPos;
  float size, nOffset, life, maxLife, energy;
  color baseColor, currentColor, glowColor;
  ParticleType type;
  float phase, frequency;
  boolean isTracing;
  float pulsation, brightness;

  // Enhanced properties
  float glowSize, trailOpacity;
  ArrayList<PVector> trail;

  // Strategic stop logic
  boolean isStopped = false;
  PVector stopPoint = null;

  // --- Color & Glow Optimization ---
  color cachedPaletteColor;
  boolean colorDirty = true; // Mark when color needs update

  Particle(ParticleType t) {
    type = t;
    trail = new ArrayList<PVector>();
    reset();
  }

  void reset() {
    pos = new PVector(random(width), random(height));
    prevPos = pos.copy();
    target = new PVector(random(width), random(height));
    vel = new PVector(0, 0);
    nOffset = random(1000);
    phase = random(TWO_PI);
    frequency = random(0.01, 0.05);
    life = maxLife = random(300, 800);
    isTracing = random(1) < 0.7;
    pulsation = random(TWO_PI);
    brightness = random(0.7, 1.0);
    energy = 0;

    isStopped = false;
    stopPoint = null;
    trail.clear();

    setTypeProperties();

    if (img != null) {
      int ix = constrain(int(map(pos.x, 0, width, 0, img.width-1)), 0, img.width-1);
      int iy = constrain(int(map(pos.y, 0, height, 0, img.height-1)), 0, img.height-1);
      baseColor = img.pixels[iy * img.width + ix];

      // Precompute palette color for this particle
      cachedPaletteColor = compositionPalette[int(random(compositionPalette.length))];
      baseColor = lerpColor(baseColor, cachedPaletteColor, 0.4);
      glowColor = lerpColor(baseColor, color(255, 255, 255), 0.3);
    }

    if (strategicPoints.size() > 0 && random(1) < 0.18) {
      stopPoint = strategicPoints.get(int(random(strategicPoints.size())));
    }

    colorDirty = true; // Mark color as dirty for update
  }

  void setTypeProperties() {
    switch(type) {
      case ELEVATION: 
        size = random(2, 5); 
        vel.y = -random(0.5, 1.5); 
        glowSize = random(1.5, 3.0);
        break;
      case INDUSTRIAL: 
        size = random(1, 3); 
        vel = PVector.random2D().mult(random(0.8, 2.0)); 
        glowSize = random(0.8, 1.5);
        break;
      case DECAY: 
        size = random(3, 8); 
        vel = PVector.random2D().mult(random(0.2, 0.8)); 
        glowSize = random(2.0, 4.0);
        break;
      case FINALE: 
        size = random(2, 6); 
        vel = PVector.random2D().mult(random(1.0, 3.0)); 
        glowSize = random(2.0, 5.0);
        break;
      case ASCENT: 
        size = random(2, 4); 
        glowSize = random(1.5, 2.5);
        break;
      case ORGANIC: 
        size = random(3, 6); 
        glowSize = random(2.0, 3.5);
        break;
      case PSYCHOLOGICAL: 
        size = random(1, 4); 
        glowSize = random(1.0, 6.0);
        break;
      case ORBITAL: 
        size = random(2, 4); 
        glowSize = random(1.5, 3.0);
        break;
      case SACRED: 
        size = random(2, 5); 
        glowSize = random(3.0, 6.0);
        break;
      case LIMINAL: 
        size = random(1, 6); 
        glowSize = random(1.0, 4.0);
        break;
      case VOLCANIC: 
        size = random(2, 7); 
        glowSize = random(2.5, 5.0);
        break;
      case FOLK: 
        size = random(2, 4); 
        glowSize = random(1.5, 2.5);
        break;
    }
  }

  void update(float level, float bass, float mid, float treble) {
    prevPos = pos.copy();
    energy = lerp(energy, level + bass + mid + treble, 0.1);
    pulsation += 0.1;

    // --- ImageField reactivity ---
    float b = imgField.getBright(pos.x, pos.y);         // brightness factor
    PVector flow = imgField.getFlow(pos.x, pos.y);      // gradient vector
    PVector edge = imgField.nearestEdge(pos.x, pos.y, 50);

    vel.add(flow.mult(0.5));                            // follow image flow
    energy *= lerp(0.9, 1.2, b);                        // faster in bright zones
    if (edge != null && PVector.dist(pos, edge) < 30) {
      vel.add(PVector.sub(edge, pos).mult(0.1));        // move toward edges
    }
    size = map(b, 0, 1, size * 0.8, size * 1.2);        // scale size by brightness
    // --- end ImageField reactivity ---

    // Enhanced strategic point attraction
    if (stopPoint != null && !isStopped) {
      float d = PVector.dist(pos, stopPoint);
      if (d < 3.0) {
        pos.set(stopPoint);
        vel.set(0, 0);
        isStopped = true;
      } else {
        PVector dir = PVector.sub(stopPoint, pos).normalize().mult(lerp(1.5, 0.2, constrain(d/100, 0, 1)));
        vel = dir;
      }
    } else if (!isStopped) {
      // Apply type-specific movement with enhanced audio reactivity
      switch(type) {
        case ELEVATION: updateElevation(level, treble); break;
        case INDUSTRIAL: updateIndustrial(level, mid); break;
        case DECAY: updateDecay(level, bass); break;
        case FINALE: updateFinale(level, bass, mid, treble); break;
        case ASCENT: updateAscent(level, treble); break;
        case ORGANIC: updateOrganic(level, mid); break;
        case PSYCHOLOGICAL: updatePsychological(level, treble); break;
        case ORBITAL: updateOrbital(level, mid); break;
        case SACRED: updateSacred(level, bass); break;
        case LIMINAL: updateLiminal(level, mid, treble); break;
        case VOLCANIC: updateVolcanic(level, bass); break;
        case FOLK: updateFolk(level, bass, mid); break;
      }
    }

    pos.add(vel);

    // Update trail
    trail.add(pos.copy());
    if (trail.size() > 15) trail.remove(0);

    // Enhanced life management
    life--;
    if (life <= 0 || pos.x < -50 || pos.x > width + 50 || pos.y < -50 || pos.y > height + 50) {
      reset();
    }

    // --- Color & Glow Optimization ---
    // Only update color if marked dirty or on beat/type change
    if (colorDirty) {
      float alpha = map(life, 0, maxLife, 0, 255 * brightness);
      float pulse = 1.0 + sin(pulsation) * 0.2 * energy;
      alpha *= pulse;

      currentColor = color(
        red(baseColor), 
        green(baseColor), 
        blue(baseColor), 
        constrain(alpha, 0, 255)
      );

      // Glow color is only updated if baseColor changes
      glowColor = lerpColor(baseColor, color(255, 255, 255), 0.3);

      colorDirty = false;
    } else {
      // Only update alpha for currentColor (not RGB)
      float alpha = map(life, 0, maxLife, 0, 255 * brightness);
      float pulse = 1.0 + sin(pulsation) * 0.2 * energy;
      alpha *= pulse;
      currentColor = color(
        red(currentColor),
        green(currentColor),
        blue(currentColor),
        constrain(alpha, 0, 255)
      );
    }

    // Dynamic size based on energy
    float dynamicSize = size * (1.0 + energy * 0.5);
    size = lerp(size, dynamicSize, 0.1);
  }

  // Movement update methods (enhanced versions)
  void updateElevation(float level, float treble) {
    vel.y = lerp(vel.y, -1 - treble * 4, 0.1);
    vel.x = sin(frameCount * 0.01 + nOffset) * (0.5 + treble);
    if (isTracing) vel.mult(1 + level * 3);
  }

  void updateIndustrial(float level, float mid) {
    float angle = noise(pos.x * 0.01, pos.y * 0.01, frameCount * 0.01) * TWO_PI;
    vel = PVector.fromAngle(angle).mult(0.5 + mid * 5);
    if (random(1) < mid * 0.15) vel.mult(-1);
    if (beatDetected) vel.mult(1.5);
  }

  void updateDecay(float level, float bass) {
    vel.mult(0.95);
    vel.add(PVector.random2D().mult(bass * 0.8));
    if (bass > 0.3) size *= 1.1;
  }

  void updateFinale(float level, float bass, float mid, float treble) {
    if (bass > 0.3) vel = PVector.random2D().mult(bass * 6);
    vel.add(PVector.fromAngle(atan2(height/2 - pos.y, width/2 - pos.x)).mult(treble * 3));
    if (beatDetected) glowSize *= 1.5;
  }

  void updateAscent(float level, float treble) {
    phase += frequency * (1 + treble);
    float radius = 50 + treble * 150;
    target.x = width/2 + cos(phase) * radius;
    target.y = height/2 + sin(phase) * radius - frameCount * (0.5 + level);
    vel = PVector.sub(target, pos).mult(0.05 + treble * 0.05);
  }

  void updateOrganic(float level, float mid) {
    float angle = sin(frameCount * 0.02 + nOffset) * PI;
    vel.x = cos(angle) * (1 + mid * 3);
    vel.y = sin(angle * 0.5) * (0.5 + mid * 2);
    size = lerp(size, size * (1 + mid * 0.2), 0.1);
  }

  void updatePsychological(float level, float treble) {
    if (random(1) < treble * 0.7) vel = PVector.random2D().mult(random(0.1, 4.0));
    vel.add(PVector.random2D().mult(treble * 0.8));
    if (beatDetected) {
      // On beat, pick a new palette color and update baseColor and glowColor
      cachedPaletteColor = compositionPalette[int(random(compositionPalette.length))];
      baseColor = cachedPaletteColor;
      colorDirty = true;
    }
  }

  void updateOrbital(float level, float mid) {
    PVector center = new PVector(width/2, height/2);
    PVector toCenter = PVector.sub(center, pos);
    float distance = toCenter.mag();
    toCenter.normalize();
    toCenter.rotate(PI/2 + mid * 0.5);
    vel = toCenter.mult(mid * 3 + 0.5);
  }

  void updateSacred(float level, float bass) {
    float gridSize = 40 + bass * 20;
    float gridX = round(pos.x / gridSize) * gridSize;
    float gridY = round(pos.y / gridSize) * gridSize;
    target.set(gridX, gridY);
    vel = PVector.sub(target, pos).mult(0.1 + bass * 0.5);
    glowSize = lerp(glowSize, glowSize * (1 + bass), 0.1);
  }

  void updateLiminal(float level, float mid, float treble) {
    if ((frameCount & 0x3F) < 30) vel.x = treble * 3;
    else vel.x = -treble * 3;
    vel.y = sin(frameCount * 0.05 + nOffset) * mid * 2;
    if (frameCount % 60 == 0) {
      // On interval, blend baseColor toward a palette color
      cachedPaletteColor = compositionPalette[int(random(compositionPalette.length))];
      baseColor = lerpColor(baseColor, cachedPaletteColor, 0.3);
      colorDirty = true;
    }
  }

  void updateVolcanic(float level, float bass) {
    vel.y = -bass * 4 - 0.5;
    vel.x = sin(frameCount * 0.02 + nOffset) * bass * 3;
    if (pos.y < height * 0.3) vel.y *= -0.5;
    if (bass > 0.4) {
      glowColor = lerpColor(glowColor, color(255, 100, 0), 0.2);
    }
  }

  void updateFolk(float level, float bass, float mid) {
    if ((frameCount & 0x1F) < 15) vel.x = cos(frameCount * 0.1) * mid * 3;
    else vel.y = sin(frameCount * 0.1) * bass * 3;
    brightness = lerp(brightness, 0.7 + level * 0.5, 0.05);
  }

  void drawTrail(PGraphics layer) {
    if (trail.size() < 2) return;

    layer.beginDraw();
    layer.strokeWeight(size * 0.5);

    for (int i = 1; i < trail.size(); i++) {
      PVector curr = trail.get(i);
      PVector prev = trail.get(i-1);

      float alpha = map(i, 0, trail.size()-1, 0, 150) * energy;
      layer.stroke(red(currentColor), green(currentColor), blue(currentColor), alpha);
      layer.line(prev.x, prev.y, curr.x, curr.y);
    }

    layer.endDraw();
  }

  void drawGlow(PGraphics layer) {
    layer.beginDraw();
    layer.noStroke();

    // Multiple glow layers for soft effect
    float baseAlpha = alpha(currentColor) * glowIntensity;

    for (int i = 3; i >= 1; i--) {
      float glowAlpha = baseAlpha / (i * 2);
      float glowRadius = glowSize * size * i;

      layer.fill(red(glowColor), green(glowColor), blue(glowColor), glowAlpha);
      layer.ellipse(pos.x, pos.y, glowRadius, glowRadius);
    }

    layer.endDraw();
  }

  void display() {
    fill(currentColor);
    noStroke();

    // Main particle with pulsation
    float displaySize = size * (1.0 + sin(pulsation) * 0.1 * energy);
    ellipse(pos.x, pos.y, displaySize, displaySize);

    // Type-specific additional rendering
    if (type == ParticleType.FINALE && life > maxLife * 0.8) {
      stroke(255, 150);
      strokeWeight(1);
      line(pos.x, pos.y, pos.x - vel.x * 8, pos.y - vel.y * 8);
      noStroke();
    }

    if (type == ParticleType.SACRED) {
      stroke(red(glowColor), green(glowColor), blue(glowColor), 80);
      strokeWeight(0.5);
      float s = displaySize * 1.5;
      line(pos.x - s, pos.y, pos.x + s, pos.y);
      line(pos.x, pos.y - s, pos.x, pos.y + s);
      noStroke();
    }

    if (type == ParticleType.VOLCANIC && energy > 0.5) {
      // Ember effect
      fill(255, 200, 0, 100);
      for (int i = 0; i < 3; i++) {
        float sparkX = pos.x + random(-size, size);
        float sparkY = pos.y + random(-size, size);
        ellipse(sparkX, sparkY, 1, 1);
      }
    }
  }
}

void keyPressed() {
  if (keyCode == RIGHT) {
    int newIndex = (currentIndex + 1) % images.length;
    switchComposition(newIndex);
  } else if (keyCode == LEFT) {
    int newIndex = (currentIndex - 1 + images.length) % images.length;
    switchComposition(newIndex);
  }
  if (key == ' ') {
    if (music.isPlaying()) music.pause();
    else music.play();
  }
  if (key == 'g') {
    glowIntensity = glowIntensity > 0.5 ? 0.2 : 1.0;
  }
  if (key == 't') {
    trailLength = trailLength > 0.5 ? 0.1 : 0.95;
  }
}

void switchComposition(int index) {
  // --- Memory and Resource Clean-up ---
  if (music != null) {
    music.stop();
    // No .dispose() in Processing Sound library, but set to null for GC
    music = null;
  }
  // Null old particle array for GC
  particles = null;

  // Dispose and null old PGraphics layers if needed
  if (revealMask != null) {
    revealMask.dispose();
    revealMask = null;
  }
  if (glowLayer != null) {
    glowLayer.dispose();
    glowLayer = null;
  }
  if (trailLayer != null) {
    trailLayer.dispose();
    trailLayer = null;
  }
  // --- End Clean-up ---

  currentIndex = index;
  img = loadImage("assets/" + images[currentIndex]);
  img.resize(width/2, height/2);
  music = new SoundFile(this, "assets/" + audioFiles[currentIndex]);
  amp.input(music);
  fft.input(music);

  setCompositionStyle();
  findStrategicPoints();

  particles = new Particle[particleCount];
  for (int i = 0; i < particleCount; i++) {
    particles[i] = new Particle(currentType);
  }

  // Re-create all layers
  revealMask = createGraphics(width, height, P2D);
  glowLayer = createGraphics(width, height, P2D);
  trailLayer = createGraphics(width, height, P2D);

  revealMask.beginDraw(); revealMask.background(0); revealMask.endDraw();
  glowLayer.beginDraw(); glowLayer.background(0); glowLayer.endDraw();
  trailLayer.beginDraw(); trailLayer.background(0); trailLayer.endDraw();

  imgField = new ImageField(img, 8);

  music.play();
  println("Switched to: " + compositionNames[currentIndex]);
}

class ImageField {
  PImage img;
  float[][] brightMap;
  PVector[][] gradField;
  ArrayList<PVector> edgePoints;
  int step, w, h;

  ImageField(PImage img, int step) {
    this.img = img;
    this.step = step;
    w = img.width;
    h = img.height;
    brightMap = new float[w][h];
    gradField = new PVector[w/step][h/step];
    edgePoints = new ArrayList<PVector>();
    computeMaps();
  }

  void computeMaps() {
    img.loadPixels();
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        brightMap[x][y] = brightness(img.pixels[y * w + x]) / 255.0;
      }
    }
    // Precompute gradients & edges
    for (int y = step; y < h - step; y += step) {
      for (int x = step; x < w - step; x += step) {
        float b = brightMap[x][y];
        float bx = brightMap[x + step][y];
        float by = brightMap[x][y + step];
        float dx = bx - b, dy = by - b;
        PVector g = new PVector(dx, dy).normalize();
        gradField[x/step][y/step] = g;
        if (abs(dx) + abs(dy) > 0.2) {
          edgePoints.add(new PVector(map(x, 0, w, 0, width),
                                     map(y, 0, h, 0, height)));
        }
      }
    }
  }

  // Sample brightness in screen coordinates
  float getBright(float sx, float sy) {
    int ix = constrain(int(map(sx, 0, width, 0, w-1)), 0, w-1);
    int iy = constrain(int(map(sy, 0, height, 0, h-1)), 0, h-1);
    return brightMap[ix][iy];
  }

  // Get gradient as vector
  PVector getFlow(float sx, float sy) {
    int gx = constrain(int(map(sx, 0, width, 0, w/step-1)), 0, w/step -1);
    int gy = constrain(int(map(sy, 0, height, 0, h/step-1)), 0, h/step -1);
    return gradField[gx][gy] != null ? gradField[gx][gy] : new PVector(0,0);
  }

  // Return nearest edge point (or null)
  PVector nearestEdge(float sx, float sy, float maxDist) {
    PVector loc = new PVector(sx, sy);
    PVector best = null; float bd = maxDist;
    for (PVector pt : edgePoints) {
      float d = PVector.dist(pt, loc);
      if (d < bd) { bd = d; best = pt; }
    }
    return best;
  }
}
