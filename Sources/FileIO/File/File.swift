/*
    File.swift

    Copyright (c) 2017, 2018 Stephen Whittle  All rights reserved.

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

#if os(Linux)
import Glibc
#else
import Darwin
#endif
import Foundation
import ISFLibrary

/// Basic file manipulation.
public class File: FileIO {
    // The file descriptor of the opened file.
    public let fileDescriptor: CInt
    // The filename of the opened file.
    public let filename:       String
    // The string encoding to use for reading and writing strings.
    public var encoding:       String.Encoding = .utf8
    // The mode that the file was opened with.
    public let mode:           FileMode

    // The number of bytes that have been read.
    public fileprivate(set) var bytesRead:    UInt64 = 0
    // The number of bytes that have been written.
    public fileprivate(set) var bytesWritten: UInt64 = 0

    /// Opens a file in a specified mode.
    ///
    /// - Parameters:
    ///   - filename:   The full pathname of the file to open.
    ///   - mode:       The mode to open the file in.
    ///
    /// - Throws: `FileIOError.Open`
    public init(filename: String, mode: FileMode) throws {
        let fd = filename.withCString { file in
            return open(file, mode.rawValue)
        }

        guard (fd >= 0) else {
            throw FileIOError.Open(filename: filename, mode: mode, code: errno)
        }

        self.fileDescriptor = fd
        self.filename = filename
        self.mode = mode
    }

    deinit {
        wrapper(do: {
                    guard (close(self.fileDescriptor) == 0) else {
                        throw FileIOError.Close(filename: self.filename, code: errno)
                    }
                },
                catch: { failure in
                    fileIOErrorLogger(failure)
                })
    }
}

extension File {
    /// Reposition read/write file offset.
    ///
    /// - Parameters:
    ///   - to:       The file position to base the offset on.
    ///     offset:   The offset from the file position specified.
    ///
    /// - Throws: `FileIOError.Seek`
#if os(Linux)
    public func seek(to position: FileIOPosition, offset: Int = 0) throws {
        precondition(offset >= 0, "offset must be greater than or equal to zero")

        guard (lseek(fileDescriptor, offset, position.rawValue) == 0) else {
            throw FileIOError.Seek(filename: filename, to: position, offset: offset, code: errno)
        }
    }
#else
    public func seek(to position: FileIOPosition, offset: off_t = 0) throws {
        precondition(offset >= 0, "offset must be greater than or equal to zero")

        guard (lseek(fileDescriptor, offset, position.rawValue) == 0) else {
            throw FileIOError.Seek(filename: filename, to: position, offset: offset, code: errno)
        }
    }
#endif
}

extension File {
    /// Read bytes from file.
    ///
    /// - Parameters:
    ///   - count:   The number of bytes to read from the file.
    ///
    /// - Throws: `FileIOError.Read`
    ///           `FileIOError.EndOfFile`
    public func read(count: Int) throws -> Data {
        precondition(count > 0, "count must be greater than zero")

        let buffer = Array<Byte>(repeating: 0x00, count: count)

#if os(Linux)
        let numberOfBytes = Glibc.read(fileDescriptor, UnsafeMutablePointer(mutating: buffer), buffer.count)
#else
        let numberOfBytes = Darwin.read(fileDescriptor, UnsafeMutablePointer(mutating: buffer), buffer.count)
#endif

        guard (numberOfBytes == buffer.count) else {
            if (numberOfBytes == 0) {
                throw FileIOError.EndOfFile(filename: filename)
            }

            throw FileIOError.Read(filename: filename, code: errno)
        }

        bytesRead += UInt64(buffer.count)

        return Data(buffer)
    }
}

extension File {
    /// Write bytes to file.
    ///
    /// - Parameters:
    ///   - data:   The bytes to write to the file.
    ///
    /// - Throws: `FileIOError.Write`
    public func write(_ data: Data) throws {
        precondition(data.count > 0, "data.count must be greater than zero")

#if os(Linux)
        let numberOfBytes = Glibc.write(fileDescriptor, data.bytes, data.count)
#else
        let numberOfBytes = Darwin.write(fileDescriptor, data.bytes, data.count)
#endif

        guard (numberOfBytes == data.count) else {
            throw FileIOError.Write(filename: filename, code: errno)
        }

        bytesWritten += UInt64(data.count)
    }
}
