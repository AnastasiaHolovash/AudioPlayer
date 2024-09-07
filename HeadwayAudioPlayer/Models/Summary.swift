//
//  Summary.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 06.09.2024.
//

import Foundation
import IdentifiedCollections

struct Summary {
    struct KeyPoint: Identifiable {
        let orderNumber: Int
        let title: String
        let audioURL: URL?

        var id: Int {
            orderNumber
        }
    }

    let imageURL: URL?
    let keyPoints: IdentifiedArrayOf<KeyPoint>
}

extension Summary {

    var firstKeyPointOrderNumber: Int {
        keyPoints.first?.orderNumber ?? .zero
    }

    var lastKeyPointOrderNumber: Int {
        keyPoints.last?.orderNumber ?? .zero
    }

    func keyPointID(nextTo id: Int) -> Int? {
        guard let index = keyPoints.index(id: id),
              index < keyPoints.endIndex - 1
        else {
            return nil
        }

        return keyPoints.ids[keyPoints.index(after: index)]
    }

    func keyPointID(previousTo id: Int) -> Int? {
        guard let index = keyPoints.index(id: id),
              index > keyPoints.startIndex
        else {
            return nil
        }

        return keyPoints.ids[keyPoints.index(before: index)]
    }

}

extension Summary {

    static let zeroToOne = Summary(
        imageURL: URL(string: "https://static.get-headway.com/600_3182022704394b4587ab-15e0764877ed68.jpg"),
        keyPoints: [
            KeyPoint(
                orderNumber: 0,
                title: "Be unique to conquer the market",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F0_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 1,
                title: "The competition trap",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F1_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 2,
                title: "Find a way to control the market",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F2_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 3,
                title: "Realize the danger of indefinite optimism",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F3_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 4,
                title: "Secure a solid foundation for your startup",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F4_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 5,
                title: "Remember: you have to sell",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F5_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 6,
                title: "Combine technology and human effort",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F6_1707208816_en.mp3")
            ),
            KeyPoint(
                orderNumber: 7,
                title: "Conclusion",
                audioURL: URL(string: "https://static.get-headway.com/audio%2F3182022704394b4587ab%2FPatrick%2F7_1707208816_en.mp3")
            )
        ]
    )

}
