module ChessPlay where

import Chess
import Chess qualified as C
import ChessAI
import ChessParser
import Control.Monad.State.Lazy
import Data.Array
import GameAI
import Parser qualified as P

-- | Starts a new game of chess
playGame :: IO ()
playGame = do
  putStrLn "Welcome to Chess!"
  putStrLn "Would you like to play against the computer? (Y/N)"
  ai <- getLine
  case ai of
    "N" -> playGameHuman C.initBoard
    "Y" -> do
      player <- getPlayerColor
      depth <- getSearchDepth
      playGameAI player depth C.initBoard
    _ -> do
      putStrLn "Invalid input!"
      playGame

-- | Gets the player's color
getPlayerColor :: IO Player
getPlayerColor = do
  putStrLn "Would you like to play as White or Black? (W/B)"
  player <- getLine
  case player of
    "W" -> return W
    "B" -> return B
    _ -> do
      putStrLn "Invalid player!"
      getPlayerColor

-- | Gets a move from the user
getUserMove :: Player -> IO C.Move
getUserMove p = do
  putStrLn "Enter a move:"
  move <- getLine
  let parsedMove = P.parse (parseChessMove p) move
  case parsedMove of
    Left _ -> do
      putStrLn "Invalid move!"
      getUserMove p
    Right m -> return m

-- | Plays a game of chess against another human
playGameHuman :: GameState -> IO ()
playGameHuman g = do
  print g
  move <- getUserMove (player g)
  let newG = C.move g move
  case C.checkResult newG of
    BlackWin -> print newG >> putStrLn "Game Over! Black wins!"
    WhiteWin -> print newG >> putStrLn "Game Over! White wins!"
    Draw -> print newG >> putStrLn "Game Over! Draw!"
    InProgress -> playGameHuman newG

-- | Get search depth from user
getSearchDepth :: IO Int
getSearchDepth = do
  putStrLn "Enter search depth (1-3):"
  depth <- getLine
  let parsedDepth = read depth :: Maybe Int
  case parsedDepth of
    Nothing -> do
      putStrLn "Invalid depth!"
      getSearchDepth
    Just d ->
      if d >= 1 && d <= 3
        then return d
        else do
          putStrLn "Invalid depth!"
          getSearchDepth

-- | Plays a game of chess against the AI
playGameAI :: Player -> Int -> GameState -> IO ()
playGameAI selected d g = do
  let currPlayer = player g
  print g
  if currPlayer == selected
    then do
      move <- getUserMove currPlayer
      let newG = C.move g move
      case C.checkResult newG of
        BlackWin -> print newG >> putStrLn "Game Over! Black wins!"
        WhiteWin -> print newG >> putStrLn "Game Over! White wins!"
        Draw -> print newG >> putStrLn "Game Over! Draw!"
        InProgress -> playGameAI selected d newG
    else do
      putStrLn "AI is thinking..."
      let move = alphaBetaSearch d g
      let newG = C.move g move
      case C.checkResult newG of
        BlackWin -> print newG >> putStrLn "Game Over! Black wins!"
        WhiteWin -> print newG >> putStrLn "Game Over! White wins!"
        Draw -> print newG >> putStrLn "Game Over! Draw!"
        InProgress -> playGameAI selected d newG