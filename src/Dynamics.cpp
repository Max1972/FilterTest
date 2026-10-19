#include "openmb/Dynamics.h"
#include <algorithm>
namespace openmb {
namespace {
float positiveKnee(float x, float width) noexcept {
    if (width <= 0) return std::max(0.0f, x);
    if (x <= -width * 0.5f) return 0;
    if (x >= width * 0.5f) return x;
    const float t = x + width * 0.5f;
    return t * t / (2 * width);
}
}
float gainComputer(float level, const DynamicsParameters& p) noexcept {
    const float ratio = std::clamp(p.ratio, 1.0f, 100.0f);
    const float above = positiveKnee(level - p.thresholdDb, std::clamp(p.kneeDb, 0.0f, 36.0f));
    const float below = positiveKnee(p.thresholdDb - level, std::clamp(p.kneeDb, 0.0f, 36.0f));
    float db = 0;
    switch (p.mode) {
        case Mode::downwardCompression: db = -(1 - 1 / ratio) * above; break;
        case Mode::upwardCompression: db = (1 - 1 / ratio) * below; break;
        case Mode::downwardExpansion: db = -(ratio - 1) * below; break;
        case Mode::upwardExpansion: db = (ratio - 1) * above; break;
        case Mode::limiting: db = -above; break;
        case Mode::gating: db = -(ratio - 1) * below; break;
    }
    const float range = std::clamp(std::abs(p.rangeDb), 0.0f, 60.0f);
    return std::clamp(db, -range, range);
}
void Dynamics::prepare(double rate) noexcept {
    sampleRate_ = std::isfinite(rate) && rate >= 8000 ? rate : 48000;
    setParameters(parameters_);
    reset();
}
void Dynamics::setParameters(DynamicsParameters p) noexcept {
    parameters_ = p;
    attack_ = static_cast<float>(std::exp(-1.0 / (sampleRate_ * std::clamp(p.attackMs, 0.1f, 500.0f) * 0.001)));
    release_ = static_cast<float>(std::exp(-1.0 / (sampleRate_ * std::clamp(p.releaseMs, 1.0f, 3000.0f) * 0.001)));
}
float Dynamics::process(float magnitude) noexcept {
    if (!std::isfinite(magnitude)) magnitude = 0;
    const float level = 20 * std::log10(std::max(std::abs(magnitude), 1.0e-12f));
    const float target = gainComputer(level, parameters_);
    const float coefficient = std::abs(target) > std::abs(gainDb_) ? attack_ : release_;
    gainDb_ = target + coefficient * (gainDb_ - target);
    if (std::abs(gainDb_) < 1.0e-12f) gainDb_ = 0;
    return std::pow(10.0f, gainDb_ / 20);
}
}
