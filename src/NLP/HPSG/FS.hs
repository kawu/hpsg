-- | Feature structures.


module NLP.HPSG.FS
(
-- * Feature structure
  FS
, FN (..)
, FV
-- * Unification
, unifyWrong
) where


import           Control.Applicative ((<$>))
import           Data.Traversable (traverse)
import qualified Data.Map as M


-- On the basis of the description in the book:
--
-- 1#
--
-- Types of feature structures are arranged in
-- a tree-like hierarchy.
--
-- It is certainly possible to represent this FS hierarchy on
-- the level of the Haskell type system, but is it reasonable?
-- No, it doesn't seems to be what we want!  It is more like
-- an inheritance hierarchy, which is not a kind of hierarchy
-- easily represented with the Haskell type system.  So there's
-- no point to do that.
--
-- 2#
--
-- It can be concluded from 3.3.4, that it should be possible
-- to define FS templates (abbreviated descriptions, in other words).
-- Templates in 3.3.4 are simple, but perhaps it makes sense to allow
-- functional (lambda) templates as well.


-- -- | Feature structure type.
-- data FSType a = FSType {
--     -- | Name of the FS type.
--       fsType    :: a
--     -- | Map from attributes defined for a particular type to
--     -- values (names of other FS types or atomic entities).
--     -- Attribute names and value names can collide.
--     , fsAtts    :: M.Map a (FVType a)
--     } deriving (Show, Eq, Ord)
-- 
-- 
-- -- | A feature value.
-- data FVType a
--     = Ptr a           -- ^ Pointer to another feature type
--     | Dom (S.Set a)   -- ^ Set of possible values
-- 
-- 
-- ---------------------------------------------------------------------
-- -- Hierarchy of types defined in the book
-- ---------------------------------------------------------------------
-- 
-- 
-- -- | FS hierarchy smart constructor.
-- mkFS :: a -> [(a, a)] -> [FSType a] -> Tree (FSType a)
-- mkFS x ys = Node (FSType x $ M.fromList ys)
-- 
-- 
-- -- | Domain smart constructor.
-- dom :: [a] -> FVType a
-- dom xs = FVType . S.fromList
-- 
-- 
-- -- | Hierarchy of FS types.
-- typHier :: Tree (FSType String)
-- typHier = mkFS "feat-struc" []
--     [ mkFS "expression"
--         [ ("head", Ptr "pos")
--         , ("val", Ptr "val-cat") ]
--         [ mkFS "phrase" []
--         , mkFS "word" [] ]
--     , mkFS "pos" []
--         [ mkFS "agr-pos" [("agr", ?)]
--             [ mkFS "noun" []
--             , mkFS "verb" [("aux", ?)]
--             , mkFS "det" [] ]
--         , mkFS "prep"
--         , mkFS "adj"
--         , mkFS "conj" ]
--     , mkFS "val-cat"
--         [ ("comps", dom ["itr", "str", "dtr"])
--         , ("spr", dom ["-", "+"]) ]


---------------------------------------------------------------------
-- Feature structures
---------------------------------------------------------------------


-- | A feature structure, possibly with variables.  Traditionally,
-- the feature type is represented separately and always has an atomic
-- value, but there seems to be no point in enforcing this on the level
-- of the type system.
type FS a = M.Map a (FN a)


-- | A (posiblly named) feature value.
data FN a = FN {
    -- | A variable name (possibly)
      varName   :: Maybe a
--     -- | A set of potential values
--     , valSet    :: S.Set (FV a)
    -- | A feature value
    , value     :: FV a
    } deriving (Show, Eq, Ord)


-- | A feature value.
data FV a
    = Sub (FS a)        -- ^ Feature sub-structure
    | Val a             -- ^ Atomic value
    deriving (Show, Eq, Ord)


---------------------------------------------------------------------
-- Unification
---------------------------------------------------------------------


-- | Disregard variables and perform simplified unification of the
-- two given feature structures.
unifyWrong :: Ord a => FS a -> FS a -> Maybe (FS a)
unifyWrong s1 s2 = do
    mut <- traverse id $ M.intersectionWith unifyFN s1 s2
    return $ mut `M.union` s1 -|- s2
  where
    unifyFN (FN q x) (FN _ y) = FN q <$> unifyFV x y
    unifyFV (Val x) (Val y) = if x == y
        then Just $ Val x
        else Nothing
    unifyFV (Sub x) (Sub y) = Sub <$> unifyWrong x y
    unifyFV _ _ = Nothing


---------------------------------------------------------------------
-- Misc
---------------------------------------------------------------------


-- | Symmetric difference on maps.
(-|-) :: Ord a => M.Map a b -> M.Map a b -> M.Map a b
(-|-) x y = (x M.\\ y) `M.union` (y M.\\ x)
