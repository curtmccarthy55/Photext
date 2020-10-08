//
//  PHNSettingsViewController.swift
//  Unroll2
//
//  Created by Curtis McCarthy on 8/4/19.
//  Copyright © 2019 Bluewraith. All rights reserved.
//

import UIKit
import SafariServices
import MessageUI
import StoreKit
import Photos

class PHNSettingsViewController: UITableViewController, PHNPhotoGrabCompletionDelegate, SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate {
    //MARK: - Properties
    
    /* --- Outlets --- */
    
    @IBOutlet weak var btnDone: UIBarButtonItem!
    /// Slider to adjust note opacity.
    @IBOutlet weak var sldOpacity: UISlider!
    /// View to demo the currently set note opacity.
    @IBOutlet weak var noteView: UIView!
    /// Label to display current note opacity level.
    @IBOutlet weak var lblOpacity: UITextField!
    /// Image view behind the note opacity view.
    @IBOutlet weak var sampleImage: UIImageView!
    /// ImageView to display thumbnail of QuickNote's current background image.
    @IBOutlet weak var qnThumbnail: UIImageView!
    /// IBOutlet collection of color buttons.
    @IBOutlet var colorButtons: [UIButton]!
    /// Easy-accessor for whiteButton, which needs additional handling when highlighting for selection/deselection.
    @IBOutlet weak var whiteButton: UIButton!
    
    /* --- Variables --- */
    
    //    var fetchResult: PHFetchResult?
    var imageManager: PHCachingImageManager?
    /// Arrangement of color options for the color buttons.
    var colorOptions: [PHNThemeColor] = [ .blue, .red, .black, .purple, .orange, .yellow, .green, .white ]
    /// Holds newly selected theme color until user selects Done and it's assigned as the user's preferred theme color.
    var temporaryColorTheme: PHNThemeColor?
    /// Flag indicating if a new theme color has been selected.
    var colorChanged = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        switch PHNUser.current.preferredThemeColor.colorBrightness() {
        case .light:
            return .default
        case .dark:
            return .lightContent
        }
    }
    
    // MARK: - Scene Set Up
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* --- Prepare navigationController. --- */
        updateNavigationBars()
        
        // Prepare background.
        let backgroundView = UIImageView(image: UIImage(named: "AlbumListBackground"))
        backgroundView.contentMode = .scaleAspectFill
        tableView.backgroundView = backgroundView

        // Disable Done button until changes are made.
        btnDone.isEnabled = false
        
        // Update preferred colors.
//        appearanceForPreferredColor()
        
        /* --- Set current opacity. --- */
        var opacity: CGFloat
        if let currentOpacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber {
            opacity = CGFloat(exactly: currentOpacity) ?? 0.75
        } else {
            opacity = 0.75
        }
        noteView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: opacity)
        lblOpacity.text = "\(roundf(Float(opacity * 100)))%"
        sldOpacity.setValue(Float(opacity * 100.0), animated: false)
        
        /* --- Highlight the button for the currently selected color. --- */
        whiteButton.layer.borderWidth = 1.0
        whiteButton.layer.borderColor = UIColor.black.cgColor
        if let buttonIndex = colorOptions.firstIndex(of: PHNUser.current.preferredThemeColor) {
            let button = colorButtons[buttonIndex]
            button.layer.borderWidth = 2.0
            button.layer.borderColor = UIColor.green.cgColor
        }
        
        ignoreAccessibilityColorInvert()
    }
    
    /// Sets `accessibilityIgnoresInvertColors` on appropriate views.
    func ignoreAccessibilityColorInvert() {
        for btn in colorButtons {
            btn.accessibilityIgnoresInvertColors = true
        }
        qnThumbnail.accessibilityIgnoresInvertColors = true
        noteView.accessibilityIgnoresInvertColors = true
        sampleImage.accessibilityIgnoresInvertColors = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        appearanceForPreferredColor()
        displayQuickNoteThumbnail()
        setNeedsStatusBarAppearanceUpdate()
    }
    
    func updateNavigationBars() {
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.toolbar.isHidden = false
        navigationController?.toolbar.isTranslucent = true
    }
    
    /// Updates navigation bar style, tint, and color based on user selected theme color.
    func appearanceForPreferredColor() {
        var themeColor: PHNThemeColor
        // If a new theme color has been selected, use that. Otherwise, use User color.
        if let tempTheme = temporaryColorTheme {
            themeColor = tempTheme
        } else {
            themeColor = PHNUser.current.preferredThemeColor
        }
        let userColor = themeColor.colorForTheme()
        navigationController?.navigationBar.barTintColor = userColor
        navigationController?.toolbar.barTintColor = userColor
        
        let colorBrightness = themeColor.colorBrightness()
        switch colorBrightness {
        case .light:
            // Light theme will require dark text and icons.
            navigationController?.navigationBar.tintColor = .black
            navigationController?.toolbar.tintColor = .black
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black]
        case .dark:
            // Dark themes will require light text and icons.
            navigationController?.navigationBar.tintColor = .white
            navigationController?.toolbar.tintColor = .white
            navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
            navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        }
        

        
