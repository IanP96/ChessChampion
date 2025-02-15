//
//  Chess.swift
//  ChessChampion
//
//  Created by Ian Pinto on 6/11/20.
//  Copyright © 2020 Ian Pinto. All rights reserved.
//

import Foundation

// MARK: - Enumerations

/// The different possible colours in the game (white or black).
enum Colour: String {
    
    case white, black
    
}

/// The different piece types (pawn, knight, bishop, rook, queen, or king).
enum Piece: String {
    
    case pawn, knight, bishop, rook, queen, king
    
}

/// The different move types (standard, king-side castle and queen-side castle).
enum Move {
    
    case standard(colour: Colour, piece: Piece, start: (Int, Int), end: (Int, Int), capture: Piece?, promoteTo: Piece?)
    case kingCastle(colour: Colour), queenCastle(colour: Colour)
    
}

// MARK: - Constants

let colours = [Colour.white, Colour.black]
let pieces: [Piece] = [.pawn, .knight, .bishop, .rook, .queen, .king]
let pieceValues: [Piece: Int] = [.pawn: 1, .knight: 3, .bishop: 3, .rook: 5, .queen: 9]
/// The row where the main pieces (not pawns) are found for each colour.
let mainRows: [Colour: Int] = [.white: 0, .black: 7]
/// The rows where the pawns are found for each colour.
let pawnRows: [Colour: Int] = [.white: 1, .black: 6]

// MARK: - Functions

/// Gets the opponent's colour.
///
/// - Parameter colour: The colour.
///
/// - Returns: The opponent's colour.
func otherColour(_ colour: Colour) -> Colour {
    
    if colour == .white {
        return .black
    }
    return .white
    
}

/// Creates a two-dimensional list of pieces in the starting layout.
///
/// - Returns: A two-dimensional list of pieces in the starting layout.
func startPieces() -> [Colour: [[Piece?]]] {
    
    let emptyList = [[Piece?]](repeating: [Piece?](repeating: nil, count: 8), count: 8)
    var pieces = [Colour.white: emptyList, Colour.black: emptyList]
    
    let startPieces: [Piece] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
    for (colour, row) in mainRows {
        for x in 0..<8 {
            pieces[colour]![x][row] = startPieces[x]
        }
    }
    for (colour, row) in pawnRows {
        for x in 0..<8 {
            pieces[colour]![x][row] = .pawn
        }
    }
    
    return pieces
    
}

/// Evaluates the benefit of a move.
///
/// The benefit of a move equals:
/// - 100 if it results in checkmate;
/// - The value of the piece captured; or
/// - 0 if no piece is captured and checkmate is not a result.
///
/// - Parameters:
///   - colour: The colour to evaluate the benefit for.
///   - move: The move to evaluate.
///   - board: The board before the move.
///
/// - Returns: The benefit of the move.
func benefit(for colour: Colour, of move: Move, from board: Board) -> Int {
    
    let newBoard = board.newBoard(after: move)
    if newBoard.isInCheckmate(colour: otherColour(colour)) {
        return 50 * 100
    }
    // TODO: Experiment with different benefit values for checkmate
    var totalBenefit = 0
    switch move {
    case .standard(_, let piece, let start, let end, let capture, let promoteTo):
        if capture != nil {
            totalBenefit += pieceValues[capture!]! * 100
        }
        if promoteTo != nil {
            totalBenefit += pieceValues[promoteTo!]! * 100
        }
        // Additional benefits (i.e. not moving king, moving to centre, moving pieces up the board, castling)
        if piece != .king {
            if end.0 > 1 && end.0 < 6 {
                totalBenefit += 2
            }
            let yGain = (end.1 - start.1) * (colour == .white ? 1 : -1)
            totalBenefit += yGain
        }
    default: break
    }
    return totalBenefit
    
    /*
     switch $0 {
     case .standard(_, let piece, let start, let end, _, _):
         guard piece != .king && end.0 > 1 && end.0 < 6  else {
             return false
         }
         let yGain = end.1 - start.1
         return (yGain > 0 && colour == .white) || (yGain < 0 && colour == .black)
     default:
         return true // For any other case, it is castling
     }
     */
}

