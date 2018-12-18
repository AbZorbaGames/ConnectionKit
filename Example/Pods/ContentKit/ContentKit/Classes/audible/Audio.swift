//
//  Audio.swift
//  ContentKit
//
// Created by Georges Boumis on 09/12/2016.
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

/// Audio is an audible content that can be played and stopped.
public protocol Audio: AudibleContent {
    /// The duration of the receiver.
    var duration: TimeInterval { get }

    /// Begins playback of the receiver.
    func play()

    /// Stops the playback of the receiver.
    /// - parameter fadeOut: A Boolean indicating wether a face out should
    /// occur.
    func stop(fadeOut: Bool)
}
