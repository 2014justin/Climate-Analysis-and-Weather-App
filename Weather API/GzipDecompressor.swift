/// Decompresses the .gz METAR file. it is roughly 232 KB compressed
/// and 968 KB uncompressed.

import Foundation
import zlib

enum GzipDecompressionError: LocalizedError, Sendable {
    case initializationFailed(Int32)
    case decompressionFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .initializationFailed(let status):
            return "Could not initialize gzip decompression. Status: \(status)."

        case .decompressionFailed(let status):
            return "Could not decompress the gzip data. Status: \(status)."
        }
    }
}

struct GzipDecompressor: Sendable {
    func decompress(
        _ compressedData: Data
    ) throws -> Data {
        guard !compressedData.isEmpty else {
            return Data()
        }

        var stream = z_stream()

        /// The 15 + 32 tells zlib to recognize either a gzip header or a normal zlib header. Aviation Weather supplies gzip.
        let initializationStatus = inflateInit2_(
            &stream,
            15 + 32,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        )

        guard initializationStatus == Z_OK else {
            throw GzipDecompressionError
                .initializationFailed(initializationStatus)
        }

        defer {
            inflateEnd(&stream)
        }

        let chunkSize = 64 * 1024

        var output = Data()
        output.reserveCapacity(
            compressedData.count * 8
        )

        try compressedData.withUnsafeBytes {
            compressedBuffer in

            guard let compressedBaseAddress =
                    compressedBuffer.baseAddress else {
                return
            }

            stream.next_in = UnsafeMutablePointer<Bytef>(
                mutating: compressedBaseAddress
                    .assumingMemoryBound(to: Bytef.self)
            )

            stream.avail_in = uInt(
                compressedData.count
            )

            var status: Int32 = Z_OK

            repeat {
                var chunk = [UInt8](
                    repeating: 0,
                    count: chunkSize
                )

                status = chunk.withUnsafeMutableBytes {
                    chunkBuffer in

                    stream.next_out =
                        chunkBuffer.baseAddress?
                            .assumingMemoryBound(
                                to: Bytef.self
                            )

                    stream.avail_out = uInt(
                        chunkSize
                    )

                    return inflate(
                        &stream,
                        Z_NO_FLUSH
                    )
                }

                guard status == Z_OK
                        || status == Z_STREAM_END else {
                    throw GzipDecompressionError
                        .decompressionFailed(status)
                }

                let producedByteCount =
                    chunkSize - Int(stream.avail_out)

                output.append(
                    contentsOf:
                        chunk.prefix(producedByteCount)
                )
            } while status != Z_STREAM_END
        }

        return output
    }
}
