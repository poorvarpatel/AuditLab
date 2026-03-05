//
//  PersistenceController.swift
//  AuditLab
//
//  Core Data stack: main context for UI, optional background context for bulk work.
//  Uses a single NSManagedObjectModel so app and tests share one model (avoids "Multiple NSEntityDescriptions claim" crashes).
//

import CoreData

final class PersistenceController {

    /// Single model instance for the process so multiple containers (e.g. app + in-memory test) don't duplicate entity descriptions.
    private static let sharedModel: NSManagedObjectModel = {
        guard let url = Bundle.main.url(forResource: "AuditLab", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: url) else {
            fatalError("AuditLab.momd not found in bundle")
        }
        return model
    }()

    let viewContext: NSManagedObjectContext

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AuditLab", managedObjectModel: Self.sharedModel)

        if inMemory {
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        viewContext = container.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
