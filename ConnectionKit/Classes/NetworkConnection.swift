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
    
    final private let connection: NWConnection
    final public let host: Host
    final public let port: Port
    final private let queue: DispatchQueue
    
    public init(host: Host,
                port: Port,
                delegate: ConnectionDelegate?,
                errorDelegate: ConnectionErrorDelegate?) {
        self.host = host
        self.port = port
        self.delegate = delegate
        self.errorDelegate = errorDelegate
        self.queue = DispatchQueue(label: "ConnectionKit.connection.queue",
                                   qos: DispatchQoS.userInitiated,
                                   autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem)
        let tcpOptions = NWProtocolTCP.Options()
        tcpOptions.connectionTimeout = 5
        tcpOptions.enableKeepalive = true
        let parameters = NWParameters(tls: nil, tcp: tcpOptions)
        parameters.expiredDNSBehavior = .allow
        parameters.serviceClass = .responsiveData
        self.connection = NWConnection(host: NWEndpoint.Host.name(host, nil),
                                       port: NWEndpoint.Port(rawValue: self.port)!,
                                       using: parameters)
        self.connection.stateUpdateHandler = { (state: NWConnection.State) in
            switch state {
            case NWConnection.State.ready:
                self.delegate?.didConnect(self)
                
            case NWConnection.State.failed(let error):
                print("ConnectionKit.NetworkConnection failed with \(error)")
                self.errorDelegate?.didFail(with: ConnectionError.connectionFailed)
                
            case NWConnection.State.waiting(let error):
                print("ConnectionKit.NetworkConnection waiting due to \(error)")
                self.delegate?.didDisconnect(self, reason: error)
            default:
                fatalError()
            }
        }
    }
    
    
    final public func connect() throws {
        self.connection.start(queue: self.queue)
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
                                print("ConnectionKit.NetworkConnection failed with \(error)")
        }))
    }
    
    
}
#endif
