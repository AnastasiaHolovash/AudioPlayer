//
//  Summary.swift
//  HeadwayAudioPlayer
//
//  Created by Anastasia Holovash on 06.09.2024.
//

import Foundation

struct Summary {
    let imageURL: URL?
    let keyPoints: [KeyPoint] // IdentifiedArrayOf?

    struct KeyPoint {
        let orderNumber: Int
        let title: String
        let audioURL: URL?
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
