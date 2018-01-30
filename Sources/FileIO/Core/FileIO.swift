/*
    FileIO.swift

    Copyright (c) 2017 Stephen Whittle  All rights reserved.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom
    the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
    THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    IN THE SOFTWARE.
*/

import Foundation
import ISFLibrary

public protocol FileIO {
    // The file descriptor of the opened file.
    var fileDescriptor: CInt { get }
    // The filename of the opened file.
    var filename:       String { get }
    // The string encoding to use for reading and writing strings.
    var encoding:       String.Encoding { get set }
    // The number of bytes that have been read.
    var bytesRead:      UInt64 { get }
    // The number of bytes that have been written.
    var bytesWritten:   UInt64 { get }

    /// Reposition read/write file or file stream offset.
    ///
    /// - Parameters:
    ///   - to:       The file position to base the offset on.
    ///     offset:   The offset from the file position specified.
    ///
    /// - Throws: `FileIOError.Seek`
    func seek(to position: FileIOPosition, offset: off_t) throws

    /// Read bytes from file or file stream.
    ///
    /// - Parameters:
    ///   - count:   The number of bytes to read from the file.
    ///
    /// - Throws: `FileIOError.Read`
    ///           `FileIOError.EndOfFile`
    func read(count: Int) throws -> Data

    /// Write bytes to file or file stream.
    ///
    /// - Parameters:
    ///   - data:   The bytes to write to the file.
    ///
    /// - Throws: `FileIOError.Write`
    func write(_ data: Data) throws
}

extension FileIO {
    /// Read a byte from file or file stream.
    ///
    /// - Throws: `FileIOError.Read`
    ///           `FileIOError.EndOfFile`
    public func read() throws -> Byte {
        return try read(count: 1)[0]
    }

    /// Read a string from file or file stream.
    ///
    /// - Parameters:
    ///   - count:   The number of bytes to read from the file.
    ///   - terminator:
    ///   - throwOnEndOfFile:
    ///
    /// - Throws: `FileIOError.Read`
    ///           `FileIOError.EndOfFile`
    public func read(count: Int = -1, terminator: String = "\n", throwOnEndOfFile: Bool = false) throws -> String {
        var buffer = Data()
        let terminator = (terminator.isEmpty) ? Data() : terminator.data(using: encoding)!

        while (count < 1 || (count > 0 && buffer.count < count)) {
            var byte: Byte

            do {
                byte = try read()
            } catch FileIOError.EndOfFile {
                if (throwOnEndOfFile) {
                    throw FileIOError.EndOfFile(filename: filename)
                }

                break
            }

            if (!terminator.isEmpty && ((buffer.count >= terminator.count) || (buffer.isEmpty && terminator.count == 1))) {
                var bufferTail = Data()

                if (terminator.count > 1) {
                    bufferTail = Data(buffer[(buffer.count + 1) - terminator.count ..< buffer.count])
                }

                bufferTail.append(byte)

                if (bufferTail == terminator) {
                    if (terminator.count > 1) {
                        buffer = Data(buffer[0 ... buffer.count - terminator.count])
                    }

                    break
                }
            }

            buffer.append(byte)
        }

        return (buffer.isEmpty) ? "" : String(data: buffer, encoding: encoding)!
    }
}

extension FileIO {
    /// Write a byte to file or file stream.
    ///
    /// - Throws: `FileIOError.Write`
    public func write(_ byte: Byte) throws {
        try write(Data(bytes: [byte]))
    }

    /// Write a string to file or file stream.
    ///
    /// - Parameters:
    ///   - string:   The bytes to write to the file.
    ///   - terminator:
    ///
    /// - Throws: `FileIOError.Write`
    public func write(_ string: String, terminator: String = "\n") throws {
        var data = string.data(using: encoding)!

        if (!terminator.isEmpty) {
            data.append(terminator.data(using: encoding)!)
        }

        try write(data)
    }
}
