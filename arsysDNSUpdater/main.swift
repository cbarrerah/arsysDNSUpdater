//
//  main.swift
//  arsysDNSUpdater
//
//  Created by Carlos Barrera on 13/7/16.
//  Copyright © 2016 Carlos Barrera. All rights reserved.
//

import Foundation


class theParserDelegate: NSObject, XMLParserDelegate {
    var delegate : MyConnector?
    var currentElementName : String = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElementName = elementName
    }
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if currentElementName == "value" {
//            print(currentElementName)
            DispatchQueue.main.async(execute: { 
                print("Old IP: \(string)")
            })
            delegate?.oldIP = string
            delegate?.oldIPUpdated = true
        }
    }

}


class MyConnector: NSObject, URLSessionDelegate {
    let wsdlString = "https://api.servidoresdns.net:54321/hosting/api/soap/index.php?wsdl"
    let serverString = "https://api.servidoresdns.net:54321/hosting/api/soap/index.php"
    let username = Process.arguments[1]
    let password = Process.arguments[2]
    var oldIP = ""
    var newIP = ""
    var arsysSession : URLSession?
    var finished = false
    var oldIPUpdated = false
    var newIPUpdated = false
    
    let queue = DispatchQueue(label: "com.arsys.dnsUpdate")
    
    func updateIP() {
    }
    
    func getOldIP()
    {
        let aParser = theParserDelegate()

        aParser.delegate = self
        
        let postBodyString = "<SOAP-ENV:Envelope SOAP-ENV:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/'> <SOAP-ENV:Body> <InfoDNSZone xmlns='InfoDNSZone'> <input> <domain xsi:type='xsd:string'>\(username)</domain> <type xsi:type='xsd:string'>A</type> </input> </InfoDNSZone>  </SOAP-ENV:Body> </SOAP-ENV:Envelope>"

        let config = URLSessionConfiguration.default()
        let userPasswordString = "\(username):\(password)"
        let userPasswordData = userPasswordString.data(using: String.Encoding.utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString()
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString, "Content-Type": "text/xml; charset=utf-8"]
        self.arsysSession = URLSession(configuration: config)

        
        let url = URL(string: serverString)!
        
        var infoDNSRequest = URLRequest(url: url)
        
        let soapBody = postBodyString.data(using: String.Encoding.utf8)
        infoDNSRequest.httpMethod = "POST"
        infoDNSRequest.httpBody = soapBody

        let task = self.arsysSession?.dataTask(with: infoDNSRequest) {
            ( data,  response,  error) in
            if let _ = response as? HTTPURLResponse {
                let parser = XMLParser(data: data!)
                parser.delegate = aParser
                parser.parse()
            }
            
            self.queue.async {
                self.getNewIP()
            }

        }
        task?.resume()
    }
    
    func getNewIP()
    {

        //lets check the check my ip service and get our public IP
        let serverString = "http://httpbin.org/ip"
        
        let config = URLSessionConfiguration.default()
        let ipSession = URLSession(configuration: config)
        
        let task = ipSession.dataTask(with: URL(string: serverString)!) {
            ( data,  response,  error) in
            if let _ = response as? HTTPURLResponse {
//                let dataString = String(data: data!, encoding: String.Encoding.utf8)
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)
                    if let ip = json["origin"] as? String {
//                        print("New IP: \(ip)")
                        self.newIP = ip
                    }
                    
                } catch  {
                    print(error)
                }
                
            }
            self.queue.async {
                self.DNSEntryDecision()
            }

        }
        task.resume()
    }
    
    func DNSEntryDecision()
    {
        if self.oldIP == self.newIP {
            print("change not needed")
            finished = true
            DispatchQueue.main.async {
                exit(0)
            }
        } else {
            //let's change the dns register
//            print("change needed")
            print("Old: \(self.oldIP)  - New: \(self.newIP)")
            self.queue.async {
                self.updateDNSEntry(oldValue: self.oldIP, newValue: self.newIP)
            }
        }
    }
    
    func updateDNSEntry(oldValue:String, newValue:String) {
        
        let postBodyString = "<SOAP-ENV:Envelope SOAP-ENV:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:xsd='http://www.w3.org/2001/XMLSchema' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/'>     <soap:Body>     <ModifyDNSEntry xmlns='ModifyDNSEntry'>         <input>             <newvalue xsi:type='xsd:string'>\(self.newIP)</newvalue>              <currentvalue xsi:type='xsd:string'>\(self.oldIP)</currentvalue>              <dns xsi:type='xsd:string'>\(self.username)</dns>             <domain xsi:type='xsd:string'>\(self.username)</domain>              <currenttype xsi:type='xsd:string'>A</currenttype>         </input>      </ModifyDNSEntry> </soap:Body> </SOAP-ENV:Envelope>"
 
 
 let url = URL(string: serverString)!
 
 var modifyDNSEntryRequest = URLRequest(url: url)
 
 let soapBody = postBodyString.data(using: String.Encoding.utf8)
 modifyDNSEntryRequest.httpMethod = "POST"
 modifyDNSEntryRequest.httpBody = soapBody
        
        let task = self.arsysSession?.dataTask(with: modifyDNSEntryRequest) {
            ( data,  response,  error) in
            if let httpResponse = response as? HTTPURLResponse {
                //                let parser = XMLParser(data: data!)
                //                parser.delegate = aParser
                //                parser.parse()
                print(httpResponse.statusCode)
            }
            self.finished = true
            DispatchQueue.main.async {
                exit(0)
            }

        }
        
        task?.resume()

    }
}


let feliciano = MyConnector()
DispatchQueue.main.async {
    feliciano.getOldIP()

}
dispatchMain()
