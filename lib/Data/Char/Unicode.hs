module Data.Char.Unicode (
        GeneralCategory (..), generalCategory,
        unicodeVersion,
        isControl,
        isPrint, isSpace, isUpper,
        isLower, isAlpha, isDigit,
        isAlphaNum, isNumber,
        isMark, isSeparator,
        isPunctuation, isSymbol,
        toTitle, toUpper, toLower,
    ) where
import qualified Prelude(); import MiniPrelude
import Primitives(primOrd, primUnsafeCoerce)
import Data.Bounded
import qualified Data.ByteString.Internal as BS
import Data.ByteString.Internal(ByteString)
import Data.Version
import System.Compress

data GeneralCategory
  = UppercaseLetter       -- Lu: Letter, Uppercase
  | LowercaseLetter       -- Ll: Letter, Lowercase
  | TitlecaseLetter       -- Lt: Letter, Titlecase
  | ModifierLetter        -- Lm: Letter, Modifier
  | OtherLetter           -- Lo: Letter, Other
  | NonSpacingMark        -- Mn: Mark, Non-Spacing
  | SpacingCombiningMark  -- Mc: Mark, Spacing Combining
  | EnclosingMark         -- Me: Mark, Enclosing
  | DecimalNumber         -- Nd: Number, Decimal
  | LetterNumber          -- Nl: Number, Letter
  | OtherNumber           -- No: Number, Other
  | ConnectorPunctuation  -- Pc: Punctuation, Connector
  | DashPunctuation       -- Pd: Punctuation, Dash
  | OpenPunctuation       -- Ps: Punctuation, Open
  | ClosePunctuation      -- Pe: Punctuation, Close
  | InitialQuote          -- Pi: Punctuation, Initial quote
  | FinalQuote            -- Pf: Punctuation, Final quote
  | OtherPunctuation      -- Po: Punctuation, Other
  | MathSymbol            -- Sm: Symbol, Math
  | CurrencySymbol        -- Sc: Symbol, Currency
  | ModifierSymbol        -- Sk: Symbol, Modifier
  | OtherSymbol           -- So: Symbol, Other
  | Space                 -- Zs: Separator, Space
  | LineSeparator         -- Zl: Separator, Line
  | ParagraphSeparator    -- Zp: Separator, Paragraph
  | Control               -- Cc: Other, Control
  | Format                -- Cf: Other, Format
  | Surrogate             -- Cs: Other, Surrogate
  | PrivateUse            -- Co: Other, Private Use
  | NotAssigned           -- Cn: Other, Not Assigned
  deriving (Show, Eq, Ord, Enum, Bounded)

isControl :: Char -> Bool
isControl c = bomb "isControl" c $
  case generalCategory c of
    Control -> True
    _       -> False

isPrint :: Char -> Bool
isPrint c = bomb "isPrint" c $
  case generalCategory c of
    LineSeparator      -> False
    ParagraphSeparator -> False
    Control            -> False
    Format             -> False
    Surrogate          -> False
    PrivateUse         -> False
    NotAssigned        -> False
    _                  -> True

isSpace :: Char -> Bool
isSpace c =  bomb "isSpace" c $
  generalCategory c == Space

isUpper :: Char -> Bool
isUpper c = bomb "isUpper" c $
  case generalCategory c of
    UppercaseLetter -> True
    TitlecaseLetter -> True
    _               -> False

isLower :: Char -> Bool
isLower c = bomb "isLower" c $
  case generalCategory c of
    LowercaseLetter -> True
    _               -> False

isAlpha :: Char -> Bool
isAlpha c = bomb "isAlpha" c $
  case generalCategory c of
    UppercaseLetter -> True
    LowercaseLetter -> True
    TitlecaseLetter -> True
    ModifierLetter  -> True
    OtherLetter     -> True
    _               -> False

isAlphaNum :: Char -> Bool
isAlphaNum c = bomb "isAlphaNum" c $
  case generalCategory c of
    UppercaseLetter -> True
    LowercaseLetter -> True
    TitlecaseLetter -> True
    ModifierLetter  -> True
    OtherLetter     -> True
    DecimalNumber   -> True
    LetterNumber    -> True
    OtherNumber     -> True
    _               -> False

isNumber :: Char -> Bool
isNumber c = bomb "isNumber" c $
  case generalCategory c of
    DecimalNumber -> True
    LetterNumber  -> True
    OtherNumber   -> True
    _             -> False

isMark :: Char -> Bool
isMark c = bomb "isMark" c $
  case generalCategory c of
    NonSpacingMark       -> True
    SpacingCombiningMark -> True
    EnclosingMark        -> True
    _                    -> False

isSeparator :: Char -> Bool
isSeparator c = bomb "isSeparator" c $
  case generalCategory c of
    Space              -> True
    LineSeparator      -> True
    ParagraphSeparator -> True
    _                  -> False

isPunctuation :: Char -> Bool
isPunctuation c = bomb "isPunctuation" c $
  case generalCategory c of
    ConnectorPunctuation    -> True
    DashPunctuation         -> True
    OpenPunctuation         -> True
    ClosePunctuation        -> True
    InitialQuote            -> True
    FinalQuote              -> True
    OtherPunctuation        -> True
    _                       -> False

isSymbol :: Char -> Bool
isSymbol c = bomb "isSymbol" c $
  case generalCategory c of
    MathSymbol              -> True
    CurrencySymbol          -> True
    ModifierSymbol          -> True
    OtherSymbol             -> True
    _                       -> False

toTitle :: Char -> Char
toTitle c =
  case generalCategory c of
    (LowercaseLetter; UppercaseLetter) -> bomb "toTitle" c $ convLU tcTable c
    _ -> c

toUpper :: Char -> Char
toUpper c =
  case generalCategory c of
    (LowercaseLetter; TitlecaseLetter) -> bomb "toUpper" c $ convLU ucTable c
    _ -> c

toLower :: Char -> Char
toLower c =
  case generalCategory c of
    (UppercaseLetter; TitlecaseLetter) -> bomb "toLower" c $ convLU lcTable c
    _ -> c

-- Used to debug unintentional use of Unicode module
bomb :: String -> Char -> a -> a
--bomb s c _ = error $ "bomb " ++ s ++ show c
bomb _ _ a = a

-- XXX We could build a search tree and use binary search.
convLU :: [(Int, Int, Int)] -> Char -> Char
convLU t c = conv t
  where i = primOrd c
        conv [] = c
        conv ((l, h, d):lhds) | l <= i && i <= h = chr (i + d)
                              | otherwise = conv lhds

generalCategory :: Char -> GeneralCategory
generalCategory c =
  let i = primOrd c
  in  if i < 0 || i >= BS.length bytestringGCTable then
        NotAssigned
      else
        toEnum (fromEnum (BS.primBSindex bytestringGCTable i))

bytestringGCTable :: BS.ByteString
bytestringGCTable = bsDecompressRLE compressedGCTable

