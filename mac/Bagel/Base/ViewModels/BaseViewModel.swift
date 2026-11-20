//
//  BaseViewModel.swift
//  Bagel
//
//  Created by Yagiz Gurgul on 30/08/2018.
//  Copyright © 2018 Yagiz Lab. All rights reserved.
//

import Cocoa

@MainActor
class BaseViewModel: NSObject {

    var onChange: (()->())?
}
