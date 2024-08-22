//
//  Time+CoreDataProperties.swift
//  OneDay
//
//  Created by 양문경 on 8/20/24.
//
//

import Foundation
import CoreData


extension Time {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Time> {
        return NSFetchRequest<Time>(entityName: "Time")
    }

    @NSManaged public var ampm: String?
    @NSManaged public var hour: Int16
    @NSManaged public var minute: Int16

}

extension Time : Identifiable {

}