/// Evaluates if a given position is on the board (x and y are both between 0 and 7).
///
/// - Parameter position: The position to check.
///
/// - Returns: Whether the position is on the board.
func isValidSquare(_ position: (Int, Int)) -> Bool {
    
    return position.0 > -1 && position.0 < 8 && position.1 > -1 && position.1 < 8
    
}

// MARK: - Structures

/// A chess board and the layout of its pieces.
struct Board {
    
    var pieces: [Colour: [[Piece?]]]
    var kingMoved: [Colour: Bool]
    var rookMoved: [Colour: [Piece: Bool]]
    var kingPositions: [Colour: (Int, Int)]
    
    /// Initialises a board with starting positions.
    init() {
        
        // TODO: Give initialiser a specific name since there are other ways a board can be initialised other than from the start position
        
        pieces = startPieces()
        kingPositions = [.white: (4, 0), .black: (4, 7)]
        kingMoved = [.white: false, .black: false]
        rookMoved = [.white: [.king: false, .queen: false], .black: [.king: false, .queen: false]]
        
    }
    
    /// Moves a piece from one position to another, without capturing.
    ///
    /// - Parameters:
    ///   - colour: The colour of the piece.
    ///   - start: The start position in the form (x, y).
    ///   - end: The end position in the form (x, y).
    ///
    /// - Note: This function does not process captures.
    mutating func move(_ piece: Piece, ofColour colour: Colour, from start: (Int, Int), to end: (Int, Int)) {
        
        pieces[colour]![start.0][start.1] = nil
        pieces[colour]![end.0][end.1] = piece
        
    }
    
    /// Creates a new board after a certain move.
    ///
    /// - Parameter move: The move to process.
    ///
    /// - Returns: The new board after the move.
    func newBoard(after move: Move) -> Board {
        
        var newBoard = self
        switch move {
            
        case .standard(let colour, let piece, let start, let end, let capture, let promoteTo):
            
            if let promotionPiece = promoteTo {
                newBoard.removePiece(ofColour: colour, at: start)
                newBoard.pieces[colour]![end.0][end.1] = promotionPiece
                if capture != nil {
                    newBoard.removePiece(ofColour: otherColour(colour), at: end)
                }
                
            } else {
                newBoard.move(piece, ofColour: colour, from: start, to: end)
                if capture != nil {
                    newBoard.removePiece(ofColour: otherColour(colour), at: end)
                }
                if piece == .king {
                    newBoard.kingMoved[colour] = true
                    newBoard.kingPositions[colour] = end
                } else if piece == .rook {
                    if start.1 == mainRows[colour]! {
                        switch start.0 {
                        case 7:
                            newBoard.rookMoved[colour]![.king] = true
                        case 0:
                            newBoard.rookMoved[colour]![.queen] = true
                        default:
                            break
                        }
                    }
                }
            }
        
        case .kingCastle(let colour):
            let y = mainRows[colour]!
            newBoard.move(.king, ofColour: colour, from: (4, y), to: (6, y))
            newBoard.move(.rook, ofColour: colour, from: (7, y), to: (5, y))
            newBoard.kingMoved[colour] = true
        
        case .queenCastle(let colour):
            let y = mainRows[colour]!
            newBoard.move(.king, ofColour: colour, from: (4, y), to: (2, y))
            newBoard.move(.rook, ofColour: colour, from: (0, y), to: (3, y))
            newBoard.kingMoved[colour] = true
            
        }
        
        return newBoard
        
    }
    
    /// Evaluates whether the given player is in check.
    ///
    /// - Parameters:
    ///   - colour: The colour to check for.
    ///   - position: *(Optional)* If this is provided, the function evaluates whether a king at the given position would be in check.
    /// - Returns: Whether the given player is in check.
    func isInCheck2(colour: Colour, at position: (Int, Int)? = nil) -> Bool {
        
        var testBoard = self
        if let kingPosition = position {
            testBoard.pieces[colour]![kingPosition.0][kingPosition.1] = .king
        }
        
        let opponentMoves = testBoard.moves(for: otherColour(colour), forCheck: true)
        for move in opponentMoves {
            switch move {
            case .standard(_, _, _, _, let captureOptional, _):
                if let capture = captureOptional {
                    if capture == .king {
                        return true
                    }
                }
            default: break
            }
        }
        
        return false
        
    }
    
