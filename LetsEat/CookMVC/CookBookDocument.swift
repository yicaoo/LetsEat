//
//  CookBookDocument.swift
//  LetsEat
//
//  Created by Yi Cao on 5/24/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit

class CookBookDocument: UIDocument {
    
    var cookBook: CookBook?
    var thumbnail: UIImage?
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return cookBook?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load document from contents
        if let json = contents as? Data {
            cookBook = CookBook(json: json)
            
        }
    }
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocumentSaveOperation) throws -> [AnyHashable : Any] {
        var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
        if let thumbnail = self.thumbnail {
            attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey:thumbnail]
        }
        return attributes
    }
}

