#ifndef EcalMonitorPrescaler_H
#define EcalMonitorPrescaler_H

#include "FWCore/Framework/interface/EDFilter.h"
#include "DataFormats/EcalRawData/interface/EcalRawDataCollections.h"

#include <utility>

namespace edm {
  class ConfigurationDescriptions;
}

class EcalMonitorPrescaler: public edm::EDFilter {
 public:
  EcalMonitorPrescaler(edm::ParameterSet const&);
  ~EcalMonitorPrescaler();

  void beginRun(edm::Run const&, edm::EventSetup const&) override;
  bool filter(edm::Event&, edm::EventSetup const&) override;

  static void fillDescriptions(edm::ConfigurationDescriptions&);

 private:
  enum Prescalers {
    kPhysics,
    kCosmics,
    kCalibration,
    kLaser,
    kLed,
    kTestPulse,
    kPedestal,
    nPrescalers
  };

  static uint32_t filterBits_[nPrescalers];

  edm::EDGetTokenT<EcalRawDataCollection> EcalRawDataCollection_;

  std::pair<unsigned long long, unsigned> prescalers_[nPrescalers];
};

#endif // EcalMonitorPrescaler_H
