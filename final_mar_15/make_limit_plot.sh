#!/bin/bash
THESIS_PATH="/Users/meloam/Dropbox/thesis/auto_generated/Stop450/"
TARGET_DIR=${1:-}
if [ ! -z "$TARGET_DIR" ]; then
    OUTPUT_FILE="brazil_limit_${TARGET_DIR}.pdf"
else
    OUTPUT_FILE="brazil_limit.pdf"
fi

cat << EOF > brazil_limit.C
#include <TGraphErrors.h>
#include <TMath.h>
#include <TCanvas.h>
#include <TAttLine.h>
#include <TAxis.h>
#include <TLine.h>
#include <TLegend.h>
#include <TROOT.h>
using namespace std;
void brazil_limit() {
gROOT->SetStyle("Plain");
gStyle->SetHatchesSpacing( 1 );
gStyle->SetHatchesLineWidth( 1 );
gStyle->SetTextSize( 0.04 );
gStyle->SetTextFont( 42 );
gStyle->SetTitle("Paper");
gStyle->SetErrorX(0);
//gStyle->SetPalette(51);
gStyle->SetCanvasBorderMode(0);
gStyle->SetCanvasColor(kWhite);
gStyle->SetCanvasDefH(800);
gStyle->SetCanvasDefW(800);
gStyle->SetCanvasDefX(0);
gStyle->SetCanvasDefY(0);
gStyle->SetFrameBorderMode(0);
gStyle->SetFrameBorderSize(1);
gStyle->SetFrameFillColor(kBlack);
gStyle->SetFrameFillStyle(0);
gStyle->SetFrameLineColor(kBlack);
gStyle->SetFrameLineStyle(0);
gStyle->SetFrameLineWidth(1);
gStyle->SetPadBorderMode(0);
gStyle->SetPadColor(kWhite);
gStyle->SetPadGridX(kFALSE);
gStyle->SetPadGridY(kFALSE);
gStyle->SetGridColor(0);
gStyle->SetGridStyle(3);
gStyle->SetGridWidth(1);
gStyle->SetPadTopMargin(0.06);
gStyle->SetPadBottomMargin(0.18);
gStyle->SetPadLeftMargin(0.2);
gStyle->SetPadRightMargin(0.04);
gStyle->SetOptStat(0);
gStyle->SetOptTitle(1);
gStyle->SetTitleFont(42,"");
gStyle->SetTitleColor(1);
gStyle->SetTitleTextColor(1);
gStyle->SetTitleFillColor(0);
gStyle->SetTitleFontSize(0.04);
gStyle->SetTitleAlign(23);
gStyle->SetTitleX(0.6);
gStyle->SetTitleH(0.05);
gStyle->SetTitleBorderSize(0);
gStyle->SetTitleAlign(13);
gStyle->SetTitleX(0.19);
gStyle->SetTitleH(0.038);
gStyle->SetAxisColor(1,"XYZ");
gStyle->SetTickLength(0.03,"XYZ");
gStyle->SetNdivisions(505,"XYZ");
gStyle->SetPadTickX(1);
gStyle->SetPadTickY(1);
gStyle->SetStripDecimals(kFALSE);
gStyle->SetTitleColor(1,"XYZ");
gStyle->SetLabelColor(1,"XYZ");
gStyle->SetLabelFont(42,"XYZ");
gStyle->SetLabelOffset(0.007,"XYZ");
gStyle->SetLabelSize(0.04,"XYZ");
gStyle->SetTitleFont(42,"XYZ");
gStyle->SetTitleSize(0.045,"XYZ");
gStyle->SetTitleXOffset(1.5);
gStyle->SetTitleYOffset(1.5);
gStyle->SetLegendBorderSize(0);
gStyle->SetStatFontSize(0.03);
gStyle->SetStatX(0.92);
gStyle->SetStatY(0.86);
gStyle->SetStatH(0.16);
gStyle->SetStatW(0.22);
//   gROOT->ProcessLine(".L tdrStyle.C");
//   setTDRStyle();
  #include <iostream>
  #include <iomanip>
//   TCanvas *c1 = new TCanvas("c1","c1",200,10,700,500);
TCanvas* c1 = new TCanvas("c1","c1",800,800);
c1->SetBottomMargin(.16);
c1->SetLeftMargin(0.15);
c1->SetRightMargin(0.23);
c1->SetTopMargin(0.06);
c1->SetLogz();
c1->cd();
   double stop250_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop250/stop_sf.txt);
   double stop300_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop300/stop_sf.txt);
   double stop350_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop350/stop_sf.txt);
   double stop400_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop400/stop_sf.txt);
   double stop450_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop450/stop_sf.txt);
   double stop500_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop500/stop_sf.txt);
   double stop600_shyftSF = $(cat higgs_download/$TARGET_DIR/Stop600/stop_sf.txt);
   double r03_stop250 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');;
   double r03_stop300 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');;
   double r03_stop350 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');;
   double r03_stop400 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');;
   double r03_stop450 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');;
   double r03_stop500 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');;
   double r03_stop600 = $(grep '^Expected  2.5' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');;


   double r16_stop250 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');;
   double r16_stop300 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');;
   double r16_stop350 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');;
   double r16_stop400 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');;
   double r16_stop450 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');;
   double r16_stop500 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');;
   double r16_stop600 = $(grep '^Expected 16.0' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');;

   double r50_stop250 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');;
   double r50_stop300 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');;
   double r50_stop350 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');;
   double r50_stop400 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');;
   double r50_stop450 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');;
   double r50_stop500 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');;
   double r50_stop600 = $(grep '^Expected 50.0' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');;

   double r84_stop250 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');;
   double r84_stop300 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');;
   double r84_stop350 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');;
   double r84_stop400 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');;
   double r84_stop450 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');;
   double r84_stop500 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');;
   double r84_stop600 = $(grep '^Expected 84.0' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');;
   double r98_stop250 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');;
   double r98_stop300 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');;
   double r98_stop350 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');;
   double r98_stop400 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');;
   double r98_stop450 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');;
   double r98_stop500 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');;
   double r98_stop600 = $(grep '^Expected 97.5' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');;
   double obs_stop250 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop250/log.txt | awk '{ print $5 }');
   double obs_stop300 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop300/log.txt | awk '{ print $5 }');
   double obs_stop350 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop350/log.txt | awk '{ print $5 }');
   double obs_stop400 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop400/log.txt | awk '{ print $5 }');
   double obs_stop450 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop450/log.txt | awk '{ print $5 }');
   double obs_stop500 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop500/log.txt | awk '{ print $5 }');
   double obs_stop600 = $(grep '^Observed' higgs_download/$TARGET_DIR/Stop600/log.txt | awk '{ print $5 }');
   const Int_t n = 7;
   Float_t x[n]  = {250,300,350,400,450,500,600};
   Float_t exp_raw[n] = {r50_stop250,r50_stop300,r50_stop350,r50_stop400,r50_stop450,r50_stop500,r50_stop600};
   Float_t sf[n] = {stop250_shyftSF,stop300_shyftSF,stop350_shyftSF,stop400_shyftSF,stop450_shyftSF,stop500_shyftSF,stop600_shyftSF};
   Float_t y_observed[n] = {12.97*obs_stop250*stop250_shyftSF,4.885*obs_stop300*stop300_shyftSF,2.050*obs_stop350*stop350_shyftSF,0.9316*obs_stop400*stop400_shyftSF,0.4571*obs_stop450*stop450_shyftSF,0.2291*obs_stop500*stop500_shyftSF,0.06515*obs_stop600*stop600_shyftSF};
   Float_t y_expected_mutau[n]  = {12.97*r50_stop250*stop250_shyftSF,4.885*r50_stop300*stop300_shyftSF,2.050*r50_stop350*stop350_shyftSF,0.9316*r50_stop400*stop400_shyftSF,0.4571*r50_stop450*stop450_shyftSF,0.2291*r50_stop500*stop500_shyftSF,0.06515*r50_stop600*stop600_shyftSF};
   Float_t y_expected_mutau_minus1sigma[n]  = {12.97*r16_stop250*stop250_shyftSF,4.885*r16_stop300*stop300_shyftSF,2.050*r16_stop350*stop350_shyftSF,0.9316*r16_stop400*stop400_shyftSF,0.4571*r16_stop450*stop450_shyftSF,0.2291*r16_stop500*stop500_shyftSF,0.06515*r16_stop600*stop600_shyftSF};
   Float_t y_expected_mutau_plus1sigma[n]  = {12.97*r84_stop250*stop250_shyftSF,4.885*r84_stop300*stop300_shyftSF,2.050*r84_stop350*stop350_shyftSF,0.9316*r84_stop400*stop400_shyftSF,0.4571*r84_stop450*stop450_shyftSF,0.2291*r84_stop500*stop500_shyftSF,0.06515*r84_stop600*stop600_shyftSF};
   Float_t y_expected_mutau_minus2sigma[n]  = {12.97*r03_stop250*stop250_shyftSF,4.885*r03_stop300*stop300_shyftSF,2.050*r03_stop350*stop350_shyftSF,0.9316*r03_stop400*stop400_shyftSF,0.4571*r03_stop450*stop450_shyftSF,0.2291*r03_stop500*stop500_shyftSF,0.06515*r03_stop600*stop600_shyftSF};
   Float_t y_expected_mutau_plus2sigma[n]  = {12.97*r98_stop250*stop250_shyftSF,4.885*r98_stop300*stop300_shyftSF,2.050*r98_stop350*stop350_shyftSF,0.9316*r98_stop400*stop400_shyftSF,0.4571*r98_stop450*stop450_shyftSF,0.2291*r98_stop500*stop500_shyftSF,0.06515*r98_stop600*stop600_shyftSF};
   Float_t y_err0[n]  = {0,0,0,0,0,0,0};
   Float_t y_theory[n]     = {12.97,4.885,2.050,0.9316,0.4571,0.2291,0.06515};
   // 1 sigma
   TGraph *limit_1s_up = new TGraph(2*n+1);
   for (int i=0;i<n;i++) {
     limit_1s_up->SetPoint(i,x[i],y_expected_mutau_plus1sigma[i]);
     limit_1s_up->SetPoint(i+n,x[n-1-i],y_expected_mutau_minus1sigma[n-1-i]);
   }
   limit_1s_up->SetPoint(2*n,x[0],y_expected_mutau_plus1sigma[0]);
   limit_1s_up->SetLineStyle(2);
   limit_1s_up->SetFillColor(kYellow);
   // 2 sigma
   TGraph *limit_2s_up = new TGraph(2*n+1);
   for (int i=0;i<n;i++) {
     limit_2s_up->SetPoint(i,x[i],y_expected_mutau_plus2sigma[i]);
     limit_2s_up->SetPoint(i+n,x[n-1-i],y_expected_mutau_minus2sigma[n-1-i]);
   }
   limit_2s_up->SetPoint(2*n,x[0],y_expected_mutau_plus2sigma[0]);
   limit_2s_up->SetLineStyle(2);
   limit_2s_up->SetFillColor(kGreen);
   limit_2s_up->SetMinimum(0.01);
   limit_2s_up->SetMaximum(100.);
   limit_2s_up->SetTitle(0);
   limit_2s_up->GetXaxis()->SetTitle("m(#tilde{t}) [GeV]");
   limit_2s_up->GetXaxis()->SetLabelFont(42);
   limit_2s_up->GetXaxis()->SetLabelSize(0.05);
   limit_2s_up->GetXaxis()->SetTitleSize(0.05);
   limit_2s_up->GetXaxis()->SetTitleOffset(0.9);
   limit_2s_up->GetXaxis()->SetTitleFont(42);
   limit_2s_up->GetYaxis()->SetTitle("#sigma(pp#rightarrow#tilde{t}#tilde{t}) x Br(#tilde{t}#rightarrow b#tilde{#chi}_{1}^{#pm}) x Br(#tilde{#chi}_{1}^{#pm}#rightarrow #nu#tilde{#tau}) [pb]");
   limit_2s_up->GetYaxis()->SetLabelFont(42);
   limit_2s_up->GetYaxis()->SetLabelSize(0.05);
   limit_2s_up->GetYaxis()->SetTitleSize(0.05);
   limit_2s_up->GetYaxis()->SetTitleOffset(1.29);
   limit_2s_up->GetYaxis()->SetTitleFont(42);   
   limit_2s_up->Draw("ALF2");
   limit_1s_up->Draw("LF2same");
   TGraph *limit_1s_dn_leg = new TGraph(n, x, y_expected_mutau_minus1sigma);
   limit_1s_dn_leg->SetLineWidth(2);
   limit_1s_dn_leg->SetLineStyle(4);
   //Expected
   TGraph *limit_exp = new TGraph(n,x,y_expected_mutau);
   limit_exp->SetLineWidth(2);
   limit_exp->SetLineStyle(10);
   limit_exp->SetLineColor(1);
   limit_exp->Draw("C");
   TGraph *limit_exp_leg = new TGraph(n,x,y_expected_mutau);
   limit_exp_leg->SetLineWidth(2);
   limit_exp_leg->SetLineStyle(10);
   for (int i = 0 ; i < n; i++) {
       cout<<"Mass "<<x[i]<<"  Expected "<<y_expected_mutau[i]<<" Expected (raw) "<<exp_raw[i]<<" Observed "<<y_observed[i]<<" Theory "<<y_theory[i]<<" SF "<<sf[i]<<endl;
   }
   //Observed
   TGraph *limit_obs = new TGraph(n,x,y_observed);
   limit_obs->SetLineWidth(3);
   limit_obs->SetLineColor(1);
   limit_obs->Draw("C");
   TGraph *limit_obs_leg = new TGraph(n,x,y_observed);
   limit_obs_leg->SetLineWidth(3);
   // Theory
   TGraph *limit_theory = new TGraph(n, x, y_theory);
   limit_theory->SetLineColor(kBlue);
   limit_theory->SetLineWidth(2);
   limit_theory->SetLineStyle(1);
   limit_theory->Draw("C");
   c1->SetLogy();
   //Legend
   TLegend *legendr = new TLegend(0.4778894,0.6781337,0.668593,0.9037604,NULL,"brNDC");
   legendr->SetShadowColor(0);
   legendr->SetBorderSize(0);
   legendr->SetFillColor(0);
   legendr->AddEntry(limit_obs_leg,"Observed","L");
   legendr->AddEntry(limit_1s_up,"Expected #pm 1#sigma","fl");
   legendr->AddEntry(limit_exp_leg, "Expected", "L"); 
   legendr->AddEntry(limit_2s_up,"Expected #pm 2#sigma","fl");
   legendr->AddEntry(limit_theory,"#sigma(LO)","L");
   legendr->SetFillStyle(0);
   legendr->SetTextSize(.04);
   legendr->SetTextFont(42);
   legendr->SetFillColor(0);
 
   legendr->SetBorderSize(0);
   legendr->Draw();
   TPaveText *pt = new TPaveText(0.1072864,0.9618663,0.9080402,0.9820056,"brNDC");
   pt->SetBorderSize(0);
   pt->SetFillColor(0);
   pt->SetLineColor(0);
   pt->SetTextFont(42);
   pt->SetTextSize(0.035);
   TText *text = pt->AddText("CMS Preliminary                19.7 fb^{-1}, #sqrt{s} = 8 TeV            ");
   text->SetTextFont(42);
   pt->Draw();
   c1->SaveAs("$OUTPUT_FILE");
}
void setTDRStyle(){
  TStyle *tdrStyle = new TStyle("tdrStyle","Style for P-TDR");
  // For the canvas:
  tdrStyle->SetCanvasBorderMode(0);
  tdrStyle->SetCanvasColor(kWhite);
  tdrStyle->SetCanvasDefH(600); //Height of canvas
  tdrStyle->SetCanvasDefW(600); //Width of canvas
  tdrStyle->SetCanvasDefX(0);   //POsition on screen
  tdrStyle->SetCanvasDefY(0);
  // For the Pad:
  tdrStyle->SetPadBorderMode(0);
  // tdrStyle->SetPadBorderSize(Width_t size = 1);
  tdrStyle->SetPadColor(kWhite);
  tdrStyle->SetPadGridX(false);
  tdrStyle->SetPadGridY(false);
  tdrStyle->SetGridColor(0);
  tdrStyle->SetGridStyle(3);
  tdrStyle->SetGridWidth(1);
  // For the frame:
  tdrStyle->SetFrameBorderMode(0);
  tdrStyle->SetFrameBorderSize(1);
  tdrStyle->SetFrameFillColor(0);
  tdrStyle->SetFrameFillStyle(0);
  tdrStyle->SetFrameLineColor(1);
  tdrStyle->SetFrameLineStyle(1);
  tdrStyle->SetFrameLineWidth(1);
  // For the histo:
  tdrStyle->SetHistFillColor(0);
  tdrStyle->SetHistLineColor(1);
  tdrStyle->SetHistLineStyle(0);
  tdrStyle->SetHistLineWidth(1);
  tdrStyle->SetErrorX(0.);
  tdrStyle->SetMarkerStyle(20);
  //For the fit/function:
  tdrStyle->SetOptFit(1);
  tdrStyle->SetFitFormat("5.4g");
  //tdrStyle->SetFuncColor(1);
  tdrStyle->SetFuncStyle(1);
  tdrStyle->SetFuncWidth(1);
  //For the date:
  tdrStyle->SetOptDate(0);
  // For the statistics box:
  tdrStyle->SetOptFile(0);
  tdrStyle->SetOptStat("e"); // To display the mean and RMS:   SetOptStat("mr");
  tdrStyle->SetStatColor(kGray);
  tdrStyle->SetStatFont(42);
  tdrStyle->SetStatTextColor(1);
  tdrStyle->SetStatFormat("6.4g");
  tdrStyle->SetStatBorderSize(0);
  tdrStyle->SetStatX(1.); //Starting position on X axis
  tdrStyle->SetStatY(1.); //Starting position on Y axis
  tdrStyle->SetStatFontSize(0.025); //Vertical Size
  tdrStyle->SetStatW(0.15); //Horizontal size
  // tdrStyle->SetStatStyle(Style_t style = 1001);
  // Margins:
  tdrStyle->SetPadTopMargin(0.05);
  tdrStyle->SetPadBottomMargin(0.125);
  tdrStyle->SetPadLeftMargin(0.105);
  tdrStyle->SetPadRightMargin(0.1);
  // For the Global title:
  //  tdrStyle->SetOptTitle(0);
  tdrStyle->SetTitleFont(42);
  tdrStyle->SetTitleColor(1);
  tdrStyle->SetTitleTextColor(1);
  tdrStyle->SetTitleFillColor(10);
  tdrStyle->SetTitleFontSize(0.05);
  // For the axis titles:
  tdrStyle->SetTitleColor(1, "XYZ");
  tdrStyle->SetTitleFont(42, "XYZ");
  tdrStyle->SetTitleSize(0.06, "XYZ");
  tdrStyle->SetTitleXOffset(0.9);
  tdrStyle->SetTitleYOffset(0.9);
  tdrStyle->SetTitleOffset(0.7, "Y"); // Another way to set the Offset
  // For the axis labels:
  tdrStyle->SetLabelColor(1, "XYZ");
  tdrStyle->SetLabelFont(42, "XYZ");
  tdrStyle->SetLabelOffset(0.007, "XYZ");
  tdrStyle->SetLabelSize(0.05, "XYZ");
  // For the axis:
  tdrStyle->SetAxisColor(1, "XYZ");
  tdrStyle->SetStripDecimals(kTRUE);
  tdrStyle->SetTickLength(0.03, "XYZ");
  tdrStyle->SetNdivisions(510, "XYZ");
  tdrStyle->SetPadTickX(1);  // To get tick marks on the opposite side of the frame
  tdrStyle->SetPadTickY(1);
  // Change for log plots:
  tdrStyle->SetOptLogx(0);
  tdrStyle->SetOptLogy(0);
  tdrStyle->SetOptLogz(0);
  tdrStyle->cd();
}
EOF
root -l -b -q brazil_limit.C
open $OUTPUT_FILE
