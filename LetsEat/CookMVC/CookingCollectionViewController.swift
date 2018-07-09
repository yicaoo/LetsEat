//
//  CookingCollectionViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/20/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Reading Cite: https://medium.com/@maximbilan/ios-sharing-via-instagram-9bf9a9f7f14d, https://stackoverflow.com/questions/44400741/convert-image-to-cvpixelbuffer-for-machine-learning-swift?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa, https://www.appcoda.com/coreml-introduction/
//  Machine learning powered by ResNet50
import UIKit
import MobileCoreServices
import CoreML

class CookingCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UICollectionViewDropDelegate, UIDropInteractionDelegate, UICollectionViewDragDelegate {
    private var model: Resnet50!
    
    // MARK: -Document
    private var cookBook: CookBook! {
        get {
            if document?.cookBook == nil {
                let newCookBook = CookBook(name:[], imageData:[], imageAspectRatio:[], description: [], imageCellWidth: ScaleConstants.imageCellDefaultWidth)
                document?.cookBook = newCookBook
            }
            return document?.cookBook
        } set {
            document?.cookBook = newValue
            cookingCollectionView.reloadData()
        }
    }
    
    var document: CookBookDocument?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if document?.documentState != .normal {
            document?.open { success in
                if success {
                    self.title = self.document?.localizedName
                    self.cookBook = self.document?.cookBook
                    self.model = Resnet50()
                } else {
                    self.addGenericAlert(message: AlertConstants.openDocumentAlertMessage, alertTitle: AlertConstants.openDocumentAlertTitle, actionTitle: AlertConstants.dismiss)
                }
            }
        }
    }
    
    private func saveCurrentState() {
        cookBook.imageCellWidth = Double(imageCellWidth)
        document?.cookBook = self.cookBook
        document?.updateChangeCount(.done)
    }
    
    @IBAction func done(_ sender: UIBarButtonItem? = nil) {
        saveCurrentState()
        //create thumbnail as the last image
        if document?.cookBook != nil {
            let itemIndex = (cookBook.name.count - 1 > 0) ? cookBook.name.count - 1 : 0
            let cell = cookingCollectionView.cellForItem(at: [0,itemIndex]) as? CookingCollectionViewCell
            document?.thumbnail = cell?.snapshot
        }
        // clean up all observers
        dismiss(animated: true) {
            self.document?.close() {success in
                if let observer = self.cookBookObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let observer = self.keyboardObserver {
                    NotificationCenter.default.removeObserver(observer)
                }
                if let observer = self.hideKeyboardObserver{
                    NotificationCenter.default.removeObserver(observer)
                }
            }
        }
    }
    
    // MARK: -Image and Camera
    private let picker = UIImagePickerController()
    
    @IBOutlet weak var imageLibraryButton: UIBarButtonItem! {
        // enable when can access photo library
        didSet {
            imageLibraryButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
        }
    }
    
    @IBOutlet weak var cameraButton: UIBarButtonItem! {
        //enable when have camera
        didSet {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker,animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
    
    @IBAction func loadLibraryImage(_ sender: UIBarButtonItem) {
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // pick image
    @objc internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var predictionResult: (String, Double)?
        if let image = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage {
            if let imageData = UIImageJPEGRepresentation(image, ImageConstant.bestQuality) {
                // predict what the image is
                predictionResult = predictImage(for: image)
                let width = image.size.width
                let height = image.size.height
                let aspectRatio = height/width
                self.cookBook.imageAspectRatio.append(Double(aspectRatio))
                self.cookBook.imageData.append(imageData)
                self.cookBook.name.append(CookBookConstants.defaultName.madeUnique(withRespectTo: cookBook.name))
                self.cookBook.description.append(CookBookConstants.defaultDescription)
                cookingCollectionView.reloadData()
            } else {
                self.addGenericAlert(message: AlertConstants.badImageMessage, alertTitle: AlertConstants.badImageTitle, actionTitle: AlertConstants.dismiss)
            }
        }
        picker.presentingViewController?.dismiss(animated: true)
        if predictionResult != nil {
            presentUserResult(with: predictionResult!)
        }
    }
    
    //since title is limited to 12 characters, process ML returned name
    private func shortenName(name: String)->String{
        // first strip out the description adj before the noun
        var returnName = name
        if let space = name.index(of: ImageConstant.space) {
            returnName = String(name[name.index(after: space)..<name.endIndex])
        }
        // take first 12 characters
        if returnName.count > ImageConstant.maxCharacter {
            returnName = String(returnName.prefix(ImageConstant.maxCharacter))
        }
        return returnName
    }
    
    // present machine learning prediction result to user
    private func presentUserResult(with predictionResult: (String, Double)) {
        var displayPrediction = predictionResult.0.components(separatedBy: ImageConstant.seperation).first!
        let displayProbability = Int(predictionResult.1*ScaleConstants.percentage)
        let title = ImageConstant.imagePredictionTitle + displayPrediction + ImageConstant.question
        let message = ImageConstant.AI+String(displayProbability)+ImageConstant.confident+displayPrediction
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: AlertConstants.agree, style: .default, handler: {action in
            if displayPrediction.count > ImageConstant.maxCharacter {
                displayPrediction = self.shortenName(name: displayPrediction)
            }
            self.cookBook.name[self.cookBook.name.count-1] = displayPrediction
            self.cookingCollectionView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: AlertConstants.disagree, style: .default, handler:nil))
        present(alert, animated: true)
    }
    
    // convert image to CVPixelBuffer
    private func convertImageForMLModel(image: UIImage)-> CVPixelBuffer{
        // creates a bitmap-based graphics context
        UIGraphicsBeginImageContextWithOptions(CGSize(width: ImageConstant.MLImageSize, height: ImageConstant.MLImageSize), true, ScaleConstants.bitmapScaleFactor)
        image.draw(in: CGRect(x: 0, y: 0, width: ImageConstant.MLImageSize, height: ImageConstant.MLImageSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        // removes the current bitmap-based graphics context from the top of the stack.
        UIGraphicsEndImageContext()
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        //creates a single pixel buffer for a given size and pixel format.
        CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        // locks the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: ImageConstant.bits, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: ScaleConstants.contextXScale, y: ScaleConstants.contextYScale)
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer!
    }
    
    // predict image
    private func predictImage(for image: UIImage)-> (String, Double) {
        //ML model requires input image of scene to be classified as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
        let buffer = convertImageForMLModel(image: image)
        if let prediction = try? model.prediction(image: buffer) {
            let maxProbabilityResult = prediction.classLabelProbs.max{ a, b in a.value < b.value }
            return (maxProbabilityResult!.key, maxProbabilityResult!.value)
        } else {
            return (ImageConstant.failtoPredict, 0)
        }
    }
    
    // MARK: -Layout Collection View
    // make sure the equal spacing among all rows in either portrait or landscape mode
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var maxNumItemsPerRow = view.bounds.width / imageCellWidth
        maxNumItemsPerRow = maxNumItemsPerRow.rounded(.down)
        if maxNumItemsPerRow > 1 {
            flowLayout?.minimumInteritemSpacing = (view.bounds.width - maxNumItemsPerRow * imageCellWidth)/(maxNumItemsPerRow-1)
        }
    }
    
    @IBOutlet var cookingCollectionView: UICollectionView!{
        didSet {
            cookingCollectionView.dragInteractionEnabled = true
            cookingCollectionView.dataSource = self
            cookingCollectionView.delegate = self
            // for collection view drag and drop
            cookingCollectionView.dragDelegate = self
            cookingCollectionView.dropDelegate = self
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(adjustImageCellScale(byHandlingGestureRecognizedBy:)))
            cookingCollectionView.addGestureRecognizer(pinch)
        }
    }
    
    private var cookBookObserver: NSObjectProtocol?
    private var keyboardObserver: NSObjectProtocol?
    private var hideKeyboardObserver: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()
        cookBookObserver = NotificationCenter.default.addObserver(forName: .saveDescription , object: nil, queue: OperationQueue.main) { (notification) in
            self.updateDescription(notification: notification)
        }
        keyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: OperationQueue.main) { (notification) in
            self.adjustKeyboard(notification:notification)
        }
        hideKeyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { (notification) in
            self.adjustKeyboard(notification:notification)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tapToDismiss(_sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func adjustKeyboard(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if notification.name == Notification.Name.UIKeyboardWillChangeFrame {
            cookingCollectionView.contentInset = UIEdgeInsets(top: ScaleConstants.zeroOffset, left: ScaleConstants.zeroOffset, bottom: keyboardFrame.height, right: ScaleConstants.zeroOffset)
        } else {
            cookingCollectionView.contentInset = UIEdgeInsets(top: ScaleConstants.zeroOffset, left: ScaleConstants.zeroOffset, bottom: ScaleConstants.zeroOffset, right: ScaleConstants.zeroOffset)
        }
    }
    private func updateDescription(notification: Notification) {
        let imageInfoViewController = notification.object as! ImageInfoViewController
        if (imageInfoViewController.descriptionIndex! < cookBook.description.count) {
            self.cookBook.description[imageInfoViewController.descriptionIndex!] = imageInfoViewController.imageDescription!
        }
    }
    
    // MARK: -Drag and Drop
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cookBook?.imageData.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Storyboard.newCookCell, for: indexPath)
        if let cookCell = cell as? CookingCollectionViewCell {
            let imageToDisplay = UIImage(data: cookBook.imageData[indexPath.item])
            cookCell.imageView.image = imageToDisplay
            cookCell.imageName?.text = cookBook.name[indexPath.item]
            cookCell.textFieldResignationHandler = { [unowned self, cookCell] in
                if let nameText = cookCell.imageName.text {
                    cookCell.imageName?.text = nameText
                    self.cookBook.name[indexPath.item] = nameText
                    self.cookingCollectionView.reloadData()
                }
            }
        }
        cell.layer.borderColor = UIColor.brown.cgColor
        cell.layer.borderWidth = ScaleConstants.imageCellBorderWidth
        return cell
    }
    
    //Computed variable
    private var imageCellWidth: CGFloat {
        let computedCellWidth = (imageCellScale * CGFloat(cookBook.imageCellWidth) < ScaleConstants.minCellWidth) ? ScaleConstants.minCellWidth: imageCellScale * CGFloat(cookBook.imageCellWidth)
        return computedCellWidth
    }
    
    // pinch gesture scale
    private var imageCellScale: CGFloat = ScaleConstants.imageCellDefaultScale
    @objc func adjustImageCellScale(byHandlingGestureRecognizedBy recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed,.ended:
            imageCellScale *= recognizer.scale
            imageCellScale = (imageCellScale < ScaleConstants.minScale) ? ScaleConstants.minScale : imageCellScale
            imageCellScale = (imageCellScale*CGFloat(cookBook.imageCellWidth) > UIScreen.main.bounds.width) ? UIScreen.main.bounds.width/CGFloat(cookBook.imageCellWidth) : imageCellScale
            recognizer.scale = ScaleConstants.recognizerDefaultScale
            flowLayout?.invalidateLayout()
        default:
            break
        }
    }
    
    private var flowLayout: UICollectionViewFlowLayout? {
        return cookingCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: imageCellWidth, height: CGFloat(cookBook.imageAspectRatio[indexPath.item]) * imageCellWidth)
    }
  
    //  multiple item dragging
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        session.localContext = collectionView
        return itemsToDrag(at: indexPath)
    }
    
    // start of a drag
    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: UIDragSession,
        at indexPath: IndexPath
        ) -> [UIDragItem] {
        return itemsToDrag(at: indexPath)
    }
    
    private func itemsToDrag(at indexPath: IndexPath) -> [UIDragItem] {
        if let imageView = (cookingCollectionView.cellForItem(at: indexPath) as? CookingCollectionViewCell)?.imageView {
            //only drags locally
            guard let image = imageView.image else { return [] }
            let itemProvider = NSItemProvider(object: image)
            let item = UIDragItem(itemProvider: itemProvider)
            item.localObject = self
            return [item]
        } else {
            return []
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item:0, section:0)
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                collectionView.performBatchUpdates({
                    // image data
                    switchImageData(source: sourceIndexPath.item, destination: destinationIndexPath.item)
                    // aspect ratio
                    switchAspectRatio(source: sourceIndexPath.item, destination: destinationIndexPath.item)
                    // name
                    switchName(source: sourceIndexPath.item, destination: destinationIndexPath.item)
                    // description
                    switchDescription(source: sourceIndexPath.item, destination: destinationIndexPath.item)
                    // view
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                })
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
            collectionView.reloadData()
        }
    }
    
    private func switchImageData(source: Int, destination: Int) {
        let draggedData = cookBook.imageData[source]
        cookBook.imageData.remove(at: source)
        cookBook.imageData.insert(draggedData, at: destination)
    }
    
    private func switchAspectRatio(source: Int, destination: Int) {
        let draggedAspectRatio = cookBook.imageAspectRatio[source]
        cookBook.imageAspectRatio.remove(at: source)
        cookBook.imageAspectRatio.insert(draggedAspectRatio, at: destination)
    }
    
    private func switchName(source: Int, destination: Int) {
        let draggedName = cookBook.name[source]
        cookBook.name.remove(at: source)
        cookBook.name.insert(draggedName, at: destination)
    }
    
    private func switchDescription(source: Int, destination: Int) {
        let draggedDescription = cookBook.description[source]
        cookBook.description.remove(at: source)
        cookBook.description.insert(draggedDescription, at: destination)
    }
    
    // no plus button
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        return UICollectionViewDropProposal(operation:.move, intent: .insertAtDestinationIndexPath)
    }
    
    
    // MARK: -Share and delete
    @IBAction func shareOnInstagram(_ sender: UIButton) {
        let cell = sender.superview?.superview as? CookingCollectionViewCell
        let image = cell?.imageView.image
        let instagramURL = NSURL(string: URLConstants.instagramURL)
        if UIApplication.shared.canOpenURL(instagramURL! as URL) {
            let activityController = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
            //efforts to exclude other activities to focus on sharing images
            activityController.excludedActivityTypes = [UIActivityType.mail, UIActivityType.message, UIActivityType.openInIBooks, UIActivityType.airDrop, UIActivityType.assignToContact, UIActivityType.copyToPasteboard,UIActivityType(rawValue: URLConstants.reminderEditorExtension), UIActivityType(rawValue: URLConstants.sharingExtension)]
            present(activityController, animated: true, completion: nil)
        } else {
            // if can't open instagram on this device, take user to APP store
            let alert = UIAlertController(title: AlertConstants.instagramAlertTitle, message: AlertConstants.instagramAlertMessage, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: AlertConstants.goToAppStore, style: .destructive, handler: {action in
                self.launchAppStore()
            }))
            alert.addAction(UIAlertAction(title: AlertConstants.cancel, style: .cancel, handler:nil))
            present(alert, animated: true)
        }
    }
    
    private func launchAppStore() {
        let appStoreLink = URLConstants.appStoreURL
        if let url = URL(string: appStoreLink), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: {(success: Bool) in
                guard success else {
                    self.addGenericAlert(message: AlertConstants.launchURLAlertMessage, alertTitle: AlertConstants.launchURLAlertMessage, actionTitle: AlertConstants.dismiss)
                    return
                }})
        }
    }
    
    // delete the collection view cell
    @IBAction func deletecell(_ sender: UIButton) {
        let deleteWarning = UIAlertController(title: AlertConstants.deleteAlertTitle, message: AlertConstants.deleteAlertMessage, preferredStyle: .alert)
        let confirm = UIAlertAction(title: AlertConstants.delete, style: .destructive, handler: { (action) -> Void in
            let superview = sender.superview?.superview
            if let cookCell = superview as? CookingCollectionViewCell {
                if let indexPath = self.cookingCollectionView.indexPath(for: cookCell) {
                    self.cookBook.imageData.remove(at: indexPath.item)
                    self.cookBook.name.remove(at: indexPath.item)
                    self.cookBook.description.remove(at: indexPath.item)
                    self.cookBook.imageAspectRatio.remove(at: indexPath.item)
                    self.cookingCollectionView.reloadData()
                }
            }
        })
        deleteWarning.addAction(confirm)
        deleteWarning.addAction(UIAlertAction(title: AlertConstants.cancel, style: .cancel))
        self.present(deleteWarning, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Storyboard.showImageInfo {
            let button = sender as? UIButton
            let superview = button?.superview?.superview
            if let cookCell = superview as? CookingCollectionViewCell {
                if let indexPath = cookingCollectionView.indexPath(for: cookCell) {
                    if let destination = segue.destination.contents as? ImageInfoViewController {
                        destination.imageDescription = cookBook.description[indexPath.item]
                        destination.descriptionIndex = indexPath.item
                        destination.imageData = cookBook.imageData[indexPath.item]
                    }
                }
            }
        }
    }
    
    //Constants
    private struct Storyboard {
        static let newCookCell = "newCookCell"
        static let showImageInfo = "showImageInfo"
    }
    private struct AlertConstants {
        static let deleteAlertTitle = "Please Confirm"
        static let deleteAlertMessage = "Are you sure you want to delete this photo?"
        static let delete = "Delete"
        static let cancel = "Cancel"
        static let agree = "Agree"
        static let disagree = "Disagree"
        static let openDocumentAlertMessage = "Failed to open document"
        static let openDocumentAlertTitle = "Document Open Failure"
        static let dismiss = "Dismiss"
        static let badImageMessage = "Unable to load in image"
        static let badImageTitle = "Bad Image"
        static let goToAppStore = "Go To App Store"
        static let instagramAlertTitle = "Can't Open Instagram"
        static let instagramAlertMessage = "Instagram is not available on this device"
        static let launchURLAlertMessage = "Unable to lunach app store"
        static let launchURLAlertTitle = "Can't Redirect"
    }
    private struct ScaleConstants {
        static let zeroOffset = CGFloat(0)
        static let recognizerDefaultScale = CGFloat(1.0)
        static let imageCellDefaultScale = CGFloat(1.0)
        static let imageCellDefaultWidth = Double(300)
        static let imageCellBorderWidth = CGFloat(2)
        static let minScale = CGFloat(0.5)
        static let minCellWidth = CGFloat(280)
        static let percentage = Double(100)
        static let bitmapScaleFactor = CGFloat(2)
        static let contextXScale = CGFloat(1.0)
        static let contextYScale = CGFloat(-1.0)
    }
    private struct CookBookConstants {
        static let defaultName = "Untitled"
        static let defaultDescription = "Descriptions: "
    }
    private struct ImageConstant {
        static let bestQuality = CGFloat(1.0)
        static let failtoPredict = "Fail to Predict"
        static let failtoDetect = "Fail to Detect"
        static let MLImageSize = CGFloat(224)
        static let imagePredictionTitle = "Is Your Image "
        static let question = " ?"
        static let seperation = ","
        static let space = Character(" ")
        static let AI = "AI is "
        static let confident = "% confident that your image is "
        static let bits = 8
        static let maxCharacter = 12
    }
    private struct URLConstants {
        static let appStoreURL = "https://www.apple.com/ios/app-store/"
        static let reminderEditorExtension = "com.apple.reminders.RemindersEditorExtension"
        static let sharingExtension = "com.apple.mobilenotes.SharingExtension"
        static let instagramURL = "instagram://app"
    }
}