    /// Evaluates whether the given player is in check.
    ///
    /// - Parameters:
    ///   - colour: The colour to check for.
    ///   - position: *(Optional)* If this is provided, the function evaluates whether a king at the given position would be in check.
    /// - Returns: Whether the given player is in check.
    func isInCheck(colour: Colour, at position: (Int, Int)? = nil) -> Bool {
        
        var testBoard = self
        let kingPos: (Int, Int)
        if position != nil {
            testBoard.pieces[colour]![position!.0][position!.1] = .king
            kingPos = position!
        } else {
            kingPos = testBoard.kingPositions[colour]!
        }
        let ownPieces = pieces[colour]!
        let opponentPieces = pieces[otherColour(colour)]!
        
        // Pawn
        let direction = colour == .white ? 1 : -1
        for capturePos in [(kingPos.0 + 1, kingPos.1 + direction), (kingPos.0 - 1, kingPos.1 + direction)] {
            if isValidSquare(capturePos) {
                if let opponentPiece = opponentPieces[capturePos.0][capturePos.1] {
                    if opponentPiece == .pawn {
                        return true
                    }
                }
            }
        }
        
        // Knight
        let directions = [(1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1)]
        for direction in directions {
            let capturePos = (kingPos.0 + direction.0, kingPos.1 + direction.1)
            if isValidSquare(capturePos) {
                if let opponentPiece = opponentPieces[capturePos.0][capturePos.1] {
                    if opponentPiece == .knight {
                        return true
                    }
                }
            }
        }
        
        // Bishop/queen
        for move in mapLineMoves(for: .bishop, ofColour: colour, from: kingPos, ownPieces: ownPieces, opponentPieces: opponentPieces) {
            switch move {
            case .standard(_, _, _, _, let capturedPiece, _):
                if capturedPiece == .bishop || capturedPiece == .queen {
                    return true
                }
            default: break
            }
        }
        
        // Rook/queen
        for move in mapLineMoves(for: .rook, ofColour: colour, from: kingPos, ownPieces: ownPieces, opponentPieces: opponentPieces) {
            switch move {
            case .standard(_, _, _, _, let capturedPiece, _):
                if capturedPiece == .rook || capturedPiece == .queen {
                    return true
                }
            default: break
            }
        }
        
        // King
        for move in mapLineMoves(for: .king, ofColour: colour, from: kingPos, ownPieces: ownPieces, opponentPieces: opponentPieces) {
            switch move {
            case .standard(_, _, _, _, let capturedPiece, _):
                if capturedPiece == .king {
                    return true
                }
            default: break
            }
        }
        
        return false
        
    }
    
    /// Evaluates whether the given player is in checkmate.
    ///
    /// - Parameter colour: The colour to check for.
    /// - Returns: Whether the given player is in checkmate.
    func isInCheckmate(colour: Colour) -> Bool {
        return isInCheck(colour: colour) && legalMoves(for: colour).isEmpty
    }
    
    /// Evaluates whether the given player is in stalemate.
    ///
    /// - Parameter colour: The colour to check for.
    /// - Returns: Whether the given player is in stalemate.
    func isInStalemate(colour: Colour) -> Bool {
        return !isInCheck(colour: colour) && legalMoves(for: colour).isEmpty
    }
    
