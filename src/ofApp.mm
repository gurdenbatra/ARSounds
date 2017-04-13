#include "ofApp.h"
#include "ofxCv.h"
#include "ofBitmapFont.h"

using namespace cv;
using namespace ofxCv;

void drawMarker(float size, const ofColor & color){
    
    ofPushMatrix();
    ofFill();
    ofSetColor(color);
    ofDrawSphere(size/4);
    ofPopMatrix();
    
}

void drawPlay(float size, const ofColor & color){
    
    ofPushMatrix();
    ofTranslate(size*1.5,0,size*0.5);
    ofFill();
    ofSetColor(color);
    ofDrawCone(size/3, size/3);
    ofPopMatrix();
    
}



//--------------------------------------------------------------
void ofApp::setup(){
    width = ofGetWindowWidth();
    height = ofGetWindowHeight();
    font.load("Avenir.ttc", 12);

    string boardName = "boardConfiguration.yml";
    ofSetVerticalSync(true);

	ofSetOrientation(OFXIOS_ORIENTATION_PORTRAIT);

	grabber.setup(640, 480, OF_PIXELS_BGRA);
    
    video = &grabber;
    aruco.setup("intrinsics.int", video->getWidth(), video->getHeight(), boardName);
    aruco.getBoardImage(board.getPixels());
    board.update();
    
    showMarkers = true;
    showBoard = false;
    showBoardImage = false;
    addSound = false;
    doneRecording = false;
    doesContain = false;
    play = false;
    first = false;
    
    ofEnableAlphaBlending();
    
    
    sampleRate 	= 44100;
    initialBufferSize = 512;
    
    buffer = new float[initialBufferSize];
    memset(buffer, 0, initialBufferSize * sizeof(float));

   
    ofSoundStreamSetup(2,1,this, sampleRate, initialBufferSize, 1);
    
    volume = 0;
    

    
}

//--------------------------------------------------------------
void ofApp::update(){

    
    video->update();
    if(video->isFrameNew()){
        aruco.detectBoards(video->getPixels());
    }
    
    markerCenter.x = width + 10;
    markerCenter.y = height + 10;
    doesContain = false;
    
    
}

//--------------------------------------------------------------
void ofApp::draw(){	
	
    ofSetColor(255);
    video->draw(0,0);
    
    
    if(!play){
        font.drawString("Play: Off", width-95, 25);
        ofSetColor(0, 0, 255);
        ofNoFill();
        ofDrawRectRounded(width-100, 10, 75, 20, 5);
    }
    else{
        
        ofSetColor(0, 0, 255);
        ofFill();
        ofDrawRectRounded(width-100, 10, 75, 20, 5);
        ofSetColor(255);
        font.drawString("Play: On", width-95, 25);
    }
    
    
    
    
    if(showMarkers){
        
        if(aruco.getNumMarkers() == 0){
            volume = 0;
            addSound = false;
            first = false;
            audio.clear();
        }
        
        else if(aruco.getNumMarkers() > 1){
            volume = 0;
        }
        
        else{
            
            for(int i=0;i<aruco.getNumMarkers();i++){
                aruco.begin(i);
                markers = aruco.getMarkers();
                markerCenter = markers[i].getCenter();
                markerArea = markers[i].getArea();
                currentMarker = markers[i].idMarker;
                
                if(samples.size() == 0){
                    //first ever marker detected
                    first = true;
                    drawMarker(0.1,ofColor(255,0,0));
                    
                }
                
                else {
                    first = false;
                    for(int j=0;j<samples.size();j++){
                        if(samples[j].markerid == currentMarker){
                            doesContain = true;
                            break;
                        }
                    }
                    
                    if(doesContain){
                        //recording exists
                        if(play && !addSound){
                            volume = 1;
                            
                            if(markerArea <= 1800){
                                volMultiplier = 0.1;
                                
                            }
                            else if(markerArea> 1800 && markerArea <= 5000){
                                volMultiplier = 0.2;
                                
                            }
                            else if(markerArea> 5000 && markerArea <= 10000){
                                volMultiplier = 0.4;
                                
                            }
                            else if(markerArea> 10000 && markerArea <= 20000){
                                volMultiplier = 0.6;
                                
                            }
                            else if(markerArea> 20000){
                                volMultiplier = 0.9;
                                
                            }
                            
                            
                        }
                        else{
                            volume = 0;
                        }
                        drawPlay(0.1,ofColor(0,0,255));
                        
                    }
                    drawMarker(0.1,ofColor(255,0,0));
                }
                
                aruco.end();
            }
            
        }
        
    }
    
    
    if(addSound){
        ofSetColor(255,0,0);
        
        font.drawString("Now Recording, 2 finger tap to stop", 10, height-20);
    }
    
    if(first){
        ofSetColor(200,0,0);
        font.drawString("Your first marker! Tap record to leave sound", 10, height-20);
    }

}

//--------------------------------------------------------------
void ofApp::exit(){
    
}




void ofApp::audioIn(float * input, int bufferSize, int nChannels){
    if(addSound){
        if(initialBufferSize < bufferSize){
            ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
        }
    
        int minBufferSize = MIN(initialBufferSize, bufferSize);
        

        for(int i=0; i<minBufferSize; i++) {
            buffer[i] = input[i];
            audio.push_back(buffer[i]);
            
        }
        
        AudioSample current;
        current.setup(currentMarker, audio, 0);
        samples.push_back(current);
        doneRecording = true;
        
    }
    
    
}

void ofApp::audioOut(float * output, int bufferSize, int nChannels) {
    
    
    if( initialBufferSize < bufferSize ){
        ofLog(OF_LOG_ERROR, "your buffer size was set to %i - but the stream needs a buffer size of %i", initialBufferSize, bufferSize);
        return;
    }
    
    

    for(int j=0; j<samples.size();j++){
        if(currentMarker == samples[j].markerid){
            for (int i = 0; i < bufferSize; i++){
                    
                float currentSample;
                if(samples[j].audio.size() > 0){
                    currentSample = samples[j].audio[samples[j].playhead];
                }
                    
                output[i*nChannels] =currentSample*volume*volMultiplier;
                output[i*nChannels + 1] =currentSample*volume*volMultiplier;
                samples[j].playhead++;
                    
                if(samples[j].playhead >= samples[j].audio.size()){
                    samples[j].playhead = 0;
                }
                    
            }
                
        }
    }

    
    
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    if(touch.numTouches == 1){
        if(ofDist(touch.x, touch.y, markerCenter.x, markerCenter.y) < 100){
            audio.clear();
            volume = 0;
            addSound = true;
            
        }
        
        if(ofDist(touch.x, touch.y, width-100, 10) < 75){
            play = !play;
        }
        
    }
    else if(touch.numTouches == 2){
        addSound = false;
        audio.clear();
    }
}



//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){


}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){
    

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    
}


