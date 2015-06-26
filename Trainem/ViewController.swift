//
//  ViewController.swift
//  Trainem
//
//  Created by Guy Kahlon on 6/3/15.
//  Copyright (c) 2015 GuyKahlon. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        let ints = [1,2,3,4,5]
        //Swift 1

        //map(filter(ints, {$0 % 1 == 0}), {$0 + 1})
        //Swift 2
        let newA = ints.map({$0 + 1}).filter({$0 % 2 == 0})
        
        print(newA)
        
        for character in "hello-world".characters.randomSequence(length: 5){
            character
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    var arr:Array<String>?

}

extension CollectionType {
    func randomSequence()->ProxySequence<Self>{
        return ProxySequence(self, length: nil, random:true)
    }
    
    func repeatingSequence()->ProxySequence<Self>{
        return ProxySequence(self,length: nil)
    }
    
    func randomSequence(length  length:Int)->ProxySequence<Self>{
        return ProxySequence(self, length: length, random:true)
    }
    
    func repeatingSequence(length  length:Int)->ProxySequence<Self>{
        return ProxySequence(self,length: length)
    }
}

struct ProxySequence<C: CollectionType> : SequenceType{
    let contents : C
    let length   : Int?
    let random   : Bool
    
    init(_ contents:C, length:Int?, random:Bool = false){
        self.contents = contents
        self.length   = length
        self.random   = random
    }
    
    func generate() -> ProxySequenceGenerator<C> {
        return ProxySequenceGenerator<C>(contents, length: length, random: random)
    }
}

struct ProxySequenceGenerator<C : CollectionType> : GeneratorType{
    let elements : [C.Generator.Element]
    let length : Int?
    var index = 0
    let random : Bool
    
    init(_ contents:C, length:Int?, random:Bool){
        
        self.length = length
        self.random = random
        
        var elements = Array<C.Generator.Element>()
        
        for elementIndex in contents.enumerate(){
            elements.append(elementIndex.element)
        }
        
        self.elements = elements
    }
    
    mutating func next() -> C.Generator.Element? {
        if let length = length where index == length{
            return nil
        }
        
        defer{
            index++
        }
        
        if random{
            return elements[Int(arc4random()) % elements.count]
        } else {
            return elements[index % elements.count]
        }
    }
}