class ProctoringSystem { 
    constructor() { 
        this.examActive = true; 
        this.terminated = false;
        this.violations = []; 
        this.warningCount = 0; 
        this.MAX_WARNINGS = 5;

        // Anti-false-positive controls
        this.violationCooldownMs = 15000;
        this.lastViolationAt = {};
        this.examStartAt = Date.now();
        this.gracePeriodMs = 8000; // Reduced for faster activation

        // Natural behavior tolerance
        this.audioSampleMs = 500;
        this.noiseSpikeMinDurationMs = 2500;
        this.voiceVarianceMinDurationMs = 5000;
        this.headMovementMinDurationMs = 2500;
        this.noiseSpikeStartAt = null;
        this.voiceVarianceStartAt = null;
        this.headMovementStartAt = null;
        this.fastMouseStartAt = null;
        this.lastFastMouseFlagAt = 0;

        // ACCURACY-ENHANCED THRESHOLDS (fixed for better detection)
        this.NOISE_THRESHOLD = 37.6;
        this.MULTIPLE_VOICES_THRESHOLD = 400;
        this.EYE_OFF_SCREEN_THRESHOLD = 2500; // 2.5 seconds (more responsive)
        this.HEAD_MOVEMENT_THRESHOLD = 0.14;  // 14% movement (stricter)
        this.FACE_LOST_THRESHOLD = 400;       // 0.4 seconds (faster detection)
        this.MOUTH_MOVEMENT_THRESHOLD = 1.6;  // pixels
        this.LOOKING_DOWN_ANGLE = -12;        // degrees

        // Countdown state
        this.countdownActive = false;
        this.countdownValue = 3;
        this.countdownOverlay = null;

        // Behavioral thresholds
        this.FAST_MOUSE_SPEED_PX_PER_S = 6000;
        this.FAST_MOUSE_SUSTAIN_MS = 700;
        this.FAST_MOUSE_COOLDOWN_MS = 15000;

        // State tracking 
        this.lastEyeContact = Date.now(); 
        this.lastFaceDetected = Date.now(); 
        this.backgroundNoiseBaseline = 40; 
        this.calibrationComplete = false; 
        this.previousNosePosition = null; 
        this.previousMouthHeight = null; 

        // Media streams 
        this.audioStream = null; 
        this.videoStream = null; 
        this.videoElement = null;  // Store reference for screenshot

        // Face detection 
        this.faceapi = null; 
        this.detectionInterval = null; 
        this.audioMonitor = null;
        
        // Flag to track if camera is active
        this.cameraActive = false;
    } 

    async initialize(sharedStream) { 
        console.log('🔒 Initializing Professional Proctoring System...'); 
        
        // Show proctoring status with camera indicator
        this.showStatusBanner(); 

        // Load face detection library 
        await this.loadFaceApi(); 

        // ========== FIX 1: FORCE CAMERA ACTIVATION ==========
        // Always request fresh camera stream to ensure it's working
        try {
            console.log('📷 Requesting camera access...');
            
            // If sharedStream is provided but not active, request fresh one
            let streamToUse = sharedStream;
            if (!streamToUse || !streamToUse.active || streamToUse.getVideoTracks().length === 0) {
                streamToUse = await navigator.mediaDevices.getUserMedia({
                    video: {
                        width: { ideal: 640 },
                        height: { ideal: 480 },
                        frameRate: { ideal: 24 }
                    },
                    audio: {
                        echoCancellation: false,
                        noiseSuppression: false,
                        autoGainControl: true
                    }
                });
                console.log('✅ Fresh camera stream acquired');
            }
            
            this.audioStream = streamToUse;
            this.videoStream = streamToUse;
            this.cameraActive = true;
            
            // ========== FIX 2: SHOW CAMERA PREVIEW ==========
            this.showCameraPreview();
            
        } catch (err) {
            console.error('❌ Camera access failed:', err);
            this.logViolation('CRITICAL', 'Camera unavailable - cannot proceed with proctoring');
            this.updateCameraStatus('❌ Camera access denied - please allow camera permissions');
            return;
        }

        // Initialize all monitoring systems 
        await this.initAudioMonitoring(); 
        await this.initVideoMonitoring(); 
        this.initEnvironmentLockdown(); 
        this.initBehavioralMonitoring(); 
        this.startMonitoringLoop(); 

        console.log('✅ Proctoring System Active - Camera ON'); 
        this.logToServer('INFO', 'Proctoring started successfully with camera'); 
        this.updateCameraStatus('✅ Camera active - Face monitoring engaged');
    }
    
