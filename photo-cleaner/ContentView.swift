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
    @State private var currentImage: UIImage?
    @State private var showDeleteAlert = false
    @State private var selectedImages = Set<PHAsset>()
    @State private var currentAsset: PHAsset?
    @State private var navigationHistory: [PHAsset] = []
    @State private var actionCount = 0
    @State private var canGoBack = false
    @State private var lastActionWasBack = false
    @State private var currentCyclePhotos = [PHAsset]()
    @State private var rotationAngle: Double = 0
    @State private var showAlbumSelection = true
    @State private var selectedAlbum: PHAssetCollection?
    
    var body: some View {
        if showAlbumSelection {
            AlbumSelectionView(
                selectedAlbum: $selectedAlbum,
                showAlbumSelection: $showAlbumSelection,
                resetSelection: resetSelection,
                fetchPhotos: fetchPhotos
            )
        } else {
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
                    HStack(spacing: 15) {
                        
                        // Album name button
                        Button(action: {
                            resetSelection()
                            showAlbumSelection = true
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .bold))
                                Text(albumDisplayName(selectedAlbum))
                                        .font(.system(size: 18, weight: .semibold))
                            }
                            
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Delete button
                        Button(action: { showDeleteAlert = true }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 55, height: 55)
                                
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 23, weight: .bold))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())

                        
                        // Back button
                        Button(action: {
                            goBack()
                            lastActionWasBack = true
                            canGoBack = false
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 55, height: 55)
                                
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.blue, .cyan]), startPoint: .top, endPoint: .bottom))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!canGoBack)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    
                    // Image Display
                    if let currentImage = currentImage {
                        Image(uiImage: currentImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            )
                            .frame(maxWidth: 325, maxHeight: .infinity)
                            .rotationEffect(.degrees(rotationAngle))
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
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(Color.gray.opacity(0.8), lineWidth: 6)
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "xmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundStyle(LinearGradient(gradient: Gradient(colors: [.orange, .red]), startPoint: .top, endPoint: .bottom))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tint(.white)
                        .disabled(currentAsset == nil || actionCount >= allPhotos.count)
                        .cornerRadius(100)
                        .frame(width: 100, height: 100)
                        
                        Button(action: {
                            skipImage()
                            lastActionWasBack = false
                            updateBackButtonState()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
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
    }
    
    // MARK: - Helper Functions
    
    private func resetSelection() {
        allPhotos.removeAll()
        selectedImages.removeAll()
        navigationHistory.removeAll()
        currentCyclePhotos.removeAll()
        currentAsset = nil
        currentImage = nil
        actionCount = 0
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
        guard let previousAsset = navigationHistory.last else { return }
        currentAsset = previousAsset
        loadImage(for: previousAsset)
        
        guard navigationHistory.count > 1 else { return }
        
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
        
        // Start new cycle
        let availablePhotos = allPhotos.filter { !selectedImages.contains($0) }
        if let randomAsset = availablePhotos.randomElement() {
            currentAsset = randomAsset
            navigationHistory = [randomAsset]
            currentCyclePhotos.append(randomAsset)
            loadImage(for: randomAsset)
        }
    }
   
    private func albumDisplayName(_ album: PHAssetCollection?) -> String {
        guard let album = album else { return "No Album" }
        return album.assetCollectionSubtype == .smartAlbumUserLibrary ?
               "All Photos" :
               (album.localizedTitle ?? "Untitled Album")
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
                self.rotationAngle = Double.random(in: -7...7)
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
                    // remove from all photos arrays
                    allPhotos.removeAll { assetsToDelete.contains($0) }
                    currentCyclePhotos.removeAll { assetsToDelete.contains($0) }
                    
                    // clean  history
                    navigationHistory.removeAll { assetsToDelete.contains($0) }
                    actionCount = min(actionCount, allPhotos.count)
                    // clear selection
                    selectedImages.removeAll()
                    // load next image or reset
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
            break
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        
                    } else {
                       
                    }
                }
            }
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }
    
    private func fetchPhotos() {
        guard let album = selectedAlbum else { return }
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result = PHAsset.fetchAssets(in: album, options: options)
        
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

struct AlbumSelectionView: View {
    @Binding var selectedAlbum: PHAssetCollection?
    @Binding var showAlbumSelection: Bool
    var resetSelection: () -> Void
    var fetchPhotos: () -> Void
    
    @State private var albums: [PHAssetCollection] = []
    @State private var showPermissionAlert = false
    
    var body: some View {
        VStack {
            Text("Photo Cleaner")
                   .font(.system(size: 45, weight: .bold))
                   .foregroundColor(.white)
                   .padding(.top, 25)
            
            Image("camera-icon")
                .resizable()
                .scaledToFit()
                .frame(width: 75, height: 75)
  
                   
            Text("Select Album")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 40)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(albums, id: \.localIdentifier) { album in
                        Button(action: {
                            selectedAlbum = album
                            showAlbumSelection = false
                            fetchPhotos()
                        }) {
                            HStack {
                                // icon
                                if album.assetCollectionSubtype == .smartAlbumUserLibrary {
                                    Image(systemName: "photo.stack")
                                        .foregroundColor(.white)
                                        .padding(.trailing, 5)
                                }
                               
                                
                                Text(album.assetCollectionSubtype == .smartAlbumUserLibrary ?
                                     "All Photos" :
                                     (album.localizedTitle ?? "Untitled Album"))
                                    .foregroundColor(.white)
                                    .font(.system(size: 18, weight: .medium))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Divider()
                            .background(Color.gray.opacity(0.3))
                    }
                }
                .background(Color(UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            Text("© Santi Hernandez, 2025")
                .font(.system(size: 15  , weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 5)
            
            Spacer()
        }
        .background(Color(UIColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1)))
        .onAppear {
            checkPhotoLibraryPermission()
            resetSelection()
        }
        .alert("Photo Library Access Denied", isPresented: $showPermissionAlert) {
            Button("Settings", role: .none) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable photo library access in Settings to use this app.")
        }
    }
    
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .authorized, .limited:
            fetchAlbums()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.fetchAlbums()
                    } else {
                        self.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            showPermissionAlert = true
        }
    }
    
    private func fetchAlbums() {
        let allPhotosCollection = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .smartAlbumUserLibrary,
            options: nil
        ).firstObject
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album,
            subtype: .any,
            options: nil
        )
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum,
            subtype: .any,
            options: nil
        )
        
        var allAlbums: [PHAssetCollection] = []
        
        if let allPhotos = allPhotosCollection {
                let assets = PHAsset.fetchAssets(in: allPhotos, options: nil)
                if assets.count > 0 {
                    allAlbums.append(allPhotos)
                }
            }
        
        userAlbums.enumerateObjects { collection, _, _ in
            // only show albums with photos
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            if assets.count > 0 {
                allAlbums.append(collection)
            }
        }
        
        smartAlbums.enumerateObjects { collection, _, _ in
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                if assets.count > 0 &&
                   collection.assetCollectionSubtype != .smartAlbumAllHidden &&
                   collection.assetCollectionSubtype != .smartAlbumUserLibrary {
                    allAlbums.append(collection)
                }
            }
        
        DispatchQueue.main.async {
                // sort "all photos", then alphabetical
                self.albums = allAlbums.sorted {
                    if $0.assetCollectionSubtype == .smartAlbumUserLibrary {
                        return true
                    } else if $1.assetCollectionSubtype == .smartAlbumUserLibrary {
                        return false
                    } else {
                        return ($0.localizedTitle ?? "") < ($1.localizedTitle ?? "")
                    }
                }
            }
    }
}
