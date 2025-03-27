//
//  ContentView.swift
//  photo-cleaner
//
//  Created by Santi Hernandez on 27/03/25.
//

import SwiftUI
import Photos

struct ContentView: View {
    @State private var allPhotos = [PHAsset]()
    @State private var unviewedPhotos = [PHAsset]()
    @State private var currentImage: UIImage?
    @State private var showPermissionAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedImages = Set<PHAsset>()
    @State private var currentAsset: PHAsset?
    @State private var navigationHistory: [PHAsset] = []
    @State private var actionCount = 0
    @State private var canGoBack = false
    @State private var lastActionWasBack = false
    @State private var currentCyclePhotos = [PHAsset]()

    var body: some View {
        NavigationStack {
            VStack {
                
                Text("Photo Cleaner")
                       .font(.system(size: 35, weight: .bold))
                       .foregroundColor(.white)
                       .padding(.top, 20)
                       .frame(maxWidth: .infinity, alignment: .center)
                
                Text("\(actionCount)/\(allPhotos.count)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                // Header (nav buttons)
                HStack(spacing: 120) {
                    // Delete button
                    Button(action: { showDeleteAlert = true }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(Color.gray.opacity(0.8), lineWidth: 2)
                                )
                                .frame(width: 55, height: 55) // Button size

                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 23, weight: .bold))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    HStack(spacing: 20) {
                        // Back button
                        Button(action: {
                            goBack()
                            lastActionWasBack = true
                            canGoBack = false
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(Color.gray.opacity(0.8), lineWidth: 2)
                                    )
                                    .frame(width: 55, height: 55)

                                Image(systemName: "arrow.left")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .top, endPoint: .bottom))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canGoBack)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                // Image Display
                if let currentImage = currentImage {
                    Image(uiImage: currentImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 40)
                } else {
                    VStack(spacing: 16) {
                        if allPhotos.isEmpty {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                            Text("No photos found")
                                .font(.title2)
                                .foregroundColor(.white)
                        } else {
                            ProgressView()
                            Text("Loading...")
                            .foregroundColor(.white)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }

                
                // Bottom Controls
                HStack(spacing: 125) {
                    Button(action: {
                        markForDeletion()
                        lastActionWasBack = false
                        updateBackButtonState()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(Color.gray.opacity(0.8), lineWidth: 6)
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30) // Reduced icon size
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .tint(.white)
                    .disabled(currentAsset == nil || actionCount >= allPhotos.count)
                    .cornerRadius(100) // Rounded corners to make it circular (adjust as needed)
                    .frame(width: 100, height: 100)
                    
                    Button(action: {
                        skipImage()
                        lastActionWasBack = false
                        updateBackButtonState()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 100)
                                        .stroke(Color.gray.opacity(0.8), lineWidth: 6)
                                )
                                .frame(width: 100, height: 100)

                            Image(systemName: "checkmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .font(.system(size: 40, weight: .bold))
                                .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.green, .mint]), startPoint: .top, endPoint: .bottom))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .tint(.white)
                    .disabled(currentAsset == nil || actionCount >= allPhotos.count)
                    .cornerRadius(100)
                    .frame(width: 100, height: 100)
                    
                }
                .padding(.bottom, 60)
            }
            .background(Color(UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)))
            .alert("Confirm Deletion", isPresented: $showDeleteAlert) {
                Button("Delete \(selectedImages.count) Photos", role: .destructive) {
                    deleteSelectedImages()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete \(selectedImages.count) photos from your library.")
            }
            .onAppear {
                checkPhotoLibraryPermission()
                updateBackButtonState()
            }
        }
    }

    
    // MARK: - Button Actions
    
    private func markForDeletion() {
        guard let currentAsset = currentAsset else { return }
        selectedImages.insert(currentAsset)
        actionCount += 1
        navigationHistory.append(currentAsset)
        currentCyclePhotos.append(currentAsset)
        advanceToNextImage()
    }
    
    private func skipImage() {
        guard let currentAsset = currentAsset else { return }
        actionCount += 1
        navigationHistory.append(currentAsset)
        currentCyclePhotos.append(currentAsset)
        advanceToNextImage()
    }
    
    private func goBack() {
        let previousAsset = navigationHistory.last!
        currentAsset = previousAsset
        loadImage(for: previousAsset)
        
        guard navigationHistory.count > 1 else { return }
        
        // Get current asset before removing from history
        let current = navigationHistory.last!
        
        // Remove current from history and cycle tracking
        navigationHistory.removeLast()
        currentCyclePhotos.removeAll { $0 == current }
        
        // If current was marked, unmark it
        if selectedImages.contains(current) {
            selectedImages.remove(current)
        }
        
        // Always decrement action count
        actionCount = max(0, actionCount - 1)
    }
    
    private func updateBackButtonState() {
        canGoBack = navigationHistory.count > 1 && !lastActionWasBack
    }
    
    // MARK: - Image Navigation
    
    private func advanceToNextImage() {
        guard !allPhotos.isEmpty else { return }
        
        // Check if we've made decisions about all photos
        if actionCount >= allPhotos.count {
            return
        }
        
        // Get random photo that hasn't been shown in this cycle
        let remainingPhotos = allPhotos.filter {
            !currentCyclePhotos.contains($0) && !selectedImages.contains($0)
        }
        
        if let randomAsset = remainingPhotos.randomElement() {
            currentAsset = randomAsset
            loadImage(for: randomAsset)
        } else {
            // If no remaining photos (shouldn't happen), just reset
            resetPhotoCycle()
        }
    }
    
    private func resetPhotoCycle() {
        actionCount = 0
        currentCyclePhotos.removeAll()
        lastActionWasBack = false
        
        // Start new cycle with a random image
        let availablePhotos = allPhotos.filter { !selectedImages.contains($0) }
        if let randomAsset = availablePhotos.randomElement() {
            currentAsset = randomAsset
            navigationHistory = [randomAsset]
            currentCyclePhotos.append(randomAsset)
            loadImage(for: randomAsset)
        }
    }
    
    // MARK: - Image Loading
    
    private func loadImage(for asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        
        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            DispatchQueue.main.async {
                self.currentImage = image
                self.updateBackButtonState()
            }
        }
    }
    
    // MARK: - Photo Management
    
    private func deleteSelectedImages() {
        let assetsToDelete = Array(selectedImages)
        
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSArray)
        }) { [self] success, error in
            DispatchQueue.main.async {
                if success {
                    // Remove from all photos arrays
                    allPhotos.removeAll { assetsToDelete.contains($0) }
                    currentCyclePhotos.removeAll { assetsToDelete.contains($0) }
                    
                    // Clean up history
                    navigationHistory.removeAll { assetsToDelete.contains($0) }
                    
                    // Adjust action count
                    actionCount = min(actionCount, allPhotos.count)
                    
                    // Clear selection
                    selectedImages.removeAll()
                    
                    // Load next image or reset if needed
                    if allPhotos.isEmpty {
                        currentImage = nil
                        currentAsset = nil
                    } else if actionCount >= allPhotos.count {
                        resetPhotoCycle()
                    } else {
                        advanceToNextImage()
                    }
                } else if let error = error {
                    print("Error deleting assets: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Photo Library Access
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            fetchPhotos()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        fetchPhotos()
                    } else {
                        showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }
    
    private func fetchPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        var assets = [PHAsset]()
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.allPhotos = assets
            self.actionCount = 0
            self.lastActionWasBack = false
            self.currentCyclePhotos.removeAll()
            
            if !assets.isEmpty {
                // Show first random image immediately (counter remains 0)
                if let randomAsset = assets.randomElement() {
                    self.currentAsset = randomAsset
                    self.navigationHistory = [randomAsset]
                    self.currentCyclePhotos.append(randomAsset)
                    self.loadImage(for: randomAsset)
                }
            }
            self.updateBackButtonState()
        }
    }
}
