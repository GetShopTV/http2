{-# LANGUAGE OverloadedStrings #-}

module HPACKDecode (
    run
  , Result(..)
  , EncodeStrategy(..)
  , defaultEncodeStrategy
  , CompressionAlgo(..)
  ) where

import Control.Applicative ((<$>))
import Control.Exception
import Control.Monad (when)
import qualified Data.ByteString.Char8 as B8
import Data.List (sort)
import Network.HPACK
import Network.HPACK.Context
import Network.HPACK.Context.HeaderList
import Network.HPACK.HeaderBlock

import HexString
import Types

data Conf = Conf {
    debug :: Bool
  }

data Result = Pass | Fail String deriving (Eq,Show)

run :: Bool -> Test -> IO Result
run _ (Test _ _ [])        = return $ Pass
run d (Test _ _ ccs@(c:_)) = do
    let siz = maybe 4096 id $ size c
    dctx <- newContextForDecoding siz
    let conf = Conf { debug = d }
    testLoop conf ccs dctx

testLoop :: Conf
         -> [Case]
         -> Context
         -> IO Result
testLoop _    []     _    = return $ Pass
testLoop conf (c:cs) dctx  = do
    res <- test conf c dctx
    case res of
        Right dctx' -> testLoop conf cs dctx'
        Left  e     -> return $ Fail e

test :: Conf
     -> Case
     -> Context
     -> IO (Either String Context)
test conf c dctx = do
    -- context is destructive!!!
    when (debug conf) $ do
        putStrLn "--------------------------------"
        putStrLn "---- Input headerlist"
        printHeaderList $ sort hs
        putStrLn "---- Input context"
        printContext dctx
        putStrLn "---- Input Hex"
        B8.putStrLn hex
        putStrLn "---- Input header block"
        print bshd'
    dctx0 <- case size c of
        Nothing  -> return dctx
        Just siz -> changeContextForDecoding dctx siz
    x <- try $ decodeHeader dctx0 inp
    case x of
        Left e -> return $ Left $ show (e :: DecodeError)
        Right (dctx',hs') -> do
            let pass = sort hs == sort hs'
            if pass then
                return $ Right (dctx')
              else
                return $ Left $ "Headers are different in " ++ B8.unpack hex ++ ":\n" ++ show hd ++ "\n" ++ show hs ++ "\n" ++ show hs'
  where
    hex = wire c
    inp = fromHexString hex
    hs = headers c
    bshd = fromByteStreamDebug inp
    hd = map snd <$> bshd
    bshd' = map (\(x,y)->(toHexString x,y)) <$> bshd
