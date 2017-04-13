#pragma once

#include "ofxiOS.h"

class AudioSample {
    
    public:
    
    int markerid;
    vector<float> audio;
    int playhead;
    
    void setup(int mid, vector<float> audio, int playhead){
        this->markerid = mid;
        this->audio = audio;
        this->playhead = playhead;
    }
    
};
