class Towers
  WIDTH = 700
  HEIGHT = 600
  
  def self.new_game
    @level = 0
    @text = nil
    @enemies_count = 10
    @camera = Camera.new
    self.start_new_level
    @paused = false
    @game_over = false
  end
  
  def self.start_new_level
    startpos = 5
    @level += 1
    Enemy.reset
    @enemies_count.times do |i|
      velocity = rand*5
      start_x = (rand - 0.5)*50 + startpos
      start_y = (rand - 0.5)*50 + startpos
      Enemy.new(start_x, start_y, velocity, velocity, Enemy::SMALL)
    end
    @ship = RayGun.new(WIDTH/4 * 3, HEIGHT/4)
    @ship = RayGun.new(WIDTH/4, HEIGHT/4 * 3)
  end
  
  def self.game_over
    @text = "Game Over"
  end
  
  def self.pause
    if @paused
      @text = nil
      @paused = false
    else
      @text = "   Paused"
      self.draw
      @paused = true
    end
  end
  
  def self.draw
    unless @paused
      Ray.check_for_collision_with_enemies
      $app.clear do
        $app.background $app.black
        $app.para("Enemies left: #{Enemy.enemies_left}", :top => 5, :left => 5, :stroke => $app.gray(0.5), :font => "13px")
        $app.para("Level: #{@level}", :top => 5, :left => WIDTH - 75, :stroke => $app.gray(0.5), :font => "13px")
        $app.title(@text, :top => 240, :left => 80, :stroke => $app.gray(0.15), :font => "bold 100px") if @text
        Tower.draw_all
        Ray.draw_all
        Enemy.draw_all
        Explosion.draw_all
        @camera.follow_cursor
      end
    end
  end
  
  def self.camera
    @camera
  end
  
  def self.keypress(key)
    self.new_game if key == 'n'
    self.pause if key == 'p'
  end
  
  def self.maybe_start_new_level
    if Enemy.enemies_left == 0
      @enemies_count += 2
      self.start_new_level
    end
  end
end

class ElementOnField
  attr_accessor :x, :y, :size
  
  def center_x
    @x + @size/2
  end
  
  def center_y
    @y + @size/2
  end
  
  def initialize(x, y, vel_x, vel_y, size)
    @x, @y, @vel_x, @vel_y, @size = x, y, vel_x, vel_y, size
  end
  
  def intersects_with?(thing, margin = 0)
    return true if Math.sqrt((center_x - thing.center_x)**2 + (center_y - thing.center_y)**2) < (@size/2 + ((thing.size + margin) / 2))
    return false
  end
  
  def adjust_for_camera
  #  @x -= Towers.camera.vel_x
  #  @y -= Towers.camera.vel_y
  end
end

class Enemy < ElementOnField
  LARGE = 40
  MEDIUM = 20
  SMALL = 10
  attr_accessor :health
  
  def self.add_enemy(enemy)
    @enemies << enemy
  end
  
  def self.remove_enemy(enemy)
    @enemies.delete_at(enemy)
  end
  
  def self.draw_all
    @enemies.each {|enemy| enemy.draw } unless @enemies.nil?
  end
  
  def self.enemies_left
    @enemies.length
  end
  
  def self.reset
    @enemies = []
  end
  
  def initialize(x, y, vel_x, vel_y, size)
    super(x, y, vel_x, vel_y, size)
    @color = [(rand-0.5)*0.2 + 0.15, (rand-0.5)*0.2 + 0.15, (rand-0.5)*0.3+ 0.45]
    info("#{$app.rgb((rand-0.5)*0.2 + 0.15, (rand-0.5)*0.2 + 0.15, (rand-0.5)*0.3+ 0.45, 0.5).class}")
    @health = 100
    Enemy.add_enemy(self)
  end
  
  def draw
    adjust_for_camera
    @x += @vel_x; @y += @vel_y
    @x = @x % Towers::WIDTH; @y = @y % Towers::HEIGHT
    new_color = $app.rgb(
      @color[0] + (1.0 - (@health/100)),    # Red   - Grows more red as health goes down.
      @color[1],                            # Green - Very Little!
      @color[2] + (@health/100),            # Blue  - Grows LESS blue as health decreases.
      0.5)                                  # Transparency
    $app.stroke($app.gray(1.0, 0.5))
    $app.fill(new_color)
    $app.oval(@x, @y, @size, @size)
  end
  
  def receive_damage(index, damage)
    info("#{@health}, #{damage}")
    @health = @health - damage
    if @health <= 0
      explode(index)
    end
  end
  
  def explode(index)
    Enemy.remove_enemy(index)
    explode_factor = 0
    case @size
    when LARGE
      explode_factor = rand(10) + 15
    #  [2, 3][rand(2)].times { Enemy.new(center_x - MEDIUM/2, center_y - MEDIUM/2, @vel_x, @vel_y, MEDIUM) }
    #when MEDIUM
    #  explode_factor = rand(5) + 5
    #  [2, 3][rand(2)].times { Enemy.new(center_x - SMALL/2, center_y - SMALL/2, @vel_x, @vel_y, SMALL) }
    #when SMALL
    #  explode_factor = rand(3) + 2
      Towers.maybe_start_new_level
    end
    explode_factor.times do |i|
      direction = ((2 * Math::PI) * i/explode_factor)
      Explosion.new(center_x, center_y, 4*Math.cos(direction), 4*Math.sin(direction))
    end
  end
  
  def self.check_for_collision_with(thing, margin = 0)
    @enemies.each_with_index do |enemy, index|
      return [enemy, index] if enemy.intersects_with?(thing, margin)
    end
    return false
  end