-- These table are generated by unicode/UniParse.hs
-- This is for Unicode 16.0.0
unicodeVersion :: Version
unicodeVersion = makeVersion [16,0,0]
compressedGCTable :: ByteString
compressedGCTable =
  "\159\f\t\130\EM\ESC\130\EM\NAK\SYN\EM\SUB\EM\DC4\EM\EM\137\ACK\EM\EM\130\SUB\EM\EM\153\NUL\NAK\EM\SYN\FS\DC3\FS\153\SOH\NAK\SUB\SYN\SUB\160\f\t\EM\131\ESC\GS\EM\FS\GS\DC2\ETB\SUB\r\GS\FS\GS\SUB\b\b\FS\SOH\EM\EM\FS\b\DC2\CAN\130\b\EM\150\NUL\SUB\134\NUL\151\SOH\SUB\135\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\NUL\SOH\NUL\SOH\NUL\130\SOH\NUL\NUL\SOH\NUL\SOH\NUL\NUL\SOH\130\NUL\SOH\SOH\131\NUL\SOH\NUL\NUL\SOH\130\NUL\130\SOH\NUL\NUL\SOH\NUL\NUL\SOH\NUL\SOH\NUL\SOH\NUL\NUL\SOH\NUL\SOH\SOH\NUL\SOH\NUL\NUL\SOH\130\NUL\SOH\NUL\SOH\NUL\NUL\SOH\SOH\DC2\NUL\130\SOH\131\DC2\NUL\STX\SOH\NUL\STX\SOH\NUL\STX\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\NUL\STX\SOH\NUL\SOH\130\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\134\SOH\NUL\NUL\SOH\NUL\NUL\SOH\SOH\NUL\SOH\131\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\196\SOH\DC2\154\SOH\145\DC1\131\FS\139\DC1\141\FS\132\DC1\134\FS\DC1\FS\DC1\144\FS\239\ETX\NUL\SOH\NUL\SOH\DC1\FS\NUL\SOH\DLE\DLE\DC1\130\SOH\EM\NUL\131\DLE\FS\FS\NUL\EM\130\NUL\DLE\NUL\DLE\NUL\NUL\SOH\144\NUL\DLE\136\NUL\162\SOH\NUL\SOH\SOH\130\NUL\130\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\132\SOH\NUL\SOH\SUB\NUL\SOH\NUL\NUL\SOH\SOH\178\NUL\175\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\GS\132\ETX\ENQ\ENQ\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\DLE\165\NUL\DLE\DLE\DC1\133\EM\168\SOH\EM\DC4\DLE\DLE\GS\GS\ESC\DLE\172\ETX\DC4\ETX\EM\ETX\ETX\EM\ETX\ETX\EM\ETX\135\DLE\154\DC2\131\DLE\131\DC2\EM\EM\138\DLE\133\r\130\SUB\EM\EM\ESC\EM\EM\GS\GS\138\ETX\EM\r\130\EM\159\DC2\DC1\137\DC2\148\ETX\137\ACK\131\EM\DC2\DC2\ETX\226\DC2\EM\DC2\134\ETX\r\GS\133\ETX\DC1\DC1\ETX\ETX\GS\131\ETX\DC2\DC2\137\ACK\130\DC2\GS\GS\DC2\141\EM\DLE\r\DC2\ETX\157\DC2\154\ETX\DLE\DLE\216\DC2\138\ETX\DC2\141\DLE\137\ACK\160\DC2\136\ETX\DC1\DC1\GS\130\EM\DC1\DLE\DLE\ETX\ESC\ESC\149\DC2\131\ETX\DC1\136\ETX\DC1\130\ETX\DC1\132\ETX\DLE\DLE\142\EM\DLE\152\DC2\130\ETX\DLE\DLE\EM\DLE\138\DC2\132\DLE\151\DC2\FS\133\DC2\DLE\r\r\132\DLE\136\ETX\168\DC2\DC1\151\ETX\r\159\ETX\EOT\181\DC2\ETX\EOT\ETX\DC2\130\EOT\135\ETX\131\EOT\ETX\EOT\EOT\DC2\134\ETX\137\DC2\ETX\ETX\EM\EM\137\ACK\EM\DC1\142\DC2\ETX\EOT\EOT\DLE\135\DC2\DLE\DLE\DC2\DC2\DLE\DLE\149\DC2\DLE\134\DC2\DLE\DC2\130\DLE\131\DC2\DLE\DLE\ETX\DC2\130\EOT\131\ETX\DLE\DLE\EOT\EOT\DLE\DLE\EOT\EOT\ETX\DC2\135\DLE\EOT\131\DLE\DC2\DC2\DLE\130\DC2\ETX\ETX\DLE\DLE\137\ACK\DC2\DC2\ESC\ESC\133\b\GS\ESC\DC2\EM\ETX\DLE\DLE\ETX\ETX\EOT\DLE\133\DC2\131\DLE\DC2\DC2\DLE\DLE\149\DC2\DLE\134\DC2\DLE\DC2\DC2\DLE\DC2\DC2\DLE\DC2\DC2\DLE\DLE\ETX\DLE\130\EOT\ETX\ETX\131\DLE\ETX\ETX\DLE\DLE\130\ETX\130\DLE\ETX\134\DLE\131\DC2\DLE\DC2\134\DLE\137\ACK\ETX\ETX\130\DC2\ETX\EM\137\DLE\ETX\ETX\EOT\DLE\136\DC2\DLE\130\DC2\DLE\149\DC2\DLE\134\DC2\DLE\DC2\DC2\DLE\132\DC2\DLE\DLE\ETX\DC2\130\EOT\132\ETX\DLE\ETX\ETX\EOT\DLE\EOT\EOT\ETX\DLE\DLE\DC2\142\DLE\DC2\DC2\ETX\ETX\DLE\DLE\137\ACK\EM\ESC\134\DLE\DC2\133\ETX\DLE\ETX\EOT\EOT\DLE\135\DC2\DLE\DLE\DC2\DC2\DLE\DLE\149\DC2\DLE\134\DC2\DLE\DC2\DC2\DLE\132\DC2\DLE\DLE\ETX\DC2\EOT\ETX\EOT\131\ETX\DLE\DLE\EOT\EOT\DLE\DLE\EOT\EOT\ETX\134\DLE\ETX\ETX\EOT\131\DLE\DC2\DC2\DLE\130\DC2\ETX\ETX\DLE\DLE\137\ACK\GS\DC2\133\b\137\DLE\ETX\DC2\DLE\133\DC2\130\DLE\130\DC2\DLE\131\DC2\130\DLE\DC2\DC2\DLE\DC2\DLE\DC2\DC2\130\DLE\DC2\DC2\130\DLE\130\DC2\130\DLE\139\DC2\131\DLE\EOT\EOT\ETX\EOT\EOT\130\DLE\130\EOT\DLE\130\EOT\ETX\DLE\DLE\DC2\133\DLE\EOT\141\DLE\137\ACK\130\b\133\GS\ESC\GS\132\DLE\ETX\130\EOT\ETX\135\DC2\DLE\130\DC2\DLE\150\DC2\DLE\143\DC2\DLE\DLE\ETX\DC2\130\ETX\131\EOT\DLE\130\ETX\DLE\131\ETX\134\DLE\ETX\ETX\DLE\130\DC2\DLE\DLE\DC2\DLE\DLE\DC2\DC2\ETX\ETX\DLE\DLE\137\ACK\134\DLE\EM\134\b\GS\DC2\ETX\EOT\EOT\EM\135\DC2\DLE\130\DC2\DLE\150\DC2\DLE\137\DC2\DLE\132\DC2\DLE\DLE\ETX\DC2\EOT\ETX\132\EOT\DLE\ETX\EOT\EOT\DLE\EOT\EOT\ETX\ETX\134\DLE\EOT\EOT\133\DLE\DC2\DC2\DLE\DC2\DC2\ETX\ETX\DLE\DLE\137\ACK\DLE\DC2\DC2\EOT\139\DLE\ETX\ETX\EOT\EOT\136\DC2\DLE\130\DC2\DLE\168\DC2\ETX\ETX\DC2\130\EOT\131\ETX\DLE\130\EOT\DLE\130\EOT\ETX\DC2\GS\131\DLE\130\DC2\EOT\134\b\130\DC2\ETX\ETX\DLE\DLE\137\ACK\136\b\GS\133\DC2\DLE\ETX\EOT\EOT\DLE\145\DC2\130\DLE\151\DC2\DLE\136\DC2\DLE\DC2\DLE\DLE\134\DC2\130\DLE\ETX\131\DLE\130\EOT\130\ETX\DLE\ETX\DLE\135\EOT\133\DLE\137\ACK\DLE\DLE\EOT\EOT\EM\139\DLE\175\DC2\ETX\DC2\DC2\134\ETX\131\DLE\ESC\133\DC2\DC1\135\ETX\EM\137\ACK\EM\EM\164\DLE\DC2\DC2\DLE\DC2\DLE\132\DC2\DLE\151\DC2\DLE\DC2\DLE\137\DC2\ETX\DC2\DC2\136\ETX\DC2\DLE\DLE\132\DC2\DLE\DC1\DLE\134\ETX\DLE\137\ACK\DLE\DLE\131\DC2\159\DLE\DC2\130\GS\142\EM\GS\EM\130\GS\ETX\ETX\133\GS\137\ACK\137\b\GS\ETX\GS\ETX\GS\ETX\NAK\SYN\NAK\SYN\EOT\EOT\135\DC2\DLE\163\DC2\131\DLE\141\ETX\EOT\132\ETX\EM\ETX\ETX\132\DC2\138\ETX\DLE\163\ETX\DLE\135\GS\ETX\133\GS\DLE\GS\GS\132\EM\131\GS\EM\EM\164\DLE\170\DC2\EOT\EOT\131\ETX\EOT\133\ETX\EOT\ETX\ETX\EOT\EOT\ETX\ETX\DC2\137\ACK\133\EM\133\DC2\EOT\EOT\ETX\ETX\131\DC2\130\ETX\DC2\130\EOT\DC2\DC2\134\EOT\130\DC2\131\ETX\140\DC2\ETX\EOT\EOT\ETX\ETX\133\EOT\ETX\DC2\EOT\137\ACK\130\EOT\ETX\GS\GS\165\NUL\DLE\NUL\132\DLE\NUL\DLE\DLE\170\SOH\EM\DC1\130\SOH\130\200\DC2\DLE\131\DC2\DLE\DLE\134\DC2\DLE\DC2\DLE\131\DC2\DLE\DLE\168\DC2\DLE\131\DC2\DLE\DLE\160\DC2\DLE\131\DC2\DLE\DLE\134\DC2\DLE\DC2\DLE\131\DC2\DLE\DLE\142\DC2\DLE\184\DC2\DLE\131\DC2\DLE\DLE\194\DC2\DLE\DLE\130\ETX\136\EM\147\b\130\DLE\143\DC2\137\GS\133\DLE\213\NUL\DLE\DLE\133\SOH\DLE\DLE\DC4\132\235\DC2\GS\EM\144\DC2\t\153\DC2\NAK\SYN\130\DLE\202\DC2\130\EM\130\a\135\DC2\134\DLE\145\DC2\130\ETX\EOT\136\DLE\146\DC2\ETX\ETX\EOT\EM\EM\136\DLE\145\DC2\ETX\ETX\139\DLE\140\DC2\DLE\130\DC2\DLE\ETX\ETX\139\DLE\179\DC2\ETX\ETX\EOT\134\ETX\135\EOT\ETX\EOT\EOT\138\ETX\130\EM\DC1\130\EM\ESC\DC2\ETX\DLE\DLE\137\ACK\133\DLE\137\b\133\DLE\133\EM\DC4\131\EM\130\ETX\r\ETX\137\ACK\133\DLE\162\DC2\DC1\180\DC2\134\DLE\132\DC2\ETX\ETX\161\DC2\ETX\DC2\132\DLE\197\DC2\137\DLE\158\DC2\DLE\130\ETX\131\EOT\ETX\ETX\130\EOT\131\DLE\EOT\EOT\ETX\133\EOT\130\ETX\131\DLE\GS\130\DLE\EM\EM\137\ACK\157\DC2\DLE\DLE\132\DC2\138\DLE\171\DC2\131\DLE\153\DC2\133\DLE\137\ACK\b\130\DLE\161\GS\150\DC2\ETX\ETX\EOT\EOT\ETX\DLE\DLE\EM\EM\180\DC2\EOT\ETX\EOT\134\ETX\DLE\ETX\EOT\ETX\EOT\EOT\135\ETX\133\EOT\137\ETX\DLE\DLE\ETX\137\ACK\133\DLE\137\ACK\133\DLE\134\EM\DC1\133\EM\DLE\DLE\141\ETX\ENQ\143\ETX\176\DLE\131\ETX\EOT\174\DC2\ETX\EOT\132\ETX\EOT\ETX\132\EOT\ETX\EOT\EOT\135\DC2\DLE\EM\EM\137\ACK\134\EM\137\GS\136\ETX\136\GS\130\EM\ETX\ETX\EOT\157\DC2\EOT\131\ETX\EOT\EOT\ETX\ETX\EOT\130\ETX\DC2\DC2\137\ACK\171\DC2\ETX\EOT\ETX\ETX\130\EOT\ETX\EOT\130\ETX\EOT\EOT\135\DLE\131\EM\163\DC2\135\EOT\135\ETX\EOT\EOT\ETX\ETX\130\DLE\132\EM\137\ACK\130\DLE\130\DC2\137\ACK\157\DC2\133\DC1\EM\EM\136\SOH\NUL\SOH\132\DLE\170\NUL\DLE\DLE\130\NUL\135\EM\135\DLE\130\ETX\EM\140\ETX\EOT\134\ETX\131\DC2\ETX\133\DC2\ETX\DC2\DC2\EOT\ETX\ETX\DC2\132\DLE\171\SOH\190\DC1\140\SOH\DC1\161\SOH\164\DC1\191\ETX\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\136\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\136\SOH\135\NUL\133\SOH\DLE\DLE\133\NUL\DLE\DLE\135\SOH\135\NUL\135\SOH\135\NUL\133\SOH\DLE\DLE\133\NUL\DLE\DLE\135\SOH\DLE\NUL\DLE\NUL\DLE\NUL\DLE\NUL\135\SOH\135\NUL\141\SOH\DLE\DLE\135\SOH\135\STX\135\SOH\135\STX\135\SOH\135\STX\132\SOH\DLE\SOH\SOH\131\NUL\STX\FS\SOH\130\FS\130\SOH\DLE\SOH\SOH\131\NUL\STX\130\FS\131\SOH\DLE\DLE\SOH\SOH\131\NUL\DLE\130\FS\135\SOH\132\NUL\130\FS\DLE\DLE\130\SOH\DLE\SOH\SOH\131\NUL\STX\FS\FS\DLE\138\t\132\r\133\DC4\EM\EM\ETB\CAN\NAK\ETB\ETB\CAN\NAK\ETB\135\EM\n\v\132\r\t\136\EM\ETB\CAN\131\EM\DC3\DC3\130\EM\SUB\NAK\SYN\138\EM\SUB\EM\DC3\137\EM\t\132\r\DLE\137\r\b\DC1\DLE\DLE\133\b\130\SUB\NAK\SYN\DC1\137\b\130\SUB\NAK\SYN\DLE\140\DC1\130\DLE\160\ESC\142\DLE\140\ETX\131\ENQ\ETX\130\ENQ\139\ETX\142\DLE\GS\GS\NUL\131\GS\NUL\GS\GS\SOH\130\NUL\SOH\SOH\130\NUL\SOH\GS\NUL\GS\GS\SUB\132\NUL\133\GS\NUL\GS\NUL\GS\NUL\GS\131\NUL\GS\SOH\131\NUL\SOH\131\DC2\SOH\GS\GS\SOH\SOH\NUL\NUL\132\SUB\NUL\131\SOH\GS\SUB\GS\GS\SOH\GS\143\b\162\a\NUL\SOH\131\a\b\GS\GS\131\DLE\132\SUB\132\GS\SUB\SUB\131\GS\SUB\GS\GS\SUB\GS\GS\SUB\134\GS\SUB\158\GS\SUB\SUB\GS\GS\SUB\GS\SUB\158\GS\130\139\SUB\135\GS\NAK\SYN\NAK\SYN\147\GS\SUB\SUB\134\GS\NAK\SYN\208\GS\SUB\157\GS\152\SUB\167\GS\133\SUB\199\GS\149\DLE\138\GS\148\DLE\187\b\205\GS\149\b\129\182\GS\SUB\136\GS\SUB\181\GS\135\SUB\238\GS\SUB\129\247\GS\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\157\b\171\GS\132\SUB\NAK\SYN\158\SUB\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\143\SUB\129\255\GS\129\130\SUB\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\190\SUB\NAK\SYN\NAK\SYN\159\SUB\NAK\SYN\130\129\SUB\175\GS\148\SUB\GS\GS\133\SUB\166\GS\DLE\DLE\159\GS\DLE\232\GS\175\NUL\175\SOH\NUL\SOH\130\NUL\SOH\SOH\NUL\SOH\NUL\SOH\NUL\SOH\131\NUL\SOH\NUL\SOH\SOH\NUL\133\SOH\DC1\DC1\130\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\SOH\133\GS\NUL\SOH\NUL\SOH\130\ETX\NUL\SOH\132\DLE\131\EM\b\EM\EM\165\SOH\DLE\SOH\132\DLE\SOH\DLE\DLE\183\DC2\134\DLE\DC1\EM\141\DLE\ETX\150\DC2\136\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\134\DC2\DLE\159\ETX\EM\EM\ETB\CAN\ETB\CAN\130\EM\ETB\CAN\EM\ETB\CAN\136\EM\DC4\EM\EM\DC4\EM\ETB\CAN\EM\EM\ETB\CAN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\132\EM\DC1\137\EM\DC4\DC4\131\EM\DC4\EM\NAK\140\EM\GS\GS\130\EM\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\DC4\161\DLE\153\GS\DLE\216\GS\139\DLE\129\213\GS\153\DLE\143\GS\t\130\EM\GS\DC1\DC2\a\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\GS\GS\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\DC4\NAK\SYN\SYN\GS\136\a\131\ETX\EOT\EOT\DC4\132\DC1\GS\GS\130\a\DC1\DC2\EM\GS\GS\DLE\213\DC2\DLE\DLE\ETX\ETX\FS\FS\DC1\DC1\DC2\DC4\217\DC2\EM\130\DC1\DC2\132\DLE\170\DC2\DLE\221\DC2\DLE\GS\GS\131\b\137\GS\159\DC2\165\GS\136\DLE\GS\143\DC2\158\GS\DLE\137\b\157\GS\135\b\GS\142\b\159\GS\137\b\166\GS\142\b\130\191\GS\DC2\179\189\DLE\DC2\191\GS\DC2\129\163\253\DLE\149\DC2\DC1\136\246\DC2\130\DLE\182\GS\136\DLE\167\DC2\133\DC1\EM\EM\130\139\DC2\DC1\130\EM\143\DC2\137\ACK\DC2\DC2\147\DLE\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\DC2\ETX\130\ENQ\EM\137\ETX\EM\DC1\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\DC1\DC1\ETX\ETX\197\DC2\137\a\ETX\ETX\133\EM\135\DLE\150\FS\136\DC1\FS\FS\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\130\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\DC1\135\SOH\NUL\SOH\NUL\SOH\NUL\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\DC1\FS\FS\NUL\SOH\NUL\SOH\DC2\NUL\SOH\NUL\130\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\132\NUL\SOH\132\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\SOH\131\NUL\SOH\NUL\SOH\NUL\NUL\SOH\DLE\DLE\NUL\SOH\DLE\SOH\DLE\SOH\NUL\SOH\NUL\SOH\NUL\SOH\NUL\148\DLE\130\DC1\NUL\SOH\DC2\DC1\DC1\SOH\134\DC2\ETX\130\DC2\ETX\131\DC2\ETX\150\DC2\EOT\EOT\ETX\ETX\EOT\131\GS\ETX\130\DLE\133\b\GS\GS\ESC\GS\133\DLE\179\DC2\131\EM\135\DLE\EOT\EOT\177\DC2\143\EOT\ETX\ETX\135\DLE\EM\EM\137\ACK\133\DLE\145\ETX\133\DC2\130\EM\DC2\EM\DC2\DC2\ETX\137\ACK\155\DC2\135\ETX\EM\EM\150\DC2\138\ETX\EOT\EOT\138\DLE\EM\156\DC2\130\DLE\130\ETX\EOT\174\DC2\ETX\EOT\EOT\131\ETX\EOT\EOT\ETX\ETX\130\EOT\140\EM\DLE\DC1\137\ACK\131\DLE\EM\EM\132\DC2\ETX\DC1\136\DC2\137\ACK\132\DC2\DLE\168\DC2\133\ETX\EOT\EOT\ETX\ETX\EOT\EOT\ETX\ETX\136\DLE\130\DC2\ETX\135\DC2\ETX\EOT\DLE\DLE\137\ACK\DLE\DLE\131\EM\143\DC2\DC1\133\DC2\130\GS\DC2\EOT\ETX\EOT\177\DC2\ETX\DC2\130\ETX\DC2\DC2\ETX\ETX\132\DC2\ETX\ETX\DC2\ETX\DC2\151\DLE\DC2\DC2\DC1\EM\EM\138\DC2\EOT\ETX\ETX\EOT\EOT\EM\EM\DC2\DC1\DC1\EOT\ETX\137\DLE\133\DC2\DLE\DLE\133\DC2\DLE\DLE\133\DC2\136\DLE\134\DC2\DLE\134\DC2\DLE\170\SOH\FS\131\DC1\136\SOH\DC1\FS\FS\131\DLE\207\SOH\162\DC2\EOT\EOT\ETX\EOT\EOT\ETX\EOT\EOT\EM\EOT\ETX\DLE\DLE\137\ACK\133\DLE\DC2\215\161\DLE\DC2\139\DLE\150\DC2\131\DLE\176\DC2\131\DLE\SO\134\253\DLE\SO\SO\253\DLE\SO\SO\135\253\DLE\SO\SI\177\253\DLE\SI\130\237\DC2\DLE\DLE\233\DC2\165\DLE\134\SOH\139\DLE\132\SOH\132\DLE\DC2\ETX\137\DC2\SUB\140\DC2\DLE\132\DC2\DLE\DC2\DLE\DC2\DC2\DLE\DC2\DC2\DLE\235\DC2\144\FS\143\DLE\130\234\DC2\SYN\NAK\143\GS\191\DC2\DLE\DLE\181\DC2\134\DLE\GS\159\DLE\139\DC2\ESC\130\GS\143\ETX\134\EM\NAK\SYN\EM\133\DLE\143\ETX\EM\DC4\DC4\DC3\DC3\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\NAK\SYN\EM\EM\NAK\SYN\131\EM\130\DC3\130\EM\DLE\131\EM\DC4\NAK\SYN\NAK\SYN\NAK\SYN\130\EM\SUB\DC4\130\SUB\DLE\EM\ESC\EM\EM\131\DLE\132\DC2\DLE\129\134\DC2\DLE\DLE\r\DLE\130\EM\ESC\130\EM\NAK\SYN\EM\SUB\EM\DC4\EM\EM\137\ACK\EM\EM\130\SUB\EM\EM\153\NUL\NAK\EM\SYN\FS\DC3\FS\153\SOH\NAK\SUB\SYN\SUB\NAK\SYN\EM\NAK\SYN\EM\EM\137\DC2\DC1\172\DC2\DC1\DC1\158\DC2\130\DLE\133\DC2\DLE\DLE\133\DC2\DLE\DLE\133\DC2\DLE\DLE\130\DC2\130\DLE\ESC\ESC\SUB\FS\GS\ESC\ESC\DLE\GS\131\SUB\GS\GS\137\DLE\130\r\GS\GS\DLE\DLE\139\DC2\DLE\153\DC2\DLE\146\DC2\DLE\DC2\DC2\DLE\142\DC2\DLE\DLE\141\DC2\161\DLE\250\DC2\132\DLE\130\EM\131\DLE\172\b\130\DLE\136\GS\180\a\131\b\144\GS\b\b\130\GS\DLE\140\GS\130\DLE\GS\174\DLE\172\GS\ETX\129\129\DLE\156\DC2\130\DLE\176\DC2\142\DLE\ETX\154\b\131\DLE\159\DC2\131\b\136\DLE\147\DC2\a\135\DC2\a\132\DLE\165\DC2\132\ETX\132\DLE\157\DC2\DLE\EM\163\DC2\131\DLE\135\DC2\EM\132\a\169\DLE\167\NUL\167\SOH\205\DC2\DLE\DLE\137\ACK\133\DLE\163\NUL\131\DLE\163\SOH\131\DLE\167\DC2\135\DLE\179\DC2\138\DLE\EM\138\NUL\DLE\142\NUL\DLE\134\NUL\DLE\NUL\NUL\DLE\138\SOH\DLE\142\SOH\DLE\134\SOH\DLE\SOH\SOH\130\DLE\179\DC2\139\DLE\130\182\DC2\136\DLE\149\DC2\137\DLE\135\DC2\151\DLE\133\DC1\DLE\169\DC1\DLE\136\DC1\196\DLE\133\DC2\DLE\DLE\DC2\DLE\171\DC2\DLE\DC2\DC2\130\DLE\DC2\DLE\DLE\150\DC2\DLE\EM\135\b\150\DC2\GS\GS\134\b\158\DC2\135\DLE\136\b\175\DLE\146\DC2\DLE\DC2\DC2\132\DLE\132\b\149\DC2\133\b\130\DLE\EM\153\DC2\132\DLE\EM\191\DLE\183\DC2\131\DLE\b\b\DC2\DC2\143\b\DLE\DLE\173\b\DC2\130\ETX\DLE\ETX\ETX\132\DLE\131\ETX\131\DC2\DLE\130\DC2\DLE\156\DC2\DLE\DLE\130\ETX\131\DLE\ETX\136\b\134\DLE\136\EM\134\DLE\156\DC2\b\b\EM\156\DC2\130\b\159\DLE\135\DC2\GS\155\DC2\ETX\ETX\131\DLE\132\b\134\EM\136\DLE\181\DC2\130\DLE\134\EM\149\DC2\DLE\DLE\135\b\146\DC2\132\DLE\135\b\145\DC2\134\DLE\131\EM\139\DLE\134\b\207\DLE\200\DC2\182\DLE\178\NUL\140\DLE\178\SOH\134\DLE\133\b\163\DC2\131\ETX\135\DLE\137\ACK\133\DLE\137\ACK\131\DC2\DC1\DC2\149\NUL\130\DLE\132\ETX\DC4\DC1\149\SOH\135\DLE\SUB\SUB\129\207\DLE\158\b\DLE\169\DC2\DLE\ETX\ETX\DC4\DLE\DLE\DC2\DC2\143\DLE\130\DC2\182\DLE\131\ETX\156\DC2\137\b\DC2\135\DLE\149\DC2\138\ETX\131\b\132\EM\149\DLE\145\DC2\131\ETX\131\EM\165\DLE\148\DC2\134\b\147\DLE\150\DC2\136\DLE\EOT\ETX\EOT\180\DC2\142\ETX\134\EM\131\DLE\147\b\137\ACK\ETX\DC2\DC2\ETX\ETX\DC2\136\DLE\130\ETX\EOT\172\DC2\130\EOT\131\ETX\EOT\EOT\ETX\ETX\EM\EM\r\131\EM\ETX\137\DLE\r\DLE\DLE\152\DC2\134\DLE\137\ACK\133\DLE\130\ETX\163\DC2\132\ETX\EOT\135\ETX\DLE\137\ACK\131\EM\DC2\EOT\EOT\DC2\135\DLE\162\DC2\ETX\EM\EM\DC2\136\DLE\ETX\ETX\EOT\175\DC2\130\EOT\136\ETX\EOT\EOT\131\DC2\131\EM\131\ETX\EM\EOT\ETX\137\ACK\DC2\EM\DC2\130\EM\DLE\147\b\138\DLE\145\DC2\DLE\152\DC2\130\EOT\130\ETX\EOT\EOT\ETX\EOT\ETX\ETX\133\EM\ETX\DC2\DC2\ETX\189\DLE\134\DC2\DLE\DC2\DLE\131\DC2\DLE\142\DC2\DLE\137\DC2\EM\133\DLE\174\DC2\ETX\130\EOT\135\ETX\132\DLE\137\ACK\133\DLE\ETX\ETX\EOT\EOT\DLE\135\DC2\DLE\DLE\DC2\DC2\DLE\DLE\149\DC2\DLE\134\DC2\DLE\DC2\DC2\DLE\132\DC2\DLE\ETX\ETX\DC2\EOT\EOT\ETX\131\EOT\DLE\DLE\EOT\EOT\DLE\DLE\130\EOT\DLE\DLE\DC2\133\DLE\EOT\132\DLE\132\DC2\EOT\EOT\DLE\DLE\134\ETX\130\DLE\132\ETX\138\DLE\137\DC2\DLE\DC2\DLE\DLE\DC2\DLE\165\DC2\DLE\DC2\130\EOT\133\ETX\DLE\EOT\DLE\DLE\EOT\DLE\131\EOT\DLE\EOT\EOT\ETX\EOT\ETX\DC2\ETX\DC2\EM\EM\DLE\EM\EM\135\DLE\ETX\ETX\156\DLE\180\DC2\130\EOT\135\ETX\EOT\EOT\130\ETX\EOT\ETX\131\DC2\132\EM\137\ACK\EM\EM\DLE\EM\ETX\130\DC2\157\DLE\175\DC2\130\EOT\133\ETX\EOT\ETX\131\EOT\ETX\ETX\EOT\ETX\ETX\DC2\DC2\EM\DC2\135\DLE\137\ACK\129\165\DLE\174\DC2\130\EOT\131\ETX\DLE\DLE\131\EOT\ETX\ETX\EOT\ETX\ETX\150\EM\131\DC2\ETX\ETX\161\DLE\175\DC2\130\EOT\135\ETX\EOT\EOT\ETX\EOT\ETX\ETX\130\EM\DC2\138\DLE\137\ACK\133\DLE\140\EM\146\DLE\170\DC2\ETX\EOT\ETX\EOT\EOT\133\ETX\EOT\ETX\DC2\EM\133\DLE\137\ACK\133\DLE\147\ACK\155\DLE\154\DC2\DLE\DLE\ETX\EOT\ETX\EOT\EOT\131\ETX\EOT\132\ETX\131\DLE\137\ACK\b\b\130\EM\GS\134\DC2\129\184\DLE\171\DC2\130\EOT\136\ETX\EOT\ETX\ETX\EM\227\DLE\159\NUL\159\SOH\137\ACK\136\b\139\DLE\135\DC2\DLE\DLE\DC2\DLE\DLE\135\DC2\DLE\DC2\DC2\DLE\151\DC2\133\EOT\DLE\EOT\EOT\DLE\DLE\ETX\ETX\EOT\ETX\DC2\EOT\DC2\EOT\ETX\130\EM\136\DLE\137\ACK\197\DLE\135\DC2\DLE\DLE\166\DC2\130\EOT\131\ETX\DLE\DLE\ETX\ETX\131\EOT\ETX\DC2\EM\DC2\EOT\154\DLE\DC2\137\ETX\167\DC2\133\ETX\EOT\DC2\131\ETX\135\EM\ETX\135\DLE\DC2\133\ETX\EOT\EOT\130\ETX\173\DC2\140\ETX\EOT\ETX\ETX\130\EM\DC2\132\EM\140\DLE\200\DC2\134\DLE\137\EM\129\181\DLE\160\DC2\EM\141\DLE\137\ACK\133\DLE\136\DC2\DLE\164\DC2\EOT\134\ETX\DLE\133\ETX\EOT\ETX\DC2\132\EM\137\DLE\137\ACK\146\b\130\DLE\EM\EM\157\DC2\DLE\DLE\149\ETX\DLE\EOT\134\ETX\EOT\ETX\ETX\EOT\ETX\ETX\200\DLE\134\DC2\DLE\DC2\DC2\DLE\165\DC2\133\ETX\130\DLE\ETX\DLE\ETX\ETX\DLE\134\ETX\DC2\ETX\135\DLE\137\ACK\133\DLE\133\DC2\DLE\DC2\DC2\DLE\159\DC2\132\EOT\DLE\ETX\ETX\DLE\EOT\EOT\ETX\EOT\ETX\DC2\134\DLE\137\ACK\130\181\DLE\146\DC2\ETX\ETX\EOT\EOT\EM\EM\134\DLE\ETX\ETX\DC2\EOT\140\DC2\DLE\161\DC2\EOT\EOT\132\ETX\130\DLE\EOT\EOT\ETX\EOT\ETX\140\EM\137\ACK\ETX\212\DLE\DC2\142\DLE\148\b\135\GS\131\ESC\144\GS\140\DLE\EM\135\153\DC2\229\DLE\238\a\DLE\132\EM\138\DLE\129\195\DC2\148\203\DLE\224\DC2\EM\EM\140\DLE\136\175\DC2\143\r\ETX\133\DC2\142\ETX\137\DLE\159\154\DC2\132\DLE\132\198\DC2\181\184\DLE\157\DC2\139\ETX\130\EOT\130\ETX\137\ACK\141\197\DLE\132\184\DC2\134\DLE\158\DC2\DLE\137\ACK\131\DLE\EM\EM\206\DC2\DLE\137\ACK\133\DLE\157\DC2\DLE\DLE\132\ETX\EM\137\DLE\175\DC2\134\ETX\132\EM\131\GS\131\DC1\EM\GS\137\DLE\137\ACK\DLE\134\b\DLE\148\DC2\132\DLE\146\DC2\131\175\DLE\130\DC1\167\DC2\DC1\DC1\130\EM\137\ACK\129\197\DLE\159\NUL\159\SOH\150\b\131\EM\228\DLE\202\DC2\131\DLE\ETX\DC2\182\EOT\134\DLE\131\ETX\140\DC1\191\DLE\DC1\DC1\EM\DC1\ETX\138\DLE\EOT\EOT\141\DLE\DC2\175\245\DLE\DC2\135\DLE\137\213\DC2\168\DLE\DC2\DC2\134\DLE\DC2\197\230\DLE\131\DC1\DLE\134\DC1\DLE\DC1\DC1\DLE\130\162\DC2\142\DLE\DC2\156\DLE\130\DC2\DLE\DLE\DC2\141\DLE\131\DC2\135\DLE\131\139\DC2\146\131\DLE\234\DC2\132\DLE\140\DC2\130\DLE\136\DC2\134\DLE\137\DC2\DLE\DLE\GS\ETX\ETX\EM\131\r\158\219\DLE\129\239\GS\137\ACK\133\DLE\131\179\GS\203\DLE\173\ETX\DLE\DLE\150\ETX\136\DLE\243\GS\187\DLE\129\245\GS\137\DLE\166\GS\DLE\DLE\187\GS\EOT\EOT\130\ETX\130\GS\133\EOT\135\r\135\ETX\GS\GS\134\ETX\157\GS\131\ETX\188\GS\148\DLE\193\GS\130\ETX\GS\249\DLE\147\b\139\DLE\147\b\139\DLE\214\GS\136\DLE\152\b\129\134\DLE\153\NUL\153\SOH\153\NUL\134\SOH\DLE\145\SOH\153\NUL\153\SOH\NUL\DLE\NUL\NUL\DLE\DLE\NUL\DLE\DLE\NUL\NUL\DLE\DLE\131\NUL\DLE\135\NUL\131\SOH\DLE\SOH\DLE\134\SOH\DLE\138\SOH\153\NUL\153\SOH\NUL\NUL\DLE\131\NUL\DLE\DLE\135\NUL\DLE\134\NUL\DLE\153\SOH\NUL\NUL\DLE\131\NUL\DLE\132\NUL\DLE\NUL\130\DLE\134\NUL\DLE\153\SOH\153\NUL\153\SOH\153\NUL\153\SOH\153\NUL\153\SOH\153\NUL\153\SOH\153\NUL\153\SOH\153\NUL\155\SOH\DLE\DLE\152\NUL\SUB\152\SOH\SUB\133\SOH\152\NUL\SUB\152\SOH\SUB\133\SOH\152\NUL\SUB\152\SOH\SUB\133\SOH\152\NUL\SUB\152\SOH\SUB\133\SOH\152\NUL\SUB\152\SOH\SUB\133\SOH\NUL\SOH\DLE\DLE\177\ACK\131\255\GS\182\ETX\131\GS\177\ETX\135\GS\ETX\141\GS\ETX\GS\GS\132\EM\142\DLE\132\ETX\DLE\142\ETX\136\207\DLE\137\SOH\DC2\147\SOH\133\DLE\133\SOH\129\212\DLE\134\ETX\DLE\144\ETX\DLE\DLE\134\ETX\DLE\ETX\ETX\DLE\132\ETX\132\DLE\189\DC1\160\DLE\ETX\239\DLE\172\DC2\130\DLE\134\ETX\134\DC1\DLE\DLE\137\ACK\131\DLE\DC2\GS\130\191\DLE\157\DC2\ETX\144\DLE\171\DC2\131\ETX\137\ACK\132\DLE\ESC\131\207\DLE\154\DC2\DC1\131\ETX\137\ACK\129\213\DLE\157\DC2\ETX\ETX\DC2\137\ACK\131\DLE\EM\131\223\DLE\134\DC2\DLE\131\DC2\DLE\DC2\DC2\DLE\142\DC2\DLE\129\196\DC2\DLE\DLE\136\b\134\ETX\168\DLE\161\NUL\161\SOH\134\ETX\DC1\131\DLE\137\ACK\131\DLE\EM\EM\134\144\DLE\186\b\GS\130\b\ESC\131\b\203\DLE\172\b\GS\142\b\129\193\DLE\131\DC2\DLE\154\DC2\DLE\DC2\DC2\DLE\DC2\DLE\DLE\DC2\DLE\137\DC2\DLE\131\DC2\DLE\DC2\DLE\DC2\133\DLE\DC2\131\DLE\DC2\DLE\DC2\DLE\DC2\DLE\130\DC2\DLE\DC2\DC2\DLE\DC2\DLE\DLE\DC2\DLE\DC2\DLE\DC2\DLE\DC2\DLE\DC2\DLE\DC2\DC2\DLE\DC2\DLE\DLE\131\DC2\DLE\134\DC2\DLE\131\DC2\DLE\131\DC2\DLE\DC2\DLE\137\DC2\DLE\144\DC2\132\DLE\130\DC2\DLE\132\DC2\DLE\144\DC2\179\DLE\SUB\SUB\130\141\DLE\171\GS\131\DLE\227\GS\139\DLE\142\GS\DLE\DLE\142\GS\DLE\142\GS\DLE\164\GS\137\DLE\140\b\129\160\GS\183\DLE\156\GS\140\DLE\171\GS\131\DLE\136\GS\134\DLE\GS\GS\141\DLE\133\GS\129\153\DLE\129\250\GS\132\FS\133\215\GS\131\DLE\144\GS\130\DLE\140\GS\130\DLE\246\GS\131\DLE\222\GS\133\DLE\139\GS\131\DLE\GS\142\DLE\139\GS\131\DLE\183\GS\135\DLE\137\GS\133\DLE\167\GS\135\DLE\157\GS\DLE\DLE\139\GS\131\DLE\GS\GS\189\DLE\130\211\GS\139\DLE\141\GS\DLE\DLE\140\GS\130\DLE\137\GS\132\DLE\183\GS\134\DLE\142\GS\DLE\DLE\138\GS\133\DLE\136\GS\134\DLE\129\146\GS\DLE\219\GS\137\ACK\136\133\DLE\DC2\130\205\221\DLE\DC2\159\DLE\DC2\160\183\DLE\DC2\133\DLE\DC2\129\219\DLE\DC2\DLE\DLE\DC2\172\255\DLE\DC2\141\DLE\DC2\186\174\DLE\DC2\142\DLE\DC2\132\235\DLE\DC2\147\161\DLE\132\157\DC2\139\225\DLE\DC2\166\200\DLE\DC2\132\DLE\DC2\160\221\DLE\DC2\171\184\208\DLE\r\157\DLE\223\r\255\DLE\129\239\ETX\131\252\143\DLE\SI\131\255\251\DLE\SI\DLE\DLE\SI\131\255\251\DLE\SI"

