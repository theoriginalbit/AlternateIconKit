import Foundation

extension Bundle {
    struct AppIconAssetGroup: Hashable {
        let identifier: Int
        let name: String?
        let icons: [AppIconAsset]
    }
    
    struct AppIconAsset: Hashable {
        let assetName: String
        let alternateIconName: String?
        fileprivate let groupIdentifier: Int
    }
    
    // swiftlint:disable force_cast
    var appIcons: [AppIconAssetGroup] {
        func extractIconFile(from definition: [String: Any]) -> String {
            (definition["CFBundleIconFiles"] as! [String])[0]
        }
        func extractGroupIdentifier(from definition: [String: Any]) -> Int {
            (definition["AIKGroupIdentifier"] as! Int)
        }
        let bundleIcons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as! [String: Any]
        let primaryIcon = bundleIcons["CFBundlePrimaryIcon"] as! [String: Any]
        let alternateIcons = bundleIcons["CFBundleAlternateIcons"] as! [String: Any]
        let groupTitles = bundleIcons["AIKGroupTitles"] as! [String]
        let primaryAsset = AppIconAsset(assetName: extractIconFile(from: primaryIcon),
                                        alternateIconName: nil,
                                        groupIdentifier: extractGroupIdentifier(from: primaryIcon))
        let icons = alternateIcons
            .map {
                let iconDefinition = $0.value as! [String: Any]
                return .init(assetName: extractIconFile(from: iconDefinition),
                             alternateIconName: $0.key,
                             groupIdentifier: extractGroupIdentifier(from: iconDefinition))
            }
            .reduce(into: [primaryAsset], { $0.append($1) })
        return Dictionary(grouping: icons, by: { $0.groupIdentifier })
            .map { AppIconAssetGroup(identifier: $0.key,
                                     name: groupTitles[$0.key],
                                     icons: $0.value.sorted(by: { $0.assetName < $1.assetName }))}
            .sorted(by: { $0.identifier < $1.identifier })
    }
}

private extension String {
    func commonPrefix(with other: String) -> String {
        return String(zip(self, other).prefix(while: { $0.0 == $0.1 }).map { $0.0 })
    }
}
