# LetsEat, iOS Mobile Application
![cutlery 1](https://user-images.githubusercontent.com/32280834/46499848-1a1f7c80-c7d6-11e8-8aed-c63e3d6d7a61.png)
---
Language: Swift
---
Project Outline
---
This application starts with an introduction of all its features, shown once to new users.
Inside the application, there are three main features: DineOut, Cook and Exercise:
* [DineOut] Select food category to search nearby restaurants. Get driving directions or check out the food images. Call restaurants or save phone number to contact list.
* [Cook] Create cooking albums. Take images or load images from library with machine learning image recognition feature. Edit photo info while listening to music. Email or text photos with descriptions.
* [Exercise] Check number of steps and walking distance recorded from HealthKit. Enter caffeine and protein consumption. Plan exercise with location-based reminders or start exercise with a timer.

![simulator screen shot - iphone 8 - 2018-10-04 at 13 21 36](https://user-images.githubusercontent.com/32280834/46500779-856a4e00-c7d8-11e8-805f-8b0f8e445d1e.png)

APIs Used
---
* MapKit: [DineOut]search location near user, custom annotations, launch navigation;
         [Exercise]overlay direction on map.
* Table View: [DineOut] Table view with custom cells with images, variable height;
             [Exercise] Table view with static cells, section header, used as form. 
* UIPageControl&UIPageViewController: when app is launched for the first time, walk through new user with app features.
* Animation API: animation on key drop and menu page pulsating effect.
* UISearchController: search by name and filter food by category in the DineOut table view (dynamically updated).
* WebKit: ability to go backward and forward, progress bar indicating page loading.
* UIApplication: phone call, go to App Store, go to Wi-Fi settings if no internet connection, Instagram URL.
* ContactsKit: add and fetch contacts (check for duplicates).
* UIEvent: shake phone.
* UIGestureRecognizer: tap to dismiss, pinch gesture.
* Popover API: adjustable size in both DineOut add contact and Exercise timer.
* Modal Segue: edit image info in Cook section and select location from map for reminder in Exercise.
* Document API: save Cook albums.
* UICollectionView: careful layout to fit image nicely, spacing control between cells, adjustable cell width, custom cell with text view and buttons.
* Drag and Drop: drag and drop collection view cell to reorder.
* ImagePickerAPI: load image from library or take picture with camera.
* Core Image: process image to pixel buffer for ML.
* Core Machine Learning: use core ML to predict image, customize results from ML model to present to user.
* UIActivityController: share on Instagram and customize activities.
* Notifications: used for keyboard, dismiss blur view when dismiss popover, sync textview settings with view, save image description (note: delegation was used to pass search location from the Exercise section modal map to the table instead of notification to add variety). 
* AVFoundation: for music playing: next song, previous song, fast forward, rewind, volume control, play-pause button switching, song name display.
* Core Animation: CABasic animation to animate the song title wrapping around.
* CALayer: text layer for song title, text layer for health kit data drawn on UIImage.
* MessageUI: send email and text messages with image and text and error handling.
* SettingsAPI: custom app settings to choose textview background color and changes made in settings are reflected immediately in app.
* PersistenceAPI: File manager, User Defaults for whether first time app launch, for textview background preference.
* HealthKit: Read and write data from HealthKit of various data types.
* Date API: form date component and predicate. 
* EventKit: add reminder and event, location and time based alarm.
* UIDatePicker: both picking date for event table and for HealthKit data.
* VisualEffect: blur the rest of the view when pop over, added vibrancy and custom alpha. Also blurring effect with button layered onto on the last page during app first launch.
* Timer: my popover timer.
* Storyboard design: navigation in controller is used extensively.
* Controls API: Slider, label, button (custom image), segment control, text view are all used in user friendly fashion (disable button appropriately i.e. in timer, no cover up textfield/view with keyboard, tap out to dismiss etc.)
* Alert: Used extensively everywhere in app 

UIDesign
---
Very user friendly with extensive use of alerts and takes care of situations where the user has no Wi-Fi access or no photo sharing app installed.
Looks good on iPhone/iPod devices in all orientations, custom buttons, background etc.

Example Screenshots
---
![simulator screen shot - iphone 7 - 2018-06-05 at 01 04 28](https://user-images.githubusercontent.com/32280834/46501471-74224100-c7da-11e8-990d-a1ca821aea2d.png)

![simulator screen shot - iphone 7 - 2018-06-05 at 01 16 43](https://user-images.githubusercontent.com/32280834/46501495-89976b00-c7da-11e8-8e1a-c3b49097e16d.png)

![simulator screen shot - iphone 7 - 2018-06-04 at 21 34 35](https://user-images.githubusercontent.com/32280834/46501526-a6cc3980-c7da-11e8-83f8-29cd9b306b9b.png)
