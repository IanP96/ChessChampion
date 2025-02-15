//
//  ViewController.swift
//  ChessChampion
//
//  Created by Ian Pinto on 1/9/20.
//  Copyright © 2020 Ian Pinto. All rights reserved.
//

import Cocoa

// MARK: - Variables and Constants

let drawMsg = "Draw by stalemate."
let winMsg = "You won by checkmate!"
let loseMsg = "You lost by checkmate."

var pieceImages = [Colour: [Piece: NSImage]]()
var pieceButtons = [[NSButton]](repeating: [NSButton](repeating: NSButton(image: NSImage(), target: nil, action: nil), count: 8), count: 8)

var boards = [Board()]
var movesBack = 0
var userColour = colours.randomElement()!
var selectedPosition: (Int, Int)? = nil
var possibleUserMoves = [Move]()
var gameFinished = false
var awaitingPromotion: (colour: Colour, piece: Piece, start: (Int, Int), end: (Int, Int), capture: Piece?)? = nil

class ViewController: NSViewController {
            
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        setStatus(to: "")
        kingCastleButton.isEnabled = false
        queenCastleButton.isEnabled = false
        for button in [queenPromoteButton, rookPromoteButton, bishopPromoteButton, knightPromoteButton] {
            button?.isHidden = true
        }
        promoteLabel.isHidden = true

        for colour in colours {
            var colourPieces = [Piece: NSImage]()
            for piece in pieces {
                colourPieces[piece] = NSImage(named: "\(colour.rawValue)\(piece.rawValue)")!
            }
            pieceImages[colour] = colourPieces
        }
        userColour = colours.randomElement()!

