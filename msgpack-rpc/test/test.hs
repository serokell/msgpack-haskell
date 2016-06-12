{-# LANGUAGE OverloadedStrings #-}

import           Control.Concurrent         (threadDelay)
import           Control.Concurrent.Async   (race_)
import           Control.Monad.Trans        (liftIO)
import           Test.Tasty                 (defaultMain, testGroup)
import           Test.Tasty.HUnit           (testCase, (@?=))

import           Network                    (withSocketsDo)
import           Network.MessagePack.Client (Client, call, execClient)
import           Network.MessagePack.Server (Server, method, serve)

port :: Int
port = 5000

main :: IO ()
main = withSocketsDo $ defaultMain $
  testGroup "simple service"
  [ testCase "test" $ server `race_` (threadDelay 1000 >> client) ]

server :: IO ()
server =
  serve port
    [ method "add"  add
    , method "echo" echo
    ]
  where
    add :: Int -> Int -> Server Int
    add x y = return $ x + y

    echo :: String -> Server String
    echo s = return $ "***" ++ s ++ "***"

client :: IO ()
client = execClient "127.0.0.1" port $ do
  r1 <- add 123 456
  liftIO $ r1 @?= 123 + 456
  r2 <- echo "hello"
  liftIO $ r2 @?= "***hello***"
  where
    add :: Int -> Int -> Client Int
    add = call "add"

    echo :: String -> Client String
    echo = call "echo"
