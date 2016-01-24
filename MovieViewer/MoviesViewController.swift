//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Jasmine Farrell on 1/5/16.
//  Copyright © 2016 Jasmine Farrell. All rights reserved.
//

import UIKit
import AFNetworking
import PKHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    
    
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    var searchController = UISearchController(searchResultsController: nil)
    
    @IBAction func resultsButton(sender: AnyObject) {
        
        self.presentViewController(searchController, animated: true, completion: nil)
            
        print("search")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.hidesNavigationBarDuringPresentation = false
        
        tableView.dataSource = self
        tableView.delegate = self
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "didRefresh", forControlEvents:
            .ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        networkRequest()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let movies = movies {
            
            return movies.count
            
        } else {
            
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = movies![indexPath.row]
        let title = movie["title"] as? String
        let overview = movie["overview"] as? String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        
        let imageUrl = "https://i.imgur.com/tGbaZCY.jpg"
        let imageRequest = NSURLRequest(URL: NSURL(string: imageUrl)!)
        
        cell.posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animateWithDuration( 0.8, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        
        if let posterPath = movie["poster_path"] as? String {
        let posterURL = NSURL(string: baseURL + posterPath)
        cell.posterView.setImageWithURL(posterURL!)
        }
        
        return cell
    }
        
        func networkRequest() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
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
                            
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            //print(self.movies![1]["title"])
                            self.tableView.reloadData()
                            
                            PKHUD.sharedHUD.hide()
                            self.refreshControl.endRefreshing()
                    }
                } else {
                    
                    print("There was a network error")
                }
        });
        task.resume()
        
    }
    
    func didRefresh() {
        networkRequest()
    }
    
    /*func delay(delay:Double, closure:() ->()) {
        dispatch_after( dispatch_time( DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue(), closure)
    }
    
    func onRefresh() { delay(2, closure: { self.refreshControl.endRefreshing() })
    }
    */
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "detailView" {
            print("detail segue called")
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            let movie = movies![indexPath!.row]
        
            let detailViewController = segue.destinationViewController as! DetailViewController
            detailViewController.movie = movie
        
        
            print("detail segue called")
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
        } else if segue.identifier == "gridView" {
            let gridViewController = segue.destinationViewController as! CollectionViewController
            gridViewController.endpoint = endpoint
        }
    }
    

}

