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
//import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var networkLabel: UIImageView!
    @IBOutlet weak var tableView: UITableView!

    
    var movies: [NSDictionary]?
    var filterMovies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    
    //search bar display
    var searchController = UISearchController(searchResultsController: nil)
    
    //search bar display
    @IBAction func resultsButton(sender: AnyObject) {
        
        self.presentViewController(searchController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //search bar display
        
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        //searchController.searchBar.backgroundColor = [UIColor: Black]
        searchController.searchResultsUpdater = self

        
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
    
    
    func roundFloat(value: Float) -> Float {
        return roundf(value * 100) / 100
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.active && searchController.searchBar.text != "" {
            return filterMovies!.count
        }
        if let movies = movies {
            //return filterMovies!.count
            return movies.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //table view function that runs when an item is selected
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        print("item selected")
        print(indexPath)
        
    
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "all") {
        filterMovies = movies!.filter { mov in return mov["title"]!.lowercaseString.containsString(searchText.lowercaseString)
        }
        
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        
        var movie = movies![indexPath.row]
        
        if searchController.active && searchController.searchBar.text != "" {
            movie = filterMovies![indexPath.row]
        }
        
        let title = movie["title"] as? String
        let overview = movie["overview"] as? String
        let rating = String(format: " %.2f /10", movie["vote_average"] as! Float)
        
        cell.ratingLabel.text = rating
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.getMoreData(movie["id"] as! Int)
        
        let imageUrl = "https://i.imgur.com/tGbaZCY.jpg"
        let baseURL = "http://image.tmdb.org/t/p/w500"
        
        let low_resolution = "https://image.tmdb.org/t/p/w45"
        let high_resolution = "https://image.tmdb.org/t/p/original"
        let imageRequest = NSURLRequest(URL: NSURL(string: imageUrl)!)
        if let posterPath = movie["poster_path"] as? String{
            
            let smallImage = NSURL(string: low_resolution + posterPath)
            let largeImage = NSURL(string: high_resolution + posterPath)
            let smallImageRequest = NSURLRequest(URL: smallImage!)
            let largeImageRequest = NSURLRequest(URL: largeImage!)
        
        func loadLowResolutionThenLargerImages(smallImageRequest: NSURLRequest,
            largeImageRequest: NSURLRequest, poster: UIImageView?) {
                
                cell.posterView!.setImageWithURLRequest(smallImageRequest,
                    placeholderImage: nil ,
                    success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                        cell.posterView!.alpha = 0.0
                        cell.posterView!.image = smallImage
                
                        
                        UIView.animateWithDuration(0.3, animations: { cell.posterView!.alpha = 1.0 },
                            completion: { (success) -> Void in
                                
                                cell.posterView!.setImageWithURLRequest(largeImageRequest,
                                    placeholderImage: smallImage,
                                    success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                        cell.posterView!.image = largeImage
                                    }, failure: { (request, response, error ) -> Void in
                                        cell.posterView!.image = UIImage(named: "posterView")
                                })
                            }
                        )
                    }, failure: {(request, response, error) -> Void in
                        cell.posterView!.image = UIImage(named: "posterView")
                    }
                )
        }
        
        cell.posterView.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse != nil {
                    //print("Image was NOT cached, fade in image")
                    cell.posterView.alpha = 0.0
                    cell.posterView.image = image
                    UIView.animateWithDuration( 0.8, animations: { () -> Void in
                        cell.posterView.alpha = 1.0
                    })
                } else {
                    //print("Image was cached so just update the image")
                    cell.posterView.image = image
                }
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        }
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
                            print(responseDictionary)
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            //print(self.movies![1]["title"])
                            self.tableView.reloadData()
                            
                            PKHUD.sharedHUD.hide()
                            self.refreshControl.endRefreshing()
                            self.networkLabel.hidden = true
                    }
                } else {
                    self.networkLabel.hidden = false
                    print("Network error")
                    self.refreshControl.endRefreshing()
                }
        });
        task.resume()
        
    }
    
    func didRefresh() {
        networkRequest()
    }    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "detailView" {
            print("detail segue called")
            let cell = sender as! UITableViewCell
            let indexPath = tableView.indexPathForCell(cell)
            
            var movie = movies![indexPath!.row]
            if searchController.active {
                movie = filterMovies![indexPath!.row]
            }
            
            let detailViewController = segue.destinationViewController as! DetailViewController
            detailViewController.movie = movie
            
            searchController.active = false
            
        } else if segue.identifier == "gridView" {
            let gridViewController = segue.destinationViewController as! CollectionViewController
            gridViewController.endpoint = endpoint
        }
    }

}
extension MoviesViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}


// MARK: - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation

