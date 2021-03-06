//
//  ProtobufDecoder.swift
//  commond_line
//
//  Created by 田纪原 on 2019/10/25.
//  Copyright © 2019 田纪原. All rights reserved.
//

import Cocoa

class Decoder: NSObject{
    var buffer: [Int] = []
    var pos: Int = 0
    var limit: Int = 0
    var _namespace: String?
    
    init(namespace:String){
        _namespace = namespace
    }
    
    func printJson<T:Codable>(object:T){
        let encoder = JSONEncoder()
        do{
            let jData = try encoder.encode(object)
            let json = String(data:jData,encoding:String.Encoding.utf8)
            print(json!)
        }
        catch{
            print(error)
        }
    }
    
    func deserialize<T: NSObject>(data:[Int], typeT:T.Type) ->T{
        buffer = data
        pos = 0;
        limit = data.count;
        let result = T.init()
        return deserializeObject(limit:data.count, obj:result);
    }
    
func deserializeObject<T: NSObject>(limit:Int, obj:T)->T{
    //这里对模型字段进行排序
    let result = obj
    let mirror = Mirror(reflecting: result)
    if(mirror.children.count == 0){
        pos = limit
        return result;
    }
    var fieldNameDict:[String: Mirror.Child] = [:]
    for property in mirror.children{
        fieldNameDict[property.label!] = property
    }
    let sortedKeys = Array(fieldNameDict.keys).sorted(by:{$0.lowercased()<$1.lowercased()})
    var fieldNumberDict:[Int: Mirror.Child] = [:]
    var order = 1
    for key in sortedKeys{
        fieldNumberDict[order]=fieldNameDict[key]
        order += 1
    }
    //排序是否完成
    while(pos < limit){
        //读取字节中的序号字段
        let fieldNum = readTag();
        //为了老版本客户端的兼容性，如果读取到的序号已经超过了模型的最大字段序号
        //那么就说明这是新版本客户端新增的字段，老版本客户端就不需要解析了
        if(fieldNum >= order){
            pos = limit
            return result
        }
        //获取和序号相符合的字段
        if let field = fieldNumberDict[fieldNum] {
            //通过反射获取字段信息
            let fm = Mirror(reflecting: field.value)
            //根据字段描述判断出字段的类型，然后进入不同的读取数据的方法
            if(fm.description == "Mirror for Optional<String>"){
                let r = readString();
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Int"){
                let r = readInt()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Bool"){
                let r = readBool()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Double"){
                let r = readDouble()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Float"){
                let r = readFloat()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Int64"){
                let r = readInt64()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Optional<Array<String>>"){
                let r = readStringArray()
                let value = result.value(forKey: field.label!)
                //如果nil则新建一个数组，否则append
                if(value == nil){
                    result.setValue(r, forKey: field.label!)
                }else{
                    var array = (value as! [String])
                    array.append(contentsOf: r)
                    result.setValue(array, forKey: field.label!)
                }
            }else if (fm.description == "Mirror for Optional<Array<Int>>"){
                let r = readIntArray()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Optional<Array<Double>>"){
                let r = readDoubleArray()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Optional<Array<Float>>"){
                let r = readFloatArray()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Optional<Array<Int64>>"){
                let r = readLongArray()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description == "Mirror for Optional<Array<Bool>>"){
                let r = readBoolArray()
                result.setValue(r, forKey: field.label!)
            }else if (fm.description.hasPrefix("Mirror for Optional<Array<")){
                //如果是一个Object的Array，那么就比较复杂一些
                //首先获取该Object类型的字符串
                if let match = fm.description.range(of: "(?<=<)[^>]+", options: .regularExpression) {
                    let first = fm.description.substring(with: match)
                    let className = first.split{$0 == "<"}.map(String.init)[1]
                    //通过反射加载类
                    let cls: AnyClass = NSClassFromString("\(_namespace!).\(className)")!;
                    let objType = cls as! NSObject.Type
                    let object = objType.init()
                    //递归调用
                    let r = readObject(obj: object)
                    let currentValue = result.value(forKey: field.label!)
                    //判断数组是否为空
                    if(currentValue == nil){
                        result.setValue([r], forKey: field.label!)
                    }else{
                        var array = currentValue as! [NSObject]
                        array.append(r)
                        result.setValue(array, forKey: field.label!)
                    }
                }
            }else{
                //如果是一个Object，那么和Array类似，通过字符串动态获取模型的类
                if let match = fm.description.range(of: "(?<=<)[^>]+", options: .regularExpression) {
                    let className = fm.description.substring(with: match)
                    let cls: AnyClass = NSClassFromString("\(_namespace!).\(className)")!;
                    let objType = cls as! NSObject.Type
                    let object = objType.init()
                    //递归调用
                    let r = readObject(obj: object)
                    result.setValue(r, forKey: field.label!)
                }
            }
        }
    }
    return result
}
    
    
    func readObject<T:NSObject>(obj: T)->T{
        let length = readRawVarint32()
        let limit = pos + length
        return deserializeObject(limit: limit, obj: obj)
    }
    
