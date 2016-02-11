#include "Python.h"

/*
 PyByteArrayCheck is not present in PyPy 2.5.1
*/
#ifndef PyByteArray_Check
#define PyByteArray_Check(self) (0)
#endif