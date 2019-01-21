//
//  JXSegmentedListContainerView.swift
//  JXSegmentedView
//
//  Created by jiaxin on 2018/12/26.
//  Copyright © 2018 jiaxin. All rights reserved.
//

import UIKit

@objc
public protocol JXSegmentedListContentViewDelegate {
    func listView() -> UIView
    @objc optional func listDidAppear()
    @objc optional func listDidDisappear()
}

@objc
public protocol JXSegmentedListContainerViewDelegate {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContentViewDelegate
}

open class JXSegmentedListContainerView: UIView {
    open var scrollView = UIScrollView()
    /// 已经加载过的列表字典。key是index，value是对应的列表
    open var validListDict = [Int:JXSegmentedListContentViewDelegate]()
    /// 滚动切换的时候，滚动距离超过一页的多少百分比，就认为切换了页面。默认0.5（即滚动超过了半屏，就认为翻页了）。范围0~1，开区间不包括0和1
    open var didAppearPercent: Double = 0.5
    /// 需要和categoryView.defaultSelectedIndex保持一致
    open var defaultSelectedIndex: Int = 0 {
        didSet {
            currentIndex = defaultSelectedIndex
        }
    }
    private weak var delegate: JXSegmentedListContainerViewDelegate!
    private weak var parentVC: UIViewController!
    private var currentIndex: Int = 0
    private var isLayoutSubviewsed: Bool = false

    init(parentVC: UIViewController, delegate: JXSegmentedListContainerViewDelegate) {
        self.parentVC = parentVC
        self.parentVC.automaticallyAdjustsScrollViewInsets = false
        self.delegate = delegate

        super.init(frame: CGRect.zero)

        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func commonInit() {
        scrollView.isPagingEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        scrollView.bounces = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(scrollView)
    }

    open func reloadData() {
        for list in validListDict.values {
            list.listView().removeFromSuperview()
        }
        validListDict.removeAll()
        
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width*CGFloat(delegate.numberOfLists(in: self)), height: scrollView.bounds.size.height)

        listDidAppear(at: currentIndex)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        scrollView.frame = bounds
        scrollView.contentSize = CGSize(width: scrollView.bounds.size.width*CGFloat(delegate.numberOfLists(in: self)), height: scrollView.bounds.size.height)
        if !isLayoutSubviewsed {
            isLayoutSubviewsed = true
            listDidAppear(at: currentIndex)
        }
    }


    /// 必须调用！在`func segmentedView(_ segmentedView: JXSegmentedBaseView, scrollingFrom leftIndex: Int, to rightIndex: Int, progress: CGFloat)`回调里面调用
    ///
    /// - Parameters:
    ///   - leftIndex: leftIndex description
    ///   - rightIndex: rightIndex description
    ///   - percent: percent description
    ///   - selectedIndex: selectedIndex description
    open func categoryViewScrolling(from leftIndex: Int, to rightIndex: Int, percent: Double, selectedIndex: Int) {
        var targetIndex: Int = -1
        var disappearIndex: Int = -1
        if rightIndex == selectedIndex {
            //当前选中的在右边，用户正在从右边往左边滑动
            if percent < (1 - didAppearPercent) {
                targetIndex = leftIndex
                disappearIndex = rightIndex
            }
        }else {
            //当前选中的在左边，用户正在从左边往右边滑动
            if percent > (1 - didAppearPercent) {
                targetIndex = rightIndex
                disappearIndex = leftIndex
            }
        }

        if targetIndex != -1 && currentIndex != targetIndex {
            listDidAppear(at: targetIndex)
            listDidDisappear(at: disappearIndex)
        }
    }


    /// 必须调用！在`func segmentedView(_ segmentedView: JXSegmentedBaseView, didClickSelectedItemAt index: Int)`回调里面调用
    ///
    /// - Parameter index: index description
    open func didClickSelectedItem(at index: Int) {
        listDidDisappear(at: currentIndex)
        listDidAppear(at: index)
    }

    //MARK: - Private
    private func listDidAppear(at index: Int) {
        let count = delegate.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        self.currentIndex = index

        var list = validListDict[index]
        if list == nil {
            list = delegate.listContainerView(self, initListAt: index)
        }
        if list?.listView().superview == nil {
            list?.listView().frame = CGRect(x: CGFloat(index)*scrollView.bounds.size.width, y: 0, width: scrollView.bounds.size.width, height: scrollView.bounds.size.height)
            scrollView.addSubview(list!.listView())
            validListDict[index] = list!
        }
        list?.listDidAppear?()
    }

    private func listDidDisappear(at index: Int) {
        let count = delegate.numberOfLists(in: self)
        if count <= 0 || index >= count {
            return
        }
        validListDict[index]?.listDidDisappear?()
    }
}