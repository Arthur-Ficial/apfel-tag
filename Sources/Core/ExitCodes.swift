// ============================================================================
// ExitCodes.swift - process exit codes for apfel-tag.
// ============================================================================

public enum ExitCodes {
    /// Success.
    public static let ok: Int32 = 0
    /// Generic runtime error (model unavailable, generation failure).
    public static let error: Int32 = 1
    /// Usage error: no input piped, or invalid arguments.
    public static let usage: Int32 = 2
}