    func readBoolArray()->[Bool]{
        var result:[Bool] = []
        let length = readRawVarint32()
        let limit = pos + length;
        while (pos < limit) {
            result.append(contentsOf: [readBool()]);
        }
        return result
    }
    
    func readLongArray()->[Int64]{
        var result:[Int64] = []
        let length = readRawVarint32()
        let limit = pos + length;
        while (pos < limit) {
            let ss = readInt64()
            result.append(contentsOf: [ss]);
        }
        return result
    }
    
    func readDoubleArray()->[Double]{
        var result:[Double] = []
        let length = readRawVarint32()
        let limit = pos + length;
        while (pos < limit) {
            result.append(contentsOf: [readDouble()]);
        }
        return result
    }
    
    func readFloatArray()->[Float]{
        var result:[Float] = []
        let length = readRawVarint32()
        let limit = pos + length;
        while (pos < limit) {
            result.append(contentsOf: [readFloat()]);
        }
        return result
    }
    
    func readIntArray()->[Int]{
        var result:[Int] = []
        let length = readRawVarint32()
        let limit = pos + length;
        while (pos < limit) {
            result.append(contentsOf: [readInt()]);
        }
        return result
    }
    
    func readStringArray()->[String]{
        return [readString()]
    }
    
    
    
    func longBitsToDouble(bits:Int64)->Double{
        if(bits > 0){
            return Double(bitPattern: UInt64(bits))
        }else{
            let postiveBits:Int64 = bits & 9223372036854775807
            return -Double(bitPattern: UInt64(postiveBits))
        }
    }

    func intBitsToFloat(bits:Int)->Float{
        if(bits > 0){
            return Float(bitPattern: UInt32(bits))
        }else{
            let postiveBits:Int = bits & 2147483647
            return -Float(bitPattern: UInt32(postiveBits))
        }
    }
    
    func readRawLittleEndian32()->Int {
        let tempPos = pos;
        pos = tempPos + 4;
        let l1 = buffer[tempPos] & 255
        let l2 = (buffer[tempPos + 1] & 255) << 8
        let l3 = (buffer[tempPos + 2] & 255) << 16
        let l4 = (buffer[tempPos + 3] & 255) << 24
        let l = l1|l2|l3|l4
        return Int(l)
    }
    
    func readRawLittleEndian64()->Int64 {
        let tempPos = pos;
        pos = tempPos + 8;
        let l1 = buffer[tempPos] & 255
        let l2 = (buffer[tempPos + 1] & 255) << 8
        let l3 = (buffer[tempPos + 2] & 255) << 16
        let l4 = (buffer[tempPos + 3] & 255) << 24
        let l5 = (buffer[tempPos + 4] & 255) << 32
        let l6 = (buffer[tempPos + 5] & 255) << 40
        let l7 = (buffer[tempPos + 6] & 255) << 48
        let l8 = (buffer[tempPos + 7] & 255) << 56
        let l = l1|l2|l3|l4|l5|l6|l7|l8
        return Int64(l)
    }
    
    
    
    func readString()->String{
        let size = readRawVarint32();
        if (size > 0 && size <= limit - pos) {
            let array:[CChar] = Array(buffer[pos ..< pos + size]).map{CChar($0)}
            let str = NSString(bytes: array, length: array.count, encoding: String.Encoding.utf8.rawValue)
            pos += size;
            return str as! String;
        } else {
            return "";
        }
    }
    
    
    func readTag()->Int{
        return readRawVarint32() >> 3;
    }
    
    func readBool()->Bool{
        return readRawVarint32() == 1
    }

    func readInt()->Int{
        return readRawVarint32()
    }

    func readInt64()->Int64{
        return readRawVarint64();
    }

