#include "DQM/EcalCommon/interface/EcalMonitorPrescaler.h"

#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/EventSetup.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"

#include "FWCore/MessageLogger/interface/MessageLogger.h"
#include "FWCore/Framework/interface/MakerMacros.h"

#include <cmath>
#include <iostream>

uint32_t EcalMonitorPrescaler::filterBits_[EcalMonitorPrescaler::nPrescalers] = {
  (1 << EcalDCCHeaderBlock::MTCC) |
  (1 << EcalDCCHeaderBlock::PHYSICS_GLOBAL) |
  (1 << EcalDCCHeaderBlock::PHYSICS_LOCAL), // kPhysics
  (1 << EcalDCCHeaderBlock::COSMIC) |
  (1 << EcalDCCHeaderBlock::COSMICS_GLOBAL) |
  (1 << EcalDCCHeaderBlock::COSMICS_LOCAL), // kCosmics
  (1 << EcalDCCHeaderBlock::LASER_STD) |
  (1 << EcalDCCHeaderBlock::LASER_GAP) |
  (1 << EcalDCCHeaderBlock::LED_STD) |
  (1 << EcalDCCHeaderBlock::LED_GAP) |
  (1 << EcalDCCHeaderBlock::PEDESTAL_STD) |
  (1 << EcalDCCHeaderBlock::PEDESTAL_GAP) |
  (1 << EcalDCCHeaderBlock::TESTPULSE_MGPA) |
  (1 << EcalDCCHeaderBlock::TESTPULSE_GAP) |
  (1 << EcalDCCHeaderBlock::PEDESTAL_OFFSET_SCAN), // kCalibration
  (1 << EcalDCCHeaderBlock::LASER_STD) |
  (1 << EcalDCCHeaderBlock::LASER_GAP), // kLaser
  (1 << EcalDCCHeaderBlock::LED_STD) |
  (1 << EcalDCCHeaderBlock::LED_GAP), // kLed
  (1 << EcalDCCHeaderBlock::TESTPULSE_MGPA) |
  (1 << EcalDCCHeaderBlock::TESTPULSE_GAP), // kTestPulse
  (1 << EcalDCCHeaderBlock::PEDESTAL_STD) |
  (1 << EcalDCCHeaderBlock::PEDESTAL_GAP) |
  (1 << EcalDCCHeaderBlock::PEDESTAL_OFFSET_SCAN) // kPedestal
};

EcalMonitorPrescaler::EcalMonitorPrescaler(edm::ParameterSet const& _ps):
  EcalRawDataCollection_(consumes<EcalRawDataCollection>(_ps.getParameter<edm::InputTag>("EcalRawDataCollection")))
{
  for(unsigned iP(0); iP != nPrescalers; ++iP) prescalers_[iP].first = 0;

  prescalers_[kPhysics].second = _ps.getUntrackedParameter<unsigned>("physics");
  prescalers_[kCosmics].second = _ps.getUntrackedParameter<unsigned>("cosmics");
  prescalers_[kCalibration].second = _ps.getUntrackedParameter<unsigned>("calibration");
  prescalers_[kLaser].second = _ps.getUntrackedParameter<unsigned>("laser");
  prescalers_[kLed].second = _ps.getUntrackedParameter<unsigned>("led");
  prescalers_[kTestPulse].second = _ps.getUntrackedParameter<unsigned>("testPulse");
  prescalers_[kPedestal].second = _ps.getUntrackedParameter<unsigned>("pedestal");

  // Backward compatibility
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("occupancyPrescaleFactor")));
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("integrityPrescaleFactor")));
  prescalers_[kCosmics].second = std::min(prescalers_[kCosmics].second, (unsigned int)(_ps.getUntrackedParameter<int>("cosmicPrescaleFactor")));
  prescalers_[kLaser].second = std::min(prescalers_[kLaser].second, (unsigned int)(_ps.getUntrackedParameter<int>("laserPrescaleFactor")));
  prescalers_[kLed].second = std::min(prescalers_[kLed].second, (unsigned int)(_ps.getUntrackedParameter<int>("ledPrescaleFactor")));
  prescalers_[kPedestal].second = std::min(prescalers_[kPedestal].second, (unsigned int)(_ps.getUntrackedParameter<int>("pedestalPrescaleFactor")));
  prescalers_[kPedestal].second = std::min(prescalers_[kPedestal].second, (unsigned int)(_ps.getUntrackedParameter<int>("pedestalonlinePrescaleFactor")));
  prescalers_[kTestPulse].second = std::min(prescalers_[kTestPulse].second, (unsigned int)(_ps.getUntrackedParameter<int>("testpulsePrescaleFactor")));
  prescalers_[kPedestal].second = std::min(prescalers_[kPedestal].second, (unsigned int)(_ps.getUntrackedParameter<int>("pedestaloffsetPrescaleFactor")));
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("triggertowerPrescaleFactor")));
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("timingPrescaleFactor")));
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("physicsPrescaleFactor")));
  prescalers_[kPhysics].second = std::min(prescalers_[kPhysics].second, (unsigned int)(_ps.getUntrackedParameter<int>("clusterPrescaleFactor")));
}
    
EcalMonitorPrescaler::~EcalMonitorPrescaler()
{
}

/*static*/
void
EcalMonitorPrescaler::fillDescriptions(edm::ConfigurationDescriptions& _descs)
{
  edm::ParameterSetDescription desc;

  desc.add<edm::InputTag>("EcalRawDataCollection");

  std::string newPrescalerNames[] = {"physics", "cosmics", "calibration", "laser", "led", "testPulse", "pedestal"};
  for(unsigned iP(0); iP != sizeof(newPrescalerNames) / sizeof(std::string); ++iP)
    desc.addUntracked<unsigned>(newPrescalerNames[iP], 0);

  std::string oldPrescalerNames[] = {"occupancy", "integrity", "cosmic", "laser", "led", "pedestal", "pedestalonline", "testpulse", "pedestaloffset", "triggertower", "timing", "physics", "cluster"};
  for(unsigned iP(0); iP != sizeof(oldPrescalerNames) / sizeof(std::string); ++iP)
    desc.addUntracked<int>(oldPrescalerNames[iP] + "PrescaleFactor", 0)->setComment("Old-style prescale. Use discouraged but is still valid.");

  _descs.addDefault(desc);
}

void
EcalMonitorPrescaler::beginRun(edm::Run const&, edm::EventSetup const&)
{
  for(unsigned iP(0); iP != nPrescalers; ++iP) prescalers_[iP].first = 0;
}

bool
EcalMonitorPrescaler::filter(edm::Event& _event, edm::EventSetup const&)
{
  edm::Handle<EcalRawDataCollection> dcchs;

  if(!_event.getByToken(EcalRawDataCollection_, dcchs)){
    edm::LogWarning("EcalMonitorPrescaler") << "EcalRawDataCollection not available";
    return false;
  }

  uint32_t eventBits(0);
  for(EcalRawDataCollection::const_iterator dcchItr(dcchs->begin()); dcchItr != dcchs->end(); ++dcchItr)
    eventBits |= (1 << dcchItr->getRunType());

  for(unsigned iP(0); iP != nPrescalers; ++iP){
    if(prescalers_[iP].second != 0 && (eventBits & filterBits_[iP]) != 0 && ++prescalers_[iP].first % prescalers_[iP].second == 0)
      return true;
  }

  return false;
}

DEFINE_FWK_MODULE(EcalMonitorPrescaler);
