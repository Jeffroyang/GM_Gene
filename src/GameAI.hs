{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

module GameAI where

import Data.List (maximumBy)
import Data.Map qualified as Map
import Data.Ord (comparing)

-- | A searchable game is a game that can be searched using a tree
-- Moves should be ordered by best to worst to speed up the search
class (Ord (Move g)) => SearchableGame g where
  type Move g
  type Player g
  update :: g -> Move g -> g -- Updates the game state with a move
  gameOver :: g -> Bool -- Whether the game is over
  evaluate :: g -> Player g -> Int -- Passed in player is the maximizing player
  generateMoves :: g -> [Move g] -- All the possible moves from a given game state
  player :: g -> Player g -- The player whose turn it is

-- | Search the tree for the best move up to a certain depth
minimaxSearch :: forall g. (SearchableGame g) => g -> Int -> (Move g, Int)
minimaxSearch g d
  | d <= 0 = error "Cannot search to depth < 0"
  | otherwise = maximumBy (comparing snd) (map (\m -> (m, mini (update g m) p (d - 1))) (generateMoves g))
  where
    p = player g

maxi :: (SearchableGame g) => g -> Player g -> Int -> Int
maxi g p 0 = evaluate g p
maxi g p d =
  if gameOver g
    then evaluate g p
    else case generateMoves g of
      [] -> evaluate g p
      ms -> maximum (map (\m -> mini (update g m) p (d - 1)) ms)

mini :: (SearchableGame g) => g -> Player g -> Int -> Int
mini g p 0 = evaluate g p
mini g p d =
  if gameOver g
    then evaluate g p
    else case generateMoves g of
      [] -> evaluate g p
      ms -> minimum (map (\m -> maxi (update g m) p (d - 1)) ms)

-- | Search the tree for the best move up to a certain depth
negamaxSearch :: forall g. (SearchableGame g) => g -> Int -> (Move g, Int)
negamaxSearch g d
  | d <= 0 = error "Cannot search to depth < 0"
  | otherwise = maximumBy (comparing snd) (map (\m -> (m, -(negamax (update g m) (d - 1)))) (generateMoves g))
  where
    negamax :: (SearchableGame g) => g -> Int -> Int
    negamax g 0 = evaluate g p where p = player g
    negamax g d =
      if gameOver g
        then evaluate g p
        else case generateMoves g of
          [] -> evaluate g p
          ms -> maximum (map (\m -> -(negamax (update g m) (d - 1))) ms)
      where
        p = player g

-- | Search the tree for the best move up to a certain depth tracking alpha and beta
-- Alpha is the best value that the maximizing player can currently guarantee at that level or above
-- Beta is the best value that the minimizing player can currently guarantee at that level or above
alphaBetaSearch :: forall g. (SearchableGame g) => g -> Int -> (Move g, Int)
alphaBetaSearch g d
  | d <= 0 = error "Cannot search to depth < 0"
  | otherwise = foldl aux (head initMoves, minBound) initMoves
  where
    aux :: (SearchableGame g) => (Move g, Int) -> Move g -> (Move g, Int)
    aux (m, a) m' =
      let score = alphaBetaMin (update g m') p (d - 1) a maxBound
       in if score > a then (m', score) else (m, a)

    initMoves = generateMoves g
    p = player g

alphaBetaMax :: forall g. (SearchableGame g) => g -> Player g -> Int -> Int -> Int -> Int
alphaBetaMax g p 0 a b = evaluate g p
alphaBetaMax g p d a b =
  if gameOver g
    then evaluate g p
    else case generateMoves g of
      [] -> evaluate g p
      ms ->
        let evalMax :: (SearchableGame g) => Int -> Int -> [Move g] -> Int
            evalMax a' b' [] = a'
            evalMax a' b' (m' : ms') =
              let score = alphaBetaMin (update g m') p (d - 1) a' b'
               in if score >= b' then b' else evalMax (max a' score) b' ms'
         in evalMax a b ms

alphaBetaMin :: forall g. (SearchableGame g) => g -> Player g -> Int -> Int -> Int -> Int
alphaBetaMin g p 0 a b = evaluate g p
alphaBetaMin g p d a b =
  if gameOver g
    then evaluate g p
    else case generateMoves g of
      [] -> evaluate g p
      ms ->
        let evalMin :: (SearchableGame g) => Int -> Int -> [Move g] -> Int
            evalMin a' b' [] = b'
            evalMin a' b' (m' : ms') =
              let score = alphaBetaMax (update g m') p (d - 1) a' b'
               in if score <= a' then a' else evalMin a' (min b' score) ms'
         in evalMin a b ms