    /// Maps the possible moves for pieces that move in a linear direction (bishops, rooks, queens and kings; this function excludes pawns).
    ///
    /// - Warning: This function includes moves that may result in check.
    ///
    /// - Parameters:
    ///   - piece: The piece whose moves should be mapped.
    ///   - colour: The colour of the moving piece.
    ///   - start: The starting position of the piece.
    ///   - ownPieces: A nested array showing where there are other pieces of the same colour.
    ///   - opponentPieces: A nested array showing where there are other pieces of the opposite colour.
    ///
    /// - Returns: The possible moves.
    func mapLineMoves(for piece: Piece, ofColour colour: Colour, from start: (Int, Int), ownPieces: [[Piece?]], opponentPieces: [[Piece?]]) -> [Move] {
        
        var moves = [Move]()
        
        let directions: [(Int, Int)]
        switch piece {
        case .bishop:
            directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        case .rook:
            directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        case .queen, .king:
            directions = [(1, 1), (1, -1), (-1, 1), (-1, -1), (0, 1), (0, -1), (1, 0), (-1, 0)]
        default:
            directions = []
        }
        let maxDistance = piece == .king ? 1 : 7
        
        for direction in directions {
            for distance in 1...maxDistance {
                
                let end = (start.0 + direction.0 * distance, start.1 + direction.1 * distance)
                guard isValidSquare(end) else {
                    break
                }
                guard ownPieces[end.0][end.1] == nil else {
                    break
                }
                if let capturePiece = opponentPieces[end.0][end.1] {
                    moves.append(Move.standard(colour: colour, piece: piece, start: start, end: end, capture: capturePiece, promoteTo: nil))
                    break
                } else {
                    moves.append(Move.standard(colour: colour, piece: piece, start: start, end: end, capture: nil, promoteTo: nil))
                }
                
            }
        }
        return moves
        
    }
    
    // TODO: Consistently format all docstrings
    
    /// Finds all possible moves for the given colour.
    ///
    /// - Warning: This function includes moves that put the king in check.
    ///
    /// - Parameters:
    ///   - colour: The colour to check for.
    ///   - forCheck: Whether the given player is in check.
    ///
    /// - Returns: The list of possible moves.
    func moves(for colour: Colour, forCheck: Bool = false) -> [Move] {
        
        var moves = [Move]()
        let ownPieces = pieces[colour]!
        let opponentPieces = pieces[otherColour(colour)]!
        
        for x in 0..<8 {
            for y in 0..<8 {
                if let piece = pieces[colour]![x][y] {
                    
                    let start = (x, y)
                    
                    switch piece {
                        
                    case .pawn:
                        
                        // Not capturing
                        let direction = colour == .white ? 1 : -1
                        let promote = y == pawnRows[otherColour(colour)]
                        let endY = y + direction
                        var testPositions = [(x, endY)]
                        if y == pawnRows[colour] { // The pawn hasn't moved yet
                            testPositions.append((x, y + direction * 2))
                        }
                        for end in testPositions {
                            if ownPieces[x][end.1] == nil && opponentPieces[x][end.1] == nil {
                                if promote {
                                    for promotePiece in [Piece.knight, Piece.queen] {
                                        moves.append(Move.standard(colour: colour, piece: .pawn, start: start, end: end, capture: nil, promoteTo: promotePiece))
                                    }
                                } else {
                                    moves.append(Move.standard(colour: colour, piece: .pawn, start: start, end: end, capture: nil, promoteTo: nil))
                                }
                            } else {
                                break
                            }
                        }
                        
                        // Capturing
                        let captureTestPositions = [(x + 1, endY), (x - 1, endY)]
                        for end in captureTestPositions {
                            if isValidSquare(end) {
                                if let capturePiece = opponentPieces[end.0][endY] {
                                    if promote {
                                        for promotePiece in [Piece.knight, Piece.queen] {
                                            moves.append(Move.standard(colour: colour, piece: .pawn, start: start, end: end, capture: capturePiece, promoteTo: promotePiece))
                                        }
                                    } else {
                                        moves.append(Move.standard(colour: colour, piece: .pawn, start: start, end: end, capture: capturePiece, promoteTo: nil))
                                    }
                                }
                            }
                        }
                        
                        // TODO: Account for en passant
                    
                    case .knight:
                        let directions = [(1, 2), (1, -2), (-1, 2), (-1, -2), (2, 1), (2, -1), (-2, 1), (-2, -1)]
                        for direction in directions {
                            let end = (x + direction.0, y + direction.1)
                            if isValidSquare(end) {
                                if ownPieces[end.0][end.1] == nil {
                                    if let capturePiece = opponentPieces[end.0][end.1] {
                                        moves.append(Move.standard(colour: colour, piece: .knight, start: start, end: end, capture: capturePiece, promoteTo: nil))
                                    } else {
                                        moves.append(Move.standard(colour: colour, piece: .knight, start: start, end: end, capture: nil, promoteTo: nil))
                                    }
                                }
                            }
                        }
                    
                    case .bishop:
                        for move in mapLineMoves(for: .bishop, ofColour: colour, from: start, ownPieces: ownPieces, opponentPieces: opponentPieces) {
                            moves.append(move)
                        }
                    
                    case .rook:
                        for move in mapLineMoves(for: .rook, ofColour: colour, from: start, ownPieces: ownPieces, opponentPieces: opponentPieces) {
                            moves.append(move)
                        }
                        
                    case .queen:
                        for move in mapLineMoves(for: .queen, ofColour: colour, from: start, ownPieces: ownPieces, opponentPieces: opponentPieces) {
                            moves.append(move)
                        }
                    
                    case .king:
                        for move in mapLineMoves(for: .king, ofColour: colour, from: start, ownPieces: ownPieces, opponentPieces: opponentPieces) {
                            moves.append(move)
                        }
                        
                    }
                    
                }
            }
        }
        
        if !forCheck {
            // Castling
            let y = mainRows[colour]!
            for castleType in [Piece.king, Piece.queen] {
                guard !(kingMoved[colour]! || rookMoved[colour]![castleType]!) else {
                    continue
                }
                let passedSquares = castleType == .king ? [5, 6] : [1, 2, 3]
                let kingSquares = castleType == .king ? [4, 5, 6] : [4, 3, 2]
                var valid = true
                for x in passedSquares {
                    if !(ownPieces[x][y] == nil && opponentPieces[x][y] == nil) {
                        valid = false
                        break
                    }
                }
                guard valid else {
                    continue
                }
                for x in kingSquares {
                    let position = (x, y)
                    if isInCheck(colour: colour, at: position) {
                        valid = false
                        break
                    }
                }
                if valid {
                    moves.append(castleType == .king ? Move.kingCastle(colour: colour) : Move.queenCastle(colour: colour))
                }
            }
        }
        
        return moves
        
    }
    
