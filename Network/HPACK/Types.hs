module Network.HPACK.Types where

import Data.ByteString (ByteString)
import qualified Data.ByteString.Char8 as BS
import Data.Array

----------------------------------------------------------------

type HeaderName = ByteString
type HeaderValue = ByteString
type Header = (HeaderName, HeaderValue)
type HeaderSet = [Header]

----------------------------------------------------------------

type Index = Int

data Indexing = Add | NotAdd deriving Show

data Naming = Idx Index | Lit HeaderName deriving Show

type HeaderBlock = [Representation]

data Representation = Indexed Index
                    | Literal Indexing Naming HeaderValue
                    deriving Show

----------------------------------------------------------------

type Size = Int

-- Size is len of name + len of value + 32
type Entry = (Size,Header)

type Table = Array Index Entry

----------------------------------------------------------------

data StaticTable = StaticTable Size Table deriving Show

data HeaderTable = HeaderTable {
    maxNumOfEntries :: Int
  , offset :: Index
  , numOfEntries :: Int
  , circularTable :: Table
  , headerTableSize :: Size
  , maxHeaderTableSize :: Size
  }

data ReferenceSet = ReferenceSet [Index] deriving Show

data Context = Context {
    headerTable :: HeaderTable
  , oldReferenceSet :: ReferenceSet -- not emitted
  , newReferenceSet :: ReferenceSet -- emitted
  , headerSet :: HeaderSet
  }

----------------------------------------------------------------

data WhichTable = InHeaderTable Entry
                | InStaticTable Entry
                | IndexError
                deriving Eq

data DecodeError = IndexOverrun deriving Show

----------------------------------------------------------------

instance Show HeaderTable where
    show (HeaderTable _ off num tbl tblsiz _) =
        showArray tbl (off+1) num
     ++ "      Table size: " ++ show tblsiz

showArray :: Table -> Index -> Int -> String
showArray tbl off num = showArray' tbl off num 1

showArray' :: Table -> Index -> Int -> Int -> String
showArray' tbl off num cnt
  | cnt > num = ""
  | otherwise = "[ " ++ show cnt ++ "] " ++ keyval ++ "\n"
             ++ showArray' tbl (off+1) num (cnt+1)
  where
    (s,(k,v)) = tbl ! off
    keyval = "(s = " ++ show s ++ ") " ++ BS.unpack k ++ ": " ++ BS.unpack v

instance Show Context where
  show (Context hdrtbl oldref _ hdrset) = show hdrtbl ++ "\n"
                                       ++ show oldref ++ "\n"
                                       ++ show hdrset