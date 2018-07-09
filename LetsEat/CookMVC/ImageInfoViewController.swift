//
//  ImageInfoViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/25/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Readig Citation: https://stackoverflow.com/questions/28813339/move-a-view-up-only-when-the-keyboard-covers-an-input-field?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa, https://stackoverflow.com/questions/46453789/swift-4-settings-bundle-get-defaults?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
//  Video Citation: https://www.youtube.com/watch?v=wgHhpTV6UHs

import UIKit
import AVFoundation
import MessageUI
import MobileCoreServices

class ImageInfoViewController: UIViewController, AVAudioPlayerDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    private var keyboardObserver: NSObjectProtocol?
    private var hideKeyboardObserver: NSObjectProtocol?
    // layer needed for animating wrapping text
    private let transitioningLayer = CATextLayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerSetting()
        loadDefaults()
        adjustBackgroundColor()
        // textview background settings from userdefaults
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(syncBackground),
                                                         name: UserDefaults.didChangeNotification,
                                                         object: nil)
        // keyboard
        keyboardObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillChangeFrame, object: nil, queue: OperationQueue.main) { (notification) in
            self.adjustKeyboard(notification:notification)
            }
        hideKeyboardObserver =  NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { (notification) in
            self.adjustKeyboard(notification:notification)
        }
        // tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        // set up music player
        prepareMusicPlayer(at: musicIndex)
    }
    
    @objc func tapToDismiss(_sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }

    override func viewDidAppear(_ animated: Bool) {
        configureTextLayer()
    }
    
    // shake phone to play the next song
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
          playNextSong()
        }
    }
    
    // MARK: -Message Sender
    // Send text messages and deal with results
    @IBAction func composeText(_ sender: UIBarButtonItem) {
        if MFMessageComposeViewController.canSendText() {
            let controller = MFMessageComposeViewController()
            controller.body = descriptionTextField.text
            controller.messageComposeDelegate = self
            controller.addAttachmentData(imageData!, typeIdentifier: ImageInfoConstants.imageTypeIdentifier, filename: ImageInfoConstants.imageFileName)
            self.present(controller, animated: true, completion: nil)
        } else {
            addGenericAlert(message: AlertConstants.noTextAlertMessage, alertTitle: AlertConstants.noTextAlertTitle, actionTitle: AlertConstants.dismiss)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
        switch result {
        case .cancelled:
            addGenericAlert(message: AlertConstants.cancelAlertMessage, alertTitle: AlertConstants.failToSend, actionTitle: AlertConstants.dismiss)
        case .failed:
            addGenericAlert(message: AlertConstants.failAlertMessage, alertTitle: AlertConstants.failToSend, actionTitle: AlertConstants.dismiss)
        case .sent:
            addGenericAlert(message: AlertConstants.sentMessage, alertTitle: AlertConstants.success, actionTitle: AlertConstants.dismiss)
        }
    }

    // send emails and deal with results
    @IBAction func sendEmail(_ sender: UIBarButtonItem) {
        if MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setSubject(AlertConstants.emailSubject)
            controller.setMessageBody(descriptionTextField.text, isHTML: false)
            controller.addAttachmentData(imageData!, mimeType: ImageInfoConstants.mimeType, fileName: ImageInfoConstants.image)
            controller.mailComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        } else {
            addGenericAlert(message: AlertConstants.noMailAlertMessage, alertTitle: AlertConstants.noMailAlertTitle, actionTitle: AlertConstants.dismiss)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
        switch result {
        case .cancelled:
            addGenericAlert(message: AlertConstants.emailCancelAlertMessage, alertTitle: AlertConstants.failSend, actionTitle: AlertConstants.dismiss)
        case .failed:
            addGenericAlert(message: AlertConstants.emailFailSendMessage, alertTitle: AlertConstants.failSend, actionTitle: AlertConstants.dismiss)
        case .sent:
            addGenericAlert(message: AlertConstants.emailSentMessage, alertTitle: AlertConstants.success, actionTitle: AlertConstants.dismiss)
        case .saved:
            addGenericAlert(message: AlertConstants.emailSaveMessage, alertTitle: AlertConstants.saved, actionTitle: AlertConstants.dismiss)
        }
    }

    // MARK: -Music Player
    private var player: AVAudioPlayer!
    private var musicIndex = 0
    private func prepareMusicPlayer(at index: Int) {
        let url = Bundle.main.url(forResource: musicPlayerConstants.playList[index], withExtension:musicPlayerConstants.fileType)
        do {
            player = try AVAudioPlayer(contentsOf: url!)
            player.delegate = self
            player.prepareToPlay()
        } catch  {
            addGenericAlert(message: AlertConstants.musicAlertMessage, alertTitle: AlertConstants.musicAlertTitle, actionTitle: AlertConstants.dismiss)
        }
    }
    private var isPlaying = false
    @IBOutlet weak var toolBar: UIToolbar!
    @IBAction func playOrPause (_ sender: Any) {
        if !isPlaying {
            playMusic()
        } else {
            pauseMusic()
        }
    }
    @IBOutlet weak var songLabel: UILabel!
    @IBAction func nextSong(_ sender: UIBarButtonItem) {
        playNextSong()
    }
    @IBAction func prevSong(_ sender: UIBarButtonItem) {
        playPreviousSong()
    }
    
    private func playPreviousSong() {
        musicIndex -= 1
        musicIndex = (musicIndex < 0) ? musicPlayerConstants.playList.count - 1 : musicIndex
        prepareMusicPlayer(at: musicIndex)
        playMusic()
    }
    
    private func playNextSong() {
        musicIndex += 1
        musicIndex = (musicIndex >= musicPlayerConstants.playList.count) ? 0 : musicIndex
        prepareMusicPlayer(at: musicIndex)
        playMusic()
    }
    @IBAction func goBack(_ sender: UIBarButtonItem) {
        if player.currentTime - musicPlayerConstants.adjustAmount < 0 {
            playPreviousSong()
        } else {
            player.currentTime = player.currentTime - musicPlayerConstants.adjustAmount
        }
    }
    
    @IBAction func moveForward(_ sender: UIBarButtonItem) {
        if player.currentTime + musicPlayerConstants.adjustAmount > player.duration {
            playNextSong()
        } else {
            player.currentTime = player.currentTime + musicPlayerConstants.adjustAmount
        }
    }
    
    @IBAction func volumeControl(_ sender: UISlider) {
        player.setVolume(sender.value, fadeDuration: musicPlayerConstants.adjustAmount)
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextSong()
    }
    
    private func playMusic() {
        isPlaying = true
        player.play()
        animateLabelWrapping()
        self.toolBar.items![musicPlayerConstants.playButtonIndex] = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action:  #selector(playOrPause(_:)))
    }
    
    private func pauseMusic() {
        isPlaying = false
        animateLabelWrapping()
        player.pause()
         self.toolBar.items![musicPlayerConstants.playButtonIndex] = UIBarButtonItem(barButtonSystemItem: .play, target: self, action:  #selector(playOrPause(_:)))
    }
    
    // MARK: -Song Title Animation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        transitioningLayer.removeAnimation(forKey: AnimationConstants.transition)
        coordinator.animate(alongsideTransition: nil) { _ in
            let rect = CGRect(x:self.songLabel.frame.minX, y: self.songLabel.frame.minY+AnimationConstants.yOffset, width: self.songLabel.frame.width, height: self.songLabel.frame.height)
            self.transitioningLayer.frame = rect
            self.animateLabelWrapping()
        }
    }
    
    private func configureTextLayer() {
        transitioningLayer.frame = CGRect(x:songLabel.frame.minX, y: songLabel.frame.minY+AnimationConstants.yOffset, width: songLabel.frame.width, height: songLabel.frame.height)
        transitioningLayer.backgroundColor = AnimationConstants.clearColor
        transitioningLayer.foregroundColor = AnimationConstants.blackColor
        transitioningLayer.fontSize = AnimationConstants.fontSize
        transitioningLayer.contentsScale = UIScreen.main.scale
        view.layer.addSublayer(transitioningLayer)
    }
    
    private func animateLabelWrapping() {
        if isPlaying {
            transitioningLayer.string = musicPlayerConstants.playList[musicIndex] + musicPlayerConstants.isPlaying
            let transition = CABasicAnimation(keyPath: AnimationConstants.position)
            transition.fromValue = [0,transitioningLayer.frame.midY]
            transition.toValue = [songLabel.frame.width*AnimationConstants.frameWidthMultiplier,transitioningLayer.frame.midY]
            transition.duration = AnimationConstants.transitionDuration
            transition.repeatCount = Float.infinity
            transitioningLayer.add(transition,
                               forKey: AnimationConstants.transition)
        } else {
            transitioningLayer.removeAllAnimations()
            transitioningLayer.string =  musicPlayerConstants.playList[musicIndex] + musicPlayerConstants.stop
        }
    }

    // MARK: -Text Edit
    // Avoid keyboard cover up
    private func adjustKeyboard(notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        if notification.name == Notification.Name.UIKeyboardWillChangeFrame {
            descriptionTextField.contentInset = UIEdgeInsets(top:ImageInfoConstants.zeroOffset, left:ImageInfoConstants.zeroOffset, bottom: keyboardFrame.height, right: ImageInfoConstants.zeroOffset)
        } else {
            descriptionTextField.contentInset = UIEdgeInsets.zero
        }
        descriptionTextField.scrollRangeToVisible(descriptionTextField.selectedRange)
    }
    
    @IBAction func cancelEdit(_ sender: UIBarButtonItem) {
        dismissObservers()
        player.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveEdit(_ sender: UIBarButtonItem) {
        imageDescription = descriptionTextField.text
        NotificationCenter.default.post(name: .saveDescription, object: self)
        dismissObservers()
        player.stop()
        self.dismiss(animated: true, completion: nil)
    }
    
    private func dismissObservers() {
        if let observer = self.keyboardObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = self.hideKeyboardObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    var imageDescription: String?
    var descriptionIndex: Int?
    var imageData: Data?
    @IBOutlet weak var descriptionTextField: UITextView! {
        didSet {
            descriptionTextField.text = imageDescription
        }
    }
    
    // MARK: -Textview background
    @IBOutlet weak var segmentControl: UISegmentedControl!
    
    @IBAction func changeSegment(_ sender: UISegmentedControl) {
        adjustBackgroundColor()
    }
    
    private func adjustBackgroundColor() {
        switch segmentControl.selectedSegmentIndex
        {
        case ImageInfoConstants.segmentPurple:
            descriptionTextField.backgroundColor = ImageInfoConstants.purple
            descriptionTextField.textColor = ImageInfoConstants.gray
        case ImageInfoConstants.segmentGreen:
            descriptionTextField.backgroundColor = ImageInfoConstants.green
            descriptionTextField.textColor = ImageInfoConstants.white
        case ImageInfoConstants.segmentYellow:
            descriptionTextField.backgroundColor = ImageInfoConstants.yellow
            descriptionTextField.textColor = ImageInfoConstants.black
        case ImageInfoConstants.segmentBlue:
            descriptionTextField.backgroundColor = ImageInfoConstants.blue
            descriptionTextField.textColor = ImageInfoConstants.white
        default:
            break
        }
    }
    
    // able to set background color from app settings
    private func registerSetting(){
        let appDefaults = [String:AnyObject]()
        UserDefaults.standard.register(defaults: appDefaults)
    }
    
    private func loadDefaults(){
        //Get the defaults
        segmentControl.selectedSegmentIndex = UserDefaults.standard.integer(forKey: ImageInfoConstants.textviewColor)
    }
    
    @objc func syncBackground() {
        loadDefaults()
        adjustBackgroundColor()
    }

    private struct ImageInfoConstants {
        static let zeroOffset = CGFloat(0)
        static let mimeType = "image/jpeg"
        static let imageTypeIdentifier = "image/.jpeg"
        static let image = "image"
        static let imageFileName = "image.jpeg"
        static let segmentPurple = 0
        static let segmentGreen = 1
        static let segmentYellow = 2
        static let segmentBlue = 3
        static let textviewColor = "textview_color"
        static let purple = UIColor(red: 0.8863, green: 0.7255, blue: 0.8667, alpha: 1)
        static let gray = UIColor.gray
        static let green = UIColor(red: 0.4605, green: 0.9103, blue: 0.3977, alpha: 0.71)
        static let white = UIColor.white
        static let yellow = UIColor(red: 0.9995, green: 0.9884, blue: 0.4727, alpha: 0.87)
        static let black = UIColor.black
        static let blue = UIColor(red: 0.0639, green: 0.8903, blue: 0.9441, alpha: 0.57)
    }
    private struct AnimationConstants {
        static let transition = "transition"
        static let yOffset = CGFloat(7.5)
        static let fontSize = CGFloat(15.0)
        static let clearColor = UIColor.clear.cgColor
        static let blackColor = UIColor.black.cgColor
        static let position = "position"
        static let frameWidthMultiplier = CGFloat(1.5)
        static let transitionDuration = Double(8.0)
    }
    private struct musicPlayerConstants {
        static let playList = ["Sad Angel", "Faded", "All", "Kissing", "Simple Life"]
        static let fileType = "mp3"
        static let adjustAmount = Double(5)
        static let playButtonIndex = 3
        static let isPlaying = " is Playing"
        static let stop = " Stops"
    }
    private struct AlertConstants {
        static let cancelAlertMessage = "Message was cancelled"
        static let dismiss = "Dismiss"
        static let failToSend = "Failed to Send"
        static let success = "Success"
        static let failAlertMessage = "Message was failed to send"
        static let sentMessage = "Message was sent"
        static let noTextAlertMessage = "Can't text on this device"
        static let noTextAlertTitle = "Failed to send text"
        static let noMailAlertMessage = "Can't send mail on this device"
        static let emailCancelAlertMessage = "Email was cancelled"
        static let failSend = "Failed to Send"
        static let noMailAlertTitle = "Failed to send mail"
        static let emailFailSendMessage = "Email was failed to send"
        static let emailSentMessage = "Email was sent"
        static let emailSaveMessage = "Email was saved"
        static let saved = "Saved"
        static let emailSubject = "Check out my recipe"
        static let musicAlertMessage = "Unable to play music"
        static let musicAlertTitle = "Can't Play Music"
    }
}
