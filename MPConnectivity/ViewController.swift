//
//  ViewController.swift
//  MPConnectivity
//
//  Created by Haitham Alkibsi on 4/11/19.
//  Copyright © 2019 Haitham Alkibsi. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, MCBrowserViewControllerDelegate, MCSessionDelegate {
    
    //MARK: Control Variables
    @IBOutlet weak var btnConnect: UIBarButtonItem!
    @IBOutlet weak var navItem: UINavigationItem!
    @IBOutlet weak var rockButton: UIImageView!
    @IBOutlet weak var paperButton: UIImageView!
    @IBOutlet weak var scissorsButton: UIImageView!
    @IBOutlet weak var playButton: UIImageView!
    @IBOutlet weak var opponentReadyLabel: UILabel!
    
    //MARK: Stat Variables
    @IBOutlet weak var winsCounterLabel: UILabel!
    var winsCounter = 0
    @IBOutlet weak var tiesCounterLabel: UILabel!
    var tiesCounter = 0
    @IBOutlet weak var lossesCounterLabel: UILabel!
    var lossesCounter = 0
    
    //MARK: Gameplay Variabels
    var userSelection = "nothingSelected"
    var opponentSelection = "nothingSelected"
    var userReady = false
    var opponentReady = false
    
    
    //MARK: MPC Variables 1-4
    // Four main building blocks of an MPC app
    var peerID : MCPeerID! // 1. The device ID/name as viewed by other browsing devices
    var session : MCSession! // 2. The 'connection' between devices
    var advertiser : MCAdvertiserAssistant! // 3. Helps in advertising ourself to nearby browsers
    var browser : MCBrowserViewController! // 4. Its a prebuilt VC that searches for nearby advertisers
    
    //MARK: Channel ID
    // Filters away advertisers that have another channel ID; browses relevant advertisers only.
    let serviceID : String = "rockpapersciss"
    
    //MARK: View Did Load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup MPC Objects -------------------------------------------------------------------------------------------------//
        // 1.0 setup peerID using the current device name
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        // 2.1 setup sesion using the peerID
        session = MCSession(peer: peerID)
        // 2.2 tell the delegate that all the required methods for it are located in this file (how delegates work)
        session.delegate = self
        
        // 3.1 setup advertiser
        // requires a sessionID and a serviceID or 'channel', which we have
        advertiser = MCAdvertiserAssistant(serviceType: serviceID, discoveryInfo: nil, session: session)
        // 3.2 start advertising immediately
        advertiser.start()
        
        // resize Navigation Title text to fit content better (swift 5)
        let navBarAttrs = [
            //NSAttributedString.Key.foregroundColor: UIColor.red, // if you want to change the color too
            NSAttributedString.Key.font: UIFont(name: "Helvetica-Bold", size: 12)!
        ]
        self.navigationController?.navigationBar.titleTextAttributes = navBarAttrs
        
        disablePlayButton()
        disablePlayingButtons()
    }
    
    
    //INFO: Since I'm using Auto-Layout I need to do my geometry after auto-constraints are finished.
    override func viewDidLayoutSubviews() {
        setView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        session.disconnect()
    }
    
    //MARK: Set Views
    
    func setView()
    {
        playButton.layer.cornerRadius = playButton.frame.size.height / 2
        rockButton.layer.cornerRadius = rockButton.frame.size.height / 2
        paperButton.layer.cornerRadius = paperButton.frame.size.height / 2
        scissorsButton.layer.cornerRadius = scissorsButton.frame.size.height / 2
    }
    
    //MARK: Play Button
    
    //INFO: Inform the opponent that the user is ready to play, if the opponent is already ready to play then start the sequence.
    @IBAction func playButtonTapped(_ sender: UITapGestureRecognizer) {
        userReady = true
        disablePlayButton()
        sendResponse(clientResponse: "play")
        
        rockButton.backgroundColor = UIColor.white
        paperButton.backgroundColor = UIColor.white
        scissorsButton.backgroundColor = UIColor.white
        
        if isGameReadyToStart()
        {
            startGame()
        }
    }
    
    
    
    //MARK: Playing Buttons
    
    //INFO: Inform the opponent that the user has tapped scissors.
    @IBAction func scissorsTapped(_ sender: Any) {
        if seconds <= 3
        {
            userSelection = "scissors"
            sendResponse(clientResponse: userSelection)
            
            scissorsButton.backgroundColor = UIColor.green
            rockButton.backgroundColor = UIColor.white
            paperButton.backgroundColor = UIColor.white
        }
    }
    
    //INFO: Inform the opponent that the user has tapped paper.
    @IBAction func paperTapped(_ sender: Any) {
        if seconds <= 3
        {
            userSelection = "paper"
            sendResponse(clientResponse: userSelection)
            
            paperButton.backgroundColor = UIColor.green
            scissorsButton.backgroundColor = UIColor.white
            rockButton.backgroundColor = UIColor.white
        }
    }
    
    //INFO: Inform the opponent that the user has tapped rock.
    @IBAction func rockTapped(_ sender: Any) {
        if seconds <= 3
        {
            userSelection = "rock"
            sendResponse(clientResponse: userSelection)
            
            rockButton.backgroundColor = UIColor.green
            scissorsButton.backgroundColor = UIColor.white
            paperButton.backgroundColor = UIColor.white
        }
    }
    
    
    //MARK: Send Response
    
    //INFO: This method allows for some re-usability in sending strings to the connected clients.
    func sendResponse(clientResponse: String)
    {
        do
        {
            if let encodedString = clientResponse.data(using: String.Encoding.utf8)
            {
                try session.send(encodedString, toPeers: session.connectedPeers, with: MCSessionSendDataMode.reliable)
            }
        }
        catch
        {
            print(error.localizedDescription)
        }
    }
    
    //MARK: Checks
    
    //INFO: Simple check to see if the game is ready to start.
    func isGameReadyToStart() -> Bool
    {
        if userReady && opponentReady
        {
            return true
        }
        return false
    }
    
    //MARK: Start Game
    
    var gameTimer: Timer?
    var seconds = 0
    
    func startGame()
    {
        seconds = 0
        
        enablePlayingButtons()
        disablePlayButton()
        
        //FIX: Resetting the game timer to nil with every run to prevent weird timer issue.
        gameTimer = nil
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: {[weak self] (_) in
            
            guard let strongSelf = self else { return }
            
            strongSelf.seconds += 1
            
            //INFO: Update the label with each tick.
            DispatchQueue.main.async {
                strongSelf.opponentReadyLabel.text = "\(strongSelf.seconds - 1)/3 seconds to select."
            }
            
            if strongSelf.seconds > 3
            {
                //INFO: Stop the timer, block any inputs, time has run out.
                strongSelf.gameTimer?.invalidate()
                strongSelf.disablePlayingButtons()
                strongSelf.enablePlayButton()
                
                //INFO: Inform the other player that nothing was selected.
                if strongSelf.userSelection == "nothingSelected"
                {
                    strongSelf.sendResponse(clientResponse: "nothingSelected")
                }
                
                strongSelf.userReady = false
                strongSelf.opponentReady = false
                
                DispatchQueue.main.async
                    {
                        //INFO: Check who won.
                        strongSelf.evaluateWin()
                        strongSelf.opponentReadyLabel.text = "Press play for round \(strongSelf.winsCounter + strongSelf.tiesCounter + strongSelf.lossesCounter)."
                        
                        strongSelf.userSelection = "nothingSelected"
                        strongSelf.opponentSelection = "nothingSelected"
                }
            }
        })
    }
    
    //MARK: Evaluate Win
    func evaluateWin()
    {
        //INFO: Simple win checks. This method will also set the colors for the opponent and for the current player to show what each player has selected.
        
        //INFO: If both players do not select anything they will tie. 
        if opponentSelection == userSelection
        {
            
            rockButton.backgroundColor = UIColor.white
            paperButton.backgroundColor = UIColor.white
            scissorsButton.backgroundColor = UIColor.white
            
            switch opponentSelection
            {
            case "rock":
                rockButton.alpha = 1
                rockButton.backgroundColor = UIColor.purple
            case "paper":
                paperButton.alpha = 1
                paperButton.backgroundColor = UIColor.purple
            case "scissors":
                scissorsButton.alpha = 1
                scissorsButton.backgroundColor = UIColor.purple
            default:
                print("Error404")
            }
            tiesCounter += 1
        }
            
            //INFO: If the user does not select anything they automatically lose.
        else if userSelection == "nothingSelected"
        {
            rockButton.alpha = 1
            rockButton.backgroundColor = UIColor.red
            paperButton.alpha = 1
            paperButton.backgroundColor = UIColor.red
            scissorsButton.alpha = 1
            scissorsButton.backgroundColor = UIColor.red
            lossesCounter += 1
        }
            //INFO: If the opponent does not select anything the user automatically wins.
        else if opponentSelection == "nothingSelected"
        {
            rockButton.alpha = 1
            rockButton.backgroundColor = UIColor.green
            paperButton.alpha = 1
            paperButton.backgroundColor = UIColor.green
            scissorsButton.alpha = 1
            scissorsButton.backgroundColor = UIColor.green
            winsCounter += 1
        }
        else if userSelection == "rock" && opponentSelection == "scissors"
        {
            rockButton.alpha = 1
            scissorsButton.alpha = 1
            scissorsButton.backgroundColor = UIColor.red
            winsCounter += 1
        }
        else if userSelection == "rock" && opponentSelection == "paper"
        {
            rockButton.alpha = 1
            paperButton.alpha = 1
            paperButton.backgroundColor = UIColor.red
            lossesCounter += 1
        }
        else if userSelection == "paper" && opponentSelection == "rock"
        {
            paperButton.alpha = 1
            rockButton.alpha = 1
            rockButton.backgroundColor = UIColor.red
            winsCounter += 1
        }
        else if userSelection == "paper" && opponentSelection == "scissors"
        {
            paperButton.alpha = 1
            scissorsButton.alpha = 1
            scissorsButton.backgroundColor = UIColor.red
            lossesCounter += 1
        }
        else if userSelection == "scissors" && opponentSelection == "paper"
        {
            scissorsButton.alpha = 1
            paperButton.alpha = 1
            paperButton.backgroundColor = UIColor.red
            winsCounter += 1
        }
        else if userSelection == "scissors" && opponentSelection == "rock"
        {
            scissorsButton.alpha = 1
            rockButton.alpha = 1
            rockButton.backgroundColor = UIColor.red
            lossesCounter += 1
        }
        
        updateLabels()
    }
    
    //Update the labels after a win condition.
    func updateLabels()
    {
        DispatchQueue.main.async {
            self.winsCounterLabel.text = String(self.winsCounter)
            self.tiesCounterLabel.text = String(self.tiesCounter)
            self.lossesCounterLabel.text = String(self.lossesCounter)
        }
        
    }
    
    //MARK: Connect Tapped
    @IBAction func connectTap(_ sender: Any) {
        //  establish connection when button title is "connect"
        if btnConnect.title == "Connect" {
            // 4.1 setup browser
            // our browser will look for advertisers that share the same serviceID/channel
            browser = MCBrowserViewController(serviceType: serviceID, session: session)
            // 4.2 browser delegate
            browser.delegate = self
            // 4.3 present the browser view controller
            self.present(browser, animated: true, completion: nil)
        }
        else if btnConnect.title == "Disconnect" {
            disablePlayingButtons()
            session.disconnect()
        }
    }
    
    // MARK: - MCBrowserViewControllerDelegate Callback Methods -------------------------------------------------------------- //
    // Notifies the delegate, when the user taps the done button.
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
    }
    
    // Notifies the delegate, when the user taps the cancel  button.
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true, completion: nil)
        session.disconnect()
    }
    
    
    
    // MARK: - MCSessionDelegate Callback Methods ---------------------------------------------------------------------------- //
    // Remote peer changed state.
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // this callback takes place on a async background thread
        // inorder to update the UI, we must update the main thread
        DispatchQueue.main.async {
            // What is the current state: .connected, .connecting, .notConnected
            if state == MCSessionState.connected {
                
                //INFO: Reset the play state when the player becomes connected to a new client.
                self.enablePlayButton()
                
                self.winsCounter = 0
                self.tiesCounter = 0
                self.lossesCounter = 0
                
                self.winsCounterLabel.text = "0"
                self.tiesCounterLabel.text = "0"
                self.lossesCounterLabel.text = "0"
                
                self.opponentReadyLabel.text = "Press play to start game."
                
                self.disablePlayingButtons()
                
                // how many connected peers are there?
                if session.connectedPeers.count > 1
                {
                    self.navItem.title = "Status: Connected to \(session.connectedPeers.count) peers."
                }
                else
                {
                    self.navItem.title = "Status: Connected to \(peerID.displayName)"
                }
                
                self.btnConnect.title = "Disconnect"
                
                //INFO: Enable Controls
                self.enablePlayButton()
            }
            else if state == MCSessionState.connecting
            {
                self.navItem.title = "Status: Connecting..."
                self.btnConnect.title = "Connect"
                
            }
            else if state == MCSessionState.notConnected
            {
                self.navItem.title = "Status: No Connection"
                self.btnConnect.title = "Connect"
            }
        }
    }
    
    //MARK: Session Received Data
    // Received data from remote peer.
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // Build a new string from the encodedString received
        if let receivedResponse : String = String(data: data, encoding: String.Encoding.utf8)
        {
            //INFO: Wait for play response. If the play response is received inform the current user that the opponent is waiting. Also attempt to play in the event that the current user is already waiting to play.
            if receivedResponse == "play"
            {
                opponentReady = true
                
                DispatchQueue.main.async {
                    self.opponentReadyLabel.isHidden = false
                    self.opponentReadyLabel.text = "Opponent is ready to play."
                    
                    //INFO: Check if the game is ready to start.
                    if self.isGameReadyToStart()
                    {
                        self.startGame()
                    }
                }
            }
            else
            {
                opponentSelection = receivedResponse
            }
        }
    }
    
    //MARK: Buttons Enabled Controls
    func enablePlayingButtons()
    {
        DispatchQueue.main.async {
            self.rockButton.isUserInteractionEnabled = true
            self.paperButton.isUserInteractionEnabled = true
            self.scissorsButton.isUserInteractionEnabled = true
            
            self.rockButton.alpha = 1
            self.paperButton.alpha = 1
            self.scissorsButton.alpha = 1
        }
    }
    
    func disablePlayingButtons()
    {
        DispatchQueue.main.async {
            self.rockButton.isUserInteractionEnabled = false
            self.paperButton.isUserInteractionEnabled = false
            self.scissorsButton.isUserInteractionEnabled = false
            
            self.rockButton.alpha = 0.5
            self.paperButton.alpha = 0.5
            self.scissorsButton.alpha = 0.5
        }
    }
    
    func disablePlayButton()
    {
        DispatchQueue.main.async {
            self.playButton.isUserInteractionEnabled = false
            self.playButton.alpha = 0.5
        }
    }
    
    func enablePlayButton()
    {
        DispatchQueue.main.async {
            self.playButton.isUserInteractionEnabled = true
            self.playButton.alpha = 1
        }
    }
    
    //MARK: Unused Required Methods
    
    // Received a byte stream from remote peer.
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //
    }
    
    // Start receiving a resource from remote peer.
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //
    }
    
    // Finished receiving a resource from remote peer and saved the content
    // in a temporary location - the app is responsible for moving the file
    // to a permanent location within its sandbox.
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //
    }
    
}