    // ========== NEW: Show camera preview for user transparency ==========
    showCameraPreview() {
        // Create camera preview element if not exists
        let previewContainer = document.getElementById('camera-preview-container');
        if (!previewContainer) {
            previewContainer = document.createElement('div');
            previewContainer.id = 'camera-preview-container';
            previewContainer.style.cssText = 'position: fixed; bottom: 80px; right: 20px; width: 160px; height: 120px; background: #000; border-radius: 12px; overflow: hidden; z-index: 9998; border: 2px solid #10b981; box-shadow: 0 4px 12px rgba(0,0,0,0.3); cursor: pointer;';
            previewContainer.title = "Your camera feed - click to expand";
            document.body.appendChild(previewContainer);
            
            // Add expand on click
            previewContainer.addEventListener('click', () => {
                if (previewContainer.style.width === '320px') {
                    previewContainer.style.width = '160px';
                    previewContainer.style.height = '120px';
                } else {
                    previewContainer.style.width = '320px';
                    previewContainer.style.height = '240px';
                }
            });
        }
        
        // Create or get video element for preview
        let previewVideo = document.getElementById('camera-preview-video');
        if (!previewVideo) {
            previewVideo = document.createElement('video');
            previewVideo.id = 'camera-preview-video';
            previewVideo.style.cssText = 'width: 100%; height: 100%; object-fit: cover; transform: scaleX(-1);';
            previewVideo.autoplay = true;
            previewVideo.muted = true;
            previewVideo.playsInline = true;
            previewContainer.innerHTML = '';
            previewContainer.appendChild(previewVideo);
        }
        
        if (this.videoStream) {
            previewVideo.srcObject = this.videoStream;
            previewVideo.play().catch(e => console.warn);
        }
    }
    
    updateCameraStatus(message) {
        let statusDiv = document.getElementById('camera-status-text');
        if (!statusDiv) {
            const banner = document.getElementById('proctoring-banner');
            if (banner) {
                statusDiv = document.createElement('span');
                statusDiv.id = 'camera-status-text';
                statusDiv.style.cssText = 'font-size: 10px; background: #1e3a5f; padding: 2px 8px; border-radius: 12px; margin-left: 8px;';
                banner.appendChild(statusDiv);
            }
        }
        if (statusDiv) statusDiv.textContent = message;
    }

    showStatusBanner() { 
        if (document.getElementById('proctoring-banner')) return;
        
        const banner = document.createElement('div'); 
        banner.id = 'proctoring-banner'; 
        banner.style.cssText = 'position: fixed; bottom: 12px; left: 50%; transform: translateX(-50%); background: #09294d; color: white; padding: 8px 15px; border-radius: 20px; font-size: 12px; z-index: 9999; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.2);'; 
        banner.innerHTML = '<span class="live-indicator" style="width: 10px; height: 10px; background: #10b981; border-radius: 50%; animation: pulse 2s infinite;"></span>' + 
            '<span>🎥 Proctoring Active</span>' + 
            '<span id="violation-counter" style="background: #ef4444; padding: 2px 6px; border-radius: 10px; font-size: 10px;">0</span>' +
            '<span id="camera-badge" style="background: #22c55e; padding: 2px 6px; border-radius: 10px; font-size: 10px;">📷 ON</span>'; 
        document.body.appendChild(banner); 

        const style = document.createElement('style'); 
        style.textContent = ` 
            @keyframes pulse { 
                0% { opacity: 1; transform: scale(1); } 
                50% { opacity: 0.5; transform: scale(1.2); } 
                100% { opacity: 1; transform: scale(1); } 
            } 
        `; 
        document.head.appendChild(style); 
    } 

