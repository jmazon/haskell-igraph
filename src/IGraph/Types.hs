{-# LANGUAGE DataKinds              #-}
{-# LANGUAGE DeriveGeneric          #-}
{-# LANGUAGE EmptyCase              #-}
{-# LANGUAGE FlexibleContexts       #-}
{-# LANGUAGE FlexibleInstances      #-}
{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE GADTs                  #-}
{-# LANGUAGE InstanceSigs           #-}
{-# LANGUAGE MultiParamTypeClasses  #-}
{-# LANGUAGE ScopedTypeVariables    #-}
{-# LANGUAGE StandaloneDeriving     #-}
{-# LANGUAGE TemplateHaskell        #-}
{-# LANGUAGE TypeFamilies           #-}
{-# LANGUAGE TypeOperators          #-}
{-# LANGUAGE UndecidableInstances   #-}
{-# LANGUAGE StandaloneKindSignatures #-}

module IGraph.Types where

import           Data.Serialize          (Serialize)
import           Data.Singletons.TH
import Prelude.Singletons
import           GHC.Generics            (Generic)

$(singletons [d|
    data EdgeType = D
                  | U
        deriving (Eq, Generic)
    |])

instance Serialize EdgeType

type Node = Int
type LNode a = (Node, a)

type Edge = (Node, Node)
type LEdge a = (Edge, a)

vertexAttr :: String
vertexAttr = "vertex_attribute"

edgeAttr :: String
edgeAttr = "edge_attribute"
