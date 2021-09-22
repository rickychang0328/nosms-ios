//
//  GestVerificationConfig.swift
//  NoSMS
//
//  Created by 誠帷數位科技 on 2021/6/7.
//

import JXPatternLock

struct PasswordPathConfig: PatternLockViewConfig {
    
    var matrix: Matrix
    var gridSize: CGSize
    var autoMediumGridsConnect: Bool = false
    var connectLineHierarchy: ConnectLineHierarchy = .bottom
    var errorDisplayDuration: TimeInterval = 0.5
    var connectLine: ConnectLine? = nil
    var initGridClosure: (Matrix) -> (PatternLockGrid)
    
    init() {
        gridSize = CGSize(width: ScaleWidth(at: 10), height: ScaleWidth(at: 10))
        matrix = Matrix(row: 3, column: 3)
        
        let innerColor: UIColor = .innerColor
        let normalColor: UIColor = .normalPathColor
        let outerFillConnectColor: UIColor = .outerFillConnectColor
        initGridClosure = {(matrix) -> PatternLockGrid in
            let gridView = GridView()
            let outerStrokeLineWidthStatus = GridPropertyStatus<CGFloat>.init(normal: 1, connect: 1, error: 1)
            let outerFillColorStatus = GridPropertyStatus<UIColor>(normal: nil, connect: outerFillConnectColor, error: nil)
            let innerFillColorStatus = GridPropertyStatus<UIColor>(normal: normalColor, connect: innerColor, error: nil)
            
            gridView.outerRoundConfig = RoundConfig(radius: ScaleWidth(at: 8.5), lineWidthStatus: outerStrokeLineWidthStatus, lineColorStatus: nil, fillColorStatus: outerFillColorStatus)
            gridView.innerRoundConfig = RoundConfig(radius: ScaleWidth(at: 5), lineWidthStatus: nil, lineColorStatus: nil, fillColorStatus: innerFillColorStatus)
            return gridView
        }
    }
}

struct PasswordConfig: PatternLockViewConfig {
    
    var matrix: Matrix = Matrix(row: 3, column: 3)
    var gridSize: CGSize = CGSize(width: 70, height: 70)
    var connectLine: ConnectLine?
    var autoMediumGridsConnect: Bool = false
    var connectLineHierarchy: ConnectLineHierarchy = .top
    var errorDisplayDuration: TimeInterval = 1
    var initGridClosure: (Matrix) -> (PatternLockGrid)

    init() {
        let highlightColor: UIColor = .highlightColor
        let errorColor: UIColor = .errorColor
        let innerColor: UIColor = .innerColor
        let strokeColor: UIColor = .lineColor
        let errorOutFillColor: UIColor = .errorOutFillColor
        initGridClosure = {(matrix) -> PatternLockGrid in
            let gridView = GridView()
            let outerStrokeLineWidthStatus = GridPropertyStatus<CGFloat>.init(normal: 1, connect: 1, error: 1)
            let outerStrokeColorStatus = GridPropertyStatus<UIColor>(normal: strokeColor, connect: highlightColor, error: errorOutFillColor)
            let outerFillColorStatus = GridPropertyStatus<UIColor>(normal: nil, connect: highlightColor, error: errorOutFillColor)
            gridView.outerRoundConfig = RoundConfig(radius: 35, lineWidthStatus: outerStrokeLineWidthStatus, lineColorStatus: outerStrokeColorStatus, fillColorStatus: outerFillColorStatus)
            let innerFillColorStatus = GridPropertyStatus<UIColor>(normal: nil, connect: innerColor, error: errorColor)
            let lineColorStatus = GridPropertyStatus<UIColor>(normal: nil, connect: innerColor, error: errorColor)
            gridView.innerRoundConfig = RoundConfig(radius: 10, lineWidthStatus: nil, lineColorStatus: lineColorStatus, fillColorStatus: innerFillColorStatus)
            return gridView
        }
        let lineView = ConnectLineView()
        lineView.isTriangleHidden = true
        lineView.lineColorStatus = .init(normal: innerColor, error: errorColor)
        lineView.lineWidth = 2
        connectLine = lineView
    }
}
