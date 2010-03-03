#include <stdio.h>
#include <stdlib.h>

int rmv_lcl(char *s, char *buf, size_t buflen) {
    char c, *lastsep = NULL, *p = s, *b = buf; 
    size_t  l;

    if (b == (char *)NULL) return 0;

    if (s == (char *)NULL) {
        *b = 0; 
        return 0;
    }    

    /* find last separator and length of s */
    while ((c = *p)) {
        if ((c == '.') || (c == ','))   lastsep = p; 
        ++p; 
    }    

    l = p - s;   // strlen(s)
    if (buflen < l) return 0;

    /* copy the number skipping all but last separator and all other chars */
    p = s; 
    while ((c = *p)) {
        if (((c >= '0') && (c <= '9')) || (c == '-') || (c == '+'))
            *b++ = c; 
        else if (p == lastsep)
            *b++ = '.'; 
        ++p; 
    }    

    *b = 0; 

    // cast to int to make x64 happy, can do it because numbers are not so very long
    return (int)(b - buf);  // return new len
}
