//
//  main.swift
//  protobuf-decoder-demo
//
//  Created by 田纪原 on 2020/9/20.
//  Copyright © 2020 田纪原. All rights reserved.
//

import Foundation

func printJson<T:Codable>(object:T){
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    do {
        let jData = try encoder.encode(object)
        let json = String(data:jData,encoding:String.Encoding.utf8)
        print(json!)
    } catch {
        print(error)
    }
}

var pd = Decoder(namespace:"protobuf_decoder_demo")
func request(){
    let sem = DispatchSemaphore(value:0)
    let url = URL(string: "http://localhost:8080/protobuf/getStudent")
    var request = URLRequest(url: url!)
    request.httpMethod = "GET"
    let session = URLSession(configuration: .default)

    let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
        let buffer = data!.map({ (bit) -> Int in
            let int8Bit: Int8 = Int8(bitPattern: bit)
            return Int(int8Bit)
        })
        let model = pd.deserialize(data: buffer, typeT: CoderTestStudent.self)
        printJson(object:model)
    });
    task.resume()
    sem.wait(timeout: DispatchTime.now() + 100000)
}
request()