end

class Camera < ElementOnField
  @@tightness = 0.1 # 1.0 will keep the cursor centered, less will follow it

  def initialize
  end
  
  attr_reader :vel_x, :vel_y
  
  def follow_cursor
    #@vel_x = (Cursor.cursor.center_x - Towers::WIDTH / 2) * @@tightness
    #@vel_y = (Cursor.cursor.center_y - Towers::HEIGHT / 2) * @@tightness
    #@x += @vel_x
    #@y += @vel_y
  end
end

class Explosion < ElementOnField
  @explosions = []
  def self.add_explosion(explosion)
    @explosions << explosion
  end
  
  def self.remove(index)
    @explosions.delete_at(index)
  end
  
  def self.draw_all
    @explosions.each_with_index {|explosion, i| explosion.draw(i) }
  end
  
  def initialize(x, y, vel_x, vel_y)
    super( x, y, vel_x + (rand-0.5)*4, vel_y + (rand-0.5)*4, 10)
    @transparency = 1.0
    Explosion.add_explosion(self)
  end
  
  def draw(index)
    adjust_for_camera
    @x += @vel_x; @y += @vel_y
    $app.stroke($app.gray(1.0, @transparency))
    color = [1.0, (rand-0.5)*0.7 + 0.7, 0, @transparency]
    $app.fill($app.rgb(*color))
    $app.oval(@x, @y, @size, @size)
    @transparency -= 0.065
    Explosion.remove(index) if @transparency <= 0
  end
end

class Tower < ElementOnField
  @towers = []
  UNIT = 30
  attr_accessor :shooting
  
  def initialize(x, y)
    super(x, y, 0, 0, UNIT)
    @direction = 0
    @shooting = false
    Tower.add_tower(self)
  end
  
  def self.add_tower(tower)
    @towers << tower
  end
  
  def self.remove_roid(tower)
    @towers.delete_at(tower)
  end
  
  def self.draw_all
    @towers.each {|tower| tower.draw }
  end
  
  def draw
    adjust_for_camera
    nothing, mouse_x, mouse_y = * $app.mouse                    # I don't know what this does.
    @direction = Math.atan2(mouse_y - @y, mouse_x - @x)             # Set direction.
    shoot if @shooting
    $app.stroke($app.gray(1.0, 0.5))                                                                      # Drawing instructions
    $app.fill($app.rgb(0.7, 0.2, 0.2, 0.5))                                                               #
    $app.oval(@x, @y, UNIT, UNIT)                                                                         #
    $app.oval(@x + 20*Math.cos(@direction) + 10, @y + 20*Math.sin(@direction) + 10, UNIT/3, UNIT/3)       #
    $app.fill($app.rgb(1.0, 1.0, 0.8, (1.0 - (Ray.counter.to_f / 20.0))))                                 #
    $app.oval(@x + 5*Math.cos(@direction) + 12.5, @y + 5*Math.sin(@direction) + 12.5, UNIT/5, UNIT/5)     #
  end
  
  def shoot
    Ray.new(@x + UNIT/2, @y + UNIT/2, @vel_x, @vel_y, @direction) if Ray.counter < 20
  end
end

class RayGun < Tower  # Raygun shoots a steady stream of rays, to test collision, explosion, and health systems
  def initialize(x, y)
    super(x, y)
    @direction = 0
    @shooting = true
  end
end

class Ray < ElementOnField
  @rays = []
  @counter = 0
  
  def self.counter
    return @counter
  end
  
  def self.add_ray(ray)
    @rays << ray
    @counter += 1
  end
  
  def self.draw_all
    @rays.each_with_index {|ray, i| ray.draw(i) }
  end
  
  def self.remove_ray(index)
    @rays.delete_at(index)
    @counter -= 1
  end
  
  def self.check_for_collision_with_enemies
    @rays.each_with_index do |ray, index| 
      if enemy_list = Enemy.check_for_collision_with(ray)
        Ray.remove_ray(index)
        enemy_list[0].receive_damage(enemy_list[1], 10)                         # 10 is temporary damage received. Must make more dynamic!
      end
    end
  end
  
  def initialize(x, y, vel_x, vel_y, direction)
    @direction = direction
    super(x, y, vel_x + 12 * Math.cos(@direction), vel_y + 12 * Math.sin(@direction), 5)
    Ray.add_ray(self)
  end
  
  def draw(index)
    adjust_for_camera
    @x += @vel_x; @y += @vel_y
    if @x > Towers::WIDTH || @x < 0 || @y > Towers::HEIGHT || @y < 0
      Ray.remove_ray(index)
    else
      $app.stroke($app.rgb(1.0, 1.0, 0.8, 0.8))
      $app.line(@x, @y, @x + @vel_x, @y + @vel_y)
    end
  end
end

Shoes.app :width => Towers::WIDTH, :height => Towers::HEIGHT, :title => "Towers", :resizable => false do
  $app = self
  Towers.new_game
  animate(60) { Towers.draw }
  keypress {|k| Towers.keypress(k) }
  click do |a_button, x, y|
  end
  release do |a_button, x, y|
  end
end