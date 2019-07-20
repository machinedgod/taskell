{-# LANGUAGE NoImplicitPrelude #-}

module Events.State.Types.Mode where

import ClassyPrelude

import UI.Field (Field)

data DetailMode
    = DetailNormal
    | DetailInsert Field
    deriving (Eq, Show)

data DetailItem
    = DetailItem Int
    | DetailDescription
    | DetailDate
    deriving (Eq, Show)

data ModalType
    = Help
    | MoveTo
    | Detail DetailItem
             DetailMode
    deriving (Eq, Show)

data InsertType
    = ITask
    | IList
    deriving (Eq, Show)

data InsertMode
    = IEdit
    | ICreate
    deriving (Eq, Show)

data Mode
    = Normal
    | Insert InsertType
             InsertMode
             Field
    | ExternEdit
    | Modal ModalType
    | Search Bool
             Field
    | Shutdown
    deriving (Eq, Show)
