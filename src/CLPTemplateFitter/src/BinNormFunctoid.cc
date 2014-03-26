// -*- C++ -*-
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cassert>

#include "CLPTemplateFitter/interface/BinNormFunctoid.h"

using namespace std;

ClassImp(BinNormFunctoid)

BinNormFunctoid::BinNormFunctoid() : m_funcPtr (0)
{
}

BinNormFunctoid::BinNormFunctoid(double(*ptr)(int, int, double, const double *)) : m_funcPtr (ptr)
{
}

double
BinNormFunctoid::operator() (int tempIndex, int binIndex,
                             double value, const double *paramArray) const
{
#if defined(__MAKECINT__)
    // lame
    assert(0);
    return -123456789.0;
#else
   assert(m_funcPtr);
   return(*m_funcPtr) (tempIndex, binIndex, value, paramArray);
#endif
}

void
BinNormFunctoid::dumpToOstream(ostream& o_stream) const
{
   o_stream << "old" << endl;
#if defined(__MAKECINT__)
    // lame
#else
   o_stream <<(void*) m_funcPtr << endl;
#endif
}

// friends
ostream& operator<<(ostream& o_stream, const BinNormFunctoid &rhs)
{
   rhs.dumpToOstream(o_stream);
   return o_stream;
}
