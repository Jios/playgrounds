/*
 
 Date: 7/23/18
 
 PolyMapView class:
 -----------------
 * goal:
    * demonstrate a shape drawing feature on the map view
 
 * how to use:
    * run the playground file
    * wait until the map view shown up on the live view
    * long press on the map view to start drawing
    * note 1: coordinates of a drawn shape are printed on the Console view
    * note 2: repeating step 3 will erase the previous drawn shape and create a new one
 */



import MapKit
import PlaygroundSupport



class PolyMapView: UIView, MKMapViewDelegate {
    
    // MARK: - # variable/constant
    
    private lazy var mapView: MKMapView = {
        let mView = MKMapView(frame: frame)
        mView.delegate = self
        
        return mView
    }()
    
    private var polygonCoordinates = [CLLocationCoordinate2D]()
    private let serialQueue = DispatchQueue(label: "com.polyMapView.serialQueue")
    
    
    // MARK: - # view
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(mapView)
        
        // gesture
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(_:)))
        self.addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // MARK: - # MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.red
            renderer.lineWidth = 2
            return renderer
        } else if overlay is MKPolygon {
            let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.3)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        
        return MKOverlayRenderer()
    }
    
    
    // MARK: - # guesture
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            serialQueue.sync { [weak self] in
                guard let strongSelf = self else { return }
                
                print("* gesture began")
                
                strongSelf.mapView.isScrollEnabled = false
                strongSelf.polygonCoordinates.removeAll()
                
                DispatchQueue.main.async {
                    strongSelf.mapView.removeOverlays(strongSelf.mapView.overlays)
                    strongSelf.mapView.removeAnnotations(strongSelf.mapView.annotations)
                }
            }
        case .changed:
            serialQueue.sync { [weak self] in
                guard let strongSelf = self else { return }
                
                let touchLocation = gesture.location(in: strongSelf.mapView)
                let coordinate = strongSelf.mapView.convert(touchLocation, toCoordinateFrom: strongSelf.mapView)
                
                strongSelf.polygonCoordinates.append(coordinate)
                
                let polyline = MKPolyline(coordinates: strongSelf.polygonCoordinates, count: strongSelf.polygonCoordinates.count)
                
                print("\(strongSelf.polygonCoordinates.count): (\(coordinate.latitude), \(coordinate.longitude))")
                
                DispatchQueue.main.async {
                    strongSelf.mapView.addOverlay(polyline)
                }
            }
        case .ended:
            serialQueue.sync { [weak self] in
                guard let strongSelf = self else { return }
                
                print("* gesture ended")
                
                let polygon = MKPolygon(coordinates: strongSelf.polygonCoordinates, count: strongSelf.polygonCoordinates.count)
                
                DispatchQueue.main.async {
                    strongSelf.mapView.addOverlay(polygon)
                    strongSelf.mapView.isScrollEnabled = true
                }
            }
        default:
            print(" default")
        }
    }

    
    // MARK: - # map
    
    func setMapRegion(_ region: MKCoordinateRegion, animated: Bool) {
        mapView.setRegion(region, animated: animated)
    }
}



let mapView = PolyMapView(frame: CGRect(x:0, y:0, width:800, height:1600))

// zoom to Manhattan
let coordinate = CLLocationCoordinate2DMake(40.758896, -73.985130)
let mapRegionSpan = 0.12
var mapRegion = MKCoordinateRegion()
mapRegion.center = coordinate
mapRegion.span.latitudeDelta = mapRegionSpan
mapRegion.span.longitudeDelta = mapRegionSpan

mapView.setMapRegion(mapRegion, animated: true)


// Playground Live View
PlaygroundPage.current.liveView = mapView