tcTable :: [(Int, Int, Int)]
tcTable =
  [(97,122,-32),(181,181,743),(224,254,-32),(255,255,121),(257,303,-1),(305,305,-232),(307,382,-1),(383,383,-300),(384,384,195),(387,402,-1),(405,405,97),(409,409,-1),(410,410,163),(411,411,42561),(414,414,130),(417,445,-1),(447,447,56),(452,452,1),(453,453,0),(454,454,-1),(455,455,1),(456,456,0),(457,457,-1),(458,458,1),(459,459,0),(460,476,-1),(477,477,-79),(479,495,-1),(497,497,1),(498,498,0),(499,572,-1),(575,576,10815),(578,591,-1),(592,592,10783),(593,593,10780),(594,594,10782),(595,595,-210),(596,596,-206),(598,599,-205),(601,601,-202),(603,603,-203),(604,604,42319),(608,608,-205),(609,609,42315),(611,611,-207),(612,612,42343),(613,613,42280),(614,614,42308),(616,616,-209),(617,617,-211),(618,618,42308),(619,619,10743),(620,620,42305),(623,623,-211),(625,625,10749),(626,626,-213),(629,629,-214),(637,637,10727),(640,640,-218),(642,642,42307),(643,643,-218),(647,647,42282),(648,648,-218),(649,649,-69),(650,651,-217),(652,652,-71),(658,658,-219),(669,669,42261),(670,670,42258),(837,837,84),(881,887,-1),(891,893,130),(940,940,-38),(941,943,-37),(945,961,-32),(962,962,-31),(963,971,-32),(972,972,-64),(973,974,-63),(976,976,-62),(977,977,-57),(981,981,-47),(982,982,-54),(983,983,-8),(985,1007,-1),(1008,1008,-86),(1009,1009,-80),(1010,1010,7),(1011,1011,-116),(1013,1013,-96),(1016,1019,-1),(1072,1103,-32),(1104,1119,-80),(1121,1230,-1),(1231,1231,-15),(1233,1327,-1),(1377,1414,-48),(4304,4351,0),(5112,5117,-8),(7296,7296,-6254),(7297,7297,-6253),(7298,7298,-6244),(7299,7300,-6242),(7301,7301,-6243),(7302,7302,-6236),(7303,7303,-6181),(7304,7304,35266),(7306,7306,-1),(7545,7545,35332),(7549,7549,3814),(7566,7566,35384),(7681,7829,-1),(7835,7835,-59),(7841,7935,-1),(7936,8039,8),(8048,8049,74),(8050,8053,86),(8054,8055,100),(8056,8057,128),(8058,8059,112),(8060,8061,126),(8064,8113,8),(8115,8115,9),(8126,8126,-7205),(8131,8131,9),(8144,8161,8),(8165,8165,7),(8179,8179,9),(8526,8526,-28),(8560,8575,-16),(8580,8580,-1),(9424,9449,-26),(11312,11359,-48),(11361,11361,-1),(11365,11365,-10795),(11366,11366,-10792),(11368,11507,-1),(11520,11565,-7264),(42561,42899,-1),(42900,42900,48),(42903,42998,-1),(43859,43859,-928),(43888,43967,-38864),(65345,65370,-32),(66600,66811,-40),(66967,67004,-39),(68800,68850,-64),(68976,93823,-32),(125218,125251,-34)]