    /// Finds all possible legal moves for the given colour.
    ///
    /// - Parameter colour: The colour to check for.
    ///
    /// - Returns: The list of legal moves.
    func legalMoves(for colour: Colour) -> [Move] {
        
        let allMoves = moves(for: colour, forCheck: false)
        // Filter out any moves that put the king in check
        return allMoves.filter({
            !newBoard(after: $0).isInCheck(colour: colour)
        })
        
    }
    
    /// Removes a piece from the board, either for promotion or a capture.
    ///
    /// - Parameters:
    ///   - colour: The colour of the piece to remove.
    ///   - position: The position of the piece to remove.
    mutating func removePiece(ofColour colour: Colour, at position: (Int, Int)) {
        
        pieces[colour]![position.0][position.1] = nil
        
    }
    
    // MARK: - The juicy functions
    
    /// Evaluates the best move for a given colour.
    ///
    /// - Parameter colour: The colour to check for.
    ///
    /// - Returns: The best possible move, or returns nil if no move is possible.
    func bestMove2(for colour: Colour) -> Move? {
        
        guard pieces != startPieces() else {
            // King's pawn opening
            return Move.standard(colour: colour, piece: .pawn, start: (4, 1), end: (4, 3), capture: nil, promoteTo: nil)
        }
        let move1map = legalMoves(for: colour)
        guard !move1map.isEmpty else {
            return nil
        }
        let move2map: [Move?] = move1map.map({
            let afterMove1 = newBoard(after: $0)
            let moves = afterMove1.legalMoves(for: otherColour(colour))
            guard !moves.isEmpty else {
                return nil
            }
            let moveBenefits: [Int] = moves.map({benefit(for: otherColour(colour), of: $0, from: afterMove1)})
            let bestMoveIndex = moveBenefits.firstIndex(of: moveBenefits.max()!)!
            return moves[bestMoveIndex]
        })
        var moveBenefits = [Int]()
        for moveIndex in move1map.indices {
            let move1 = move1map[moveIndex]
            let move2 = move2map[moveIndex]
            let moveBenefit: Int
            let afterMove1 = newBoard(after: move1)
            if move2 != nil {
                moveBenefit = benefit(for: colour, of: move1, from: self) - benefit(for: otherColour(colour), of: move2!, from: afterMove1)
            } else {
                if afterMove1.isInCheck(colour: otherColour(colour)) {
                    moveBenefit = 50
                } else {
                    moveBenefit = 0
                }
            }
            moveBenefits.append(moveBenefit)
        }
        let maxBenefit = moveBenefits.max()!
        var goodMoves = [Move]()
        for moveIndex in move1map.indices {
            if moveBenefits[moveIndex] == maxBenefit {
                goodMoves.append(move1map[moveIndex])
            }
        }
        if goodMoves.count == 1 {
            return goodMoves[0]
        }
        let goodCentreMoves = goodMoves.filter({
            switch $0 {
            case .standard(_, let piece, let start, let end, _, _):
                guard piece != .king && end.0 > 1 && end.0 < 6  else {
                    return false
                }
                let yGain = end.1 - start.1
                return (yGain > 0 && colour == .white) || (yGain < 0 && colour == .black)
            default:
                return true // For any other case, it is castling
            }
        })
        if goodCentreMoves.isEmpty {
            return goodMoves.randomElement()!
        } else {
            return goodCentreMoves.randomElement()!
        }
        
    }
    
