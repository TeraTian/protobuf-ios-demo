//
//  DefaultStringStudent.swift
//  protobuf-decoder-demo
//
//  Created by 田纪原 on 2020/9/20.
//  Copyright © 2020 田纪原. All rights reserved.
//

import Foundation

@objc class DefaultStringStudent:NSObject,Codable{
    @objc var defaultName:String? = "Peter"
    @objc var multipleDefaults:String? = "Peter|Mary|John"
    @objc var replacedDefault:String? = "亲爱的%@用户您好，欢迎回来"
}
