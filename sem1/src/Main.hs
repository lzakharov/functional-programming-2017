module Main where

newtype Symbol = Symbol { unSymbol :: String } deriving (Eq,Show,Read)

data TermS = SymS Symbol        -- x
           | LamS Symbol TermS  -- \x -> t
           | AppS TermS TermS   -- t1 t2
           deriving (Eq,Show,Read)

data TermI = SymI Int
           | LamI TermI
           | AppI TermI TermI
           deriving (Eq,Show,Read)

-- getIndex returns index of variable from grammar
getIndex :: (Eq a) => a -> [a] -> Int
getIndex a xs = getIndex' 0 (reverse xs)
  where
    getIndex' i [] = i
    getIndex' i (x:xs) | a == x    = i
                       | otherwise = getIndex' (i + 1) xs

-- toTermI transforms a lambda term into it's de Bruijn representation
toTermI :: TermS -> TermI
toTermI t = toTermI' [] t
  where
    toTermI' g (SymS x) = SymI (getIndex x g)
    toTermI' g (LamS x t) = LamI (toTermI' (g ++ [x]) t)
    toTermI' g (AppS t1 t2) = AppI (toTermI' g t1) (toTermI' g t2)

-- shift of the term t to the d position with cutoff c
shift :: TermI -> Int -> Int -> TermI
shift (SymI k) d c = if k < c then (SymI k) else (SymI (k + d))
shift (LamI t1) d c = LamI (shift t1 d (c + 1))
shift (AppI t1 t2) d c = AppI (shift t1 d c) (shift t2 d c)

-- substitution of the term s for the variable j in the term t
substitution :: TermI -> Int -> TermI -> TermI
substitution s j (SymI k) = if k == j then s else (SymI k)
substitution s j (LamI t1) = LamI (substitution (shift s 1 0) (j + 1) t1)
substitution s j (AppI t1 t2) = AppI (substitution s j t1) (substitution s j t2)

-- Beta reduction for terms with de Bruijn indices
betaI :: TermI -> Maybe TermI
betaI (SymI x) = Nothing
betaI (LamI t) = let t' = betaI t
                 in case t' of
                   (Just a) -> Just (LamI a)
                   otherwise -> Nothing
betaI (AppI (LamI t1) t2) = Just (shift (substitution (shift t2 1 0) 0 t1) (-1) 0)
betaI (AppI t1 t2) = let t1' = betaI t1
                     in case t1' of
                       (Just a) -> Just (AppI a t2)
                       otherwise -> let t2' = betaI t2
                                    in case t2' of
                                      (Just a) -> Just (AppI t1 a)
                                      otherwise -> Nothing

data TermP = TermP TermS
           -- Boolean constants and operations (and, or, not)
           | Boolean Bool
           | Iff TermP TermP TermP
           | Not TermP
           | And TermP TermP
           | Or TermP TermP

-- λt.λf.t
tru = LamS (Symbol "t") (LamS (Symbol "f") (SymS (Symbol "t")))
-- λt.λf.f
fls = LamS (Symbol "t") (LamS (Symbol "f") (SymS (Symbol "f")))
-- λb. λt. λf. b t f
iff = LamS (Symbol "b") (LamS (Symbol "t") (LamS (Symbol "f") (AppS (AppS (SymS (Symbol "b")) (SymS (Symbol "t"))) (SymS (Symbol "f")))))
-- λx. x fls tru
not_ = LamS (Symbol "x") (AppS (AppS (SymS (Symbol "x")) fls) (tru))
-- λx. λy. x y fls
and_ = LamS (Symbol "x") (LamS (Symbol "y") (AppS (AppS (SymS (Symbol "x")) (SymS (Symbol "y"))) (fls)))
-- λx. λy. x tru y
or_ = LamS (Symbol "x") (LamS (Symbol "y") (AppS (AppS (SymS (Symbol "x")) (tru)) (SymS (Symbol "y"))))

toTermS :: TermP -> TermS
toTermS (Boolean True) = tru
toTermS (Boolean False) = fls
toTermS (Iff b x y) = AppS (AppS (AppS (iff) (toTermS b)) (toTermS x)) (toTermS y)
toTermS (Not x) = AppS (not_) (toTermS x)
toTermS (And x y) = AppS (AppS (and_) (toTermS x)) (toTermS y)
toTermS (Or x y) = AppS (AppS (or_) (toTermS x)) (toTermS y)

-- let
sym x = SymS (Symbol x)
lam x t = LamS (Symbol x) t
app t1 t2 = AppS t1 t2

main :: IO ()
main = do
  putStrLn "Семестровая работа №1"
