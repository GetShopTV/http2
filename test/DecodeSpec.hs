module DecodeSpec where

import Network.HPACK.Context
import Network.HPACK.HeaderBlock
import Test.Hspec

import HeaderBlock

spec :: Spec
spec = do
    describe "fromHeaderBlock" $ do
        it "decodes HeaderList in request" $ do
            (c1,h1) <- newContextForDecoding 4096 >>= flip fromHeaderBlock d41
            h1 `shouldBe` d41h
            (c2,h2) <- fromHeaderBlock c1 d42
            h2 `shouldBe` d42h
            (_,h3)  <- fromHeaderBlock c2 d43
            h3 `shouldBe` d43h
        it "decodes HeaderList in response" $ do
            (c1,h1) <- newContextForDecoding 256 >>= flip fromHeaderBlock d61
            h1 `shouldBe` d61h
            (c2,h2) <- fromHeaderBlock c1 d62
            h2 `shouldBe` d62h
            (_,h3)  <- fromHeaderBlock c2 d63
            h3 `shouldBe` d63h
