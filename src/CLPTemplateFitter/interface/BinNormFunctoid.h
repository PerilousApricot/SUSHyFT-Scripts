// -*- C++ -*-

#if !defined(BinNormFunctoid_HH)
#define BinNormFunctoid_HH

#include <map>
#include "TSystem.h"

// CINT seems to need a forward declaration. *shrug*
class BinNormFunctoid;
class BinNormFunctoid : public TObject
{
    public:
        typedef double(* FuncPtr)(int tempIndex, int binIndex,
                double value, const double *paramArray);
        typedef std::map< int, BinNormFunctoid * >  IFMap;
        // Why doesn't the following work with clang/OSX?
        // typedef IFMap::const_iterator              IFMapConstIter;
        typedef std::map< int, BinNormFunctoid * >::const_iterator IFMapConstIter;

        // tells particle data how to print itself out
        friend std::ostream& operator<<(std::ostream& o_stream,
                const BinNormFunctoid &rhs);
        BinNormFunctoid();
#if defined(__MAKECINT__) || defined(__CINT__)
        // hate you, ROOT
#else
        BinNormFunctoid(double(*ptr)(int, int, double, const double *));
#endif
        // function used by fitter
        virtual double operator()(int tempIndex, int binIndex,
                double value, const double *paramArray) const;

        // print out information about this class
        virtual void dumpToOstream(ostream& o_stream) const;

    private:
#if defined(__MAKECINT__) || defined(__CINT__)
        // hate you, ROOT
        double * m_funcPtr;
#else
        FuncPtr m_funcPtr;
#endif
        ClassDef(BinNormFunctoid, 1) // BinNormFunctoid Class

};

#endif // BinNormFunctoid_HH
