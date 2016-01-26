//
//  CollectionViewController.swift
//  MovieViewer
//
//  Created by Jasmine Farrell on 1/21/16.
//  Copyright © 2016 Jasmine Farrell. All rights reserved.
//

import UIKit
import AFNetworking
import PKHUD

class CollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var movies: [NSDictionary]?
    var filterMovies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    //search bar display
    var searchController = UISearchController(searchResultsController: nil)
    
    //search bar display
    @IBAction func resultsButtonSecond(sender: AnyObject) {
        self.presentViewController(searchController, animated: true, completion: nil)
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //search bar display
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        
        searchController.searchResultsUpdater = self
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        PKHUD.sharedHUD.contentView = PKHUDProgressView()
        PKHUD.sharedHUD.show()
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "didRefresh", forControlEvents:
            .ValueChanged)
        collectionView.insertSubview(refreshControl, atIndex: 0)
        
        networkRequest()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        if searchController.active && searchController.searchBar.text != "" {
            return filterMovies!.count
        }
        if let movies = movies {
            return movies.count
        } else {
            return 0
        }
        
    }

    
    func filterContentForSearchText(searchText: String, scope: String = "all") {
        filterMovies = movies!.filter { mov in return mov["title"]!.lowercaseString.containsString(searchText.lowercaseString)
        }
        
        collectionView.reloadData()
    }

    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell: CollectionViewCell = collectionView.dequeueReusableCellWithReuseIdentifier("MoviesCollectionCells", forIndexPath: indexPath) as! CollectionViewCell
        var movie = movies![indexPath.row]
        if searchController.active && searchController.searchBar.text != "" {
            movie = filterMovies![indexPath.row]
        }
        
        let baseURL = "http://image.tmdb.org/t/p/w500"
        let imageUrl = "https://i.imgur.com/tGbaZCY.jpg"
        let imageRequest = NSURLRequest(URL: NSURL(string: imageUrl)!)
        
        
        let low_resolution = "https://image.tmdb.org/t/p/w45"       //low resolution image's address
        let high_resolution = "https://image.tmdb.org/t/p/original" //high resolution image's address
        let posterPath = movie["poster_path"] as! String?
        let smallImage = NSURL(string: low_resolution + posterPath!)
        let largeImage = NSURL(string: high_resolution + posterPath!)
        
        let smallImageRequest = NSURLRequest(URL: smallImage!)
        let largeImageRequest = NSURLRequest(URL: largeImage!)
        
        func loadLowResolutionThenLargerImages(smallImageRequest: NSURLRequest,
            largeImageRequest: NSURLRequest, poster: UIImageView?) {
                
                cell.imageCell.setImageWithURLRequest(smallImageRequest,
                    placeholderImage: nil ,
                    success: { (smallImageRequest, smallImageResponse, smallImage) -> Void in
                        cell.imageCell!.alpha = 0.0
                        cell.imageCell!.image = smallImage
                     
                        
                        UIView.animateWithDuration(0.3, animations: { cell.imageCell!.alpha = 1.0 },
                            completion: { (success) -> Void in
                                cell.imageCell!.setImageWithURLRequest(largeImageRequest,
                                    placeholderImage: smallImage,
                                    success: { (largeImageRequest, largeImageResponse, largeImage) -> Void in
                                        cell.imageCell!.image = largeImage
                                    }, failure: { (request, response, error ) -> Void in
                                        cell.imageCell!.image = UIImage(named: "posterView")
                                })
                            }
                        )
                    }, failure: {(request, response, error) -> Void in
                        cell.imageCell!.image = UIImage(named: "posterView")
                    }
                )
        }

        
        cell.imageCell.setImageWithURLRequest(
            imageRequest,
            placeholderImage: nil,
            success: { (imageRequest, imageResponse, image) -> Void in
                
                // imageResponse will be nil if the image is cached
                if imageResponse == nil {
                    print("Image was NOT cached, fade in image")
                    cell.imageCell.alpha = 0.0
                    cell.imageCell.image = image
                    UIView.animateWithDuration( 2, animations: { () -> Void in
                        cell.imageCell.alpha = 1.0
                    })
                } else {
                    print("Image was cached so just update the image")
                    cell.imageCell.image = image
                }
            },
            failure: { (imageRequest, imageResponse, error) -> Void in
                // do something for the failure condition
        })
        
        if let posterPath = movie["poster_path"] as? String {
            let posterURL = NSURL(string: baseURL + posterPath)
            cell.imageCell.setImageWithURL(posterURL!)
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
                            self.collectionView.reloadData()
                            
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
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "detailView" {
            print("detail segue called")
            let cell = sender as! UICollectionViewCell
            let indexPath = collectionView.indexPathForCell(cell)
            let movie = movies![indexPath!.row]
            
            let detailViewController = segue.destinationViewController as! DetailViewController
            detailViewController.movie = movie
            
            
            print("detail segue called")
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
        } 
    }

}
extension CollectionViewController: UISearchResultsUpdating {
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