    func readDouble()->Double{
        return longBitsToDouble(bits: readRawLittleEndian64())
    }

    func readFloat()->Float{
        return intBitsToFloat(bits: readRawLittleEndian32())
    }
    
    func readRawVarint64()->Int64{
        var tempPos:Int
        var x:Int64;
        tempPos = pos;
        if (limit != tempPos) {
            let tb = buffer;
            var y = tb[tempPos]
            tempPos+=1
            if (y >= 0) {
                pos = tempPos;
                return Int64(y);
            }
            
            if (limit - tempPos >= 9) {
                y = y ^ tb[tempPos] << 7
                tempPos+=1
                if (y < 0) {
                    x = Int64(y ^ -128);
                    pos = tempPos;
                    return x;
                }
                
                y ^= tb[tempPos] << 14
                tempPos+=1
                if (y >= 0) {
                    x = Int64(y ^ 16256);
                    pos = tempPos;
                    return x;
                }
                
                y ^= tb[tempPos] << 21
                tempPos+=1
                if (y < 0) {
                    x = Int64(y ^ -2080896);
                    pos = tempPos;
                    return x;
                }
                
                x = Int64(y) ^ Int64(tb[tempPos]) << 28
                tempPos+=1
                if (x >= 0) {
                    x ^= 266354560;
                    pos = tempPos;
                    return Int64(x);
                }
                
                x ^= Int64(tb[tempPos]) << 35
                tempPos+=1
                if (x < 0) {
                    x ^= -34093383808;
                    pos = tempPos;
                    return Int64(x);
                }
                
                x ^= Int64(tb[tempPos]) << 42
                tempPos+=1
                if (x >= 0) {
                    x ^= 4363953127296;
                    pos = tempPos;
                    return Int64(x);
                }
                
                x ^= Int64(tb[tempPos]) << 49
                tempPos+=1
                if (x < 0) {
                    x ^= -558586000294016;
                    pos = tempPos;
                    return Int64(x);
                }
                
                x ^= Int64(tb[tempPos]) << 56
                tempPos+=1
                x ^= 71499008037633920;
                if(x >= 0){
                    pos = tempPos;
                    return x;
                }else{
                    let z = buffer[tempPos]
                    tempPos += 1
                    if(z >= 0){
                        pos = tempPos;
                        return x;
                    }
                }
            }
        }
        return readRawVarint64SlowPath()
    }
    
    func readRawVarint32()->Int{
        var tempPos:Int
        var x:Int;
        tempPos = pos;
        if (limit != tempPos) {
            let tb = buffer;
            x = tb[tempPos]
            tempPos+=1
            if (x >= 0) {
                pos = tempPos;
                return x;
            }
            
            if (limit - tempPos >= 9) {
                x = x ^ tb[tempPos] << 7
                tempPos+=1
                if (x < 0) {
                    x ^= -128;
                    pos = tempPos;
                    return x;
                }
                
                x ^= tb[tempPos] << 14
                tempPos+=1
                if (x >= 0) {
                    x ^= 16256;
                    pos = tempPos;
                    return x;
                }
                
                x ^= tb[tempPos] << 21
                tempPos+=1
                if (x < 0) {
                    x ^= -2080896;
                    pos = tempPos;
                    return x;
                }
                
                let y = tb[tempPos];
                tempPos+=1
                x ^= y << 28;
                x ^= 266354560;
                let b1 = tb[tempPos]
                tempPos+=1
                let b2 = tb[tempPos]
                tempPos+=1
                let b3 = tb[tempPos]
                tempPos+=1
                let b4 = tb[tempPos]
                tempPos+=1
                let b5 = tb[tempPos]
                tempPos+=1
                if (y >= 0 || b1 >= 0 || b2 >= 0 || b3 >= 0 || b4 >= 0 || b5 >= 0) {
                    pos = tempPos;
                    return x;
                }
            }
        }
        return Int(readRawVarint64SlowPath())
    }
    func readRawVarint64SlowPath()->Int64{
        var result = 0
        for var shift in [0,7,14,21,28,35,42,49,56,63]{
            let b = readRawByte();
            result |= (b & 127) << shift
            if((b & 128) == 0){
                return Int64(result);
            }
            shift+=7
        }
        return 0
    }
    func readRawByte()->Int{
        let result =  buffer[pos]
        pos+=1
        return result
    }
}
