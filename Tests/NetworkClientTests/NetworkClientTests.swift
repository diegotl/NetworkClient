import XCTest
import Combine
import Logging
@testable import NetworkClient

enum TestEndpoints: Endpoint {
    case get
    case weather
    case empty
    case error500

    var method: RequestMethod {
        switch self {
        case .get, .weather, .empty, .error500: return .get
        }
    }

    var host: String {
        switch self {
        case .get, .empty, .error500:
            return "httpbin.org"
        case .weather:
            return "api.weather.com"
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

    func testGetEmptyReponseSuccess() throws {
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

    func testGetEmptyReponseFailure() throws {
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
                    case .badRequest(_, let httpCode):
                        responseCode = httpCode
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

    static var allTests = [
        ("testGetSuccess", testGetSuccess),
        ("testGetMappedErrorestGetSuccess", testGetMappedError),
        ("testGetEmptyReponseSuccess", testGetEmptyReponseSuccess),
        ("testGetEmptyReponseFailure", testGetEmptyReponseFailure)
    ]
}

