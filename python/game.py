# Write your code here :-)

alien = Actor('alien')
alien.topright = 0, 10
#alien.pos = 100, 56

WIDTH = 500
HEIGHT = 400  #alien.height + 50

def draw():
    screen.clear()
    screen.blit('moon', (0, 0))
    alien.draw()

def update():
    alien.left += 2
    if alien.left > WIDTH:
        alien.right = 0

def on_mouse_down(pos):
    if alien.collidepoint(pos):
        set_alien_hurt()

def set_alien_hurt():
    alien.image = 'alien_hurt'
    sounds.eep.play()
    clock.schedule_unique(set_alien_normal, 1.0)

def set_alien_normal():
    alien.image = 'alien'



