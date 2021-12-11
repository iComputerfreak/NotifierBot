//
//  File.swift
//  
//
//  Created by Jonas Frey on 11.12.21.
//

import Foundation

public enum JFConfigError: Error {
    // Contains the line that is malformed
    case malformedLineSegments(String)
    // Contains the line with the malformed integers
    case malformedIntegers(String)
}
