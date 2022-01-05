#include <stdio.h>
#include <string.h>

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned long ulong;
#define LOBYTE(x) ((uchar)((x) & 0xFF))
#define HIBYTE(x) ((uchar)(((x) >> 8) & 0xFF))
#define GEN 4129

ushort icrc1(ushort crc, uchar onech)
{
    int i;
    ushort ans = (crc ^ (onech << 8));

    for (i = 0; i < 8; i++)
    {
        //printf("i=%d\n", i);
        if (ans & 0x8000)
        {
            //printf("\t %d << 1 ^ %d\n", ans, GEN);
            ans = (ans << 1) ^ GEN;
        }
        else
        {
            //printf("\t %d << 1\n", ans);
            ans <<= 1;
        }
    }
    return ans;
}

/**
    Calculeaza CRC-ul pe 16b pentru o secventa de octeti

    ARG:
        - crc -
        - uchar* bufptr - pointer catre sirul de octeti
        - ulong len     - lungimea sirului de octeti
        - short jinit   - >=0 - CRC-ul se initializeaza cu fiecare octet
                                pe valoarea jinit
                        - <0  - CRC-ul se initializeaza cu valoarea crc
                                (care poate fi crc-ul unei secvente precedente
                                de octeti (*1))
        - int jrev      - <0  - caracterele prelucrate vor fi inversate dpdv al
                                bitilor (al endianess-ului?)
                              - de asemenea, crc-ul final va fi inversat dpdv. al
                                bitilor

*/
ushort icrc(ushort crc, uchar* bufptr, ulong len, short jinit, int jrev)
{
    ushort icrc1(ushort crc, uchar onech); // fct generare zapare 8b/template crc
    static ushort icrctb[256]; // < tabel crc pentru fiecare caracter ASCII
    static ushort init = 0;
    static uchar rchr[256]; // < tabel pentru caract ASCII bit-inversate
    // jos: nibblesi bit inversati
    static uchar it[16] = {0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15};
    ushort j;
    ushort cword = crc;

    // daca nu am mai rulat crc(), initializat tabelul de crc si tabelul
    // caracterelor bit-inversate
    if (!init)
    {
        init = 1;
        for (j = 0; j <= 255; j++)
        {
            icrctb[j] = icrc1(j << 8, (uchar) 0);
            printf("icrctb: %x\n", icrctb[j]);
            rchr[j] = (uchar)(it[j & 0xF] << 4 | it[j >> 4]);
            printf("rchr: %x\n", rchr[j]);
        }
    }


    if (jinit >= 0)
    {
        cword = ((uchar) jinit) | (((uchar) jinit) << 8);
    }
    else if (jrev < 0)
    {
        // in acest pct e implicit ca cword = crc;
        // inversez bitii lui cword
        cword = rchr[HIBYTE(cword)] | rchr[LOBYTE(cword)] << 8;
    }

    // iteratie la nivel de caracter din sir / pe 8 biti (*2)
    uchar next_char;
    for (j = 0; j < len; j++)
    {
        //printf("char %c, ", bufptr[j]);
        next_char = (jrev < 0 ? rchr[bufptr[j]] : bufptr[j]);
        cword = icrctb[next_char ^ HIBYTE(cword)] ^ (LOBYTE(cword) << 8);
    }

    return (jrev >= 0 ? cword : rchr[HIBYTE(cword)] | rchr[LOBYTE(cword)] << 8);
}

int main(void)
{
    //ushort x = 0x1A71;
    uchar str[] = "Piatra crapa capul caprei in patru, cum a crapat si capra piatra in patru.";
    ushort crc = icrc(0, str, strlen((const char*)str), 0, 0);
    printf("sir = %s\ncrc = %x\n", str, crc);
    return 0;
}


/**
    (*1) - XOR este comutativ si asociativ; doar bitii din octetul superior
        afecteaza zaparile => putem prelucra cate 8 biti din sir la o iteratie
        in algoritm; din aceasta cauza, daca incarcam la inceput in rezultat
        un rezultat precedet, pastram legatura din crc intre primul sir prelucrat
        si al doilea:
            in acest caz crc(s1) >> crc(s2) == crc(s1s2)
        astfel prelucram fisiere mai mare, fara a le tine toti octetii in memorie,
        si pastrand legatura intre blocurile de octeti prelucrate

    (*2) - intra caracter nou (normal sau bit-inversat)
         - se zapeaza folosind



*/
