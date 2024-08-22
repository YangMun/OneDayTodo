//
//  Category+CoreDataProperties.swift
//  OneDay
//
//  Created by 양문경 on 8/20/24.
//
//

import Foundation
import CoreData


extension Category {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Category> {
        return NSFetchRequest<Category>(entityName: "Category")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var statuses: NSSet?
    @NSManaged public var user: User?

}

// MARK: Generated accessors for statuses
extension Category {

    @objc(addStatusesObject:)
    @NSManaged public func addToStatuses(_ value: Status)

    @objc(removeStatusesObject:)
    @NSManaged public func removeFromStatuses(_ value: Status)

    @objc(addStatuses:)
    @NSManaged public func addToStatuses(_ values: NSSet)

    @objc(removeStatuses:)
    @NSManaged public func removeFromStatuses(_ values: NSSet)

}

extension Category : Identifiable {

}