    /// Evaluates the best move for a given colour.
    ///
    /// - Parameter colour: The colour to check for.
    ///
    /// - Returns: The best possible move, or returns nil if no move is possible.
    func bestMove(for colour: Colour) -> Move? {
        
        guard pieces != startPieces() else {
            // First move of the game - 3 is for Queen's Pawn, 4 is for King's Pawn
            let column = Int.random(in: 3...4)
            return Move.standard(colour: colour, piece: .pawn, start: (column, 1), end: (column, 3), capture: nil, promoteTo: nil)
            // TODO: Add more openings
        }
        
        let firstMoves = legalMoves(for: colour)
        guard firstMoves.count > 0 else {
            return nil
        }
        var moveMap = [Int]()
        for move1 in firstMoves {
            var benefits = [(Int, Int, Int)]()
            let move1Benefit = benefit(for: colour, of: move1, from: self)
            let board1 = newBoard(after: move1)
            let secondMoves = board1.legalMoves(for: otherColour(colour))
            if secondMoves.count == 0 {
                benefits.append((0, 0, 0))
            } else {
                
                for move2 in secondMoves {
                    let move2Benefit = -benefit(for: otherColour(colour), of: move2, from: board1) // Note the negative sign
                    let board2 = board1.newBoard(after: move2)
                    let thirdMoves = board2.legalMoves(for: colour)
                    if thirdMoves.count == 0 {
                        benefits.append((move2Benefit, 0, 0))
                    } else {
                        
                        for move3 in thirdMoves {
                            let move3Benefit = benefit(for: colour, of: move3, from: board2)
                            let board3 = board2.newBoard(after: move3)
                            let fourthMoves = board3.legalMoves(for: otherColour(colour))
                            if fourthMoves.count == 0 {
                                benefits.append((move2Benefit, move3Benefit, 0))
                            } else {
                                
                                var worstCase = 200 * 100
                                for move4 in fourthMoves {
                                    let move4Benefit = -benefit(for: otherColour(colour), of: move4, from: board3)
                                    if move4Benefit < worstCase {
                                        worstCase = move4Benefit
                                    }
                                }
                                benefits.append((move2Benefit, move3Benefit, worstCase))
                                
                            }
                        }
                        
                    }
                }
                
                let b0 = benefits.map({ $0.0 })
                for _0 in b0 {
                    let u = benefits.filter({ $0.0 == _0 })
                    let k = u.map({ $0.1 + $0.2 }).max()!
                    benefits.removeAll(where: { ($0.0 == _0) && ($0.1 + $0.2 < k) })
                }
                let j = benefits.map({ $0.0 + $0.1 + $0.2 }).min()!
                moveMap.append(move1Benefit + j)
                // TODO: Better names and commenting
                
            }
        }
                
        let index = moveMap.firstIndex(of: moveMap.max()!)!
        return firstMoves[index]
                
    }
    
}
