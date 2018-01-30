/*
    FileIOError.swift

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

/// Potential errors thrown.
public enum FileIOError: Error {
    case Open(filename: String, mode: FileMode, code: CInt)
    case OpenStream(filename: String, mode: FileStreamMode, code: CInt)
    case Close(filename: String, code: CInt)
    case FileNo(filename: String, code: CInt)
    case Seek(filename: String, to: FileIOPosition, offset: Int, code: CInt)
    case Tell(filename: String, code: CInt)
    case Read(filename: String, code: CInt)
    case EndOfFile(filename: String)
    case Write(filename: String, code: CInt)
    case SetBuffer(filename: String, bufferType: FileStreamBufferType, size: Int, code: CInt)
    case Flush(filename: String, code: CInt)
}

extension FileIOError: CustomStringConvertible {
    public var description: String {
        func errorString(_ code: CInt) -> String {
            return String(cString: strerror(code)) + " (#\(code))"
        }

        switch self {
            case .Open(let filename, let mode, let code):
                return "open('\(filename)', \(mode)) failed: " + errorString(code)
            case .OpenStream(let filename, let mode, let code):
                return "fopen('\(filename)', \(mode)) failed: " + errorString(code)
            case .Close(let filename, let code):
                return "close('\(filename)') failed: " + errorString(code)
            case .FileNo(let filename, let code):
                return "fileno('\(filename)') failed: " + errorString(code)
            case .Seek(let filename, let offset, let to, let code):
                return "seek('\(filename)', \(offset), \(to)) failed: " + errorString(code)
            case .Tell(let filename, let code):
                return "ftell('\(filename)') failed: " + errorString(code)
            case .Read(let filename, let code):
                return "read('\(filename)') failed: " + errorString(code)
            case .EndOfFile(let filename):
                return "feof('\(filename)')"
            case .Write(let filename, let code):
                return "write('\(filename)') failed: " + errorString(code)
            case .SetBuffer(let filename, let bufferType, let size, let code):
                return "setvbuf('\(filename)', \(bufferType), \(size)) failed: " + errorString(code)
            case .Flush(let filename, let code):
                return "fflush('\(filename)') failed: " + errorString(code)
        }
    }
}
