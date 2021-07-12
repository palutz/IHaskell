{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeSynonymInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans  #-}

module IHaskell.Display.Widgets.Float.BoundedFloat.FloatLogSlider
  ( -- * The FloatSlider Widget
    FloatLogSlider
    -- * Constructor
  , mkFloatLogSlider
  ) where

-- To keep `cabal repl` happy when running from the ihaskell repo
import           Prelude

import           Control.Monad (void)
import           Data.Aeson
import           Data.IORef (newIORef)
import qualified Data.Scientific as Sci
import           Data.Vinyl (Rec(..), (<+>))

import           IHaskell.Display
import           IHaskell.Eval.Widgets
import           IHaskell.IPython.Message.UUID as U

import           IHaskell.Display.Widgets.Types
import           IHaskell.Display.Widgets.Common

-- | 'FloatLogSlider' represents an FloatLogSlider widget from IPython.html.widgets.
type FloatLogSlider = IPythonWidget 'FloatLogSliderType

-- | Create a new widget
mkFloatLogSlider :: IO FloatLogSlider
mkFloatLogSlider = do
  -- Default properties, with a random uuid
  wid <- U.random

  let boundedFloatAttrs = defaultBoundedFloatWidget "FloatLogSliderView" "FloatLogSliderModel"
      sliderAttrs = (Orientation =:: HorizontalOrientation)
                    :& (ShowRange =:: False)
                    :& (ReadOut =:: True)
                    :& (SliderColor =:: "")
                    :& (BaseFloat =:: 10.0)
                    :& RNil
      widgetState = WidgetState $ boundedFloatAttrs <+> sliderAttrs

  stateIO <- newIORef widgetState

  let widget = IPythonWidget wid stateIO

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen widget $ toJSON widgetState

  -- Return the widget
  return widget

instance IHaskellWidget FloatLogSlider where
  getCommUUID = uuid
  comm widget val _ =
    case nestedObjectLookup val ["state", "value"] of
      Just (Number value) -> do
        void $ setField' widget FloatValue (Sci.toRealFloat value)
        triggerChange widget
      _ -> pure ()
