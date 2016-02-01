//
//  MovieCell.swift
//  MovieViewer
//
//  Created by Jasmine Farrell on 1/21/16.
//  Copyright © 2016 Jasmine Farrell. All rights reserved.
//

import UIKit

class MovieCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var overviewLabel: UILabel!
    
    @IBOutlet weak var ratingLabel: UILabel!
    
    @IBOutlet weak var posterView: UIImageView!
    
    @IBOutlet weak var genresLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func getMoreData(movieId : Int) -> String {
        var genres = [""]
        genres.removeAll()
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"http://api.themoviedb.org/3/movie/\(movieId)?api_key=\(apiKey)")
        print(url)
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            //NSLog("response: \(responseDictionary)")
                            
                            for genre in (responseDictionary["genres"] as? [NSDictionary])! {
                                genres.append(genre["name"] as! String)
                            }
                            self.genresLabel.text = genres.joinWithSeparator(", ")
                    }
                } else {
                    
                    print("There was a network error")
                }
        });
        print(genres)
        
        task.resume()
        return ""
    }

}
