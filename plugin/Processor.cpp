#include <juce_audio_utils/juce_audio_utils.h>
#include "openmb/Dynamics.h"
class OpenMBProcessor final : public juce::AudioProcessor {
public:
    OpenMBProcessor() : AudioProcessor(BusesProperties().withInput("Input", juce::AudioChannelSet::stereo(), true).withOutput("Output", juce::AudioChannelSet::stereo(), true)) {}
    const juce::String getName() const override { return "OpenMB"; }
    void prepareToPlay(double rate, int) override { dynamics.prepare(rate); }
    void releaseResources() override {}
    bool isBusesLayoutSupported(const BusesLayout& l) const override {
        return l.getMainInputChannelSet()==l.getMainOutputChannelSet() && (l.getMainInputChannelSet()==juce::AudioChannelSet::mono() || l.getMainInputChannelSet()==juce::AudioChannelSet::stereo());
    }
    void processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer&) override {
        juce::ScopedNoDenormals guard;
        for(int n=0;n<buffer.getNumSamples();++n) {
            float peak=0;
            for(int c=0;c<buffer.getNumChannels();++c) peak=std::max(peak,std::abs(buffer.getSample(c,n)));
            const float gain=dynamics.process(peak);
            for(int c=0;c<buffer.getNumChannels();++c) buffer.setSample(c,n,buffer.getSample(c,n)*gain);
        }
    }
    juce::AudioProcessorEditor* createEditor() override { return new juce::GenericAudioProcessorEditor(*this); }
    bool hasEditor() const override { return true; }
    bool acceptsMidi() const override { return false; }
    bool producesMidi() const override { return false; }
    double getTailLengthSeconds() const override { return 0; }
    int getNumPrograms() override { return 1; }
    int getCurrentProgram() override { return 0; }
    void setCurrentProgram(int) override {}
    const juce::String getProgramName(int) override { return "Default"; }
    void changeProgramName(int,const juce::String&) override {}
    void getStateInformation(juce::MemoryBlock& block) override { block.reset(); }
    void setStateInformation(const void*,int) override {}
private:
    openmb::Dynamics dynamics;
};
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter() { return new OpenMBProcessor; }