    async loadFaceApi() { 
        return new Promise((resolve) => { 
            if (window.faceapi) { 
                this.faceapi = window.faceapi; 
                resolve(); 
                return; 
            } 

            const script = document.createElement('script'); 
            script.src = 'https://cdn.jsdelivr.net/npm/face-api.js@0.22.2/dist/face-api.min.js'; 
            script.onload = async () => { 
                try { 
                    // Use reliable CDN for models
                    const MODEL_URL = 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights';
                    await faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL); 
                    await faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL); 
                    await faceapi.nets.faceExpressionNet.loadFromUri(MODEL_URL); 
                    this.faceapi = faceapi; 
                    console.log('✅ Face detection models loaded'); 
                    resolve(); 
                } catch (err) { 
                    console.warn('Face-api model load issue:', err); 
                    resolve(); 
                } 
            }; 
            script.onerror = () => { 
                console.warn('Face-api script failed'); 
                resolve(); 
            }; 
            document.head.appendChild(script); 
        }); 
    } 

    async initVideoMonitoring() { 
        try { 
            if (!this.videoStream || this.videoStream.getVideoTracks().length === 0) {
                throw new Error('No video stream available');
            }

            // Create visible video element for processing (not hidden anymore for better detection)
            let videoElement = document.getElementById('proctorVideo'); 
            if (!videoElement) { 
                videoElement = document.createElement('video'); 
                videoElement.id = 'proctorVideo'; 
                videoElement.style.cssText = 'position: fixed; top: -9999px; left: -9999px; width: 1px; height: 1px; opacity: 0;'; // hidden but still processes
                document.body.appendChild(videoElement); 
            } 

            videoElement.srcObject = this.videoStream; 
            videoElement.muted = true; 
            videoElement.setAttribute('playsinline', '');
            
            // Wait for video to be ready
            await new Promise((resolve) => {
                videoElement.onloadedmetadata = () => {
                    videoElement.play().then(resolve).catch(resolve);
                };
                setTimeout(resolve, 2000);
            });
            
            this.videoElement = videoElement;

            // Create canvas for processing 
            this.videoCanvas = document.createElement('canvas'); 
            this.videoContext = this.videoCanvas.getContext('2d'); 

            // Start face detection with faster interval for accuracy
            this.startFaceDetection(videoElement); 
            
            this.updateCameraStatus('✅ Camera ready - tracking face');

        } catch (err) { 
            console.error('Video monitoring error:', err);
            this.logViolation('CRITICAL', 'Camera monitoring unavailable - ' + err.message); 
            this.updateCameraStatus('❌ Camera error - please refresh');
        } 
    } 

    async startFaceDetection(videoElement) { 
        // Faster detection for accuracy (300ms instead of 500ms)
        this.detectionInterval = setInterval(async () => { 
            if (!this.examActive || !videoElement || !videoElement.videoWidth) return; 

            try { 
                if (this.faceapi && videoElement.videoWidth > 0) { 
                    const detections = await this.faceapi 
                        .detectAllFaces(videoElement, new this.faceapi.TinyFaceDetectorOptions()) 
                        .withFaceLandmarks() 
                        .withFaceExpressions(); 
                    this.processFaceDetections(detections); 
                    
                    // Update camera status based on detection
                    if (detections.length > 0 && !this.cameraStatusUpdated) {
                        this.updateCameraStatus('✅ Face detected - monitoring active');
                        this.cameraStatusUpdated = true;
                    }
                } 
            } catch (err) { 
                // Silent fail 
            } 
        }, 300); // Faster detection = more accurate
    } 

    processFaceDetections(detections) { 
        if (!detections || detections.length === 0) { 
            const timeLost = Date.now() - this.lastFaceDetected;
            if (timeLost > this.FACE_LOST_THRESHOLD) { 
                this.updateCameraStatus(`⚠️ No face detected for ${Math.floor(timeLost/1000)}s`);
                this.handleCountdown(timeLost, 'FACE NOT DETECTED');
            } 
            return; 
        } 

        this.lastFaceDetected = Date.now(); 
        this.hideCountdown();
        this.updateCameraStatus('✅ Face locked - monitoring');

        // Multiple faces detection 
        if (detections.length > 1) { 
            this.logViolation('VISUAL', 'Multiple people detected in camera frame'); 
        } 

        const face = detections[0]; 

        // GAZE DETECTION (improved accuracy)
        const lookingAtScreen = this.detectGazeDirection(face.landmarks); 
        if (!lookingAtScreen) { 
            if (Date.now() - this.lastEyeContact > this.EYE_OFF_SCREEN_THRESHOLD) { 
                this.logViolation('VISUAL', 'Looking away from screen'); 
                this.updateCameraStatus('⚠️ Looking away from screen');
            } 
        } else { 
            this.lastEyeContact = Date.now(); 
        } 

        // Head movement detection
        const headMovement = this.detectHeadMovement(face.landmarks); 
        if (headMovement > this.HEAD_MOVEMENT_THRESHOLD) {
            const now = Date.now();
            if (!this.headMovementStartAt) this.headMovementStartAt = now;
            if (now - this.headMovementStartAt >= this.headMovementMinDurationMs) {
                this.logViolation('VISUAL', 'Excessive head movement detected');
                this.headMovementStartAt = now;
            }
        } else {
            this.headMovementStartAt = null;
        }

        // Face obstruction
        if (this.detectFaceObstruction(face.landmarks)) { 
            this.logViolation('VISUAL', 'Face partially obscured'); 
        } 

        // Looking down detection (phone in lap)
        const headPose = this.estimateHeadPose(face.landmarks); 
        if (headPose.pitch < this.LOOKING_DOWN_ANGLE) { 
            this.logViolation('VISUAL', 'Looking down - possible phone use'); 
        } 

        // Lip movement
        if (this.detectLipMovement(face.landmarks, face.expressions)) { 
            this.logViolation('BEHAVIOR', 'Lip movement detected - possible verbal communication'); 
        } 
    } 

    // ... (keep all your existing detection methods: detectGazeDirection, eyeAspectRatio, 
    // detectHeadMovement, detectFaceObstruction, estimateHeadPose, detectLipMovement, 
    // processFallbackDetection, initAudioMonitoring, calibrateNoise, analyzeAudio, 
    // calculateVariance, initEnvironmentLockdown, enforceFullscreen, 
    // initBehavioralMonitoring, startMonitoringLoop, shouldCountViolation, 
    // isInGracePeriod, logViolation, captureEvidence, showWarning, 
    // autoSubmitForCheating, handleCountdown, showCountdown, updateCountdown, 
    // hideCountdown, sendViolationToServer, logToServer, stop)
    
    // NOTE: Keep all the existing methods above exactly as they are in your original code.
    // Only the initialize() and video-related methods have been enhanced above.
}

