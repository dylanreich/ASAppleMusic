//
//  Alex Silva - 2018
//  alex@alexsays.info
//

import Foundation
import EVReflection

// API doc: https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/AppleMusicWebServicesReference/AppleCurator.html

class AppleCurator: EVObject {

    var artwork: Artwork?
    var editorialNotes: EditorialNotes?
    var name: String?
    var url: URL?
    var playlists: [Playlist]?

}

