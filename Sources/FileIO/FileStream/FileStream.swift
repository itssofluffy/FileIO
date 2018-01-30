/*
    FileStream.swift

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

public class FileStream: FileIO {
    // The file pointer of the opened file stream.
    public let filePointer: FileStreamPointer
    // The filename of the opened file stream.
    public let filename:    String
    // The string encoding to use for reading and writing strings.
    public var encoding:    String.Encoding = .utf8
    // The mode that the file stream was opened with.
    public let mode:        FileStreamMode

    // The number of bytes that have been read.
    public fileprivate(set) var bytesRead:    UInt64 = 0
    // The number of bytes that have been written.
    public fileprivate(set) var bytesWritten: UInt64 = 0

    public fileprivate(set) var bufferType: FileStreamBufferType = .None
    public fileprivate(set) var buffer = FileStreamBuffer()

    /// Opens a file stream in a specified mode.
    ///
    /// - Parameters:
    ///   - filename:   The full pathname of the file stream to open.
    ///   - mode:       The mode to open the file stream in.
    ///
    /// - Throws: `FileIOError.OpenStream`
    public init(filename: String, mode: FileStreamMode) throws {
        let fp = filename.withCString { file in
            return mode.rawValue.withCString { filemode in
                return fopen(file, filemode)
            }
        }

        guard (fp != nil) else {
            throw FileIOError.OpenStream(filename: filename, mode: mode, code: errno)
        }

        self.filePointer = fp!
        self.filename = filename
        self.mode = mode
    }

    deinit {
        wrapper(do: {
                    guard (fclose(self.filePointer) == 0) else {
                        throw FileIOError.Close(filename: self.filename, code: errno)
                    }
                },
                catch: { failure in
                    fileIOErrorLogger(failure)
                })
    }
}

extension FileStream {
    // The file descriptor of the opened file stream.
    public var fileDescriptor: CInt {
        return wrapper(do: {
                           let fd = fileno(self.filePointer)

                           guard (fd >= 0) else {
                               throw FileIOError.FileNo(filename: self.filename, code: errno)
                           }

                           return fd
                       },
                       catch: { failure in
                           fileIOErrorLogger(failure)
                       })!
    }

    public func clearError() {
        clearerr(filePointer)
    }

    public var hasError: Bool {
        return (ferror(filePointer) != 0)
    }

    public var endOfFile: Bool {
        return (feof(filePointer) != 0)
    }
}

extension FileStream {
    public var position: off_t {
        get {
            return wrapper(do: {
                               return try self.tell()
                           },
                           catch: { failure in
                               fileIOErrorLogger(failure)
                           })!
        }
        set {
            wrapper(do: {
                        try self.seek(to: .Begining, offset: newValue)
                    },
                    catch: { failure in
                        fileIOErrorLogger(failure)
                    })
        }
    }

    // The size of the file stream in bytes.
    public var size: Int {
        let offset = position

        wrapper(do: {
                    try self.seek(to: .End)
                },
                catch: { failure in
                    fileIOErrorLogger(failure)
                })

        let size = position
        position = offset

        return size
    }
}

extension FileStream {
    public func seek(to position: FileIOPosition, offset: off_t = 0) throws {
        precondition(offset >= 0, "offset must be greater than or equal to zero")

        guard (fseek(filePointer, offset, position.rawValue) == 0) else {
            throw FileIOError.Seek(filename: filename, to: position, offset: offset, code: errno)
        }
    }

    // The current position within the file stream in bytes.
    public func tell() throws -> Int {
        let position = ftell(filePointer)

        guard (position >= 0) else {
            throw FileIOError.Tell(filename: filename, code: errno)
        }

        return position
    }
}

extension FileStream {
    /// Read bytes from the filestream.
    ///
    /// - Parameters:
    ///   - count:   The number of bytes to read from the file.
    ///
    /// - Throws: `FileIOError.Read`
    ///           `FileIOError.EndOfFile`
    public func read(count: Int) throws -> Data {
        precondition(count > 0, "count must be greater than zero")

        let buffer = Array<Byte>(repeating: 0x00, count: count)

        guard (fread(UnsafeMutablePointer(mutating: buffer), 1, buffer.count, filePointer) == buffer.count) else {
            if (endOfFile) {
                throw FileIOError.EndOfFile(filename: filename)
            }

            throw FileIOError.Read(filename: filename, code: errno)
        }

        bytesRead += UInt64(buffer.count)

        return Data(buffer)
    }
}

extension FileStream {
    /// Write bytes to the filestream.
    ///
    /// - Parameters:
    ///   - data:   The bytes to write to the file.
    ///
    /// - Throws: `FileIOError.Write`
    public func write(_ data: Data) throws {
        precondition(data.count > 0, "data.count must be greater than zero")

        guard (fwrite(data.bytes, 1, data.count, filePointer) == data.count) else {
            throw FileIOError.Write(filename: filename, code: errno)
        }

        bytesWritten += UInt64(data.count)
    }
}

extension FileStream {
    public func setBuffer(to bufferType: FileStreamBufferType = .Full, bufferSize: Int) throws {
        precondition(bufferSize >= 0, "bufferSize must be greater than zero")

        buffer = FileStreamBuffer(repeating: 0x00, count: bufferSize)

        guard (setvbuf(filePointer, UnsafeMutablePointer(mutating: buffer), bufferType.rawValue, size) == 0) else {
            buffer = FileStreamBuffer()
            throw FileIOError.SetBuffer(filename: filename, bufferType: bufferType, size: size, code: errno)
        }

        self.bufferType = bufferType
    }

    public func flush() throws {
        guard (fflush(filePointer) == 0) else {
            throw FileIOError.Flush(filename: filename, code: errno)
        }
    }
}
