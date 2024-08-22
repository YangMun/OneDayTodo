//
//  Status+CoreDataProperties.swift
//  OneDay
//
//  Created by 양문경 on 8/20/24.
//
//

import Foundation
import CoreData


extension Status {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Status> {
        return NSFetchRequest<Status>(entityName: "Status")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var selectedDate: Date?
    @NSManaged public var title: String?
    @NSManaged public var category: Category?
    @NSManaged public var user: User?

}

extension Status : Identifiable {

}
