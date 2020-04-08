/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE

import UIKit
import HomeKit

class HomeViewController: BaseCollectionViewController {
  var homes: [HMHome] = []
  
  // Add the homeManager
  let homeManager = HMHomeManager()
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    // Add HomeViewController as delegate to homeManager
    homeManager.delegate = self
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    title = "Homes"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(newHome(sender:)))
    
    // Add homes from homeManager
    addHomes(homeManager.homes)
    
    collectionView?.reloadData()
  }
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return homes.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! HomeCell
    cell.home = homes[indexPath.row]
    
    return cell
  }
  
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    
    let target = navigationController?.storyboard?.instantiateViewController(withIdentifier: "AccessoryViewController") as! AccessoryViewController
    target.home = homes[indexPath.row]
    navigationController?.pushViewController(target, animated: true)
  }
  
  @objc func newHome(sender: UIBarButtonItem) {
    showInputDialog { homeName, roomName in
      // Add new Home + Room
      // Call addHome(withName:completionHandler:) passing in the name of the home.
      self.homeManager.addHome(withName: homeName) { [weak self] home, error in
        guard let self = self else {
          return
        }

        // Verify there was no error while adding the home. If there was an error, simply print it out.
        if let error = error {
          print("Failed to add home: \(error.localizedDescription)")
        }

        // If you successfully created an HMHome, add a room to it using the name entered in the dialog.
        if let discoveredHome = home {
          discoveredHome.addRoom(withName: roomName) { _, error  in

            // If you successfully added a room, add the newly created home to the homes array and refresh the collection view.
            if let error = error {
              print("Failed to add room: \(error.localizedDescription)")
            } else {
              self.homes.append(discoveredHome)
              self.collectionView?.reloadData()
            }
          }
        }
      }
    }
  }
  
  func showInputDialog(_ handler: @escaping ((String, String) -> Void)) {
    let alertController = UIAlertController(title: "Create new Home?",
                                            message: "Enter the name of your new home and give it a Room",
                                            preferredStyle: .alert)
    
    let confirmAction = UIAlertAction(title: "Create", style: .default) { _ in
      guard let homeName = alertController.textFields?[0].text,
            let roomName = alertController.textFields?[1].text else {
        return
      }

      handler(homeName, roomName)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
    
    alertController.addTextField { textField in
      textField.placeholder = "Enter Home name"
    }
    alertController.addTextField { textField in
      textField.placeholder = "Enter Room name"
    }
    
    alertController.addAction(confirmAction)
    alertController.addAction(cancelAction)
    
    present(alertController, animated: true)
  }
  
  func addHomes(_ homes: [HMHome]) {
    self.homes.removeAll()
    for home in homes {
      self.homes.append(home)
    }
    collectionView?.reloadData()
  }
}

// Implement HMHomeManagerDelegate as extension on HomeViewController
extension HomeViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
  }
}