ucTable :: [(Int, Int, Int)]
ucTable =
  [(97,122,-32),(181,181,743),(224,254,-32),(255,255,121),(257,303,-1),(305,305,-232),(307,382,-1),(383,383,-300),(384,384,195),(387,402,-1),(405,405,97),(409,409,-1),(410,410,163),(411,411,42561),(414,414,130),(417,445,-1),(447,447,56),(453,453,-1),(454,454,-2),(456,456,-1),(457,457,-2),(459,459,-1),(460,460,-2),(462,476,-1),(477,477,-79),(479,498,-1),(499,499,-2),(501,572,-1),(575,576,10815),(578,591,-1),(592,592,10783),(593,593,10780),(594,594,10782),(595,595,-210),(596,596,-206),(598,599,-205),(601,601,-202),(603,603,-203),(604,604,42319),(608,608,-205),(609,609,42315),(611,611,-207),(612,612,42343),(613,613,42280),(614,614,42308),(616,616,-209),(617,617,-211),(618,618,42308),(619,619,10743),(620,620,42305),(623,623,-211),(625,625,10749),(626,626,-213),(629,629,-214),(637,637,10727),(640,640,-218),(642,642,42307),(643,643,-218),(647,647,42282),(648,648,-218),(649,649,-69),(650,651,-217),(652,652,-71),(658,658,-219),(669,669,42261),(670,670,42258),(837,837,84),(881,887,-1),(891,893,130),(940,940,-38),(941,943,-37),(945,961,-32),(962,962,-31),(963,971,-32),(972,972,-64),(973,974,-63),(976,976,-62),(977,977,-57),(981,981,-47),(982,982,-54),(983,983,-8),(985,1007,-1),(1008,1008,-86),(1009,1009,-80),(1010,1010,7),(1011,1011,-116),(1013,1013,-96),(1016,1019,-1),(1072,1103,-32),(1104,1119,-80),(1121,1230,-1),(1231,1231,-15),(1233,1327,-1),(1377,1414,-48),(4304,4351,3008),(5112,5117,-8),(7296,7296,-6254),(7297,7297,-6253),(7298,7298,-6244),(7299,7300,-6242),(7301,7301,-6243),(7302,7302,-6236),(7303,7303,-6181),(7304,7304,35266),(7306,7306,-1),(7545,7545,35332),(7549,7549,3814),(7566,7566,35384),(7681,7829,-1),(7835,7835,-59),(7841,7935,-1),(7936,8039,8),(8048,8049,74),(8050,8053,86),(8054,8055,100),(8056,8057,128),(8058,8059,112),(8060,8061,126),(8064,8113,8),(8115,8115,9),(8126,8126,-7205),(8131,8131,9),(8144,8161,8),(8165,8165,7),(8179,8179,9),(8526,8526,-28),(8560,8575,-16),(8580,8580,-1),(9424,9449,-26),(11312,11359,-48),(11361,11361,-1),(11365,11365,-10795),(11366,11366,-10792),(11368,11507,-1),(11520,11565,-7264),(42561,42899,-1),(42900,42900,48),(42903,42998,-1),(43859,43859,-928),(43888,43967,-38864),(65345,65370,-32),(66600,66811,-40),(66967,67004,-39),(68800,68850,-64),(68976,93823,-32),(125218,125251,-34)]

