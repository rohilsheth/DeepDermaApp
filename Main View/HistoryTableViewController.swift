//
//  HistoryTableViewController.swift
//  DeepDerma
//
//  Created by Rohil Sheth on 2/20/23.
//  Copyright © 2023 Apple. All rights reserved.
//

import UIKit
import CoreData

class HistoryTableViewController: UITableViewController {
    var modelResults: [NSFetchRequestResult] = []
    var numPatientsMO: [NSManagedObject] = []
    var uniqueValuesCount = 0
    var patientNames: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
    }
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
      
      //1
      guard let appDelegate =
        UIApplication.shared.delegate as? AppDelegate else {
          return
      }
      
      let managedContext =
        appDelegate.persistentContainer.viewContext
      
      //2
        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: "ScanResult")
        fetchRequest2.resultType = .dictionaryResultType
        fetchRequest2.propertiesToFetch = ["patientname"]
        fetchRequest2.returnsDistinctResults = true
        
      if let results = try? managedContext.fetch(fetchRequest2) as? [[String:Any]] {
          patientNames = results.compactMap({ $0["patientname"] as? String })
          tableView.reloadData()
      }
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return patientNames.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {fatalError("Unable to get app delegate")}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<ScanResult>(entityName: "ScanResult")
        fetchRequest.predicate = NSPredicate(format: "patientname == %@", patientNames[section])
        let results = try? managedContext.fetch(fetchRequest)
        return results?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "modelResult", for: indexPath)
        // Configure the cell...
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {fatalError("Unable to get app delegate")}
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<ScanResult>(entityName: "ScanResult")
        fetchRequest.predicate = NSPredicate(format: "patientname == %@", patientNames[indexPath.section])
        fetchRequest.fetchLimit = 1
        fetchRequest.fetchOffset = indexPath.row
        if let result = try? managedContext.fetch(fetchRequest).first {
            cell.textLabel?.text = result.time
            cell.detailTextLabel?.text = result.prediction
        }

        return cell
    }
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return patientNames[section]
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
