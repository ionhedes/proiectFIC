#include <stdio.h>
#include <stdbool.h>
#include <string.h>

bool decchk(const char* string, size_t n, char* ch)
{
    char c;
    size_t j;
    int k = 0;
    int m = 0;

    static int ip[10][8] = {
        0,1,5,8,9,4,2,7, 1,5,8,9,4,2,7,0,
        2,7,0,1,5,8,9,4, 3,6,3,6,3,6,3,6,
        4,2,7,0,1,5,8,9, 5,8,9,4,2,7,0,1,
        6,3,6,3,6,3,6,3, 7,0,1,5,8,9,4,2,
        8,9,4,2,7,0,1,5, 9,4,2,7,0,1,5,8
    };
    static int ij[10][10] = {
        0,1,2,3,4,5,6,7,8,9, 1,2,3,4,0,6,7,8,9,5,
        2,3,4,0,1,7,8,9,5,6, 3,4,0,1,2,8,9,5,6,7,
        4,0,1,2,3,9,5,6,7,8, 5,9,8,7,6,0,4,3,2,1,
        6,5,9,8,7,1,0,4,3,2, 7,6,5,9,8,2,1,0,4,3,
        8,7,6,5,9,3,2,1,0,4, 9,8,7,6,5,4,3,2,1,0
    };

    for (j = 0; j < n ; j++)
    {
        c = string[j];
        printf("%c %d: ", c, c);
        if (c >= 48 && c <= 57) // < ignor caracterele care nu sunt numere
        {
            printf("cifra! ");
            printf("indecsi ((%d, %d), (%d, %d)) ", (c + 2) % 10, 7 & m, k, ip[(c + 2) % 10][7 & m]);
            k = ij[k][ip[(c + 2) % 10][7 & m++]];
            printf("%d\n", k);
        }
        else
        {
            printf("nu cifra!\n");
        }
    }

    for (j = 0; j <= 9; j++)
    {
        if (!ij[k][ip[j][m & 7]])
        {
            break;
        }
    }
    *ch = j + 48; // < convertesc caracterul la cifra ascii coresp valorii lui

    return (k == 0);
}

int main(void)
{
    const char* string = "1923556417";
    char ch = 0;
    printf("sir %s\n", string);
    bool correct_checksum = decchk(string, strlen(string), &ch);
    printf("checksum: %c\n", ch);
    printf("daca cifra checksum fusese deja lipita de sir, atunci ar fi fost corecta: %d", correct_checksum);
    return 0;
}
