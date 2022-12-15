{-# OPTIONS_GHC -fplugin=Evoke -fplugin-opt=Evoke:--verbose #-}
{-# LANGUAGE DerivingVia #-}
module Lib
  ( someFunc,
  )
where

import Data.Aeson

data Person = Person
  { name :: String
  , age :: Int
  } deriving ToJSON via "Evoke"

someFunc :: IO ()
someFunc = do
  putStrLn $ ("hey" <>) . name $ Person "Fono" 923
