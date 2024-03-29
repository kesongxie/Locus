//
//  TunesDetailsViewController.swift
//  Spottunes
//
//  Created by Xie kesong on 4/15/17.
//  Copyright © 2017 ___Spottunes___. All rights reserved.
//

import UIKit
import Parse

fileprivate let resueIden = "ListsCell"
fileprivate let playerViewSizeHeightFraction: CGFloat = 0.96
fileprivate let detailPlayerBackgroundMaxAlpha: CGFloat = 0.6

class TunesDetailsViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!{
        didSet{
            self.tableView.delegate = self
            self.tableView.dataSource = self
            self.tableView.estimatedRowHeight = self.tableView.rowHeight
            self.tableView.rowHeight = UITableViewAutomaticDimension
            self.tableView.backgroundColor = UIColor.clear
            let edge = UIEdgeInsets(top: self.headerOriginHeight - 20, left: 0, bottom: 44, right: 0)
            self.tableView.contentInset = edge
        }
    }
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerViewTopConstraint: NSLayoutConstraint!
    
    
    
    @IBOutlet weak var playerView: UIView!{
        didSet{
            let pan = UIPanGestureRecognizer(target: self, action: #selector(playerViewPanning(_:)))
            self.playerView.addGestureRecognizer(pan)
            self.playerView.isUserInteractionEnabled = true
            self.playerView.layer.cornerRadius = 8.0
            self.playerView.clipsToBounds = true
        }
    }

    @IBOutlet weak var playerViewCenterYConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var playerMinView: UIView!
    
    @IBOutlet weak var playerViewHeightConstraint: NSLayoutConstraint!{
        didSet{
            self.playerViewOriginalHeight = self.playerViewHeightConstraint.constant
        }
    }
    
    @IBOutlet weak var overlayView: UIView!
    
    
    @IBOutlet weak var playerDetailView: UIView!
    
    @IBOutlet weak var navigationBarView: UIView!{
        didSet{
            self.navigationBarView.alpha = 0
        }
    }

    @IBOutlet weak var navigationItemCustom: UINavigationItem!{
        didSet{
            self.navigationItemCustom.title = "GEISEL LIBRARY"
        }
    }

    @IBOutlet weak var navigationBar: UINavigationBar!{
        didSet{
            self.navigationBar.barTintColor = UIColor.white
            self.navigationBar.titleTextAttributes = App.Style.NavigationBar.titleTextAttribute
        }
    }
    
    @IBAction func shuffleBtnTapped(_ sender: UIButton) {
        let color = UIColor(hexString: "#D0A021")
        sender.imageBtnActivateWithColor(color: color)
    }
    
    
    @IBAction func likeBtnTapped(_ sender: UIButton) {
        let color = UIColor(hexString: "#B70C1F")
        sender.imageBtnActivateWithColor(color: color)
    }
    
    
    @IBAction func playBtnTapped(_ sender: UIButton) {
//        let color = UIColor(hexString: "#0F53B6")
        let color = UIColor(red: 20 / 255.0, green: 20 / 255.0, blue: 20 / 255.0, alpha: 1)
        let image = #imageLiteral(resourceName: "playing-icon")
        sender.imageBtnActivateWithColor(color: color, usingImage: image)

    }
    
    
    //min player
    @IBOutlet weak var playingSongNameLabel: UILabel!
    @IBOutlet weak var playingSongAuthorLabel: UILabel!
    
    var playerViewOriginalHeight: CGFloat!
    var currentPlayingList: Playlist?
    
    //defines the hidden or minimized position of the playerview
    var playerViewOriginalCenterY: CGFloat!
    
    //defines the open or maximized position of the playerview
    var playerViewOpenOriginalCenterY: CGFloat!
    
    
    var topLists = [Playlist](){
        didSet{
            self.tableView.reloadData()
        }
    }
    
    //set the header height the same as the screen width
    var headerOriginHeight: CGFloat = App.screenWidth
    var statusBarStyle: UIStatusBarStyle = .lightContent
    var playerViewMarginTop:CGFloat{
        return UIScreen.main.bounds.size.height - playerViewHeight
    }
    
    
    private var isPlayerViewDetailRevealed = false
    private let playerViewHeight = 0.9 * UIScreen.main.bounds.size.height
    
    
    //player for playign music
    lazy var streamController: SPTAudioStreamingController = SPTAudioStreamingController.sharedInstance()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //init the player
        
        //update the UI
        self.playerViewCenterYConstraint.constant = UIScreen.main.bounds.size.height - self.playerMinView.frame.size.height - (1 - playerViewSizeHeightFraction) *  UIScreen.main.bounds.size.height / 2
        self.playerViewOriginalCenterY = self.playerViewCenterYConstraint.constant
        self.navigationController?.isNavigationBarHidden = true
        
        self.updatePlayerView()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.headerViewHeightConstraint.constant = self.headerOriginHeight
        self.headerOriginHeight =  self.headerViewHeightConstraint.constant
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       // self.animateZoomHeader()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
   
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return self.statusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    
    @IBOutlet weak var progressTrack: UIProgressView!
    
    
    
    func playerViewPanning(_ gesture: UIPanGestureRecognizer){
        let translationY = gesture.translation(in: nil).y
        var beginCenter: CGPoint = CGPoint(x: 0, y: 0)
        switch gesture.state{
        case .began:
            beginCenter = self.playerView.center
        case .changed:
            if  !self.isPlayerViewDetailRevealed {
                self.playerViewCenterYConstraint.constant =  min(max(self.playerViewMarginTop, self.playerViewOriginalCenterY + translationY), self.playerViewOriginalCenterY)
                let fadeOutAlpha = max(0, 1 + translationY / 100)
                self.playerMinView.alpha = fadeOutAlpha
                self.progressTrack.alpha = fadeOutAlpha
                self.overlayView.isHidden = false
                self.playerDetailView.alpha = max(1, self.playerViewMarginTop / self.playerViewCenterYConstraint.constant * 1.2) //speed up the process
                self.overlayView.alpha =  min(detailPlayerBackgroundMaxAlpha, self.playerViewMarginTop / self.playerViewCenterYConstraint.constant)
            }else{
                 self.playerViewCenterYConstraint.constant = max(self.playerViewMarginTop, beginCenter.y + translationY)
//                print( self.playerViewCenterYConstraint.constant)
//                let fadeInAlpha = self.playerViewCenterYConstraint.constant / self.playerViewOriginalCenterY
//                self.playerMinView.alpha = fadeInAlpha
//                self.progressTrack.alpha = fadeInAlpha
//                self.playerDetailView.alpha = 1 - fadeInAlpha
//                self.overlayView.alpha = max(0, max(0.6, 1 - fadeInAlpha))
            }
        case .ended:
            if  !self.isPlayerViewDetailRevealed {
                var destinationAlpha: CGFloat = 0
                var playerViewAlpha: CGFloat = 0
                var shouldPlayerMaximize = true
                if self.playerViewOriginalCenterY - self.playerViewCenterYConstraint.constant < 80 {
                    self.playerViewCenterYConstraint.constant =  self.playerViewOriginalCenterY
                    shouldPlayerMaximize = false
                    destinationAlpha = 1
                }else{
                    self.playerViewCenterYConstraint.constant = self.playerViewMarginTop
                    playerViewAlpha = detailPlayerBackgroundMaxAlpha
                }
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    self.playerMinView.alpha = destinationAlpha
                    self.progressTrack.alpha = destinationAlpha
                    self.playerDetailView.alpha = 1 - destinationAlpha
                    self.overlayView.alpha = playerViewAlpha
                }, completion: {
                    finished in
                    if finished{
                        if shouldPlayerMaximize{
                            self.isPlayerViewDetailRevealed = true
                            self.playerViewOpenOriginalCenterY = self.playerViewCenterYConstraint.constant
                        }else{
                            self.overlayView.isHidden = true
                            self.isPlayerViewDetailRevealed = false
                        }
                    }
                })
            }else{
                var destinationAlpha: CGFloat = 0
                var shouldPlayerMinimize = true
                if  self.playerViewCenterYConstraint.constant - self.playerViewOpenOriginalCenterY < 80 {
                    self.playerViewCenterYConstraint.constant = self.playerViewMarginTop
                    shouldPlayerMinimize = false
                }else{
                    self.playerViewCenterYConstraint.constant =  self.playerViewOriginalCenterY
                    destinationAlpha = 1
                }
                UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                    self.playerMinView.alpha = destinationAlpha
                    self.progressTrack.alpha = destinationAlpha
                    self.playerDetailView.alpha = 1 - destinationAlpha
                    self.overlayView.alpha = 0
                }, completion: {
                    finished in
                    if finished{
                        if shouldPlayerMinimize{
                            self.isPlayerViewDetailRevealed = false
                        }else{
                            self.overlayView.isHidden = true
                            self.isPlayerViewDetailRevealed = true
                        }
                    }
                })
            }
        default:
            break
        }
        
        
        
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //adjust heaer when scrollView is global self.tableView
        let adjustOffset = scrollView.contentOffset.y + headerOriginHeight
        if adjustOffset <= 0{
            self.headerViewTopConstraint.constant = 0
            self.headerViewHeightConstraint.constant = -scrollView.contentOffset.y
        }else{
            self.headerViewTopConstraint.constant = -adjustOffset * 0.6 //create a parallax effect for the header
            var shouldSetStatusBarStyleDefault = false
            let diff = adjustOffset - (self.headerOriginHeight - self.navigationBarView.frame.size.height)
            
            if diff > 0{
                self.navigationBarView.alpha = min(1, diff * 0.04)
                if self.navigationBarView.alpha > 0.2{
                    self.statusBarStyle = .default
                    shouldSetStatusBarStyleDefault = true
                }
            }else{
                self.navigationBarView.alpha = 0
            }
            
            //adjust the status bar style
            if !shouldSetStatusBarStyleDefault{
                self.statusBarStyle = .lightContent
            }
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    
    func updatePlayerView(){
//        self.playingSongNameLabel.text = App.delegate?.songPlaying?.name
//        self.playingSongAuthorLabel.text = App.delegate?.songPlaying?.author
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension TunesDetailsViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.topLists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: resueIden, for: indexPath) as! ListTableViewCell
        cell.item = self.topLists[indexPath.row]
        return cell
    }
}


