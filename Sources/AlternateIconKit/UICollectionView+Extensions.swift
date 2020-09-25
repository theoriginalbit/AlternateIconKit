import UIKit

protocol CollectionReusableView: UICollectionReusableView {
    static var reuseIdentifier: String { get }
}

extension CollectionReusableView {
    static var reuseIdentifier: String {
        String(describing: self)
    }
}

protocol CollectionSupplementaryView: CollectionReusableView {
    static var elementKind: String { get }
}

extension UICollectionView {
    func registerCell<Cell: CollectionReusableView>(
        _ cellClass: Cell.Type
    ) {
        register(cellClass, forCellWithReuseIdentifier: cellClass.reuseIdentifier)
    }

    func registerSupplementaryView<Cell: CollectionSupplementaryView>(
        _ cellClass: Cell.Type
    ) {
        register(cellClass, forSupplementaryViewOfKind: cellClass.elementKind, withReuseIdentifier: cellClass.reuseIdentifier)
    }

    func dequeueReusableCell<Cell: CollectionReusableView>(
        _ cellClass: Cell.Type,
        for indexPath: IndexPath
    ) -> Cell {
        dequeueReusableCell(withReuseIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
    }

    func dequeueReusableSupplementaryView<Cell: CollectionSupplementaryView>(
        _ cellClass: Cell.Type,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> Cell {
        dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: cellClass.reuseIdentifier, for: indexPath) as! Cell
    }
}