// ========== FIXED AUTO-START WITH FORCED CAMERA ==========
document.addEventListener('DOMContentLoaded', function () {
    (async function() {
        try {
            // Check if exam form exists
            var examForm = document.getElementById('myform');
            if (!examForm) return;
            
            // Don't re-initialize if already running
            if (window.proctor && window.proctor.examActive) return;
            
            console.log('🚀 Auto-starting proctoring with camera...');
            
            // Force camera access immediately
            let stream = null;
            try {
                stream = await navigator.mediaDevices.getUserMedia({ 
                    video: { 
                        width: { ideal: 640 },
                        height: { ideal: 480 }
                    }, 
                    audio: true 
                });
                console.log('✅ Camera and microphone access granted');
            } catch (err) {
                console.error('❌ Could not access camera:', err);
                // Show user-friendly message
                const warningDiv = document.createElement('div');
                warningDiv.style.cssText = 'position: fixed; top: 20px; left: 50%; transform: translateX(-50%); background: #dc2626; color: white; padding: 15px 25px; border-radius: 8px; z-index: 100000; font-weight: bold;';
                warningDiv.innerHTML = '⚠️ Camera access required for proctoring. Please allow camera permissions and refresh.';
                document.body.appendChild(warningDiv);
                setTimeout(() => warningDiv.remove(), 5000);
                return;
            }
            
            var p = new ProctoringSystem();
            window.proctor = p;
            await p.initialize(stream);
            
        } catch (err) {
            console.error('Auto-start proctoring failed:', err);
        }
   })();
});

    // Begin button proctoring hook moved to the confirmation modal handler above.
