//
//  DetailViewController.swift
//  MovieViewer
//
//  Created by Jasmine Farrell on 1/17/16.
//  Copyright © 2016 Jasmine Farrell. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    var movie: NSDictionary!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: infoView.frame.origin.y + infoView.frame.size.height)
        scrollView.autoresizingMask = .FlexibleHeight
        
        let title = movie["title"] as? String
        titleLabel.text = title
        
        let overview = movie["overview"]
        overviewLabel.text = overview as? String
        
        ratingLabel.text = movie["vote_average"]!.stringValue + " / 10"
        
        overviewLabel.sizeToFit()
        
     //   let time = movieInfo["runtime"] as? Int
        
        //var time = movie["runtime"]!.integerValue!;
        
        let releaseDate = movie["release_date"] as! String
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.dateFromString(releaseDate)
        dateFormatter.dateFormat = "MM.dd.yy"
        let dateText = dateFormatter.stringFromDate(date!)
        releaseDateLabel.text = dateText
        
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        
        if let posterPath = movie["poster_path"] as? String {
            
            let posterURL = NSURL(string: baseURL + posterPath)
            posterImageView.setImageWithURL(posterURL!)
        }


        // Do any additional setup after loading the view.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
