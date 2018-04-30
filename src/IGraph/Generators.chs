{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}
module IGraph.Generators
    ( full
    , ErdosRenyiModel(..)
    , erdosRenyiGame
    , degreeSequenceGame
    , rewire
    ) where

import           Control.Monad                  (when)
import           Data.Hashable                  (Hashable)
import           Data.Serialize                 (Serialize)
import Data.Singletons (SingI, Sing, sing, fromSing)
import System.IO.Unsafe (unsafePerformIO)

import qualified Foreign.Ptr as C2HSImp
import Foreign

import           IGraph
import           IGraph.Mutable
{#import IGraph.Internal #}
{#import IGraph.Internal.Constants #}
{# import IGraph.Internal.Initialization #}

#include "haskell_igraph.h"

full :: forall d. SingI d
     => Int   -- ^ The number of vertices in the graph.
     -> Bool  -- ^ Whether to include self-edges (loops)
     -> Graph d () ()
full n hasLoop = unsafePerformIO $ do
    gr <- igraphFull n directed hasLoop
    unsafeFreeze $ MGraph gr
  where
    directed = case fromSing (sing :: Sing d) of
        D -> True
        U -> False
{#fun igraph_full as ^
    { allocaIGraph- `IGraph' addIGraphFinalizer*
    , `Int', `Bool', `Bool'
    } -> `CInt' void- #}

data ErdosRenyiModel = GNP Int Double
                     | GNM Int Int

erdosRenyiGame :: forall d. SingI d
               => ErdosRenyiModel
               -> Bool  -- ^ self-loop
               -> IO (Graph d () ())
erdosRenyiGame model self = do
    igraphInit
    gr <- case model of
        GNP n p -> igraphErdosRenyiGame IgraphErdosRenyiGnp n p directed self
        GNM n m -> igraphErdosRenyiGame IgraphErdosRenyiGnm n (fromIntegral m)
            directed self
    unsafeFreeze $ MGraph gr
  where
    directed = case fromSing (sing :: Sing d) of
        D -> True
        U -> False
{#fun igraph_erdos_renyi_game as ^
    { allocaIGraph- `IGraph' addIGraphFinalizer*
    , `ErdosRenyi', `Int', `Double', `Bool', `Bool'
    } -> `CInt' void- #}

-- | Generates a random graph with a given degree sequence.
degreeSequenceGame :: [Int]   -- ^ Out degree
                   -> [Int]   -- ^ In degree
                   -> IO (Graph 'D () ())
degreeSequenceGame out_deg in_deg = withList out_deg $ \out_deg' ->
    withList in_deg $ \in_deg' -> do
        gp <- igraphDegreeSequenceGame out_deg' in_deg' IgraphDegseqSimple
        unsafeFreeze $ MGraph gp
{#fun igraph_degree_sequence_game as ^
    { allocaIGraph- `IGraph' addIGraphFinalizer*
    , castPtr `Ptr Vector', castPtr `Ptr Vector', `Degseq'
    } -> `CInt' void- #}

-- | Randomly rewires a graph while preserving the degree distribution.
rewire :: (Hashable v, Serialize v, Eq v, Serialize e)
       => Int    -- ^ Number of rewiring trials to perform.
       -> Graph d v e
       -> IO (Graph d v e)
rewire n gr = do
    (MGraph gptr) <- thaw gr
    err <- igraphRewire gptr n IgraphRewiringSimple
    when (err /= 0) $ error "failed to rewire graph!"
    unsafeFreeze $ MGraph gptr
{#fun igraph_rewire as ^ { `IGraph', `Int', `Rewiring' } -> `Int' #}
