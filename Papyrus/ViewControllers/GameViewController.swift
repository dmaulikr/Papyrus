//
//  GameViewController.swift
//  Papyrus
//
//  Created by Chris Nevin on 14/07/2015.
//  Copyright (c) 2015 CJNevin. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController, GameSceneDelegate, UITextFieldDelegate {
    @IBOutlet var skView: SKView?
    var scene: GameScene?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            Lexicon.sharedInstance
        }
        if let view = skView, gscene = GameScene(fileNamed:"GameScene") {
            gscene.scaleMode = SKSceneScaleMode.ResizeFill
            view.showsFPS = false
            view.showsNodeCount = false
            view.ignoresSiblingOrder = false //true is faster
            view.presentScene(gscene)
            scene = gscene
            gscene.actionDelegate = self
        }
        title = "Papyrus"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Submit", style: .Done, target: self, action: "submit:")
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: "restart:")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if !Papyrus.sharedInstance.inProgress {
            newGame()
        }
    }
    
    func newGame() {
        Papyrus.sharedInstance.newGame() { [weak self] (lifecycle, game) in
            guard let this = self, scene = this.scene else { return }
            switch (lifecycle) {
            case .Cleanup:
                this.title = "Cleanup"
            case .Preparing:
                this.title = "Loading..."
            case .Ready:
                this.title = "Papyrus"
                this.enableButtons(true)
                game.createPlayer()
                game.createPlayer()
            default:
                this.title = "Complete"
            }
            scene.changed(lifecycle)
        }
    }
    
    func boundariesChanged(boundary: Boundary?, error: ValidationError?, score: Int) {
        navigationItem.rightBarButtonItem?.enabled = boundary != nil && error == nil && score > 0
        print("Score: \(score)")
    }
    
    func pickLetter(completion: (Character) -> ()) {
        let alertController = UIAlertController(title: "Enter Replacement Letter", message: nil, preferredStyle: .Alert)
        let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
            if let letter = alertController.textFields?.first?.text?.characters.first {
                completion(letter)
            }
        }
        alertController.addTextFieldWithConfigurationHandler { (textField) in
            textField.autocapitalizationType = UITextAutocapitalizationType.AllCharacters
            textField.delegate = self
        }
        alertController.addAction(OKAction)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        // Filter alphabet, allow only one character
        let charSet = NSCharacterSet(charactersInString: "ABCDEFGHIJKLMNOPQRSTUVWXYZ").invertedSet
        let filtered = "".join(string.componentsSeparatedByCharactersInSet(charSet))
        let current: NSString = textField.text ?? ""
        let newLength = current.stringByReplacingCharactersInRange(range, withString: string).lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        return filtered == string && (newLength == 0 || newLength == 1)
    }
    
    func enableButtons(enabled: Bool) {
        navigationItem.leftBarButtonItem?.enabled = enabled
        navigationItem.rightBarButtonItem?.enabled = enabled
    }
    
    func restart(sender: UIBarButtonItem) {
        enableButtons(false)
        newGame()
    }
    
    func submit(sender: UIBarButtonItem) {
        do {
            try scene?.submitPlay()
        } catch let err as ValidationError {
            switch err {
            case .Message(let s):
                let alertController = UIAlertController(title: s, message: nil, preferredStyle: .Alert)
                let OKAction = UIAlertAction(title: "OK", style: .Default) { (action) in
                }
                alertController.addAction(OKAction)
                presentViewController(alertController, animated: true, completion: nil)
            default:
                print(err)
            }
        } catch _ {
            
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}
