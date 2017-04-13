#pragma once

#include "ofxiOS.h"
#include "ofxAruco.h"
#include "AudioSample.h"

class ofApp : public ofxiOSApp{
	
	public:
        void setup();
        void update();
        void draw();
        void exit();
    
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);
	
        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
        int width, height;
        ofTrueTypeFont font;
		
		ofVideoGrabber grabber;
		ofTexture tex;
		unsigned char * pix;
    
        ofBaseVideoDraws * video;
    
        ofxAruco aruco;
        bool useVideo;
        bool showMarkers;
        bool showBoard;
        bool showBoardImage;
        bool doesContain;
        bool play;
        ofImage board;
        ofImage marker;
    
        vector<aruco::Marker> markers;
        cv::Point2f markerCenter;
    
        bool addSound;
        bool doneRecording;
    
        void audioOut(float * output, int bufferSize, int nChannels);
        void audioIn(float * input, int bufferSize, int nChannels);
    
        //int		bufferSize;
        int		sampleRate;
        int	initialBufferSize;

        double outputs;
        float * buffer;
    
    
        int volume;
    
        vector<float> audio;
        int currentMarker;
    
    
        vector<AudioSample> samples;


};
