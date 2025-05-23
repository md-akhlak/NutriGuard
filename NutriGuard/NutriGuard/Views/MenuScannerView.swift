import SwiftUI
import VisionKit
import Vision
import PhotosUI

struct MenuScannerView: View {
    @StateObject private var viewModel: MenuScannerViewModel
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @Environment(\.colorScheme) var colorScheme
    
    init(userProfile: UserProfile) {
        _viewModel = StateObject(wrappedValue: MenuScannerViewModel(userProfile: userProfile))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.analyzedItems.isEmpty {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [
                            colorScheme == .dark ? Color.black : Color.white,
                            colorScheme == .dark ? Color.blue.opacity(0.1) : Color.blue.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        } else {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 80))
                                .foregroundStyle(.linearGradient(
                                    colors: [.blue, .blue.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                .padding()
                                .background(
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 150, height: 150)
                                )
                        }
                        
                        VStack(spacing: 12) {
                            Text(viewModel.isScanning ? "Processing Menu..." : "Ready to Scan")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Choose a menu image to get personalized recommendations")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 40)
                        }
                        
                        if viewModel.isScanning {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                        } else {
                            VStack(spacing: 16) {
                                // Camera Button
                                Button(action: {
                                    // Handle camera action
                                }) {
                                    HStack {
                                        Image(systemName: "camera.fill")
                                        Text("Take Photo")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                // Gallery Button
                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    HStack {
                                        Image(systemName: "photo.fill")
                                        Text("Choose from Gallery")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.secondary.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.vertical, 40)
                }
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if let selectedImage = viewModel.selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 200)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                        }
                        
                        VStack(spacing: 16) {
                            ForEach(viewModel.analyzedItems, id: \.name) { item in
                                MenuItemAnalysisCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                
                Button(action: viewModel.clearScan) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Scan New Menu")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Menu Scanner")
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await viewModel.processImage(image)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct MenuItemAnalysisCard: View {
    let item: (name: String, safety: FoodSafetyLevel)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    
                    if item.safety != .safe {
                        Text("Contains restricted ingredients")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                SafetyBadge(safety: item.safety)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SafetyBadge: View {
    let safety: FoodSafetyLevel
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(safetyColor)
                .frame(width: 12, height: 12)
            
            Text(safetyText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(safetyColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(safetyColor.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var safetyColor: Color {
        switch safety {
        case .safe:
            return .green
        case .caution:
            return .yellow
        case .unsafe:
            return .red
        }
    }
    
    private var safetyText: String {
        switch safety {
        case .safe:
            return "Safe"
        case .caution:
            return "Caution"
        case .unsafe:
            return "Unsafe"
        }
    }
}

@available(iOS 16.0, *)
struct DataScannerViewController: UIViewControllerRepresentable {
    let completionHandler: (String) -> Void
    
    func makeUIViewController(context: Context) -> DataScannerVC {
        let vc = DataScannerVC(completionHandler: completionHandler)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: DataScannerVC, context: Context) {}
}

@available(iOS 16.0, *)
class DataScannerVC: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let completionHandler: (String) -> Void
    private var captureSession: AVCaptureSession?
    private var requests = [VNRequest]()
    
    init(completionHandler: @escaping (String) -> Void) {
        self.completionHandler = completionHandler
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupVision()
        startScanning()
    }
    
    private func setupVision() {
        let textRequest = VNRecognizeTextRequest { [weak self] request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation],
                  let firstObservation = observations.first,
                  let firstCandidate = firstObservation.topCandidates(1).first else {
                return
            }
            
            DispatchQueue.main.async {
                self?.completionHandler(firstCandidate.string)
            }
        }
        textRequest.recognitionLevel = .accurate
        self.requests = [textRequest]
    }
    
    private func startScanning() {
        let session = AVCaptureSession()
        self.captureSession = session
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        
        session.beginConfiguration()
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? imageRequestHandler.perform(self.requests)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
} 