//
//  ViewController.swift
//  TestProj
//
//  Created by c7121 on 18/03/2020.
//  Copyright © 2020 alhamrani. All rights reserved.
//

import UIKit
import MapKit
import FacebookLogin
import CoreLocation
import FBSDKCoreKit

class ViewController: UIViewController,MKMapViewDelegate,UIGestureRecognizerDelegate {

    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var labelTapMap: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    var FROMLAT : Double = 54.689460
    var FROMLONG : Double = 25.279860
    
    var TOLAT : Double = 59.442692
    var TOLONG : Double = 24.753201
    
    var FROM_ROUTE = "VILNIUS,LITHUNA"
    var TO_ROUTE = "TALLIN,ESTONIA"
    
    var token  :  String = ""

    @IBOutlet var tapGesture: UITapGestureRecognizer!
    
    var locManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        authorizeLocation()
        checkFBLogin()
        
        tapGesture.delegate = self
        // Do any additional setup after loading the view.
       
               mapView.delegate = self
        
               
               let sourceLocation = CLLocationCoordinate2D(latitude: FROMLAT, longitude: FROMLONG)
               let destinationLocation = CLLocationCoordinate2D(latitude: TOLAT, longitude: TOLONG)
 
               let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
               let destinationPlacemark = MKPlacemark(coordinate: destinationLocation, addressDictionary: nil)
               
      
               let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
               let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
               
     
               let sourceAnnotation = MKPointAnnotation()
               sourceAnnotation.title = FROM_ROUTE
               
               if let location = sourcePlacemark.location {
                   sourceAnnotation.coordinate = location.coordinate
               }
               
               
               let destinationAnnotation = MKPointAnnotation()
               destinationAnnotation.title = TO_ROUTE
               
               if let location = destinationPlacemark.location {
                   destinationAnnotation.coordinate = location.coordinate
               }
               
             
               self.mapView.showAnnotations([sourceAnnotation,destinationAnnotation], animated: true )
               
    
        let directionRequest = MKDirections.Request()
               directionRequest.source = sourceMapItem
               directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
               
              
               let directions = MKDirections(request: directionRequest)
               
               
        directions.calculate {
                   (response, error) -> Void in
                   
                   guard let response = response else {
                       if let error = error {
                           print("Error: \(error)")
                       }
                       
                       return
                   }
                   
                   let route = response.routes[0]
            self.mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
                   let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        
        }
    }
    
    func checkFBLogin(){
        if (AccessToken.current != nil) {
          self.facebookButton.isHidden  = true
        }
    }
 
    
    @IBAction func onTapMap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended{
              
            let region =  mapView.convert(mapView.annotationVisibleRect, toRegionFrom: mapView)
            mapView.region  = region
            
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "Restaurants"
            request.region = mapView.region
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response else {
                    print("There was an error searching for: \(request.naturalLanguageQuery) error: \(error)")
                    return
                }
                
                var places = [MKAnnotation]()
              
                for item in response.mapItems { // add pin every restaurant
                  
                  
                    let placemark = item.placemark
                   
                    let sourceLocation = CLLocationCoordinate2D(latitude:  placemark.coordinate.latitude, longitude:  placemark.coordinate.longitude)
                    
                    let sourcePlacemark = MKPlacemark(coordinate: sourceLocation, addressDictionary: nil)
                
                    
                    let sourceAnnotation = MKPointAnnotation()
                     sourceAnnotation.title = item.name
                
                    
                    if let location = sourcePlacemark.location {
                        sourceAnnotation.coordinate = location.coordinate
                    }
                    places.append(sourceAnnotation)
                   
                   
                }
                var count = String(response.mapItems.count)
                self.labelTapMap.text = "FOUND "+count+" RESTAURANTS"
                 self.mapView.showAnnotations(places, animated: true )
            }
       
         }
    }
    
    func authorizeLocation(){
         locManager = CLLocationManager()
        
      let authorizationStatus = CLLocationManager.authorizationStatus()
        if (authorizationStatus == CLAuthorizationStatus.notDetermined) || (authorizationStatus == nil) {
               locManager.requestWhenInUseAuthorization()
           } else {
               locManager.startUpdatingLocation()
           }
    }

    
    @IBAction func facebookLogin(_ sender: Any) {
                
        LoginManager().logIn(permissions: ["public_profile", "email"], from: self) { (result, error) in
          if let error = error {
            print("Failed to login: \(error.localizedDescription)")
            return
          }
            guard let accessToken = AccessToken.current else {
            print("Failed to get access token")
            return
          }
            self.facebookButton.isHidden  = true
            self.token = accessToken.tokenString
    }
    }
    // triggered from delegate onrender
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 4.0
    
            return renderer
        }
    
    // triggered when restuarant is selected
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView){
     
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
           let centerField  = "\(numberFormatter.string(for: view.annotation?.coordinate.latitude)!),\(numberFormatter.string(for: view.annotation?.coordinate.longitude)!)"

        GraphRequest(
            graphPath: "search",
            parameters: ["type":"place", "center": centerField,  "fields": "name, location"]).start(completionHandler:
                { (connection, result, error) in

                   if let error = error {
                       print("Error fetching restaurants" ,error)
                       return
                   } //  query result


                    if let result = result as? NSDictionary {
                        if let allPlacesData = result["data"] as? [NSDictionary] {
                              print("allPlacesData",allPlacesData)
                        }
                    }

                }
            )
                    
    }
}
    


    





