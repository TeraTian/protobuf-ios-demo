//
//  CoderTestStudent.swift
//  protobuf-decoder-demo
//
//  Created by 田纪原 on 2020/9/20.
//  Copyright © 2020 田纪原. All rights reserved.
//
import Foundation

@objc class CoderTestStudent:NSObject,Codable{
   @objc var age:Int = 0
   @objc var father:Parent?
   @objc var friends:[String]
   @objc var hairCount:Int64 = 0
   @objc var height:Double = 0
   @objc var hobbies:[Hobby]?
   @objc var isMale:Bool
   @objc var mother:Parent?
   @objc var name:String?
   @objc var weight:Float
}

@objc class Parent:NSObject,Codable{
    @objc var age:Int = 0
    @objc var name:String?
}

@objc class Hobby:NSObject,Codable {
    @objc var cost:Int = 0
    @objc var name:String?
}
