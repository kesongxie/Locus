//
//  PlayList.swift
//  Spottunes
//
//  Created by Xie kesong on 4/15/17.
//  Copyright © 2017 ___Spottunes___. All rights reserved.
//

import Foundation
import Parse


let PlayListRecordName = "playlist"
fileprivate let NameKey = "name"
fileprivate let CoverURLKey = "cover"
fileprivate let HitsKey = "hits"


class PlayList{
//    var coverURL: String?{
//        return self.object[CoverURLKey] as? String
//    }
//    
//    var name: String?{
//        return self.object[NameKey] as? String
//    }
//    
//    var hits: Int?{
//        return self.object[HitsKey] as? Int
//    }
    
    var coverURL: String?
    
    var name: String?
    
    var hits: Int!{
        guard let songs = songs else{
            return 0
        }
        return songs.reduce(0, { (results, song) -> Int in
            return results + song.hits
        })
    }
    
    var username: String?
    
    var object: PFObject!
    
    var songs:[Song]?
    
    var songPlaying: Song?
    
    init(object: PFObject) {
        self.object = object
    }
    
    init(coverURL: String, name: String, username: String){
        self.coverURL = coverURL
        self.name = name
        self.username = username
    }
    
    
    
    
}