lcTable :: [(Int, Int, Int)]
lcTable =
  [(65,222,32),(256,302,1),(304,304,-199),(306,374,1),(376,376,-121),(377,381,1),(385,385,210),(386,388,1),(390,390,206),(391,391,1),(393,394,205),(395,395,1),(398,398,79),(399,399,202),(400,400,203),(401,401,1),(403,403,205),(404,404,207),(406,406,211),(407,407,209),(408,408,1),(412,412,211),(413,413,213),(415,415,214),(416,420,1),(422,422,218),(423,423,1),(425,425,218),(428,428,1),(430,430,218),(431,431,1),(433,434,217),(435,437,1),(439,439,219),(440,444,1),(452,452,2),(453,453,1),(455,455,2),(456,456,1),(458,458,2),(459,494,1),(497,497,2),(498,500,1),(502,502,-97),(503,503,-56),(504,542,1),(544,544,-130),(546,562,1),(570,570,10795),(571,571,1),(573,573,-163),(574,574,10792),(577,577,1),(579,579,-195),(580,580,69),(581,581,71),(582,886,1),(895,895,116),(902,902,38),(904,906,37),(908,908,64),(910,911,63),(913,939,32),(975,975,8),(984,1006,1),(1012,1012,-60),(1015,1015,1),(1017,1017,-7),(1018,1018,1),(1021,1023,-130),(1024,1039,80),(1040,1071,32),(1120,1214,1),(1216,1216,15),(1217,1326,1),(1329,1366,48),(4256,4301,7264),(5024,5103,38864),(5104,5109,8),(7305,7305,1),(7312,7359,-3008),(7680,7828,1),(7838,7838,-7615),(7840,7934,1),(7944,8121,-8),(8122,8123,-74),(8124,8124,-9),(8136,8139,-86),(8140,8140,-9),(8152,8153,-8),(8154,8155,-100),(8168,8169,-8),(8170,8171,-112),(8172,8172,-7),(8184,8185,-128),(8186,8187,-126),(8188,8188,-9),(8486,8486,-7517),(8490,8490,-8383),(8491,8491,-8262),(8498,8498,28),(8544,8559,16),(8579,8579,1),(9398,9423,26),(11264,11311,48),(11360,11360,1),(11362,11362,-10743),(11363,11363,-3814),(11364,11364,-10727),(11367,11371,1),(11373,11373,-10780),(11374,11374,-10749),(11375,11375,-10783),(11376,11376,-10782),(11378,11381,1),(11390,11391,-10815),(11392,42875,1),(42877,42877,-35332),(42878,42891,1),(42893,42893,-42280),(42896,42920,1),(42922,42922,-42308),(42923,42923,-42319),(42924,42924,-42315),(42925,42925,-42305),(42926,42926,-42308),(42928,42928,-42258),(42929,42929,-42282),(42930,42930,-42261),(42931,42931,928),(42932,42946,1),(42948,42948,-48),(42949,42949,-42307),(42950,42950,-35384),(42951,42953,1),(42955,42955,-42343),(42956,42970,1),(42972,42972,-42561),(42997,42997,1),(65313,65338,32),(66560,66771,40),(66928,66965,39),(68736,68786,64),(68944,93791,32),(125184,125217,34)]
