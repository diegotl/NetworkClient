
class HttpBinResponse: Codable {
    let slideshow: Slideshow
}

class Slideshow: Codable {
    let author: String
}
