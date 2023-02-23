/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller that selects an image and makes a prediction using Vision and Core ML.
*/

import UIKit
import CoreData

class MainViewController: UIViewController, UITextFieldDelegate {
    var firstRun = true

    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
    let imagePredictor = ImagePredictor()

    /// The largest number of predictions the main view controller displays the user.
    let predictionsToShow = 1
    var modelResults: [NSManagedObject] = []
    

    // MARK: Main storyboard outlets
    @IBOutlet weak var startupPrompts: UIStackView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var recommendationLabel: UILabel!
    @IBOutlet weak var logo: UIImageView!
    @IBOutlet weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
}



extension MainViewController {
    // MARK: Main storyboard actions
    /// The method the storyboard calls when the user one-finger taps the screen.

    @IBAction func buttonClick() {
        // Show options for the source picker only if the camera is available.
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            present(photoPicker, animated: false)
            return
        }

        present(cameraPicker, animated: false)
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension MainViewController {
    // MARK: Main storyboard updates
    /// Updates the storyboard's image view.
    /// - Parameter image: An image.
    func updateImage(_ image: UIImage) {
        DispatchQueue.main.async {
            self.imageView.image = image
        }
    }
    func save(severity: String, rec: String, time: String) {
        guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        // 1
        let managedContext =
        appDelegate.persistentContainer.viewContext
        
        // 2
        let entity =
        NSEntityDescription.entity(forEntityName: "ScanResult",
                                   in: managedContext)!
        
        let modresult = NSManagedObject(entity: entity,
                                        insertInto: managedContext)
        
        // 3
        modresult.setValue(severity, forKeyPath: "prediction")
        modresult.setValue(rec, forKeyPath: "recommendation")
        modresult.setValue(time, forKey: "time")
        modresult.setValue(textField.text, forKey: "patientname")
        
        // 4
        do {
            try managedContext.save()
            modelResults.append(modresult)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    /// Updates the storyboard's prediction label.
    /// - Parameter message: A prediction or message string.
    /// - Tag: updatePredictionLabel
    func updatePredictionLabel(_ message1: String, _ message2: String, _ message3: String) {
        DispatchQueue.main.async {
            self.predictionLabel.text = message1
            self.recommendationLabel.text = message2
        }
        if message3 != "Time..." {
            save(severity: message1, rec: message2, time: message3)
        }

        if firstRun {
            DispatchQueue.main.async {
                self.firstRun = false
                self.predictionLabel.superview?.isHidden = false
                self.startupPrompts.isHidden = true
                self.recommendationLabel.superview?.isHidden = false
                self.logo.isHidden = true
            }
        }
    }
    
    
    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
    /// - Parameter photo: A photo from the camera or photo library.
    func userSelectedPhoto(_ photo: UIImage) {
        updateImage(photo)
        updatePredictionLabel("Making predictions for the photo...", "Generating recommendations...", "Time...")

        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(photo)
        }
    }

}

extension MainViewController {
    // MARK: Image prediction methods
    /// Sends a photo to the Image Predictor to get a prediction of its content.
    /// - Parameter image: A photo.
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)","No recommendations.","No Time")
            return
        }

        let formattedPredictions = formatPredictions(predictions)[0].0

        let predictionString = formattedPredictions
        let recommendationString = formatPredictions(predictions)[0].1
        let timeString = formatPredictions(predictions)[0].2
        updatePredictionLabel(predictionString, recommendationString, timeString)
    }
    
    

    /// Converts a prediction's observations into human-readable strings.
    /// - Parameter observations: The classification observations from a Vision request.
    /// - Tag: formatPredictions
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [(String,String,String)] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [(String, String, String)] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification
            
            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }
            var sev = ""
            var treatment = ""
            if name == "0" {
                sev = "Clear"
                treatment = "No treatment necessary."
            }
            else if name == "1" {
                sev = "Almost Clear"
                treatment = "Benzoyl peroxide wash and/or a mild topical retinoid."
            }
            else if name == "2" {
                sev = "Mild"
                treatment = "Benzoyl peroxide wash and a topical retinoid."
            }
            else if name == "3" {
                sev = "Mild to Moderate"
                treatment = "Benzoyl peroxide wash and a stronger topical retinoid or a topical retinoid. Possible consideration of an oral antibiotic."
            }
            else if name == "4" {
                sev = "Moderate"
                treatment = "Benzoyl peroxide wash, topical treatment, and an oral antibiotic."
            }
            else if name == "5" {
                sev = "Moderate to Severe"
                treatment = "Benzoyl peroxide wash, topical treatment, and an oral antibiotic. Start considering Isotretinoin"
            }
            else if name == "6" {
                sev = "Severe"
                treatment = "Benzoyl peroxide wash, topical treatment, and an oral antibiotic. Recommend Isoretinoin."
            }
            else if name == "7" {
                sev = "More Severe"
                treatment = "Place on Isotretonin, along with Benzoyl peroxide wash, topical treatment, and an oral antibiotic. In very severe circumstances, start with lower dosage of Isotretinoin and add corticosteroids."
            }
            let dateFormatter = DateFormatter()
            let date = Date()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let time = dateFormatter.string(from: date)
            
            return ("Severity Level of: \(sev)",treatment, time)
            
            
            
            
            
            
            
            //            return "\(name) - \(prediction.confidencePercentage)"
        }

        return (topPredictions)
    }
}

 

