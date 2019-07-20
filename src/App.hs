{-# LANGUAGE NoImplicitPrelude #-}

module App
    ( go
    ) where

import ClassyPrelude

import Control.Lens ((^.), (.~))

import Brick
import Graphics.Vty              (Mode (BracketedPaste), outputIface, setMode, supportsMode)
import Graphics.Vty.Input.Events (Event (..))

import qualified Control.FoldDebounce as Debounce

import System.Process          (callProcess)

import Data.Taskell.Date       (currentDay)
import Data.Taskell.Lists      (Lists)
import Events.Actions          (ActionSets, event, generateActions)
import Events.State            (continue, countCurrent)
import Events.State.Types      (State, current, io, lists, mode, path)
import Events.State.Types.Mode (InsertMode (..), InsertType (..), ModalType (..), Mode (..))
import IO.Config               (Config, generateAttrMap, getBindings, layout)
import IO.Taskell              (writeData)
import UI.Draw                 (chooseCursor, draw)
import UI.Types                (ListIndex (..), ResourceName (..), TaskIndex (..))

type DebouncedMessage = (Lists, FilePath)

type DebouncedWrite = DebouncedMessage -> IO ()

type Trigger = Debounce.Trigger DebouncedMessage DebouncedMessage

-- store
store :: Config -> DebouncedMessage -> IO ()
store config (ls, pth) = writeData config ls pth

next :: DebouncedWrite -> State -> EventM ResourceName (Next State)
next send state =
    case state ^. io of
        Just ls -> do
            invalidateCache
            liftIO $ send (ls, state ^. path)
            Brick.continue $ Events.State.continue state
        Nothing -> Brick.continue state

-- debouncing
debounce :: Config -> State -> IO (DebouncedWrite, Trigger)
debounce config initial = do
    trigger <-
        Debounce.new
            Debounce.Args
            { Debounce.cb = store config
            , Debounce.fold = flip const
            , Debounce.init = (initial ^. lists, initial ^. path)
            }
            Debounce.def
    let send = Debounce.send trigger
    pure (send, trigger)

-- cache clearing
clearCache :: State -> EventM ResourceName ()
clearCache state = do
    let (li, ti) = state ^. current
    invalidateCacheEntry (RNList li)
    invalidateCacheEntry (RNTask (ListIndex li, TaskIndex ti))

clearAllTitles :: State -> EventM ResourceName ()
clearAllTitles state = do
    let count = length (state ^. lists)
    let range = [0 .. (count - 1)]
    traverse_ (invalidateCacheEntry . RNList) range
    traverse_ (invalidateCacheEntry . RNTask . flip (,) (TaskIndex (-1)) . ListIndex) range

clearList :: State -> EventM ResourceName ()
clearList state = do
    let (list, _) = state ^. current
    let count = countCurrent state
    let range = [0 .. (count - 1)]
    invalidateCacheEntry $ RNList list
    traverse_ (invalidateCacheEntry . RNTask . (,) (ListIndex list) . TaskIndex) range

-- event handling
handleVtyEvent ::
       (DebouncedWrite, Trigger) -> ActionSets -> State -> Event -> EventM ResourceName (Next State)
handleVtyEvent (send, trigger) actions previousState e = do
    let state = event actions e previousState
    case previousState ^. mode of
        Search _ _               -> invalidateCache
        (Modal MoveTo)           -> clearAllTitles previousState
        (Insert ITask ICreate _) -> clearList previousState
        _                        -> pure ()
    case state ^. mode of
        Shutdown -> liftIO (Debounce.close trigger) *> Brick.halt state
        (Modal MoveTo) -> clearAllTitles state *> next send state
        (Insert ITask ICreate _) -> clearList state *> next send state
        -- *** DEBUG PUKECODE ***
        -- TODO this so doesn't work. Brick or Graphics.Vty seem to steal
        --      keyboard events or something.
        ExternEdit -> do
            void $ liftIO $ withSystemTempFile
                                "taskell-extern-edit"
                                (\fp h -> callProcess "vim" [fp] *> hGetContents h)
            Brick.continue (mode .~ Modal MoveTo $ state)
        -- *** End DEBUG PUKECODE ***
        _ -> clearCache previousState *> clearCache state *> next send state

handleEvent ::
       (DebouncedWrite, Trigger)
    -> ActionSets
    -> State
    -> BrickEvent ResourceName e
    -> EventM ResourceName (Next State)
handleEvent _ _ state (VtyEvent (EvResize _ _)) = invalidateCache *> Brick.continue state
handleEvent db actions state (VtyEvent ev)      = handleVtyEvent db actions state ev
handleEvent _ _ state _                         = Brick.continue state

-- | Runs when the app starts
--   Adds paste support
appStart :: State -> EventM ResourceName State
appStart state = do
    output <- outputIface <$> getVtyHandle
    when (supportsMode output BracketedPaste) . liftIO $ setMode output BracketedPaste True
    pure state

-- | Sets up Brick
go :: Config -> State -> IO ()
go config initial = do
    attrMap' <- const <$> generateAttrMap
    today <- currentDay
    db <- debounce config initial
    bindings <- getBindings
    let app =
            App
            { appDraw = draw (layout config) bindings today
            , appChooseCursor = chooseCursor
            , appHandleEvent = handleEvent db (generateActions bindings)
            , appStartEvent = appStart
            , appAttrMap = attrMap'
            }
    void (defaultMain app initial)
