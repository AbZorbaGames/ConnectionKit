//
//  NetworkConnection.swift
//  ConnectionKit
//
//  Created by Georges Boumis on 07/06/2018.
//
//  Licensed to the Apache Software Foundation (ASF) under one
//  or more contributor license agreements.  See the NOTICE file
//  distributed with this work for additional information
//  regarding copyright ownership.  The ASF licenses this file
//  to you under the Apache License, Version 2.0 (the
//  "License"); you may not use this file except in compliance
//  with the License.  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.
//

import Foundation
import RepresentationKit
#if canImport(Network)
import Network

@available(iOS 12, *)
public final class NetworkConnection: Connection {
    
    final public var delegate: ConnectionDelegate?
    final public var errorDelegate: ConnectionErrorDelegate?
    
    final private var connection: NWConnection!
    final public let host: Host
    final public let port: Port
    
    public init(host: Host,
                port: Port,
                delegate: ConnectionDelegate?,
                errorDelegate: ConnectionErrorDelegate?) {
        self.host = host
        self.port = port
        self.delegate = delegate
        self.errorDelegate = errorDelegate
        self.bootstrap()
    }
    
    deinit {
        self.disconnect()
    }
    
    final private func bootstrap() {
        
        let tcpOptions = NWProtocolTCP.Options()
//        tcpOptions.connectionTimeout = 5
//        tcpOptions.enableKeepalive = true
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.expiredDNSBehavior = .allow
        parameters.serviceClass = .responsiveData
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host.name(self.host, nil),
                                           port: NWEndpoint.Port(rawValue: self.port)!)
        self.connection = NWConnection(to: endpoint,
                                       using: parameters)
        self.connection.stateUpdateHandler = { [weak self] (state: NWConnection.State) in
            guard let strelf = self else { return }
            switch state {
            case NWConnection.State.ready:
                strelf.delegate?.didConnect(strelf)
                strelf.receive()
                
            case NWConnection.State.failed(let error):
                print("ConnectionKit.NetworkConnection.stateUpdateHandler failed with \(error)")
                strelf.errorDelegate?.didFail(with: ConnectionError.connectionFailed)
                strelf.bootstrap()
                
            case NWConnection.State.cancelled:
                strelf.delegate?.didDisconnect(strelf, reason: ConnectionError.disconnection)
            default:
                break
            }
        }
    }
    
    final private func receive() {
        self.connection.receive(minimumIncompleteLength: 1,
                                maximumLength: Int(Int16.max),
                                completion: { [weak self] (d: Data?, context: NWConnection.ContentContext?, isComplete: Bool, e: NWError?) in
            guard let strelf = self else { return }
            
            if let error = e {
                print("ConnectionKit.NetworkConnection.received failed with \(error)")
                strelf.errorDelegate?.didFail(with: ConnectionError.receiveFailed)
                return
            }
            
            guard let data = d, let jsonString = String(data: data, encoding: String.Encoding.utf8) else {
                print("ConnectionKit.NetworkConnection.received failed with data/json")
                strelf.errorDelegate?.didFail(with: ConnectionError.receiveFailed)
                return
            }
            let representable: Representable = jsonString.trimmingCharacters(in: CharacterSet.newlines)
            strelf.delegate?.didReceive(representable)
        })
    }
    
    
    final public func connect() throws {
        print("ConnectionKit.NetworkConnection.connect")
        if self.connection.state != NWConnection.State.setup {
            self.connection.forceCancel()
            self.bootstrap()
        }
        self.connection.start(queue: DispatchQueue.main)
    }
    
    final public func disconnect() {
        self.connection.forceCancel()
    }
    
    final public func close() {
        self.connection.cancel()
    }
    
    final public func send(_ representable: Representable) {
        var jsonBuilder: JSONRepresentationBuilder = JSONRepresentationBuilder()
        jsonBuilder = representable.represent(using: jsonBuilder)
        self.connection.send(content: jsonBuilder.jsonData,
                             completion: NWConnection.SendCompletion.contentProcessed({ (e: NWError?) in
                                guard let error = e else { return }
                                print("ConnectionKit.NetworkConnection.send failed with \(error)")
        }))
    }
}
#endif
