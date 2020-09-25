func configure<T>(
    _ value: T,
    using block: (inout T) throws -> Void
) rethrows -> T {
    var value = value
    try block(&value)
    return value
}
