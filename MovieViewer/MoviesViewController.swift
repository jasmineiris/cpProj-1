//
//  MoviesViewController.swift
//  MovieViewer
//
//  Created by Jasmine Farrell on 1/5/16.
//  Copyright © 2016 Jasmine Farrell. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var networkErrorView: UIImageView!
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
        
        //network error display
        view.addSubview(networkErrorView)
        
        //search bar display
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        
        tableView.dataSource = self
        tableView.delegate = self
        
        //programatic instantiation refresh Controller
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "didRefresh", forControlEvents:
            .ValueChanged)
        tableView.insertSubview(refreshControl, atIndex: 0)
        
        networkRequest()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //search bar display
        if searchController.active && searchController.searchBar.text != "" {
            return filterMovies!.count
        }
        if let movies = movies {
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
        //filter data for search bar display
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
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        let low_resolution = "https://image.tmdb.org/t/p/w45" //low resolution image's address
        let high_resolution = "https://image.tmdb.org/t/p/original" //high resolution image's address

        if let posterPath = movie["poster_path"] as? String{
            
            let smallImage = NSURL(string: low_resolution + posterPath)
            let largeImage = NSURL(string: high_resolution + posterPath)
            let smallImageRequest = NSURLRequest(URL: smallImage!)
            let largeImageRequest = NSURLRequest(URL: largeImage!)
                
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
                    },
                    failure: { (request, response, error ) -> Void in
                        cell.posterView!.image = UIImage(named: "posterView")
                    })
                })
            },
            failure: {(request, response, error) -> Void in
                cell.posterView!.image = UIImage(named: "posterView")
            })
        } else if let posterPath = movie["poster_path"] as? String {
            
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
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                        
                            print(responseDictionary)
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.tableView.reloadData()
                            MBProgressHUD.hideHUDForView(self.view, animated: true)
                            self.refreshControl.endRefreshing()
                            self.networkErrorView.hidden = true
                    }
                } else {
                    
                    self.tableView.hidden = true
                    self.networkErrorView.hidden = false
                    self.view.bringSubviewToFront(self.networkErrorView)
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                    self.refreshControl.endRefreshing()
                    UIView.animateWithDuration(1.5, delay: 0.2, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                        self.networkErrorView.alpha = 1.0
                        }, completion: {
                            (finished: Bool) -> Void in
                            UIView.animateWithDuration(1.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                                self.networkErrorView.alpha = 0.0
                                }, completion: nil)
                    })
                    
                    self.tableView.hidden = false
                    print("Network error")
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
