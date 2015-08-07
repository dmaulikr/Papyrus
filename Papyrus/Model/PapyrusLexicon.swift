//
//  PapyrusLexicon.swift
//  Papyrus
//
//  Created by Chris Nevin on 11/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

struct Lexicon {
    static let sharedInstance = Lexicon()
    let DefKey = "Def"
    
    typealias LexiconType = [String: AnyObject]
    var dictionary: LexiconType?
    private init() {
        if let path = NSBundle.mainBundle().pathForResource("CSW12", ofType: "plist"), contents = NSDictionary(contentsOfFile: path) as? LexiconType {
            self.dictionary = contents
        }
    }
    
    /// Determine if a word is defined in the dictionary.
    func defined(word: String) throws -> String {
        var current = dictionary
        var index = word.startIndex
        for char in word.uppercaseString.characters {
            if let inner = current?[String(char)] as? LexiconType {
                index = advance(index, 1)
                if index == word.endIndex {
                    guard let def = inner[DefKey] as? String else {
                        throw ValidationError.Undefined(word)
                    }
                    return def
                }
                current = inner
            } else {
                throw ValidationError.Undefined(word)
            }
        }
        throw ValidationError.Undefined(word)
    }
    
    func anagramsOf(letters: String, length: Int? = Int.min, prefix: String, fixedLetters: [(Int, Character)], source: AnyObject, inout results: Set<String>) {
        // Cast as [String: AnyObject]
        guard let source = source as? LexiconType else {
            return
        }
        let prefixLength = prefix.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
        if let c = fixedLetters.filter({$0.0 == prefixLength}).map({$0.1}).first, newSource = source[String(c)] {
            let reverseFiltered = fixedLetters.filter({$0.0 != prefixLength})
            anagramsOf(letters, prefix: prefix + String(c), fixedLetters: reverseFiltered, source: newSource, results: &results)
            return
        }
        
        // See if word exists
        if let _ = source.indexForKey(DefKey) {
            // Add word to results
            if let length = length where length != Int.min && prefixLength == length {
                results.insert(prefix)
            } else if length! == Int.min {
                results.insert(prefix)
            }
        }
        // Before continuing...
        for (key, value) in source {
            // Search for ? or key
            if let range = letters.rangeOfString("?") ?? letters.rangeOfString(key) {
                // Strip key/?
                let newLetters = letters.stringByReplacingCharactersInRange(range, withString: "")
                // Create anagrams with remaining letters
                anagramsOf(newLetters, prefix: prefix + key, fixedLetters: fixedLetters, source: value, results: &results)
            }
        }
    }
}