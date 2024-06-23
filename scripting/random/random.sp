#define MAX_RANDOM_RANGE 2147483647
#define WEAPON_RANDOM_RANGE 10000

//We are adding a range on GetURandomint() this still has some bias but should be good enough
int RandomInt(int minVal, int maxVal)
{
    int range = maxVal - minVal + 1;
    int random, scaledRandom;

    do {
        random = GetURandomInt();

        //this should not happen but whatever
        if (random < 0) 
        {
            random = -random;
        }
    } while (random == 0 || random >= MAX_RANDOM_RANGE - (MAX_RANDOM_RANGE % range));

    scaledRandom = random % range;

    return scaledRandom + minVal;
}