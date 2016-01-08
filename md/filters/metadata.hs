#!/usr/bin/runhaskell

import Data.Map.Lazy (fromList, (!), unions)

import Text.Pandoc
import Text.Pandoc.JSON
import Text.Pandoc.Error

getMeta :: Pandoc -> Meta
getMeta (Pandoc meta _) = meta

getDoc :: Pandoc -> [Block]
getDoc (Pandoc _ doc) = doc

concatPandocs :: [Pandoc] -> Pandoc
concatPandocs pds = Pandoc (Meta (unions (map (unMeta . getMeta) pds))) (concatMap getDoc pds)

fullFile :: Pandoc -> Pandoc
fullFile p@(Pandoc meta doc) =
    case lookupMeta "include" meta of
        Just mv -> Pandoc (Meta (fromList [("include", mv)])) doc
        _       -> p

main :: IO ()
main = toJSONFilter fullFile
