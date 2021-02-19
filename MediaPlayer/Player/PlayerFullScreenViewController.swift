//
//  PlayerFullScreenViewController.swift
//  Eceibs
//
//  Created by sword on 2018/4/10.
//  Copyright © 2018年 sword. All rights reserved.
//

import UIKit

class PlayerFullScreenViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations:UIInterfaceOrientationMask{
        return .landscapeRight
    }
    
    override var shouldAutorotate:Bool{
        return false
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
