//
//  PersistenceController.swift
//  AuditLab
//
//  Core Data stack: main context for UI, optional background context for bulk work.
//

import CoreData

final class PersistenceController {

    static let shared = PersistenceController()

    let viewContext: NSManagedObjectContext

    private let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "AuditLab")

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

    /// Initializer for tests: use a file-backed store at the given URL so "restart" can be simulated with a new controller and same URL.
    init(storeURL: URL) {
        container = NSPersistentContainer(name: "AuditLab")
        let desc = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [desc]

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
