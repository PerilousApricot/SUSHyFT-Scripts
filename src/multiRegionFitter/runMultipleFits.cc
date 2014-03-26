#include "TFile.h"
#include "TH1.h"
#include "TCanvas.h"
#include "TLegend.h"
#include "TStyle.h"
#include "TROOT.h"
#include "TTree.h"
#include "TFile.h"
#include "TBenchmark.h"
#include "TRandom3.h"

#include "OptionUtils/interface/CommandLineParser.h"
#include "OptionUtils/interface/dout.h"
#include "CLPTemplateMorph/interface/dumpSTL.icc"
#include "MRFitterNamespace.h"

#include <iostream>
#include <string>
#include <cassert>

using namespace std;

// forward declarations
void localInitialize();

int main(int argc, char** argv)
{
   /////////////////////////////////////////
   // Setup fitters and parameter vectors //
   /////////////////////////////////////////
   localInitialize();     // hook up local options
   mrf::ns_parser.parseArguments(argc, argv, true);
   mrf::setDataName();
   const optutl::CommandLineParser::SVec arguments =
      mrf::ns_parser.nonOptionArgsVec();

   if(arguments.size() != 3)
   {
      cerr << "Must provide 3 configuration filenames." << endl;
      mrf::ns_parser.help();
   }
   int nfits = arguments.size();
   string fitterConfigNames[nfits];
   for(int i = 0; i<nfits; i++){
     fitterConfigNames[i] =  arguments.at(i);
   }
   string peFitterConfigName( arguments.at(0) );

   mrf::MRFitter fitters[3] = {
     mrf::MRFitter( fitterConfigNames[0] ),
     mrf::MRFitter( fitterConfigNames[1] ),
     mrf::MRFitter( fitterConfigNames[2] )
   };
   mrf::MRFitter peFitter( peFitterConfigName, "PE");

   gRandom->SetSeed(peFitter.integerValue ("randomSeed"));
   mrf::DVec paramVec[nfits];
   mrf::DVec peParamVec;
   BinsSumCont &binsSumCont = peFitter.binsSumCont();
   // setup parameter vectors to fitter initial values
   for(int i = 0; i<nfits; i++){
     fitters[i].setupParamVec(paramVec[i],   true);
   }
   peFitter.setupParamVec(peParamVec, true);

    ///////////////////////
    // Setup output name //
    ///////////////////////
    string tag;
    mrf::processOptions(tag);
    fitters[0].stringValue("output") =
       optutl::CommandLineParser::removeEnding(fitters[0].
                                                stringValue("output"),
                                                ".root");
    fitters[0].stringValue("output") += tag;
    if(fitters[0].integerValue ("randomSeed"))
    {
       fitters[0].stringValue("output") +=
          Form("_seed%03d", fitters[0].integerValue ("randomSeed"));
    }
    if(! fitters[0].doubleValue ("intLumi") )
    {
       // do nothing
    } else if(fitters[0].doubleValue ("intLumi") < 0.0001 ||
        fitters[0].doubleValue("intLumi") > 1e4)
    {
       fitters[0].stringValue("output") +=
          Form("_lum%f", fitters[0].doubleValue ("intLumi"));
    } else if(fitters[0].doubleValue ("intLumi") >= 0.0001 &&
               fitters[0].doubleValue("intLumi") < 1.0)
    {
       fitters[0].stringValue("output") +=
          Form("_lum%.4f", fitters[0].doubleValue ("intLumi"));
    } else if(fitters[0].doubleValue ("intLumi") >= 1.0 &&
               fitters[0].doubleValue("intLumi") < 1e3)
    {
       fitters[0].stringValue("output") +=
          Form("_lum%.1f", fitters[0].doubleValue ("intLumi"));
    } else {
       fitters[0].stringValue("output") +=
          Form("_lum%.0f", fitters[0].doubleValue ("intLumi"));
    }

//    //////////////////////////////////////////////
//    // Save templates with specified parameters //
//    //////////////////////////////////////////////
//    if(fitter.stringVector ("saveCanvasWithParams").size())
//    {
//       mrf::DVec tempParamVec;
//       fitter.setupParamVec(tempParamVec, true);
//       mrf::SDMap valueMap;
//       mrf::_svecToSDMap(fitter.stringVector ("saveCanvasWithParams"),
//                          valueMap);
//       for(mrf::SDMapConstIter iter = valueMap.begin();
//            valueMap.end() != iter;
//            ++iter)
//       {
//          int index = fitter.parameterIndex( iter->first );
//          if(index < 0)
//          {
//             // uh oh
//             cerr << "Fitter does not have a parameter '" << iter->first
//                  << "'." << endl;
//             assert(0);
//          }
//          tempParamVec.at(index) = iter->second;
//       } // for iter
//       fitter.saveCanvasResult(fitter.stringValue ("output") + "_params",
//                                 tempParamVec);
//    }
//
    //////////////
    // Fit Data //
    //////////////
   int fitterConfigNumber=2;
    if(fitters[fitterConfigNumber].boolValue ("fitData"))
    {
       fitters[fitterConfigNumber].fit(true);
//       if(fitters[fitterConfigNumber].boolValue ("savePlots"))
//       {
//          fitters[fitterConfigNumber].saveCanvasResult(fitters[fitterConfigNumber].stringValue ("output"));
//       }
//       if(binsSumCont.size() && fitters[fitterConfigNumber].integerValue ("covarPEs"))
//       {
//          mrf::DVec resultVec;
//          fitters[fitterConfigNumber].fillParamVec(resultVec);
//          mrf::SVec nameVec;
//          binsSumCont.getAllNames(nameVec);
//          mrf::DVec centerVec;
//          binsSumCont.setParamVec(resultVec);
//          binsSumCont.getValues(centerVec);
//          fitters[fitterConfigNumber].storeSqrtMatrix();
//          for(int loop = 0;
//               loop < fitters[fitterConfigNumber].integerValue("covarPEs");
//               ++loop)
//          {
//             mrf::DVec randomVec(resultVec);
//             fitters[fitterConfigNumber].generateRandomParams(randomVec);
//             binsSumCont.setParamVec(randomVec);
//             binsSumCont.recordTrials();
//          } // for loop
//          mrf::DVec meanVec, rmsVec;
//          binsSumCont.fillMeansAndRMSs(meanVec, rmsVec);
//          // dumpNamedSTLendl("meas   ", meanVec);
//          // dumpNamedSTLendl("center ", centerVec);
//          // dumpNamedSTLendl("rms    ", rmsVec);
//       } // if we have something to play with
    } // if fitting data

   /////////////////
   // Test Fitter //
   /////////////////
   if(fitters[0].boolValue ("runFitterTest"))
   {
      fitters[0].testFitter();
   }

   // only bother going further if we are going to generate PEs
   if(! fitters[0].integerValue ("numPEs"))
   {
      return 0;
   }

   ////////////////////////////
   // ////////////////////// //
   // // //////////////// // //
   // // // Throw PEs! // // //
   // // //////////////// // //
   // ////////////////////// //
   ////////////////////////////

   //////////////////////
   // //////////////// //
   // // Setup Tree // //
   // //////////////// //
   //////////////////////
   TFile *outputFilePtr = 0;
   TTree *treePtr = 0;
   string outputName = fitters[0].stringValue("output") + ".root";
   cout << "Opening '" << outputName<< "' for output." << endl;
   outputFilePtr = TFile::Open(outputName.c_str(), "RECREATE");
   assert(outputFilePtr);
   // write out names of objects that are saved in vectors
   outputFilePtr->WriteObject(& (fitters[0].toFillNames()), "names");
   outputFilePtr->WriteObject(& (peFitter.toFillNames()), "PEnames");
   mrf::SVec scanNamesVec;
   int scanVecSize =(int) fitters[0].scanStructVec().size();
   if(scanVecSize)
   {
      for(mrf::ScanStructVecConstIter ssvIter = fitters[0].scanStructVec().begin();
           fitters[0].scanStructVec().end() != ssvIter;
           ++ssvIter)
      {
         scanNamesVec.push_back( ssvIter->m_name );
      } // for ssvIter
   }
   outputFilePtr->WriteObject( &scanNamesVec, "scanNames");
   treePtr = new TTree("PEtree", "PEtree");

   ////////////////////
   // Define Vectors //
   ////////////////////
   mrf::DVec *genVecPtr  [3] = {
     new mrf::DVec(fitters[0].numToFill(), 0.),
     new mrf::DVec(fitters[1].numToFill(), 0.),
     new mrf::DVec(fitters[2].numToFill(), 0.)};
   mrf::DVec *measVecPtr  [3] = {
     new mrf::DVec(fitters[0].numToFill(), 0.),
     new mrf::DVec(fitters[1].numToFill(), 0.),
     new mrf::DVec(fitters[2].numToFill(), 0.)};
   mrf::DVec *errVecPtr  [3] = {
     new mrf::DVec(fitters[0].numToFill(), 0.),
     new mrf::DVec(fitters[1].numToFill(), 0.),
     new mrf::DVec(fitters[2].numToFill(), 0.)};
   // minos errors
   mrf::DVec *posErrVecPtr  = 0;
   mrf::DVec *negErrVecPtr  = 0;
   // scan errors
   mrf::DVec *scanPosErrVecPtr = 0;
   mrf::DVec *scanNegErrVecPtr = 0;
   // Bins sums numbers
   mrf::DVec *bscMeasVecPtr = 0;
   mrf::DVec *bscCentVecPtr = 0;
   mrf::DVec *bscGenVecPtr  = 0;
   mrf::DVec *bscErrVecPtr  = 0;

   ////////////////////
   // Setup Branches //
   ////////////////////
   for(int i = 0; i<nfits; i++){
     treePtr->Branch(Form("measVec%i",i), "vector<double>", &measVecPtr[i]);
     treePtr->Branch(Form("genVec%i",i) , "vector<double>", &genVecPtr[i]);
     treePtr->Branch(Form("errVec%i",i) , "vector<double>", &errVecPtr[i]);
   }
   if(fitters[0].boolValue ("doMinos"))
   {
      treePtr->Branch("posErrVec",  "vector<double>", &posErrVecPtr);
      treePtr->Branch("negErrVec",  "vector<double>", &negErrVecPtr);
      posErrVecPtr  = new mrf::DVec(fitters[0].numToFill(), 0.);
      negErrVecPtr  = new mrf::DVec(fitters[0].numToFill(), 0.);
   }
   if(scanVecSize)
   {
      scanPosErrVecPtr = new mrf::DVec(scanVecSize, 0.);
      scanNegErrVecPtr = new mrf::DVec(scanVecSize, 0.);
      treePtr->Branch("scanPosErr", "vector<double>", &scanPosErrVecPtr);
      treePtr->Branch("scanNegErr", "vector<double>", &scanNegErrVecPtr);
   }
//   if(binsSumCont.size() && fitters[0].integerValue ("covarPEs"))
//   {
//      bscMeasVecPtr = new mrf::DVec;
//      bscCentVecPtr = new mrf::DVec;
//      bscGenVecPtr  = new mrf::DVec;
//      bscErrVecPtr  = new mrf::DVec;
//      treePtr->Branch("measBsc", "vector<double>", &bscMeasVecPtr);
//      treePtr->Branch("centBsc", "vector<double>", &bscMeasVecPtr);
//      treePtr->Branch("genBsc",  "vector<double>", &bscGenVecPtr);
//      treePtr->Branch("errBsc",  "vector<double>", &bscErrVecPtr);
//      mrf::SVec bscNamesVec;
//      binsSumCont.getAllNames(bscNamesVec);
//      outputFilePtr->WriteObject(&bscNamesVec, "bscNames");
//   } // if we are using binsSumContainers

   ////////////////////////
   // Final Preparations //
   ////////////////////////
   int everyN = 1000;
   if(fitters[0].integerValue ("numPEs") % 20 < everyN &&
       fitters[0].integerValue("numPEs") > 20)
   {
      everyN = fitters[0].integerValue("numPEs") / 20;
      if(! everyN)
      {
         everyN = 1;
      }
   }
   // setup vector, initializing it
   // dumpNamedSTLendl("names", peFitter.stringVector ("PEnames"));
   mrf::BlurStructVec blurVec;
   peFitter.setupBlurStruct(blurVec,
                             peFitter.stringVector("PEnames"),
                             peFitter.doubleVector("PEmeans"),
                             peFitter.doubleVector("PEsigmas"));
   mrf::SVec peParamNamesVec;
   peFitter.fillNameVec(peParamNamesVec);

   /////////////////////////
   // Throw, Baby, Throw! //
   /////////////////////////
   for(int loop = 0; loop < peFitter.integerValue ("numPEs"); ++loop)
   {
      if((loop + 1) % everyN == 0 || fitters[0].boolValue ("printFitResults"))
      {
         cout << "event " << loop + 1 << endl;
      }
      // only put in new values into vector
      mrf::blurParamVec(peParamVec, blurVec);
      if(fitters[0].boolValue ("printFitResults"))
      {
         assert(peParamVec.size() == peParamNamesVec.size());
         int size = peParamNamesVec.size();
         cout << "Thrown:" << endl;
         for(int loop = 0; loop < size; ++loop)
         {
            cout << Form("%-10s: %f",
                          peParamNamesVec.at(loop).c_str(),
                          peParamVec.at(loop))
                 << endl;
         }
      } // if printing results
      // throw using PE fitter
      peFitter.throwPE(peParamVec, peFitter.boolValue ("idealPE"));
      // move PE from PE fitter to fitting fitter
      for(int i = 0; i<nfits; i++){
	fitters[i].getDataFromOtherFitter(peFitter);
	// fit
	fitters[i].fit(fitters[i].boolValue ("printFitResults"));
	mrf::DVec fitterValues, fitterErrors;
	fitters[i].fillParamVec(fitterValues);
	fitters[i].fillErrorVec(fitterErrors);
	// generated values is from peFitter; results from fitter
	peFitter.convertFitterToTreeOrder(peParamVec,   *genVecPtr[i]);
	fitters[i].convertFitterToTreeOrder(fitterValues, *measVecPtr[i]);
	fitters[i].convertFitterToTreeOrder(fitterErrors, *errVecPtr[i]);
      }
      if(fitters[0].boolValue ("doMinos"))
      {
         mrf::DVec posErrors, negErrors;
         fitters[0].fillPosErrorVec(posErrors);
         fitters[0].fillNegErrorVec(negErrors);
         fitters[0].convertFitterToTreeOrder(posErrors, *posErrVecPtr);
         fitters[0].convertFitterToTreeOrder(negErrors, *negErrVecPtr);
      }
      if(scanVecSize)
      {
         for(int loop = 0; loop < scanVecSize; ++loop)
         {
            scanPosErrVecPtr->at(loop) =
               fitters[0].scanStructVec().at(loop).m_upperError;
            scanNegErrVecPtr->at(loop) =
               fitters[0].scanStructVec().at(loop).m_lowerError;
         } // for loop
      } // if scanning variables
//       if(fitters[0].boolValue ("savePlots"))
//       {
//          fitters[0].saveCanvasResult( Form ("%s_pe%d",
//                                         fitters[0].stringValue("output").c_str(),
//                                         loop) );
//          fitters[0].saveCanvasResult( Form ("%s_pe%d_should",
//                                         fitters[0].stringValue("output").c_str(),
//                                         loop),
//                                   paramVec );
//       }
//       if(binsSumCont.size() && fitters[0].integerValue ("covarPEs"))
//       {
//          binsSumCont.reset();
//          fitters[0].storeSqrtMatrix();
//          binsSumCont.setParamVec(fitterValues);
//          binsSumCont.getValues(*bscCentVecPtr);
//          for(int loop = 0; loop < fitters[0].integerValue ("covarPEs");
//               ++loop)
//          {
//             mrf::DVec randomVec(fitterValues);
//             fitters[0].generateRandomParams(randomVec);
//             binsSumCont.setParamVec(randomVec);
//             binsSumCont.recordTrials();
//          }
//          binsSumCont.fillMeansAndRMSs(*bscMeasVecPtr, *bscErrVecPtr);
//          binsSumCont.setParamVec(paramVec);
//          binsSumCont.getValues(*bscGenVecPtr);
//          if(fitters[0].boolValue ("printFitResults"))
//          {
//             // dumpNamedSTLendl("meas   ", *bscMeasVecPtr);
//             // dumpNamedSTLendl("center ", *bscCentVecPtr);
//             // dumpNamedSTLendl("rms    ", *bscErrVecPtr);
//             // dumpNamedSTLendl("gen    ", *bscGenVecPtr);
//             cout << endl << endl << endl << endl;
//          } // if print results
//       } // if running covariance PEs

      treePtr->Fill();
   } // for loop
   // write out everything
   outputFilePtr->cd();
   treePtr->Write();
   outputFilePtr->Close();
   cout << "done." << endl;
}