//        let gradientMask = CAGradientLayer()
//        gradientMask.frame = navigationController?.navigationBar.frame ?? CGRect.zero
//        gradientMask.colors = [UIColor.darkGray.cgColor, UIColor.clear.cgColor]
//        navigationController?.navigationBar.layer.insertSublayer(gradientMask, at: 1)
    }
    
    /// Displays a thumbnail for the current QuickNote background.
    func displayQuickNoteThumbnail() {
        // Get the QuickNote album.
        let album = PHNAlbumManager.sharedInstance.userQuickNote
        
        // Use the added photo, if one exists, otherwise use a default image.
        if album.albumPhotos.count > 0 { // User selected photo exists.
            let qnImage = album.albumPhotos[0]
            
            PHNServices.sharedInstance.fetchThumbnailForImage(photoNote: qnImage) { [weak self] (thumbnail) in
                guard let weakSelf = self else {
                    return
                }
                guard let image = thumbnail else {
                    weakSelf.qnThumbnail.image = UIImage(named: "InAppIcon")
                    return
                }
                // If thumbnail not properly captured during import, create one.
                if image.size.width == 0 {
                    qnImage.thumbnailNeedsRedraw = true
                    PHNServices.sharedInstance.removeImageFromCache(qnImage)
                } else {
                    weakSelf.qnThumbnail.image = image
                }
            }
        } else { // No user photo exists, use default image.
            qnThumbnail.image = UIImage(named: "InAppIcon")
        }
    }
    
    //MARK: - IBActions
    
    @IBAction func doneAction(_ sender: Any?) {
        let opacity = UserDefaults.standard.value(forKey: "noteOpacity") as? NSNumber
        if opacity?.floatValue != sldOpacity.value {
            let newOpac = NSNumber(value: sldOpacity.value / 100)
            UserDefaults.standard.set(newOpac, forKey: "noteOpacity") // TODO make Int?
        }
        
        // Update user color to selected theme color.
        if colorChanged,
            let themeColor = temporaryColorTheme {
            PHNUser.current.preferredThemeColor = themeColor
        }
        
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelAction(_ sender: Any?) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    /// Color buttons action.
    @IBAction func selectedColor(_ sender: UIButton) {
        // Changes made.
        colorChanged = true
        btnDone.isEnabled = true
        
        // Change the border for the previously selected and newly selected buttons.
        let currentColor = PHNUser.current.preferredThemeColor
        if let currentColorIndex = colorOptions.firstIndex(of: currentColor) {
            // Until custom color implemented, check that the current color index does not exceed the last index of the colorButtons collection
            if currentColorIndex <= colorButtons.count - 1 {
                let currentButton = colorButtons[currentColorIndex]
                if (currentColor == .white) ||
                    (currentColor == .custom(red: 1.0, green: 1.0, blue: 1.0)) {
                    // White button needs black border to stand out from white background.
                    currentButton.layer.borderWidth = 1.0
                    currentButton.layer.borderColor = UIColor.black.cgColor
                } else {
                    // Non-white button doesn't need a border to stand out from white background.
                    currentButton.layer.borderWidth = 0.0
                }
            }
        }
            
        // Update border on newly selected color.
        sender.layer.borderWidth = 2.0
        sender.layer.borderColor = UIColor.green.cgColor
        
        // Update user color.
        let selectedButtonInt = sender.tag
        let selectedTheme = colorOptions[selectedButtonInt]
        temporaryColorTheme = selectedTheme
        
        // Update appearance for new user preferred theme color.
        appearanceForPreferredColor()
    }
    
    //MARK: - Opacity Slider
    
    @IBAction func slider(_ sender: UISlider) {
        let oVal = sender.value
        lblOpacity.text = "\(roundf(oVal))%"
        noteView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: (CGFloat(oVal / 100)))
        lblOpacity.alpha = 1.0
        
        if !btnDone.isEnabled {
            btnDone.isEnabled = true
        }
    }
    
    //MARK: - PHNPhotoGrabber Methods and Delegate
    
    /// Modally presents the image import view controller.
    func presentPhotoGrabViewController() {
        let sbName = "Main"
        let storyboard = UIStoryboard(name: sbName, bundle: nil)
        let navigationVC = storyboard.instantiateViewController(withIdentifier: "NavPhotoGrabViewController") as! UINavigationController
        navigationVC.modalPresentationStyle = .fullScreen
        let vc = navigationVC.topViewController as! PHNImportAlbumsViewController
        vc.delegate = self
        vc.singleSelection = true
        
        present(navigationVC, animated: true, completion: nil)
    }
    
    func photoGrabSceneDidCancel() {
        dismiss(animated: true, completion: nil)
        let indexPath = IndexPath(row: 0, section: 1)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    /// Iterate through array of selected photos, convert them to Photo Note instances, and add to the current album.
    func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
        var newImages = [PhotoNote]()
        // Pull the images, image creation dates, and image locations from each PHAsset in the received array.
        let fileSerializer = PHNFileSerializer()
        
        if imageManager != nil {
            imageManager = PHCachingImageManager()
        }
        
        let imageLoadGroup = DispatchGroup()
        for asset in photos {
            let assetImage = PhotoNote()
            
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.version = .current
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager!.requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    if let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeObject(imageData, toRelativePath: assetImage.fileName)
                        //                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            
            imageLoadGroup.enter()
            autoreleasepool(invoking: {
                imageManager!.requestImage(for: asset,
                                    targetSize: CGSize(width: 120.0, height: 120.0),
                                   contentMode: .aspectFill,
                                       options: options,
                                 resultHandler: { (result, info) in
                    if let cResult = result,
                        let cInfo = info,
                        let degraded = cInfo[PHImageResultIsDegradedKey] as? Bool,
                        !degraded {
                        fileSerializer.writeImage(cResult, toRelativePath: assetImage.thumbnailFileName)
                        assetImage.thumbnailNeedsRedraw = false
                        
                        //                        imageLoadGroup.leave()
                    }
                    imageLoadGroup.leave()
                })
            })
            assetImage.setInitialValuesWithAlbum("CJMQuickNote")
            assetImage.photoCreationDate = Date()
            
            newImages.append(assetImage)
        }
        
        let album = PHNAlbumManager.sharedInstance.userQuickNote
        let newImage = newImages[0]
        if album.albumPhotos.count > 0 {
            let oldImage = album.albumPhotos[0]
            newImage.photoTitle = oldImage.photoTitle
            newImage.photoNote = oldImage.photoNote
            newImage.photoCreationDate = oldImage.photoCreationDate
        }
        PHNAlbumManager.sharedInstance.albumWithName( "CJMQuickNote",
                                        deleteImages: album.albumPhotos)
        
        album.add(newImage)
        btnDone.isEnabled = true
        
        imageLoadGroup.notify(queue: .main) { [weak self] in
            self?.navigationController?.view.isUserInteractionEnabled = true
            self?.dismiss(animated: true, completion: nil)
            PHNAlbumManager.sharedInstance.save()
            self?.displayQuickNoteThumbnail()
            self?.navigationController?.view.isUserInteractionEnabled = true //TODO why the repeat?
        }
    }
    
    func photosFromLibrary() {
        PHPhotoLibrary.requestAuthorization { [weak self] (status) in
            if status != .authorized {
                let adjustPrivacyController = UIAlertController(title: "Denied Access to Photos", message: "Please allow Photo Notes permission to use the camera.", preferredStyle: .alert)
                
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
                    UIApplication.shared.canOpenURL(settingsUrl)
                {
                    let actionSettings = UIAlertAction(title: "Open Settings", style: .default, handler: { (_) in
                        UIApplication.shared.open(settingsUrl) { (success) in
                            #if DEBUG
                            print("Settings opened: \(success)")
                            #endif
                        }
                    })
                    adjustPrivacyController.addAction(actionSettings)
                }
                
                let actionDismiss = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
                
                adjustPrivacyController.addAction(actionDismiss)
                self?.present(adjustPrivacyController, animated: true, completion: nil)
            } else {
                // requestAuthorization() is asynchronous. Must dispatch to main.
                DispatchQueue.main.async {
                    self?.presentPhotoGrabViewController()
                }
            }
        }
    }
    
    //MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            photosFromLibrary()
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                let str_URL = "https://itunes.apple.com/us/app/photo-notes-add-context-to-your-photos/id1021742238?mt=8"
                UIApplication.shared.open(URL(string: str_URL)!, options: [UIApplication.OpenExternalURLOptionsKey.universalLinksOnly : false] , completionHandler: nil)
            } else if indexPath.row == 1 {
                let vc = SFSafariViewController(url: URL(string: "https://www.twitter.com/beDevCurt")!)
                vc.delegate = self
                present(vc, animated: true, completion: nil)
            } else {
                if MFMailComposeViewController.canSendMail() {
                    let vc = MFMailComposeViewController()
                    vc.mailComposeDelegate = self
                    vc.modalPresentationStyle = .pageSheet
                    vc.setToRecipients(["bedevcurt@gmail.com"])
                    vc.setSubject("Photo Notes Support")
                    vc.setMessageBody("Hey Curt!", isHTML: false)
                    present(vc, animated: true, completion: nil)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //MARK: - Safari and Mail Delegates
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == .cancelled || result == .sent {
            dismiss(animated: true, completion: nil)
        } else if result == .failed {
            dismiss(animated: true, completion: nil)
            
            let alert = UIAlertController(title: "Email Failed", message: "The message failed to send.  Please try again or email me at bedevcurt@gmail.com direct from your Mail app", preferredStyle: .alert)
            let dismiss = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alert.addAction(dismiss)
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
    }

}
