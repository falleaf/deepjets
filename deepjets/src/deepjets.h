#include "Pythia8/Pythia.h"
#include "Pythia8Plugins/FastJet3.h"
#include <stdio.h>
#include <stdlib.h>
#include <cmath>
#include <algorithm>

using namespace Pythia8;

/*
 * Instead if passing around many arguments, we use a Result struct
 */
struct Result {
  ~Result() {
    delete jet_clusterseq;
    delete subjet_clusterseq;
  }
  fastjet::PseudoJet jet;
  std::vector<fastjet::PseudoJet> subjets;
  fastjet::ClusterSequence* jet_clusterseq;
  fastjet::ClusterSequence* subjet_clusterseq;
  double shrinkage;
};

bool keep_event(Event& event, int cut_on_pdgid, double pt_min, double pt_max) {
  if (pt_min < 0 && pt_max < 0) return true;
  bool passes = false;
  double pt;
  for (int i = 0; i < event.size(); ++i) {
    if (abs(event[i].id()) == cut_on_pdgid) {
      pt = abs(event[i].pT());
      if (pt_min >= 0 && pt < pt_min) {
        break;
      } else if (pt_max > pt_min && pt > pt_max) {
        break;
      }
      passes = true;
      break;
    }
  }
  return passes;
}

void result_to_arrays(Result& result,
                      double* jet_arr, double* subjet_arr,
                      double* jet_constit_arr, double* subjet_constit_arr) {
  /*
   * Fill arrays from the contents of a Result struct
   */
  jet_arr[0] = result.jet.perp();
  jet_arr[1] = result.jet.eta();
  jet_arr[2] = result.jet.phi_std();
  jet_arr[3] = result.jet.m();

  std::vector<fastjet::PseudoJet> constits = result.jet.constituents();

  for (unsigned int i = 0; i < constits.size(); ++i) {
      jet_constit_arr[i * 3 + 0] = constits[i].Et();
      jet_constit_arr[i * 3 + 1] = constits[i].eta();
      jet_constit_arr[i * 3 + 2] = constits[i].phi_std();
  }

  fastjet::PseudoJet subjet_sum;

  // Get details and constituents from subjets.
  int iconstit = 0;
  for (unsigned int i = 0; i < result.subjets.size(); ++i) {
    subjet_sum += result.subjets[i];
    subjet_arr[i * 4 + 0] = result.subjets[i].perp();
    subjet_arr[i * 4 + 1] = result.subjets[i].eta();
    subjet_arr[i * 4 + 2] = result.subjets[i].phi_std();
    subjet_arr[i * 4 + 3] = result.subjets[i].m();
    constits = result.subjets[i].constituents();
    for (unsigned int j = 0; j < constits.size(); ++j) {
      subjet_constit_arr[iconstit * 3 + 0] = constits[j].Et();
      subjet_constit_arr[iconstit * 3 + 1] = constits[j].eta();
      subjet_constit_arr[iconstit * 3 + 2] = constits[j].phi_std();
      ++iconstit;
    }
  }

  // The trimmed jet
  jet_arr[4] = subjet_sum.perp();
  jet_arr[5] = subjet_sum.eta();
  jet_arr[6] = subjet_sum.phi_std();
  jet_arr[7] = subjet_sum.m();
}

Result* get_jets(Event& event,
                 double eta_max,
                 double jet_size, double subjet_size_fraction,
                 double jet_pt_min, double subjet_pt_min_fraction,
                 bool shrink, double shrink_mass) {
  /*
   * Find leading pT jet in event with anti-kt algorithm (params jet_size, jet_pt_min, eta_max).
   * Find subjets by re-cluster jet using kt algorith (params subjet_size_fraction * jet_size, subjet_size_fraction).
   * Return a Result struct
   */

  // Begin FastJet analysis: extract particles from event record.
  std::vector<fastjet::PseudoJet> fjInputs;
  for (int i = 0; i < event.size(); ++i) if (event[i].isFinal()) {
    // Require visible particles inside detector.
    if (!event[i].isVisible()) continue;
    if (abs(event[i].eta()) > eta_max) continue;

    // Create a PseudoJet from the complete Pythia particle.
    fastjet::PseudoJet particleTemp = event[i];

    // Store acceptable particles as input to Fastjet.
    // Conversion to PseudoJet is performed automatically
    // with the help of the code in FastJet3.h.
    fjInputs.push_back(particleTemp);
  }

  // Run Fastjet algorithm and sort jets in pT order.
  std::vector<fastjet::PseudoJet> sortedjets;
  fastjet::JetDefinition jetDef(fastjet::genkt_algorithm, jet_size, -1); // anti-kt
  fastjet::ClusterSequence* clustSeq = new fastjet::ClusterSequence(fjInputs, jetDef);
  sortedjets = sorted_by_pt(clustSeq->inclusive_jets(jet_pt_min));

  // Get leading jet.
  fastjet::PseudoJet& jet = sortedjets[0];
  std::vector<fastjet::PseudoJet> Jconstits = jet.constituents();
  int Jsize = Jconstits.size();

  // Store constituents from leading jet.
  std::vector<fastjet::PseudoJet> TfjInputs;
  for (int i = 0; i < Jsize; ++i) {
    TfjInputs.push_back(Jconstits[i]);
  }

  double shrinkage = 1.;
  double actual_size;
  if (shrink) {
    // Shrink distance parameter to 2 * m / pT
    if (shrink_mass <= 0) {
        // Use jet mass
        shrink_mass = jet.m();
    }
    actual_size = std::min(jet_size, std::abs(2 * shrink_mass / jet.perp()));
    shrinkage = actual_size / jet_size;
    jet_size = actual_size;
    // TODO handle case where m==0
  }

  // Run Fastjet trimmer on leading jet.
  fastjet::JetDefinition TjetDef(fastjet::genkt_algorithm, subjet_size_fraction * jet_size, 1); // kt
  fastjet::ClusterSequence* TclustSeq = new fastjet::ClusterSequence(TfjInputs, TjetDef);

  Result* result = new Result();
  result->jet = jet;
  result->subjets = sorted_by_pt(TclustSeq->inclusive_jets(jet.perp() * subjet_pt_min_fraction));
  result->jet_clusterseq = clustSeq;
  result->subjet_clusterseq = TclustSeq;
  result->shrinkage = shrinkage;
  return result;
}