void localInitialize()
{
   using namespace optutl;
   using namespace mrf;
   ns_parser.addOption("fitData",
                        VariableMapCont::kBool,
                        "Fit data or not",
                        false);
   ns_parser.addOption("numPEs",
                        VariableMapCont::kInteger,
                        "Number of PEs to throw",
                        0);
   ns_parser.addOption("output",
                        VariableMapCont::kString,
                        "Name of output root file",
                        "output.root");
   ns_parser.addOption("idealPE",
                        VariableMapCont::kBool,
                        "Throw ideal PE",
                        false);
   ns_parser.addOption("savePlots",
                        VariableMapCont::kBool,
                        "Save Plots",
                        false);
   ns_parser.addOption("printFitResults",
                        VariableMapCont::kBool,
                        "Print fit results for PEs",
                        false);
   ns_parser.addOption("runFitterTest",
                        VariableMapCont::kBool,
                        "Run testFitter subroutine for debugging",
                        false);
   ns_parser.addOption("randomSeed",
                        VariableMapCont::kInteger,
                        "Random seed to use for PEs",
                        0);
   ns_parser.addOption("print",
                        VariableMapCont::kBool,
                        "Print all values after loading config file",
                        false);
   ns_parser.addOption("covarPEs",
                        VariableMapCont::kInteger,
                        "Number of covariance sets to generate",
                        0);
   ns_parser.addOption("saveCanvasWithParams",
                        VariableMapCont::kStringVector,
                        "Name and value pairs used to save canvas");
   ns_parser.addOption("peNames",
                        VariableMapCont::kStringVector,
                        "Names of variables to fluctuate for PEs");
   ns_parser.addOption("peMeans",
                        VariableMapCont::kDoubleVector,
                        "Means of variables to fluctuate for PEs");
   ns_parser.addOption("peSigmas",
                        VariableMapCont::kDoubleVector,
                        "Sigmas of variables to fluctuate for PEs");

}
