-- Copyright 2023 Lennart Augustsson
-- See LICENSE file for full license.
module Data.Char(
  module Data.Char,
  module Data.Char_Type       -- exports Char and String
  ) where
import qualified Prelude()              -- do not import Prelude
import Primitives
import Control.Error
import Data.Bool
import Data.Bounded
import Data.Char_Type
import {-# SOURCE #-} qualified Data.Char.Unicode as U
import Data.Eq
import Data.Function
import Data.Int
import Data.List_Type
import Data.Num
import Data.Ord
import Text.Show

instance Eq Char where
  (==) = primCharEQ
  (/=) = primCharNE

instance Ord Char where
  compare = primCharCompare
  (<)  = primCharLT
  (<=) = primCharLE
  (>)  = primCharGT
  (>=) = primCharGE

-- Using primitive comparison is still a small speedup, even using mostly bytestrings
instance Eq String where
  (==) = primStringEQ

instance Ord String where
  compare =  primStringCompare
  x <  y  =  case primStringCompare x y of { LT -> True; _ -> False }
  x <= y  =  case primStringCompare x y of { GT -> False; _ -> True }
  x >  y  =  case primStringCompare x y of { GT -> True; _ -> False }
  x >= y  =  case primStringCompare x y of { LT -> False; _ -> True }

instance Bounded Char where
  minBound = chr 0
  maxBound = chr 0x10ffff

chr :: Int -> Char
chr = primChr

ord :: Char -> Int
ord = primOrd

isLower :: Char -> Bool
isLower c =
  if primCharLE c '\177' then
     isAsciiLower c
  else
     U.isLower c

isAsciiLower :: Char -> Bool
isAsciiLower c = 'a' <= c && c <= 'z'

isUpper :: Char -> Bool
isUpper c =
  if isAscii c then
    isAsciiUpper c
  else
    U.isUpper c

isAsciiUpper :: Char -> Bool
isAsciiUpper c = 'A' <= c && c <= 'Z'

isAlpha :: Char -> Bool
isAlpha c =
  if isAscii c then
    isLower c || isUpper c
  else
    U.isAlpha c

isDigit :: Char -> Bool
isDigit c = '0' <= c && c <= '9'

isOctDigit :: Char -> Bool
isOctDigit c = '0' <= c && c <= '7'

isHexDigit :: Char -> Bool
isHexDigit c = isDigit c || ('a' <= c && c <= 'f') || ('A' <= c && c <= 'F')

isAlphaNum :: Char -> Bool
isAlphaNum c =
  if isAscii c then
    isAlpha c || isDigit c
  else
    U.isAlphaNum c

isSymbol :: Char -> Bool
isSymbol c =
 if isAscii c then
   c == '$' || c == '+' || c == '<' || c == '=' || c == '>' || c == '^' || c == '`' || c == '|' || c == '~'
 else
   U.isSymbol c

isPrint :: Char -> Bool
isPrint c =
  if isAscii c then
    ' ' <= c && c <= '~'
  else
    U.isPrint c

isSpace :: Char -> Bool
isSpace c =
  if isAscii c then
    c == ' ' || c == '\t' || c == '\n'
  else
    U.isSpace c

isAscii :: Char -> Bool
isAscii c = c <= '\127'

isControl :: Char -> Bool
isControl c = c <= '\31' || c == '\127'

isLetter :: Char -> Bool
isLetter = isAlpha

digitToInt :: Char -> Int
digitToInt c | (primCharLE '0' c) && (primCharLE c '9') = ord c - ord '0'
             | (primCharLE 'a' c) && (primCharLE c 'f') = ord c - (ord 'a' - 10)
             | (primCharLE 'A' c) && (primCharLE c 'F') = ord c - (ord 'A' - 10)
             | otherwise                                = error "digitToInt"

intToDigit :: Int -> Char
intToDigit i | i < 10 = chr (ord '0' + i)
             | otherwise = chr (ord 'A' - 10 + i)

toLower :: Char -> Char
toLower c | 'A' <= c && c <= 'Z' = chr (ord c - ord 'A' + ord 'a')
          | isAscii c = c
          | True = U.toLower c

toUpper :: Char -> Char
toUpper c | 'a' <= c && c <= 'a' = chr (ord c - ord 'a' + ord 'A')
          | isAscii c = c
          | True = U.toUpper c

instance Show Char where
  showsPrec _ '\'' = showString "'\\''"
  showsPrec _ c = showChar '\'' . showString (encodeChar c "") . showChar '\''
  showList    s = showChar '"'  . f s
    where f [] = showChar '"'
          f (c:cs) =
            if c == '"' then showString "\\\"" . f cs
            else showString (encodeChar c cs) . f cs

-- XXX should not export this
encodeChar :: Char -> String -> String
encodeChar c rest =
  let
    needProtect =
      case rest of
        [] -> False
        c : _ -> isDigit c
    spec = [('\a',"\\a"::String), ('\b', "\\b"::String), ('\f', "\\f"::String), ('\n', "\\n"::String),
            ('\r', "\\r"::String), ('\t', "\\t"::String), ('\v', "\\v"::String), ('\\', "\\\\"::String)]
    look [] = if isAscii c && isPrint c then [c] else ("\\"::String) ++ show (ord c) ++ if needProtect then "\\&"::String else []
    look ((d,s):xs) = if d == c then s else look xs
  in look spec
