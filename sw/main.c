#define LED             (*(volatile int*) 0x40000000)
#define CONTROLLER_REG  (*(volatile int*) 0x00000FFC)  // dernier mot de la RAM
#define SCREEN_BUFFER   ((volatile int*)  0x00000800)  // 64 mots : 0x800 à 0x8FF

#ifdef SIM
  #define DELAY 20            // compiler avec -DSIM pour la simulation
#else
  #define DELAY 1500000       // environ 0,3 s par pas à 27 MHz
#endif

int snake_x;// coords tete serpent 
int snake_y;
int food_x;// coords pomme
int food_y;
int score;// nb pommes mangées

int dir;

void clear_screen() {
    int i;
    for(i = 0; i < 64; i++) {
        SCREEN_BUFFER[i] = 0; // ecrit 0 à cq case mémoire entre 0x1100 et 0x11F0
    }
}

void reset_game() {
    score = 0;
    dir = 0;
    snake_x = 5; snake_y = 5;
    food_x = 2;  food_y = 2;
    clear_screen();
    SCREEN_BUFFER[(food_y << 3) + food_x] = 2;   // 2 = pomme
    LED = score;
}

void update_game() {
    int cmd = CONTROLLER_REG; // 

    if (cmd != 0) dir = cmd;        // garde la direction si aucun bouton

    if (dir == 1) snake_y--;        // haut
    if (dir == 2) snake_y++;        // bas
    if (dir == 3) snake_x--;        // gauche
    if (dir == 4) snake_x++;        // droite

    // condition de défaite
    if (snake_x < 0 || snake_x > 7 || snake_y < 0 || snake_y > 7) {
        reset_game();
        return;
    }

    if (snake_x == food_x && snake_y == food_y) { //est ce qu'on mange la pomme
        score++;
        LED = score;
        food_x = ((score << 1) + score) & 7;   // (score * 3) % 8
        food_y = ((score << 2) + score) & 7;   // (score * 5) % 8
        SCREEN_BUFFER[(food_y << 3) + food_x] = 2;
    }

    SCREEN_BUFFER[(snake_y << 3) + snake_x] = 1;   // 1 = serpent
}

int main() {
    reset_game();
    while (1) {
        update_game();
        int delay = DELAY;
        while (delay > 0) delay--;
    }
    return 0;
}