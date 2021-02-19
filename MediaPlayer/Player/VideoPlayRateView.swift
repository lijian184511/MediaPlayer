//
//  VideoPlayRateView.swift
//  Eceibs
//
//  Created by sword on 2018/6/11.
//  Copyright © 2018年 sword. All rights reserved.
//

///视频倍速控件

enum VideoQuality {
    case ld //流畅
    case sd //高清
    case hd //超清
}

import UIKit

typealias VideoPlayRateSelect = (Float) -> ()

typealias VideoPlayQualitySelect = (VideoQuality) -> ()

fileprivate let cellHeight: CGFloat = 30.0

class VideoPlayRateView: UIView, UITableViewDelegate, UITableViewDataSource {
    private var tableView: UITableView?
    
    private var rateArr: [Float]?
    
    private var qualityArr: [String]?
    
    private var selectedRate: Float?
    
    private var selectedQuality: String?
    
    var rateSelect: VideoPlayRateSelect?
    
    var qualitySelect: VideoPlayQualitySelect?
    
    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
     // Drawing code
     }
     */
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func loadTableView(rates: [Float]? = nil, qualities: [String]? = nil, selectedRate: Float? = nil, selectedQuality: String? = nil) {
        rateArr = rates
        
        qualityArr = qualities
        
        self.selectedRate = selectedRate
        self.selectedQuality = selectedQuality
        
        if tableView == nil {
            tableView = UITableView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
            tableView!.bounces = false
            tableView!.backgroundColor = .clear
            tableView!.separatorStyle = .none
            tableView!.delegate = self
            tableView!.dataSource = self
            addSubview(tableView!)
        } else {
            tableView!.reloadData()
        }
        tableView!.frame.size.height = CGFloat(rates == nil ? qualities!.count : rates!.count)*cellHeight
        
        frame.size.height = tableView!.frame.height
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (rateArr == nil ? qualityArr!.count : rateArr!.count)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = UIColor.white.withAlphaComponent(0.5)
        cell.textLabel?.font = UIFont.systemFont(ofSize: 12)
        cell.contentView.backgroundColor = .clear
        cell.backgroundColor = .clear
        if rateArr != nil {
            cell.textLabel?.text = "\(rateArr![indexPath.row])X"
            
            if rateArr![indexPath.row] == selectedRate {
                cell.textLabel?.textColor = .white
            }
            
        } else {
            cell.textLabel?.text = qualityArr![indexPath.row]
            
            if qualityArr![indexPath.row].contains(selectedQuality!) {
                cell.textLabel?.textColor = .white
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if rateArr != nil {
            rateSelect?(rateArr![indexPath.row])
        } else {
            switch qualityArr![indexPath.row] {
            case "标清":
                qualitySelect?(.ld)
            case "高清":
                qualitySelect?(.sd)
            case "超清":
                qualitySelect?(.hd)
            default:
                break
            }
        }
    }
}
