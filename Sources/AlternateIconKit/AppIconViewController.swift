import os.log
import UIKit

open class AppIconViewController: UIViewController {
    // MARK: - DataSource
    
    typealias DataSource = UICollectionViewDiffableDataSource<Bundle.AppIconAssetGroup, Bundle.AppIconAsset>
    
    // MARK: - Cell definitions
    
    class AppIconCell: UICollectionViewCell, CollectionReusableView {
        private static let cornerRadius: CGFloat = 13.5
        private static let padding: CGFloat = 6
        
        private let iconImageView = configure(UIImageView()) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = AppIconCell.cornerRadius
            $0.layer.cornerCurve = .continuous
            $0.clipsToBounds = true
            $0.contentMode = .scaleAspectFit
        }
        
        override var isHighlighted: Bool {
            didSet {
                selectedBackgroundView?.layer.borderColor = (isHighlighted ? UIColor.gray : UIView().tintColor).cgColor
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.addSubview(iconImageView)
            
            let selectedBackgroundView = configure(UIView()) {
                $0.translatesAutoresizingMaskIntoConstraints = true
                $0.backgroundColor = .clear
                $0.layer.cornerCurve = .continuous
                $0.layer.borderColor = UIView().tintColor.cgColor
                $0.clipsToBounds = true
            }
            self.selectedBackgroundView = selectedBackgroundView
            
            NSLayoutConstraint.activate([
                iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 60),
                iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            selectedBackgroundView?.layer.cornerRadius = Self.cornerRadius + Self.padding
            selectedBackgroundView?.layer.borderWidth = Self.padding / 2
        }
        
        func bind(to item: Bundle.AppIconAsset) {
            iconImageView.image = UIImage(named: item.assetName)
        }
    }
    
    class AppIconGroupHeader: UICollectionReusableView, CollectionSupplementaryView {
        static let elementKind = UICollectionView.elementKindSectionHeader
        
        private lazy var titleLabel = configure(UILabel()) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.font = .preferredFont(forTextStyle: .title3)
            $0.adjustsFontForContentSizeCategory = true
            $0.textColor = .label
            $0.numberOfLines = 0
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20),
                titleLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
                titleLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
                titleLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
        }
        
        func bind(to sectionName: String) {
            titleLabel.text = NSLocalizedString(sectionName, comment: "")
        }
    }
    
    // MARK: - Properties
    
    private var dataSource: DataSource!
    
    private var collectionView: UICollectionView {
        view as! UICollectionView
    }
    
    public convenience init() {
        self.init(nibName: nil, bundle: nil)
        navigationItem.title = "App Icon"
        navigationItem.largeTitleDisplayMode = .always
    }
    
    open override func loadView() {
        view = configure(UICollectionView(frame: .zero, collectionViewLayout: makeLayout())) {
            $0.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            $0.backgroundColor = .systemGroupedBackground
            $0.delegate = self
            $0.alwaysBounceVertical = true
            $0.registerCell(AppIconCell.self)
            $0.registerSupplementaryView(AppIconGroupHeader.self)
        }
        
        dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(AppIconCell.self, for: indexPath)
            cell.bind(to: item)
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard let self = self else { return nil }
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]
            guard let sectionName = section.name else { return nil }
            let view = collectionView.dequeueReusableSupplementaryView(AppIconGroupHeader.self, ofKind: kind, for: indexPath)
            view.bind(to: sectionName)
            return view
        }
        
        applyInitialSnapshot()
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // doing this in the trait collection refuses to work
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

// MARK: - UITableViewDelegate

extension AppIconViewController: UICollectionViewDelegate {
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        UIApplication.shared.setAlternateIconName(item.alternateIconName) { error in
            if let error = error {
                os_log(.error, "Unable to update alternate icon: %s", error.localizedDescription)
            }
        }
    }
}

private extension AppIconViewController {
    func applyInitialSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Bundle.AppIconAssetGroup, Bundle.AppIconAsset>()
        
        let groups = Bundle.main.appIcons
        snapshot.appendSections(groups)
        for group in groups {
            snapshot.appendItems(group.icons, toSection: group)
        }
        
        dataSource.apply(snapshot, animatingDifferences: false)
        
        // Select the current selected item
        let selectedIcon = UIApplication.shared.alternateIconName
        
        sectionSearch: for sectionIndex in groups.startIndex ..< groups.endIndex {
            let group = groups[sectionIndex].icons
            for itemIndex in group.startIndex ..< group.endIndex where group[itemIndex].alternateIconName == selectedIcon {
                collectionView.selectItem(at: IndexPath(item: itemIndex, section: sectionIndex), animated: false, scrollPosition: [])
                break sectionSearch
            }
        }
    }
    
    func makeLayout() -> UICollectionViewLayout {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 72, height: 72)
        flowLayout.sectionInsetReference = .fromLayoutMargins
        flowLayout.headerReferenceSize = UIView.layoutFittingExpandedSize
        flowLayout.headerReferenceSize.height = 44.0
        return flowLayout
    }
}
