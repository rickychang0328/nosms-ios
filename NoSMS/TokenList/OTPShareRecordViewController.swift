//
//  OTPShareRecordViewController.swift
//  NoSMS
//
//  Created by Andy LI on 2020/10/13.
//

import UIKit
import RxSwift
import RxCocoa

class OTPShareRecordViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let disposeBag: DisposeBag = .init()
    var tableView = UITableView()
    
    var otpValueDicArray: [ShareRecordObject] = ShareRecordStoreManager().getAllRecord().reversed()
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .getColor(red: 41, green: 44, blue: 68, alpha: 1)
        view.addCornerRadius(at: 10)
        return view
    }()
    
    
    let titleLabel: UILabel = {
        
        let label = UILabel()
        label.text = "您近期在此设备上通过MustAuth验证器执行的操作"
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.getColor(red: 102, green: 102, blue: 102, alpha: 1))
            .setNumberOfLine(0)
            .setTextAlignment(.center)
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigate()
        navigationController?.navigationBar.barTintColor = .navigationColor
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationItem.title = "近期分享记录"
        tableView.register(ShareOTPRecordTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        view.addSubview(titleLabel)
        view.addSubview(tableView)
        titleLabel.preferredMaxLayoutWidth = ScaleWidth(at: 235)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 25))
            $0.left.equalToSuperview().offset(20)
            $0.right.equalToSuperview().offset(-20)
            $0.height.equalTo(21)
        }
      
        tableView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 25))
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
              super.traitCollectionDidChange(previousTraitCollection)
              setNavigate()
          }
    
    func setNavigate() {
          let leftbarItem = UIBarButtonItem(image: .noSmsBack, style: .plain, target: nil, action: nil)

          leftbarItem.rx.tap.subscribe(onNext: {[weak self] in
              
              self?.navigationController?.popViewController(animated: true)
          }).disposed(by: disposeBag)
          
          navigationItem.leftBarButtonItem = leftbarItem
          var color: UIColor
          if #available(iOS 13.0, *) {
              
              if UITraitCollection.current.userInterfaceStyle == .some(.dark) {
                  
                  color = .getColor(red: 33, green: 33, blue: 33, alpha: 0.56)
              } else {
                  
                  color = .navColorLight
              }
          } else {
              color = .navColorLight
              // Fallback on earlier versions
          }
          navigationController?.navigationBar.barTintColor = color
      }
    
    @objc func confirm(sender:UIButton!) {
        self.view.removeFromSuperview()
    }
    
    // return the number of cells each section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return otpValueDicArray.count
    }
    
    // return cells
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ShareOTPRecordTableViewCell
        cell.otpValueCount.text = otpValueDicArray[indexPath.row].description
        cell.otpValueTime.text = otpValueDicArray[indexPath.row].time
        cell.backgroundColor = .otpShareReceiveButtonColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
}

class ShareOTPRecordTableViewCell: UITableViewCell {
    
    var otpValueCount: UILabel = {
        let label = UILabel()
        label.text = ""
        label.backgroundColor = .clear
        label.setFont(.pingFangMediumFont(size: 16))
            .setTextColor(.otpScanHintTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    var otpValueTime: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.setFont(.pingFangMediumFont(size: 12))
            .setTextColor(.getColor(red: 136, green: 136, blue: 136, alpha: 1))
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    var lineView: UIView = {
          let view = UIView()
          view.backgroundColor = .otpshareRecordCellLineColor
          return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        contentView.addSubview(otpValueCount)
        contentView.addSubview(otpValueTime)
        contentView.addSubview(lineView)
        otpValueCount.snp.makeConstraints {
            $0.height.equalTo(22.5)
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(15)
            $0.width.equalTo(200)
        }
        
        otpValueTime.snp.makeConstraints {
            $0.height.equalTo(16.5)
            $0.left.equalToSuperview().offset(16)
            $0.top.equalTo(otpValueCount.snp.bottom).offset(11)
            $0.width.equalTo(150)
        }
        
        lineView.snp.makeConstraints {
            $0.height.equalTo(5)
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


struct ShareRecordObject {
    
    let time: String
    let description: String
}

class ShareRecordStoreManager {
    
    private let userDefault: UserDefaults = .standard
    private let userDefaultKey: String = "shareOTPDicArray"
    private let userDefaultDicDescriptionKey: String = "shareInformation"
    private let userDefaultTimeKey: String = "time"

    func getAllRecord() -> [ShareRecordObject] {
        
        let shareOTPDicArray: [[String: String]] = userDefault.object(forKey: userDefaultKey) as? [[String: String]] ?? []
        let result = shareOTPDicArray.compactMap({ dic -> ShareRecordObject? in
            
            guard let description = dic[userDefaultDicDescriptionKey] else {
                
                return nil
            }
            guard let time = dic[userDefaultTimeKey] else {
                
                return nil
            }
            
            return ShareRecordObject(time: time, description: description)
        })

        return result
    }
    
    func addNewRecord(description: String) {
        
        var shareOTPDicArray: [[String: String]] = []
        shareOTPDicArray = userDefault.object(forKey: userDefaultKey) as? [[String : String]] ?? []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let time = dateFormatter.string(from: Date())
        shareOTPDicArray.append([userDefaultDicDescriptionKey: description, userDefaultTimeKey: time])
        userDefault.set(shareOTPDicArray, forKey: userDefaultKey)
    }
    
}
