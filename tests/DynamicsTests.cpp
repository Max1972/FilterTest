#include "openmb/Dynamics.h"
#include <array>
#include <cstdlib>
#include <iostream>
#include <limits>
void check(bool ok, const char* message) { if (!ok) { std::cerr << message << '\n'; std::exit(1); } }
int main() {
    using namespace openmb;
    DynamicsParameters p; p.kneeDb = 0;
    check(std::abs(gainComputer(-12, p) + 9) < 0.001f, "4:1 compression curve");
    check(gainComputer(-30, p) == 0, "below threshold identity");
    p.ratio = 1;
    for (int i=0; i<4; ++i) { p.mode=static_cast<Mode>(i); check(gainComputer(-12,p)==0 && gainComputer(-40,p)==0, "1:1 identity"); }
    p.ratio=4;
    for (int mode=0; mode<6; ++mode) {
        p.mode=static_cast<Mode>(mode);
        for (float level=-120; level<=12; level+=0.1f) {
            const float gain=gainComputer(level,p);
            check(std::isfinite(gain) && std::abs(gain)<=24.001f, "bounded curve");
        }
    }
    p.mode=Mode::upwardCompression; check(gainComputer(-36,p)>0,"upward compression");
    p.mode=Mode::downwardExpansion; check(gainComputer(-36,p)<0,"downward expansion");
    p.mode=Mode::upwardExpansion; check(gainComputer(-12,p)>0,"upward expansion");
    p.mode=Mode::limiting; check(std::abs(gainComputer(-12,p)+12)<0.001f,"limiting");
    p.mode=Mode::gating; check(gainComputer(-100,p)==-24,"gate floor");
    p.mode=Mode::downwardCompression; p.kneeDb=6;
    for(float level=-29; level<-19; level+=0.001f)
        check(std::abs(gainComputer(level+0.001f,p)-gainComputer(level,p))<0.002f,"continuous knee");
    for (double rate : {44100.,48000.,88200.,96000.,176400.,192000.}) {
        Dynamics d; d.prepare(rate); d.setParameters(p);
        for(int n=0;n<static_cast<int>(rate);++n) {
            float gain=d.process(1); check(std::isfinite(gain) && gain>0 && gain<=1,"stable envelope");
        }
        check(std::abs(d.gainDb()+18)<0.1f,"envelope settles");
        check(std::isfinite(d.process(std::numeric_limits<float>::infinity())),"invalid detector safety");
        d.reset(); check(d.gainDb()==0,"reset");
    }
    std::cout << "PASS: six curves, knee continuity, range bounds, envelope at six sample rates, reset and detector safety\n";
}
