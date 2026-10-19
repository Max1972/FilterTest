#pragma once
#include <cmath>
namespace openmb {
enum class Mode { downwardCompression, upwardCompression, downwardExpansion, upwardExpansion, limiting, gating };
struct DynamicsParameters {
    Mode mode = Mode::downwardCompression;
    float thresholdDb = -24, ratio = 4, kneeDb = 6, rangeDb = 24;
    float attackMs = 10, releaseMs = 100;
};
// Pure static curve: returned value is a gain adjustment in dB.
float gainComputer(float levelDb, const DynamicsParameters&) noexcept;
class Dynamics {
public:
    void prepare(double sampleRate) noexcept;
    void reset() noexcept { gainDb_ = 0; }
    void setParameters(DynamicsParameters parameters) noexcept;
    float process(float detectorMagnitude) noexcept;
    float gainDb() const noexcept { return gainDb_; }
private:
    double sampleRate_ = 48000;
    DynamicsParameters parameters_;
    float attack_ = 0, release_ = 0, gainDb_ = 0;
};
}