        for screenX in 0..<8 {
            for screenY in 0..<8 {
                let button = NSButton(image: NSImage(), target: self, action: #selector(pieceButtonPressed))
                button.title = ""
                button.setButtonType(.switch)
                button.frame = NSRect(x: 50 * (screenX + 1), y: 50 * (screenY + 1), width: 50, height: 50)
                button.identifier = NSUserInterfaceItemIdentifier(rawValue: "\(convert(screenX))\(convert(screenY))")
                pieceButtons[screenX][screenY] = button
                view.addSubview(button)
            }
        }
        
        update()
        if userColour == .white {
            userTurn()
        } else {
            comTurn()
        }
        
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var kingCastleButton: NSButton!
    @IBOutlet weak var queenCastleButton: NSButton!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var promoteLabel: NSTextField!
    @IBOutlet weak var queenPromoteButton: NSButton!
    @IBOutlet weak var rookPromoteButton: NSButton!
    @IBOutlet weak var bishopPromoteButton: NSButton!
    @IBOutlet weak var knightPromoteButton: NSButton!
    
    // MARK: - Actions
    
    @objc func pieceButtonPressed(sender: NSButton) {
        
        guard movesBack == 0 && awaitingPromotion == nil && !gameFinished else { return }
        
        let currentSelection = buttonPosition(sender)
        
        if let previousSelection = selectedPosition {
            if previousSelection == currentSelection {
                border(on: &pieceButtons[convert(currentSelection.0)][convert(currentSelection.1)], false)
                selectedPosition = nil
            } else {
                var found = false
                for move in possibleUserMoves {
                    switch move {
                    case .standard(let colour, let piece, let start, let end, let capture, let promoteTo):
                        if start == previousSelection && end == currentSelection {
                            border(on: &pieceButtons[convert(previousSelection.0)][convert(previousSelection.1)], false)
                            if promoteTo != nil {
                                awaitingPromotion = (colour: colour, piece: piece, start: start, end: end, capture: capture)
                                for button in [queenPromoteButton, rookPromoteButton, bishopPromoteButton, knightPromoteButton] {
                                    button?.isHidden = false
                                }
                                promoteLabel.isHidden = false
                            } else {
                                boards.append(boards.last!.newBoard(after: move))
                                update()
                                found = true
                                comTurn()
                            }
                        }
                    default: break
                    }
                    if found { break }
                }
                if !found {
                    border(on: &pieceButtons[convert(previousSelection.0)][convert(previousSelection.1)], false)
                    selectedPosition = nil
                }
            }
        } else {
            var found = false
            for move in possibleUserMoves {
                switch move {
                case .standard(_, _, let start, _, _, _):
                    if start == currentSelection {
                        border(on: &pieceButtons[convert(currentSelection.0)][convert(currentSelection.1)], true)
                        selectedPosition = currentSelection
                        found = true
                    }
                default: break
                }
                if found { break }
            }
            if !found {
                selectedPosition = nil
            }
        }
        
    }
    
    @IBAction func castleButtonPressed(_ sender: NSButton) {
        
        if let selection = selectedPosition {
            border(on: &pieceButtons[convert(selection.0)][convert(selection.1)], false)
            selectedPosition = nil
        }
        let move = sender.id == "kingside" ? Move.kingCastle(colour: userColour) : Move.queenCastle(colour: userColour)
        boards.append(boards.last!.newBoard(after: move))
        update()
        comTurn()
        
    }
    
    @IBAction func replayButtonPressed(_ sender: NSButton) {
        
        let maxReplay = boards.count - 1
        if let selection = selectedPosition {
            border(on: &pieceButtons[convert(selection.0)][convert(selection.1)], false)
            selectedPosition = nil
        }
        
        switch sender.id {
        case "back":
            if movesBack < maxReplay {
                movesBack += 1
            }
        case "start":
            movesBack = maxReplay
        case "forward":
            if movesBack > 0 {
                movesBack -= 1
            }
        case "end":
            movesBack = 0
        default: break
        }
        
        update()
        
    }
    
    @IBAction func promoteButtonPressed(_ sender: NSButton) {
        
        let promoteTo = Piece(rawValue: sender.id)
        boards.append(boards.last!.newBoard(after: Move.standard(colour: awaitingPromotion!.colour, piece: awaitingPromotion!.piece, start: awaitingPromotion!.start, end: awaitingPromotion!.end, capture: awaitingPromotion!.capture, promoteTo: promoteTo)))
        awaitingPromotion = nil
        for button in [queenPromoteButton, rookPromoteButton, bishopPromoteButton, knightPromoteButton] {
            button?.isHidden = true
        }
        promoteLabel.isHidden = true
        update()
        comTurn()
        
    }
    
    // MARK: - Game Functions
    
    func update() {
        
        for screenX in 0..<8 {
            for screenY in 0..<8 {
                pieceButtons[screenX][screenY].image = nil
                let position = buttonPosition(pieceButtons[screenX][screenY])
                for colour in colours {
                    if let piece = boards[boards.count - 1 - movesBack].pieces[colour]![position.0][position.1] {
                        pieceButtons[screenX][screenY].image = pieceImages[colour]![piece]
                    }
                }
            }
        }
        
    }
    
    func userTurn() {
        
        selectedPosition = nil
        let board = boards.last!
        possibleUserMoves = board.legalMoves(for: userColour)
        if possibleUserMoves.isEmpty {
            if board.isInCheck(colour: userColour) {
                setStatus(to: loseMsg)
            } else {
                setStatus(to: drawMsg)
            }
            gameFinished = true
        } else {
            for button in [kingCastleButton, queenCastleButton] {
                button?.isEnabled = false
            }
            for move in possibleUserMoves {
                switch move {
                case .kingCastle:
                    kingCastleButton.isEnabled = true
                case .queenCastle:
                    queenCastleButton.isEnabled = true
                default: break
                }
            }
        }
        
    }
    
    func comTurn() {
        
        setStatus(to: "Thinking...")
        
        for button in [kingCastleButton, queenCastleButton] {
            button?.isEnabled = false
        }
        
        let board = boards.last!
        setStatus(to: "Thinking...")
        if let move = board.bestMove(for: otherColour(userColour)) { // MARK: Edit this line
            boards.append(board.newBoard(after: move))
            update()
            setStatus(to: "")
            userTurn()
        } else {
            if board.isInCheck(colour: otherColour(userColour)) {
                setStatus(to: winMsg)
            } else {
                setStatus(to: drawMsg)
            }
            gameFinished = true
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func setStatus(to status: String) {
        if status == "" {
            statusLabel.isHidden = true
        } else {
            statusLabel.stringValue = status
            statusLabel.isHidden = false
        }
    }

}

// MARK: - UI Functions

func border(on button: inout NSButton, _ addBorder: Bool) {
    
    button.layer?.borderWidth = addBorder ? 5 : 0
    
}

func convert(_ coordinate: Int) -> Int {
    
    if userColour == .white {
        return coordinate
    } else {
        return 7 - coordinate
    }
    
}

func buttonPosition(_ button: NSButton) -> (Int, Int) {
    
    let x = Int(String(button.id.first!))!, y = Int(String(button.id.last!))!
    return (x, y)
    
}

// MARK: - Extensions

extension NSButton {
    
    var id: String {
        
        return identifier!.rawValue
        
    }
    
}
