import XCTest
import Combine
import Logging
@testable import NetworkClient

enum TestEndpoints: Endpoint {
    case get
    case weather
    case empty
    case error500
    case download

    var method: RequestMethod {
        switch self {
        case .get, .weather, .empty, .error500, .download: return .get
        }
    }

    var host: String {
        switch self {
        case .get, .empty, .error500:
            return "httpbin.org"
        case .weather:
            return "api.weather.com"
        case .download:
            return "upload.wikimedia.org"
        }
        
    }
    
    var path: String {
        switch self {
        case .get:
            return "/json"
        case .weather:
            return "/v3/location/search?format=json"
        case .empty:
            return "/status/200"
        case .error500:
            return "/status/500"
        case .download:
            return "/wikipedia/commons/thumb/f/fa/Apple_logo_black.svg/195px-Apple_logo_black.svg.png"
        }
    }
}

final class NetworkClientTests: XCTestCase {

    private let networkClient = NetworkClient()

    override class func setUp() {
        super.setUp()
        NetworkClient.configuration = .init(logger: Logger(label: "network.client.tests"))
    }

    func testGetSuccess() throws {
        let urlRequest = try TestEndpoints.get.makeRequest()
        let successExpectation = expectation(description: "Success")

        let cancellable = networkClient.request(urlRequest: urlRequest).sink { completion in
            successExpectation.fulfill()
        } receiveValue: { (object: HttpBinResponse) in
            print(object)
        }

        wait(for: [successExpectation], timeout: 15.0)
        cancellable.cancel()
    }

    func testGetSuccessAsync() async throws {
        let urlRequest = try TestEndpoints.get.makeRequest()
        let response: HttpBinResponse = try await networkClient.request(urlRequest: urlRequest)
        XCTAssertNotNil(response)
    }

    func testGetMappedError() throws {
        let urlRequest = try TestEndpoints.weather.makeRequest()
        let failureExpectation = expectation(description: "Failure")

        let cancellable = networkClient.request(urlRequest: urlRequest).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print(error)
                failureExpectation.fulfill()
            }
        } receiveValue: { (object: HttpBinResponse) in
            print(object)
        }

        wait(for: [failureExpectation], timeout: 15.0)
        cancellable.cancel()
    }

    func testGetMappedErrorAsync() async throws {
        let urlRequest = try TestEndpoints.weather.makeRequest()
        do {
            let _: HttpBinResponse = try await networkClient.request(urlRequest: urlRequest)
            XCTFail("Call cannot succeed")
        } catch {
            XCTAssertNoThrow(error)
        }
    }

    func testGetEmptyResponseSuccess() throws {
        let urlRequest = try TestEndpoints.empty.makeRequest()
        let successExpectation = expectation(description: "Success")

        let cancellable = networkClient.request(urlRequest: urlRequest).sink { completion in
            switch completion {
            case .finished:
                successExpectation.fulfill()
            case .failure(let error):
                print(error)
            }
        } receiveValue: { (empty: EmptyResponse) in
            print(empty)
        }

        wait(for: [successExpectation], timeout: 15.0)
        cancellable.cancel()
    }

    func testGetEmptyResponseSuccessAsync() async throws {
        let urlRequest = try TestEndpoints.empty.makeRequest()
        let emptyResponse: EmptyResponse = try await networkClient.request(urlRequest: urlRequest)
        XCTAssertNotNil(emptyResponse)
    }

    func testGetEmptyResponseFailure() throws {
        let urlRequest = try TestEndpoints.error500.makeRequest()
        let successExpectation = expectation(description: "Failure")
        var responseCode: Int?

        let cancellable = networkClient.request(urlRequest: urlRequest).sink { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                if let error = error as? NetworkError {
                    switch error {
                    case .badRequest(let logData):
                        responseCode = logData.httpResponse?.statusCode
                    default:
                        break
                    }
                }

                successExpectation.fulfill()
            }
        } receiveValue: { (empty: EmptyResponse) in
            print(empty)
        }

        wait(for: [successExpectation], timeout: 15.0)
        cancellable.cancel()

        XCTAssertEqual(responseCode, 500)
    }

    func testGetEmptyResponseFailureAsync() async throws {
        let urlRequest = try TestEndpoints.error500.makeRequest()
        do {
            let _: EmptyResponse = try await networkClient.request(urlRequest: urlRequest)
            XCTFail("Call cannot succeed")
        } catch {
            if let error = error as? NetworkError {
                switch error {
                case .badRequest(let logData):
                    XCTAssertEqual(logData.httpResponse?.statusCode, 500)
                default:
                    XCTFail("Expected error to be NetworkError.badRequest")
                }
            } else {
                XCTFail("Expected error to be NetworkError")
            }
        }
    }

    func testDownloadSuccessAsync() async throws {
        let urlRequest = try TestEndpoints.download.makeRequest()
        let destination = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("logo.png")
        do {
            let url = try await networkClient.download(urlRequest: urlRequest, destination: destination, fileManager: .default)
            XCTAssertNotNil(url)
            try FileManager.default.removeItem(at: url)
        } catch {
            XCTFail("Failure not expected")
        }
    }

    static var allTests = [
        ("testGetSuccess", testGetSuccess),
        ("testGetSuccessAsync", testGetSuccessAsync),
        ("testGetMappedError", testGetMappedError),
        ("testGetMappedErrorAsync", testGetMappedErrorAsync),
        ("testGetEmptyResponseSuccess", testGetEmptyResponseSuccess),
        ("testGetEmptyResponseSuccessAsync", testGetEmptyResponseSuccessAsync),
        ("testGetEmptyResponseFailure", testGetEmptyResponseFailure),
        ("testGetEmptyResponseFailureAsync", testGetEmptyResponseFailureAsync),
        ("testDownloadSuccessAsync", testDownloadSuccessAsync)
    ]
}

