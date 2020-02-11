//
//  CategoryViewModel.swift
//  rfios
//
//  Created by Taeheon Woo on 2019/12/07.
//  Copyright © 2019 avon. All rights reserved.
//

import Foundation
import RxCocoa
import RxRealm
import RxSwift
import SwiftyJSON

protocol CategoryViewModelType: BaseViewModelType {
    // Output
    var categoryListOb: BehaviorRelay<[Category]> { get }
    
    // Input
    var titleInput: BehaviorSubject<String> { get }
    var colorInput: BehaviorSubject<String> { get }
    
    func onAdd()
    func onModify(_ selectedIndex: Int)
    var selectedIndex: Int? { get set }
    
    func addCategory()
    func modCategory()
    func delCategory(_ index: Int)
    
    //
    var isSelection: Bool { get }
    var feedbackViewModel: FeedbackViewModelType? { get }
    func selCategory()
}

class CategoryViewModel: BaseViewModel, CategoryViewModelType {
    
    let categoryListOb: BehaviorRelay<[Category]>
    
    let titleInput: BehaviorSubject<String>
    let colorInput: BehaviorSubject<String>
    
    var categoryList: [Category] = []
    var category: Category = Category()
    
    var selectedIndex: Int?
    
    var isSelection = false
    var feedbackViewModel: FeedbackViewModelType?
    
    override init() {
        
        // -MARK: List
        self.categoryListOb = BehaviorRelay<[Category]>(value: categoryList)
        
        // -MARK: Edit
        self.titleInput = BehaviorSubject(value: "")
        self.colorInput = BehaviorSubject(value: "")
        
        super.init()
        
        Observable.combineLatest(titleInput, colorInput, resultSelector: {
                let _category = self.category
                _category.title = $0
                _category.color = $1
                return _category
            })
            .subscribe(onNext: { [weak self] in
                self?.category = $0
                
//                self?.category.title = $0.title
//                if $0.color != "" {
//                    self?.category.color = $0.color
//                }
            })
            .disposed(by: self.disposeBag)
        
        reqGetCategories()
    }
    
    
}

// -MARK: Scene
extension CategoryViewModel {
    func onAdd() {
        self.selectedIndex = nil
        SceneCoordinator.sharedInstance.showEditCategoryView(self)
    }
    
    func onModify(_ selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        self.category = self.categoryList[selectedIndex]
        SceneCoordinator.sharedInstance.showEditCategoryView(self)
    }
}

// -MARK: CRUD
extension CategoryViewModel {
    
    func addCategory() {
        print("주제 추가")
        self.reqAddCategory()
        self.categoryList.append(self.category)
        self.categoryListOb.accept(self.categoryList)
    }
    
    func modCategory() {
        NWLog.dLog(contentName: "주제 수정", contents: nil)
        self.reqModCategory()
        if let index = selectedIndex {
            self.categoryList[index] = self.category
            self.categoryListOb.accept(self.categoryList)
        }
        
    }
    
    func delCategory(_ index: Int) {
        print("주제 삭제")
        self.category = self.categoryList[index]
        reqDelCategory()
        self.categoryList.remove(at: index)
        self.categoryListOb.accept(self.categoryList)
    }
    
    func selCategory() {
        print("주제 선택 완료", self.category.title)
        self.category = self.categoryList[selectedIndex ?? 0]
        self.feedbackViewModel?.categoryOb.accept(self.category)
    }
    
}

// -MARK: Network
extension CategoryViewModel {
    
    // 카테고리 리스트 불러오기
    func reqGetCategories() {
        print("카테고리 리스트 서버에 요청")
        APIHelper.sharedInstance.rxPullResponse(.getCategories)
            .subscribe(onNext: { [weak self] in
                
                guard let dataList = $0.dataDic else { return }
                
                for data in dataList {
                    let category = Category()
                    category.id = data["category_id"] as? Int ?? -1
                    category.title = data["category_title"] as? String ?? ""
                    category.color = data["category_color"] as? String ?? ""
                    
                    self?.categoryList.append(category)
                }
                
                self?.categoryListOb.accept(self?.categoryList ?? [])
//                RealmHelper.sharedInstantce.overwrite(Category.self, objs: self?.categoryList ?? [])
                
            })
            .disposed(by: self.disposeBag)
        
    }
    
    // 카테고리 추가 요청
    func reqAddCategory() {
        print("카테고리 추가 서버에 요청")
        APIHelper.sharedInstance.rxPullResponse(.addCategory(self.category.toDictionary()))
            .subscribe(onNext: {
                print($0.msg)
            })
            .disposed(by: self.disposeBag)
    }
    
    // 카테고리 수정 요청
    func reqModCategory() {
        NWLog.dLog(contentName: "카테고리 수정 서버에 수정", contents: nil)
//        APIHelper.sharedInstance.rxPullResponse(.modCategory(self.category.toDistionary(), id: String(self.category.id)))
//            .subscribe(onNext: {
//                print($0.msg)
//            })
//            .disposed(by: self.disposeBag)
        APIHelper.sharedInstance.pushRequest(.modCategory(self.category.toDictionary(), id: String(self.category.id)))
    }
    
    func reqDelCategory() {
        APIHelper.sharedInstance.rxPullResponse(.delCategory(String(self.category.id))) 
        .subscribe(onNext: {
            print($0.msg)
        })
        .disposed(by: self.disposeBag)
//        APIHelper.sharedInstance.pushRequest(.delCategory(String(self.category.id)))
    }
    
}

extension CategoryViewModel {
    func setCategories() {
        
    }
}
