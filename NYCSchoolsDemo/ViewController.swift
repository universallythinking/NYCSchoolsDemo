//
//  ViewController.swift
//  NYCSchoolsDemo
//
//  Created by Benjamin Barnett on 5/8/20.
//  Copyright © 2020 Benjamin Barnett. All rights reserved.
//

import UIKit
import SwiftyJSON


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var message: String = ""
    var name: String = ""
    var schoolList: String? = nil
    var schoolData = [String]()
    var schools = [String]()
    var timer: Timer? = nil
    
    private var schoolTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchSchools{_ in
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewScore(school: self.schoolData[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.schools.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath as IndexPath)
        cell.textLabel!.text = "\(self.schools[indexPath.row])"
        return cell
    }
    
    func fetchSchools(completionHandler: @escaping ([String]) -> Void) {
        let url = URL(string: "https://data.cityofnewyork.us/resource/s3k6-pzi2.json")!
        
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            self.schoolList = String(data: data, encoding: .utf8)!
            if let schoolArray = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] {
                for object in schoolArray! {
                    let name = object["school_name"]
                    let uid = object["dbn"]
                    self.schoolData.append(uid as! String)
                    self.schools.append(name as! String)
                }
            }
        }
        task.resume()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.addSchoolsToView), userInfo: nil, repeats: true)
    }

    @objc func addSchoolsToView() {
        if(self.schoolData.count > 1) {
            timer?.invalidate()
            let barHeight: CGFloat = UIApplication.shared.statusBarFrame.size.height
            let displayWidth: CGFloat = self.view.frame.width
            let displayHeight: CGFloat = self.view.frame.height
            
            schoolTableView = UITableView(frame: CGRect(x: 0, y: barHeight, width: displayWidth, height: displayHeight - barHeight))
            schoolTableView.register(UITableViewCell.self, forCellReuseIdentifier: "MyCell")
            schoolTableView.dataSource = self
            schoolTableView.delegate = self
            self.view.addSubview(schoolTableView)
        }
    }
    
    func constructMessage(takers: String, mathScore: String, readingScore: String, writingScore: String) {
        self.message = "You selected " + self.name + ". This school had a total of "
        self.message = self.message + takers + " SAT Takers with an average Math Score of "
        self.message = self.message + mathScore + ", an average Reading Score of "
        self.message = self.message + readingScore + " and an average Writing Score of "
        self.message = self.message + writingScore + "."
    }
    
    func viewScore(school: String) {
        let url = URL(string: "https://data.cityofnewyork.us/resource/f9bf-2cp4.json?DBN=" + school)!
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return }
            if let schoolResults = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] {
                for object in schoolResults! {
                    self.name = object["school_name"] as! String
                    self.constructMessage(takers: object["num_of_sat_test_takers"] as! String, mathScore: object["sat_math_avg_score"] as! String, readingScore: object["sat_critical_reading_avg_score"] as! String, writingScore: object["sat_writing_avg_score"] as! String)
                }
                if (schoolResults?.count == 0) {
                    self.name = "Error"
                    self.message = "There is no data for the selected school..."
                }
            }
        }
        task.resume()
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.showAlert), userInfo: nil, repeats: true)
    }
    
    @objc func showAlert() {
        if (self.message.count > 0) {
            timer?.invalidate()
            let alert = UIAlertController(title: self.name, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                case .cancel:
                    print("cancel")
                case .destructive:
                    print("destructive")
                }
            }))
            self.present(alert, animated: true, completion: nil)
            self.message = ""
            self.name = ""
        }
    }
}

