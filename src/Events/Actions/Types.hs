{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}

module Events.Actions.Types where

import ClassyPrelude hiding (Left, Nothing, Right)

data ActionType
    = Quit
    | Undo
    | Search
    | Help
    | Previous
    | Next
    | Left
    | Right
    | Bottom
    | New
    | NewAbove
    | NewBelow
    | Edit
    | Clear
    | Delete
    | Detail
    | DueDate
    | MoveUp
    | MoveDown
    | MoveLeft
    | MoveRight
    | MoveMenu
    | ListNew
    | ListEdit
    | ListDelete
    | ListRight
    | ListLeft

    | PomodoroStart
    | PomodoroStop

    | Nothing
    deriving (Show, Eq, Ord, Enum)

allActions :: [ActionType]
allActions = [toEnum 0 ..]

read :: Text -> ActionType
read "quit"               = Quit
read "undo"               = Undo
read "search"             = Search
read "help"               = Help
read "previous"           = Previous
read "next"               = Next
read "left"               = Left
read "right"              = Right
read "bottom"             = Bottom
read "new"                = New
read "newAbove"           = NewAbove
read "newBelow"           = NewBelow
read "edit"               = Edit
read "clear"              = Clear
read "delete"             = Delete
read "detail"             = Detail
read "dueDate"            = DueDate
read "moveUp"             = MoveUp
read "moveDown"           = MoveDown
read "moveLeft"           = MoveLeft
read "moveRight"          = MoveRight
read "moveMenu"           = MoveMenu
read "listNew"            = ListNew
read "listEdit"           = ListEdit
read "listDelete"         = ListDelete
read "listRight"          = ListRight
read "listLeft"           = ListLeft
read "pomodoroStart"      = PomodoroStart
read "pomodoroStop"       = PomodoroStop
read _                    = Nothing
