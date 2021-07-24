import XCTest
import Combine
@testable import APIClient

final class APIClientTests: XCTestCase {

    private var cancellables = [AnyCancellable]()

    func testGetSuccess() {
        let endpoint = APIEndpoint(environment: TestEnvironment.httpbin, path: Path.json)
        let apiRequest = APIRequest(endpoint: endpoint)
        let successExpectation = expectation(description: "Success")

        APIClient()
            .execute(apiRequest: apiRequest)
            .sink { completion in
                switch completion {
                case .finished:
                    successExpectation.fulfill()
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { (object: HttpBinResponse) in
                print(object)
            }.store(in: &cancellables)

        wait(for: [successExpectation], timeout: 15.0)
    }

    func testGetMappedError() {
        let endpoint = APIEndpoint(environment: TestEnvironment.weather, path: Path.location)
        let apiRequest = APIRequest(endpoint: endpoint)
        let failureExpectation = expectation(description: "Failure")

        APIClient()
            .execute(apiRequest: apiRequest, errorType: RemoteError.self)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                    failureExpectation.fulfill()
                }
            } receiveValue: { (object: HttpBinResponse) in
                print(object)
            }.store(in: &cancellables)

        wait(for: [failureExpectation], timeout: 15.0)
    }

    func testGetEmptyReponseSuccess() {
        let endpoint = APIEndpoint(environment: TestEnvironment.httpbin, path: Path.empty(statusCode: 200))
        let apiRequest = APIRequest(endpoint: endpoint)
        let successExpectation = expectation(description: "Success")

        APIClient()
            .execute(apiRequest: apiRequest, accept: [200])
            .sink { completion in
                switch completion {
                case .finished:
                    successExpectation.fulfill()
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { empty in
                print(empty)
            }.store(in: &cancellables)

        wait(for: [successExpectation], timeout: 15.0)
    }

    func testGetEmptyReponseFailure() {
        let endpoint = APIEndpoint(environment: TestEnvironment.httpbin, path: Path.empty(statusCode: 500))
        let apiRequest = APIRequest(endpoint: endpoint)
        let successExpectation = expectation(description: "Failure")
        var responseCode: Int?

        APIClient()
            .execute(apiRequest: apiRequest, accept: [200])
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    responseCode = (error as? URLError)?.userInfo["response_code"] as? Int
                    successExpectation.fulfill()
                }
            } receiveValue: { empty in
                print(empty)
            }.store(in: &cancellables)

        wait(for: [successExpectation], timeout: 15.0)
        XCTAssertEqual(responseCode, 500)
    }

    func testDownload() {
        let endpoint = APIEndpoint(environment: TestEnvironment.apple, path: Path.image)
        let apiRequest = APIRequest(endpoint: endpoint)
        let successExpectation = expectation(description: "Success")

        let localPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("logo.png")

        APIClient()
            .download(apiRequest: apiRequest, destination: localPath)
            .sink { completion in
                switch completion {
                case .finished:
                    successExpectation.fulfill()
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { fileURL in
                print(fileURL)
            }.store(in: &cancellables)

        wait(for: [successExpectation], timeout: 15.0)
    }

    static var allTests = [
        ("testGetSuccess", testGetSuccess),
        ("testGetMappedErrorestGetSuccess", testGetMappedError),
        ("testDownload", testDownload)
    ]
}

