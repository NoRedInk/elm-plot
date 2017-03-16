module Svg.Plot
    exposing
        ( PlotCustomizations
        , PlotSummary
        , Point
        , defaultSeriesPlotCustomizations
        , defaultBarsPlotCustomizations
        , normalHoverContainer
        , flyingHoverContainer
        , viewJunk
        -- SERIES
        , viewSeries
        , viewSeriesCustom
        , Series
        , Interpolation(..)
        , dots
        , line
        , area
        , customSeries
        , DataPoint
        , square
        , circle
        , diamond
        , triangle
        , clear
        , dot
        , hintDot
        , emphasizedDot
        , rangeFrameDot
        , customDot
        -- BARS
        , viewBars
        , viewBarsCustom
        , Bars
        , BarGroup
        , MaxBarWidth(..)
        , groups
        , group
        , hintGroup
        , histogram
        , histogramBar
        , customGroups
        , customGroup
        -- AXIS
        , Axis
        , AxisSummary
        , TickCustomizations
        , LabelCustomizations
        , sometimesYouDoNotHaveAnAxis
        , emptyAxis
        , normalAxis
        , normalBarsAxis
        , axisAtMin
        , axisAtMax
        , customAxis
        , closestToZero
        , decentPositions
        , interval
        , remove
        , simpleLine
        , simpleTick
        , simpleLabel
        , viewLabel
        , fullLine
        -- GRID
        , Grid
        , GridLineCustomizations
        , decentGrid
        , emptyGrid
        -- HELP
        , viewCircle
        , viewSquare
        , viewDiamond
        , viewTriangle
        , displace
        )

{-|

# Series
@docs viewSeries

## Simple series
@docs dots, line, area

## Simple data points
Data points are the coordinates which makes up your series. They come with views or without.
Pass your x and y coordinate respectively to create a data point for your series.
@docs clear, square, circle, diamond, triangle

## Custom series
@docs Series, Interpolation, customSeries, DataPoint, dot, hintDot, rangeFrameDot, emphasizedDot, customDot

## Small helper views
Just thought you might want a hand with all the views you need for you data points.
@docs viewCircle, viewSquare, viewDiamond, viewTriangle

# Bars
@docs viewBars

# Simple bars
@docs groups, group, histogram, histogramBar

## Custom bars
@docs Bars, BarGroup, MaxBarWidth, hintGroup, customGroups, customGroup

# Custom view
@docs PlotCustomizations, PlotSummary, defaultSeriesPlotCustomizations, viewSeriesCustom, defaultBarsPlotCustomizations, viewBarsCustom

## Hover customizations
@docs Point, normalHoverContainer, flyingHoverContainer

## Grid customizations
@docs Grid, GridLineCustomizations, decentGrid, emptyGrid

## Junk
@docs viewJunk

# Axis customizations
@docs Axis, AxisSummary, TickCustomizations, LabelCustomizations

# Various axis
@docs normalAxis, normalBarsAxis, sometimesYouDoNotHaveAnAxis, emptyAxis, axisAtMin, axisAtMax, customAxis

## Position helpers
@docs decentPositions, interval, remove, closestToZero

## Small configuration helpers
@docs simpleLine, simpleTick, simpleLabel, fullLine, viewLabel, displace

-}

import Html exposing (Html, div, span)
import Html.Events
import Html.Attributes
import Svg exposing (Svg, Attribute, svg, text_, tspan, text, g, path, rect, polygon)
import Svg.Attributes as Attributes exposing (stroke, fill, class, r, x2, y2, style, strokeWidth, clipPath, transform)
import Svg.Draw as Draw exposing (..)
import Svg.Colors exposing (..)
import Json.Decode as Json
import Round
import Regex
import DOM


{-| Just an x and an y property.
-}
type alias Point =
  Draw.Point


{-| -}
type alias PlotSummary =
  Draw.PlotSummary


{-| A summary of information about an axis.
-}
type alias AxisSummary =
  Draw.AxisSummary


-- DATA POINTS


{-| -}
circle : Float -> Float -> DataPoint msg
circle =
  dot (viewCircle 5 pinkStroke)


{-| -}
square : Float -> Float -> DataPoint msg
square =
  dot (viewSquare 10 pinkStroke)


{-| -}
diamond : Float -> Float -> DataPoint msg
diamond =
  dot (viewDiamond 10 10 pinkStroke)


{-| -}
triangle : Float -> Float -> DataPoint msg
triangle =
  dot (viewTriangle pinkStroke)


{-| A data point without a view. -}
clear : Float -> Float -> DataPoint msg
clear =
  dot (text "")


{-| The data point. Here you can do tons of crazy stuff, although most
  importantly, you can specify the coordinates of you plot with
  the `x` and `y` properties. Besides that you can with:

  - `view`: Add a SVG view at your data point.
  - `xLine`: Provided a summary of the vertical axis, you can create
    a horizontal line. Useful when hovering your point.
  - `yLine`: Same as `xLine`, but vertically.
  - `xTick`: So this is for the progressive plotter. [Tufte](https://en.wikipedia.org/wiki/Edward_Tufte)
    recommends placing a tick where [the actual data point is](https://plot.ly/~riddhiman/254/miles-per-gallon-of-fuel-vs-car-weight-lb1000.png).
    Adding a tick view to this, will cast a tick to the horizontal axis and allow you to make a plot as in the link.
  - `yTick`: Like `xTick`, but vertically.
  - `viewHint`: The view added here will show up in the hint container (Whose view can be
    customized in the `PlotCustomizations`).

-}
type alias DataPoint msg =
  { view : Maybe (Svg msg)
  , xLine : Maybe (AxisSummary -> LineCustomizations)
  , yLine : Maybe (AxisSummary -> LineCustomizations)
  , xTick : Maybe TickCustomizations
  , yTick : Maybe TickCustomizations
  , viewHint : Maybe (Html Never)
  , x : Float
  , y : Float
  }


{-| Makes a data point provided a view, a x and a y.
-}
dot : Svg msg -> Float -> Float -> DataPoint msg
dot view x y =
  { view = Just view
  , xLine = Nothing
  , yLine = Nothing
  , xTick = Nothing
  , yTick = Nothing
  , viewHint = Nothing
  , x = x
  , y = y
  }



{-| Like `dot`, except it also takes a maybe coordinates to know if
  should add a hint view/vertical line or not.
-}
hintDot : Svg msg -> Maybe Point -> Float -> Float -> DataPoint msg
hintDot view hovering x y =
  { view = Just view
  , xLine = onHovering (fullLine [ stroke darkGrey ]) hovering x
  , yLine = Nothing
  , xTick = Nothing
  , yTick = Nothing
  , viewHint = onHovering (normalHint y) hovering x
  , x = x
  , y = y
  }


onHovering : a -> Maybe Point -> Float -> Maybe a
onHovering stuff hovering x =
  Maybe.andThen (\p ->
    if p.x == x then
      Just stuff
    else
      Nothing
    )
    hovering


{-| Really a silly surprise dot you can use if you want to be flashy. Try it if
  you're feeling lucky.
-}
emphasizedDot : Svg msg -> Float -> Float -> DataPoint msg
emphasizedDot view x y =
  { view = Just view
  , xLine = Just (fullLine [ stroke darkGrey, Attributes.strokeDasharray "5, 5" ])
  , yLine = Just (fullLine [ stroke darkGrey, Attributes.strokeDasharray "5, 5" ])
  , xTick = Nothing
  , yTick = Nothing
  , viewHint = Nothing
  , x = x
  , y = y
  }



{-| This dot implements a special plot in [Tuftes](https://en.wikipedia.org/wiki/Edward_Tufte) [book](https://www.amazon.com/Visual-Display-Quantitative-Information/dp/1930824130).
  It basically just adds ticks to your axis where [your data points are](https://plot.ly/~riddhiman/254/miles-per-gallon-of-fuel-vs-car-weight-lb1000.png)!
  You might want to use `emptyAxis` to remove all the other useless chart junk, now that your have all
  these nice ticks.
-}
rangeFrameDot : Svg msg -> Float -> Float -> DataPoint msg
rangeFrameDot view x y =
  { view = Just view
  , xLine = Nothing
  , yLine = Nothing
  , xTick = Just (simpleTick x)
  , yTick = Just (simpleTick y)
  , viewHint = Nothing
  , x = x
  , y = y
  }


normalHint : Float -> Html msg
normalHint y =
  span
    [ Html.Attributes.style [ ( "padding", "5px" ) ] ]
    [ Html.text ("y: " ++ toString y) ]



{-| Just do whatever you want.
-}
customDot :
  Maybe (Svg msg)
  -> Maybe (AxisSummary -> LineCustomizations)
  -> Maybe (AxisSummary -> LineCustomizations)
  -> Maybe TickCustomizations
  -> Maybe TickCustomizations
  -> Maybe (Html Never)
  -> Float
  -> Float
  -> DataPoint msg
customDot =
  DataPoint



-- SERIES


{-| The series configuration allows you to specify your
  own interpolation and how your data is transformed into series data points,
  but also a vertical axis relating to the series' scale. This way it's made sure
  you never have more than one y-axis per data set, because that would be just
  crazy.
-}
type alias Series data msg =
  { axis : Axis
  , interpolation : Interpolation
  , toDataPoints : data -> List (DataPoint msg)
  }


{-| -}
dots : (data -> List (DataPoint msg)) -> Series data msg
dots toDataPoints =
  { axis = normalAxis
  , interpolation = None
  , toDataPoints = toDataPoints
  }


{-| -}
line : (data -> List (DataPoint msg)) -> Series data msg
line toDataPoints =
  { axis = normalAxis
  , interpolation = Linear Nothing [ stroke pinkStroke ]
  , toDataPoints = toDataPoints
  }


{-| -}
area : (data -> List (DataPoint msg)) -> Series data msg
area toDataPoints =
  { axis = normalAxis
  , interpolation = Linear (Just pinkFill) [ stroke pinkStroke ]
  , toDataPoints = toDataPoints
  }


{-| Make your own series! The standard line series looks like this on the inside:

    line : (data -> List (DataPoint msg)) -> Series data msg
    line toDataPoints =
      { axis = normalAxis
      , interpolation = Linear Nothing [ stroke pinkStroke ]
      , toDataPoints = toDataPoints
      }

  Maybe pink isn't really your color and your want to make it green. No problem! You
  just add some different attributes to the interpolation. If you want a different
  interpolation or an area under that interpolation, look at the
  [Interpolation](#Interpolation) type for more info.
-}
customSeries : Axis -> Interpolation -> (data -> List (DataPoint msg)) -> Series data msg
customSeries =
  Series


{-| [Interpolation](https://en.wikipedia.org/wiki/Interpolation) is basically the line that goes
  between your data points. Your current options are:
  - None: No interpolation (a scatter plot).
  - Linear: A straight line.
  - Monotone: A nice looking curvy line which doesn't extend outside the y values of the two
    points involved (Huh? Here's an [illustration](https://en.wikipedia.org/wiki/Monotone_cubic_interpolation#/media/File:MonotCubInt.png)).

All but `None` **takes a color which determined whether it draws the area below the interpolation** and
list of attributes which you can use for styling your interpolation.
-}
type Interpolation
  = None
  | Linear (Maybe String) (List (Attribute Never))
  | Monotone (Maybe String) (List (Attribute Never))



-- BARS


{-| The bar configurations allows you to specify the styles of
  your bars, the max width of your bars, how your data is transformed into
  bar groups, as well the vertical axis related to your bar series.
-}
type alias Bars data msg =
  { axis : Axis
  , toGroups : data -> List BarGroup
  , styles : List (List (Attribute msg))
  , maxWidth : MaxBarWidth
  }


{-| A bar group is, well, a group of bars attached to a single data point on
  the horizontal axis.

  - The `bars` property specify the height and label of each bar in your
  group.
  - The `label` is what will show up on the horizontal axis
  at that data point. This is a function as you don't get to pick your own x.
  This is because bar charts per design is supposed to be scattered at a consistent
  interval.
  - The `viewHint` property is the view which will show up in your hint when
  hovering the group.
  - The `verticalLine` property is an option to add a vertical line. Nice when you have a hint.
-}
type alias BarGroup =
  { label : Float -> LabelCustomizations
  , viewHint : Float -> Maybe (Svg Never)
  , verticalLine : Float -> Maybe (AxisSummary -> LineCustomizations)
  , bars : List Bar
  }


{-| -}
type alias Bar =
  { label : Maybe (Svg Never)
  , height : Float
  }


{-| The width options of your bars. If `Percentage` is used, it will be _maximum_ that
  percentage of one unit on the horizontal axis wide. Similarily, using `Fixed` will
  set your bar to be maximum the provided float in pixels.
-}
type MaxBarWidth
  = Percentage Int
  | Fixed Float


{-| For regular bar charts.
-}
groups : (data -> List BarGroup) -> Bars data msg
groups toGroups =
  { axis = normalAxis
  , toGroups = toGroups
  , styles = [ [ fill pinkFill ], [ fill blueFill ] ]
  , maxWidth = Percentage 75
  }


{-| For regular groups.
-}
group : String -> List Float -> BarGroup
group label heights =
  { label = normalBarLabel label
  , verticalLine = always Nothing
  , viewHint = always Nothing
  , bars = List.map (Bar Nothing) heights
  }


{-| For groups with hint glitter.
-}
hintGroup : Maybe Point -> String -> List Float -> BarGroup
hintGroup hovering label heights =
  { label = normalBarLabel label
  , verticalLine = onHovering (fullLine [ stroke darkGrey ]) hovering
  , viewHint = \g -> onHovering (div [] <| List.map normalHint heights) hovering g
  , bars = List.map (Bar Nothing) heights
  }


{-| For histograms! Meaning that there is only one bar in each group and it's always
  one horizontal unit wide.
-}
histogram : (data -> List BarGroup) -> Bars data msg
histogram toGroups =
  { axis = normalAxis
  , toGroups = toGroups
  , styles = [ [ fill pinkFill, stroke pinkStroke ] ]
  , maxWidth = Percentage 100
  }


{-| -}
histogramBar : Float -> BarGroup
histogramBar height =
  { label = simpleLabel
  , verticalLine = always Nothing
  , viewHint = always Nothing
  , bars = [ Bar Nothing height ]
  }


{-| For special bar charts. -}
customGroups :
  Axis
  -> (data -> List BarGroup)
  -> List (List (Attribute msg))
  -> MaxBarWidth
  -> Bars data msg
customGroups =
  Bars


{-| For your special groups. -}
customGroup :
  (Float -> LabelCustomizations)
  -> (Float -> Maybe (Svg Never))
  -> (Float -> Maybe (AxisSummary -> LineCustomizations))
  -> List Bar
  -> BarGroup
customGroup =
  BarGroup


{-| So because there is extra funky labels added to your bar groups,
  your axis should not to clutter up with other random numbers. So use this one.
-}
normalBarsAxis : Axis
normalBarsAxis =
  customAxis <| \summary ->
    { position = closestToZero
    , axisLine = Just (simpleLine summary)
    , ticks = List.map simpleTick (interval 0 1 summary)
    , labels = []
    , flipAnchor = False
    }


{-| -}
normalBarLabel : String -> Float -> LabelCustomizations
normalBarLabel label position =
  { position = position
  , format = always label
  , view = viewLabel []
  }



-- PLOT


{-| The plot customizations. Here you may:

  - Add attributes to your whole plot (Useful when you want to do events for your plot).
  - Add an id (the id in here will overrule an id attribute you add in `.attributes`).
  - Change the width or height of your plot. I recommend the golden ratio!
  - Change the margin (useful when you can't see your ticks!).
  - Add a message which will be sent when your hover over a point on your plot!
  - Add your own container for your hints or use the predefined ones.
  - Add a more exciting horizontal axis. Maybe try `axisAtMin` or make your own?
  - Add a grid, but do consider whether that will actually improve the readability of your plot.
  - Change the bounds of your plot. For example, if you want your plot to start
    atleast at -5 on the y-axis, then add `toDomainLowest = min -5`.

  _Note:_ The `id` is particularily important when you have
  several plots in your dom.
-}
type alias PlotCustomizations msg =
  { attributes : List (Attribute msg)
  , id : String
  , width : Int
  , height : Int
  , margin :
    { top : Int
    , right : Int
    , bottom : Int
    , left : Int
    }
  , onHover : Maybe (Maybe Point -> msg)
  , viewHintContainer : PlotSummary -> List (Html Never) -> Html Never
  , horizontalAxis : Axis
  , grid :
    { horizontal : Grid
    , vertical : Grid
    }
  , junk : PlotSummary -> List { x : Float, y : Float, view : Svg msg }
  , toDomainLowest : Float -> Float
  , toDomainHighest : Float -> Float
  , toRangeLowest : Float -> Float
  , toRangeHighest : Float -> Float
  }


{-| The default series plot customizations.
-}
defaultSeriesPlotCustomizations : PlotCustomizations msg
defaultSeriesPlotCustomizations =
  { attributes = []
  , id = "elm-plot"
  , width = 687
  , height = 480
  , margin =
      { top = 20
      , right = 40
      , bottom = 20
      , left = 40
      }
  , onHover = Nothing
  , viewHintContainer = normalHoverContainer
  , horizontalAxis = normalAxis
  , grid =
      { horizontal = emptyGrid
      , vertical = emptyGrid
      }
  , junk = always []
  , toDomainLowest = identity
  , toDomainHighest = identity
  , toRangeLowest = identity
  , toRangeHighest = identity
  }


{-| -}
viewJunk : Svg msg -> Float -> Float -> JunkCustomizations msg
viewJunk title x y =
  { x = x
  , y = y
  , view = title
  }


{-| The default bars plot customizations.
-}
defaultBarsPlotCustomizations : PlotCustomizations msg
defaultBarsPlotCustomizations =
  { defaultSeriesPlotCustomizations
  | horizontalAxis = normalBarsAxis
  , margin =
      { top = 30
      , right = 40
      , bottom = 30
      , left = 40
      }
  }


{-| A view located at the bottom left corner of you plot, holding the hint views you
  (maybe) added in your data points or groups.
-}
normalHoverContainer : PlotSummary -> List (Html Never) -> Html Never
normalHoverContainer summary =
  div [ Html.Attributes.style [ ( "margin-left", toString summary.x.marginLower ++ "px" ) ] ]


{-| A view holding your hint views which flies around on your plot following the hovered x.
-}
flyingHoverContainer : Maybe Point -> PlotSummary -> List (Html Never) -> Html Never
flyingHoverContainer hovering summary hints =
  case hovering of
    Nothing ->
      text ""

    Just { x } ->
      let
        xOffset =
          toSVGX summary x

        isLeft =
          (x - summary.x.min) > (range summary.x) / 2

        margin =
          if isLeft then
            -20
          else
            20

        direction =
          if isLeft then
            "translateX(-100%)"
          else
            "translateX(0)"

        style =
          [ ( "position", "absolute" )
          , ( "top", "25%" )
          , ( "left", toString xOffset ++ "px" )
          , ( "transform", direction )
          , ( "padding", "5px 10px" )
          , ( "margin", "0 " ++ toString margin ++ "px" )
          , ( "background", grey )
          , ( "border-radius", "2px" )
          , ( "pointer-events", "none" )
          ]
      in
        div [ Html.Attributes.style style ] hints



-- GRID


{-| -}
type Grid
  = Grid (AxisSummary -> List GridLineCustomizations)
  | YeahGridsAreTotallyLame


{-| -}
type alias GridLineCustomizations =
  { attributes : List (Attribute Never)
  , position : Float
  }


{-| A grid with decent spacing. Uses the `decentPositions` function to calculate
  the positions of the grid lines. This also means that if you use `decentPositions`
  to calculate your tick positions, then they will match.
-}
decentGrid : Grid
decentGrid =
  grid <| \summary ->
    List.map (GridLineCustomizations [ stroke grey ]) (decentPositions summary)


{-| No grid. Tufte would be proud of you. 💛
-}
emptyGrid : Grid
emptyGrid =
  YeahGridsAreTotallyLame


{-| Make your own grid! -}
grid : (AxisSummary -> List GridLineCustomizations) -> Grid
grid =
  Grid



-- AXIS


{-| -}
type Axis
  = Axis (AxisSummary -> AxisCustomizations)
  | SometimesYouDoNotHaveAnAxis


{-| The axis customizations. You may:

  - Change the position of you axis. This is what the `axisAtMin` does!
  - Change the look and feel of the axis line.
  - Add a variation of ticks.
  - Add a variation of labels.
  - Add a title or whatever.

-}
type alias AxisCustomizations =
  { position : Float -> Float -> Float
  , axisLine : Maybe LineCustomizations
  , ticks : List TickCustomizations
  , labels : List LabelCustomizations
  , flipAnchor : Bool
  }


{-| -}
closestToZero : Float -> Float -> Float
closestToZero min max =
  clamp min max 0


{-| -}
type alias LineCustomizations =
  { attributes : List (Attribute Never)
  , start : Float
  , end : Float
  }


{-| -}
type alias TickCustomizations =
  { attributes : List (Attribute Never)
  , length : Float
  , position : Float
  }


{-| -}
type alias LabelCustomizations =
  { view : String -> Svg Never
  , format : Float -> String
  , position : Float
  }


{-| Just add whatever you want. A title might be an idea though.
-}
type alias JunkCustomizations msg =
  { x : Float
  , y : Float
  , view : Svg msg
  }


{-| When you don't have an axis, which is only sometimes.
-}
sometimesYouDoNotHaveAnAxis : Axis
sometimesYouDoNotHaveAnAxis =
  SometimesYouDoNotHaveAnAxis


{-| When you want to make your own axis. This is where the fun starts! The
  `normalAxis` looks like this on the inside:

    normalAxis : Axis
    normalAxis =
      customAxis <| \summary ->
        { position = closestToZero
        , axisLine = Just (simpleLine summary)
        , ticks = List.map simpleTick (decentPositions summary |> remove 0)
        , labels = List.map simpleLabel (decentPositions summary |> remove 0)
        , whatever = []
        }

  But the special snowflake you are, you might want something different.
-}
customAxis : (AxisSummary -> AxisCustomizations) -> Axis
customAxis =
  Axis


{-| A super regular axis.
-}
normalAxis : Axis
normalAxis =
  customAxis <| \summary ->
    { position = closestToZero
    , axisLine = Just (simpleLine summary)
    , ticks = List.map simpleTick (decentPositions summary |> remove 0)
    , labels = List.map simpleLabel (decentPositions summary |> remove 0)
    , flipAnchor = False
    }


{-| An axis closest to zero, but doesn't look like much unless you use the `rangeFrameDot`.
-}
emptyAxis : Axis
emptyAxis =
  customAxis <| \summary ->
    { position = closestToZero
    , axisLine = Nothing
    , ticks = []
    , labels = []
    , flipAnchor = False
    }


{-| An axis which is placed at the minimum of your axis! Meaning if you use it as
  a vertical axis, then it will end up to the far left, and if you use it as
  a horizontal axis, then it will end up in the bottom.
-}
axisAtMin : Axis
axisAtMin =
  customAxis <| \summary ->
    { position = min
    , axisLine = Just (simpleLine summary)
    , ticks = List.map simpleTick (decentPositions summary)
    , labels = List.map simpleLabel (decentPositions summary)
    , flipAnchor = False
    }


{-| Like `axisAtMin`, but opposite.
-}
axisAtMax : Axis
axisAtMax =
  customAxis <| \summary ->
    { position = max
    , axisLine = Just (simpleLine summary)
    , ticks = List.map simpleTick (decentPositions summary)
    , labels = List.map simpleLabel (decentPositions summary)
    , flipAnchor = True
    }


{-| A nice grey line which goes from one side of you plot to the other.
-}
simpleLine : AxisSummary -> LineCustomizations
simpleLine summary =
  fullLine [ stroke darkGrey ] summary


{-| A simple but powerful tick.
-}
simpleTick : Float -> TickCustomizations
simpleTick position =
  { position = position
  , length = 5
  , attributes = [ stroke darkGrey ]
  }


{-| A simple label. You might want to try an make your own!
-}
simpleLabel : Float -> LabelCustomizations
simpleLabel position =
  { position = position
  , format = toString
  , view = viewLabel []
  }


{-| A line which goes from one end of the plot to the other.
-}
fullLine : List (Attribute Never) -> AxisSummary -> LineCustomizations
fullLine attributes summary =
  { attributes = attributes
  , start = summary.min
  , end = summary.max
  }


{-| -}
displace : Float -> Float -> Attribute msg
displace x y =
  transform <| "translate(" ++ toString x ++ ", " ++ toString y ++ ")"


-- VIEW SERIES


{-| A series is a list of data points possibly joined by some sort of
  interpolation. The example below renders an area, with the coordinates
  of the last argument given to `viewSeries`, where the coordinates are
  emphasized with a circle.

    view : Svg msg
    view =
      viewSeries
        [ area (List.map (\{ x, y } -> circle x y)) ]
        [ { x = 0, y = 1 }
        , { x = 2, y = 2 }
        , { x = 3, y = 3 }
        , { x = 4, y = 5 }
        , { x = 5, y = 8 }
        ]
-}
viewSeries : List (Series data msg) -> data -> Html msg
viewSeries =
  viewSeriesCustom defaultSeriesPlotCustomizations


{-| Plot your series with special needs!
-}
viewSeriesCustom : PlotCustomizations msg -> List (Series data msg) -> data -> Html msg
viewSeriesCustom customizations series data =
  let
    dataPoints =
      List.map (\{ toDataPoints } -> toDataPoints data) series

    allDataPoints =
      List.concat dataPoints

    addNiceReach summary =
      List.foldl addNiceReachForSeries summary series

    summary =
      toPlotSummary customizations addNiceReach allDataPoints

    viewHorizontalAxes =
      allDataPoints
        |> List.filterMap .xTick
        |> viewHorizontalAxis summary customizations.horizontalAxis []

    viewVerticalAxes =
      dataPoints
        |> List.map (List.filterMap .yTick)
        |> List.map2 (.axis >> viewVerticalAxis summary) series
        |> List.filterMap identity
        |> g [ class "elm-plot__vertical-axes" ]
        |> Just

    viewActualSeries =
      List.map2 (viewASeries customizations summary) series dataPoints
        |> g [ class "elm-plot__all-series" ]
        |> Just

    viewGlitter =
      allDataPoints
        |> List.concatMap (viewGlitterLines summary)
        |> g [ class "elm-plot__glitter" ]
        |> Svg.map never
        |> Just

    viewHint =
      case List.filterMap .viewHint allDataPoints of
        [] ->
          div [] []

        views ->
          Html.map never <| customizations.viewHintContainer summary views

    viewJunks =
      customizations.junk summary
        |> List.map (viewActualJunk summary)
        |> g [ class "elm-plot__junk" ]
        |> Just

    children =
      List.filterMap identity
        [ Just (defineClipPath customizations summary)
        , viewHorizontalGrid summary customizations.grid.horizontal
        , viewVerticalGrid summary customizations.grid.vertical
        , viewActualSeries
        , viewHorizontalAxes
        , viewVerticalAxes
        , viewGlitter
        , viewJunks
        ]
  in
    div
      (containerAttributes customizations summary)
      [ svg (innerAttributes customizations) children, viewHint ]


addNiceReachForSeries : Series data msg -> TempPlotSummary -> TempPlotSummary
addNiceReachForSeries series =
  case series.interpolation of
    None ->
      identity

    Linear fill _ ->
      addNiceReachForArea fill

    Monotone fill _ ->
      addNiceReachForArea fill


addNiceReachForArea : Maybe String -> TempPlotSummary -> TempPlotSummary
addNiceReachForArea area ({ y, x } as summary) =
  case area of
    Nothing ->
      summary

    Just _ ->
      { summary
      | x = x
      , y = { y | min = min y.min 0, max = y.max }
      }



-- VIEW BARS


{-| -}
viewBars : Bars data msg -> data -> Html msg
viewBars =
  viewBarsCustom defaultBarsPlotCustomizations


{-| Plot your bar series with special needs!
-}
viewBarsCustom : PlotCustomizations msg -> Bars data msg -> data -> Html msg
viewBarsCustom customizations bars data =
  let
    groups =
      bars.toGroups data

    toDataPoint index group { height } =
      { x = toFloat index + 1
      , y = height
      , xLine = group.verticalLine (toFloat index + 1)
      , yLine = Nothing
      }

    toDataPoints index group =
      List.map (toDataPoint index group) group.bars

    dataPoints =
      List.concat (List.indexedMap toDataPoints groups)

    summary =
      toPlotSummary customizations addNiceReachForBars dataPoints

    xLabels =
      List.indexedMap (\index group -> group.label (toFloat index + 1)) groups

    viewGlitter =
      dataPoints
        |> List.concatMap (viewGlitterLines summary)
        |> g [ class "elm-plot__glitter" ]
        |> Svg.map never
        |> Just

    hints =
      groups
      |> List.indexedMap (\index group -> group.viewHint (toFloat index + 1))
      |> List.filterMap identity

    viewHint =
      case hints of
        [] ->
          div [] []

        hints ->
          Html.map never <| customizations.viewHintContainer summary hints

    children =
      List.filterMap identity
        [ Just (defineClipPath customizations summary)
        , viewHorizontalGrid summary customizations.grid.horizontal
        , viewVerticalGrid summary customizations.grid.vertical
        , viewActualBars summary bars groups
        , viewHorizontalAxis summary customizations.horizontalAxis xLabels []
        , viewVerticalAxis summary bars.axis []
        , viewGlitter
        ]
  in
    div (containerAttributes customizations summary)
      [ svg (innerAttributes customizations) children, viewHint ]


addNiceReachForBars : TempPlotSummary -> TempPlotSummary
addNiceReachForBars ({ x, y } as summary) =
  { summary
  | x = { x | min = x.min - 0.5, max = x.max + 0.5 }
  , y = { y | min = min y.min 0, max = y.max }
  }


-- CLIP PATH


defineClipPath : PlotCustomizations msg -> PlotSummary -> Svg.Svg msg
defineClipPath customizations summary =
  Svg.defs []
    [ Svg.clipPath [ Attributes.id (toClipPathId customizations) ]
      [ Svg.rect
        [ Attributes.x (toString summary.x.marginLower)
        , Attributes.y (toString summary.y.marginLower)
        , Attributes.width (toString (length summary.x))
        , Attributes.height (toString (length summary.y))
        ]
        []
      ]
    ]


toClipPathId : PlotCustomizations msg -> String
toClipPathId { id } =
  "elm-plot__clip-path__" ++ id


containerAttributes : PlotCustomizations msg -> PlotSummary -> List (Attribute msg)
containerAttributes customizations summary =
  case customizations.onHover of
      Just toMsg ->
        [ Html.Events.on "mousemove" (handleHint summary toMsg)
        , Html.Events.onMouseLeave (toMsg Nothing)
        , Attributes.id customizations.id
        , Html.Attributes.style
          [ ( "position", "relative" )
          , ( "margin", "0 auto" )
          , ( "width", toString customizations.width ++ "px" )
          , ( "height", toString customizations.height ++ "px" )
          ]
        ]

      Nothing ->
        [ Attributes.id customizations.id
        , Html.Attributes.style
          [ ( "position", "relative" )
          , ( "margin", "0 auto" )
          , ( "width", toString customizations.width ++ "px" )
          , ( "height", toString customizations.height ++ "px" )
          ]
        ]


innerAttributes : PlotCustomizations msg -> List (Attribute msg)
innerAttributes customizations =
  customizations.attributes ++
    [ Attributes.width (toString customizations.width)
    , Attributes.height (toString customizations.height)
    ]


viewActualJunk : PlotSummary -> JunkCustomizations msg -> Svg msg
viewActualJunk summary { x, y, view } =
  g [ place summary { x = x, y = y } 0 0 ] [ view ]


-- HINT HANDLER


handleHint : PlotSummary -> (Maybe Point -> msg) -> Json.Decoder msg
handleHint summary toMsg =
    Json.map3
        (\x y r -> toMsg (unScalePoint summary x y r))
        (Json.field "clientX" Json.float)
        (Json.field "clientY" Json.float)
        (DOM.target plotPosition)


plotPosition : Json.Decoder DOM.Rectangle
plotPosition =
    Json.oneOf
        [ DOM.boundingClientRect
        , Json.lazy (\_ -> DOM.parentElement plotPosition)
        ]


unScalePoint : PlotSummary -> Float -> Float -> DOM.Rectangle -> Maybe Point
unScalePoint summary mouseX mouseY { left, top } =
    Just
      { x = toNearestX summary <| unScaleValue summary.x (mouseX - left)
      , y = clamp summary.y.min summary.y.max <| unScaleValue summary.y (summary.y.length - mouseY - top)
      }


toNearestX : PlotSummary -> Float -> Float
toNearestX summary exactX =
  let
    default =
      Maybe.withDefault 0 (List.head summary.x.all)

    updateIfCloser closest x =
      if diff x exactX > diff closest exactX then
        closest
      else
        x
  in
    List.foldl updateIfCloser default summary.x.all


diff : Float -> Float -> Float
diff a b =
  abs (a - b)




-- INSIDE


type alias TempPlotSummary =
  { x : { min : Float, max : Float, all : List Float }
  , y : { min : Float, max : Float, all : List Float }
  }


defaultPlotSummary : TempPlotSummary
defaultPlotSummary =
  { x = { min = 0.0, max = 1.0, all = [] }
  , y = { min = 0.0, max = 1.0, all = [] }
  }


toPlotSummary : PlotCustomizations msg -> (TempPlotSummary -> TempPlotSummary) ->  List { a | x : Float, y : Float } -> PlotSummary
toPlotSummary customizations toNiceReach points =
  let
    foldAxis summary v =
      { min = min summary.min v
      , max = max summary.max v
      , all = v :: summary.all
      }

    foldPlot { x, y } result =
      case result of
        Nothing ->
          Just
            { x = { min = x, max = x, all = [ x ] }
            , y = { min = y, max = y, all = [ y ] }
            }

        Just summary ->
          Just
            { x = foldAxis summary.x x
            , y = foldAxis summary.y y
            }

    plotSummary =
      points
        |> List.foldl foldPlot Nothing
        |> Maybe.withDefault defaultPlotSummary
        |> toNiceReach
  in
    { x =
      { min = customizations.toRangeLowest (plotSummary.x.min)
      , max = customizations.toRangeHighest (plotSummary.x.max)
      , dataMin = plotSummary.x.min
      , dataMax = plotSummary.x.max
      , length = toFloat customizations.width
      , marginLower = toFloat customizations.margin.left
      , marginUpper = toFloat customizations.margin.right
      , all = List.sort plotSummary.x.all
      }
    , y =
      { min = customizations.toDomainLowest (plotSummary.y.min)
      , max = customizations.toDomainHighest (plotSummary.y.max)
      , dataMin = plotSummary.y.min
      , dataMax = plotSummary.y.max
      , length = toFloat customizations.height
      , marginLower = toFloat customizations.margin.bottom
      , marginUpper = toFloat customizations.margin.top
      , all = plotSummary.y.all
      }
    }



-- VIEW HORIZONTAL GRID


viewVerticalGrid : PlotSummary -> Grid -> Maybe (Svg msg)
viewVerticalGrid summary grid =
  case grid of
    Grid toCustomizations ->
      Just (Svg.map never (viewActualVerticalGrid summary (toCustomizations summary.x)))

    YeahGridsAreTotallyLame ->
      Nothing


viewActualVerticalGrid : PlotSummary -> List GridLineCustomizations -> Svg Never
viewActualVerticalGrid summary gridLines =
  let
    viewGridLine { attributes, position } =
      draw attributes (linear summary [ { x = position, y = summary.y.min }, { x = position, y = summary.y.max } ])
  in
    g [ class "elm-plot__horizontal-grid" ] (List.map viewGridLine gridLines)



-- VIEW VERTICAL GRID


viewHorizontalGrid : PlotSummary -> Grid -> Maybe (Svg msg)
viewHorizontalGrid summary grid =
  case grid of
    Grid toCustomizations ->
      Just (Svg.map never (viewActualHorizontalGrid summary (toCustomizations summary.y)))

    YeahGridsAreTotallyLame ->
      Nothing


viewActualHorizontalGrid : PlotSummary -> List GridLineCustomizations -> Svg Never
viewActualHorizontalGrid summary gridLines =
  let
    viewGridLine { attributes, position } =
      draw attributes (linear summary [ { x = summary.x.min, y = position }, { x = summary.x.max, y = position } ])
  in
    g [ class "elm-plot__vertical-grid" ] (List.map viewGridLine gridLines)



-- SERIES VIEWS


viewASeries : PlotCustomizations msg -> PlotSummary -> Series data msg -> List (DataPoint msg) -> Svg msg
viewASeries customizations plotSummary { axis, interpolation } dataPoints =
  g [ class "elm-plot__series" ]
    [ Svg.map never (viewPath customizations plotSummary interpolation dataPoints)
    , viewDataPoints plotSummary dataPoints
    ]


viewPath : PlotCustomizations msg -> PlotSummary -> Interpolation -> List (DataPoint msg) -> Svg Never
viewPath customizations plotSummary interpolation dataPoints =
  case interpolation of
    None ->
      path [] []

    Linear fill attributes ->
      viewInterpolation customizations plotSummary linear linearArea fill attributes dataPoints

    Monotone fill attributes ->
      viewInterpolation customizations plotSummary monotoneX monotoneXArea fill attributes dataPoints


viewInterpolation :
  PlotCustomizations msg
  -> PlotSummary
  -> (PlotSummary -> List Point -> List Command)
  -> (PlotSummary -> List Point -> List Command)
  -> Maybe String
  -> List (Attribute Never)
  -> List (DataPoint msg)
  -> Svg Never
viewInterpolation customizations summary toLine toArea area attributes dataPoints =
  case area of
    Nothing ->
      draw
        (fill transparent
        :: stroke pinkStroke
        :: class "elm-plot__series__interpolation"
        :: clipPath ("url(#" ++ toClipPathId customizations ++ ")")
        :: attributes)
        (toLine summary (points dataPoints))

    Just color ->
      draw
        (fill color
        :: fill pinkFill
        :: stroke pinkStroke
        :: class "elm-plot__series__interpolation"
        :: clipPath ("url(#" ++ toClipPathId customizations ++ ")")
        :: attributes)
        (toArea summary (points dataPoints))



-- DOT VIEWS


viewDataPoints : PlotSummary -> List (DataPoint msg) -> Svg msg
viewDataPoints plotSummary dataPoints =
  dataPoints
    |> List.map (viewDataPoint plotSummary)
    |> List.filterMap identity
    |> g [ class "elm-plot__series__points" ]


viewDataPoint : PlotSummary -> DataPoint msg -> Maybe (Svg msg)
viewDataPoint plotSummary { x, y, view } =
  case view of
    Nothing ->
      Nothing

    Just svgView ->
      Just <| g [ place plotSummary { x = x, y = y } 0 0 ] [ svgView ]



{-| Pass radius and color to make a circle!
-}
viewCircle : Float -> String -> Svg msg
viewCircle radius color =
  Svg.circle
    [ r (toString radius)
    , stroke "transparent"
    , fill color
    ]
    []


{-| Pass width and color to make a square!
-}
viewSquare : Float -> String -> Svg msg
viewSquare width color =
  rect
    [ Attributes.width (toString width)
    , Attributes.height (toString width)
    , Attributes.x (toString (-width / 2))
    , Attributes.y (toString (-width / 2))
    , stroke "transparent"
    , fill color
    ]
    []


{-| Pass width, height and color to make a diamond and impress with your
  classy plot!
-}
viewDiamond : Float -> Float -> String -> Svg msg
viewDiamond width height color =
  rect
    [ Attributes.width (toString width)
    , Attributes.height (toString height)
    , Attributes.transform "rotate(45)"
    , Attributes.x (toString (-width / 2))
    , Attributes.y (toString (-height / 2))
    , stroke "transparent"
    , fill color
    ]
    []


{-| Pass a color to make a triangle! Great for academic looking plots.
-}
viewTriangle : String -> Svg msg
viewTriangle color =
  polygon
    [ Attributes.points "0,-5 5,5 -5,5"
    , Attributes.transform "translate(0, -2.5)"
    , fill color
    ]
    []



-- VIEW BARS


viewActualBars : PlotSummary -> Bars data msg -> List BarGroup -> Maybe (Svg msg)
viewActualBars summary { styles, maxWidth } groups =
    let
        barsPerGroup =
            toFloat (List.length styles)

        defaultWidth =
            1 / barsPerGroup

        width =
          case maxWidth of
            Percentage perc ->
              defaultWidth * (toFloat perc) / 100

            Fixed max ->
              if defaultWidth > unScaleValue summary.x max then
                unScaleValue summary.x max
              else
                defaultWidth

        offset x i =
          x + width * (toFloat i - barsPerGroup / 2)

        viewLabel label =
          g [ Attributes.transform ("translate(" ++ toString (scaleValue summary.x (width / 2)) ++ ", -5)")
            , Attributes.style "text-anchor: middle;"
            ]
            [ label ]

        viewBar x attributes (i, { height, label }) =
          g [ place summary { x = offset x i, y = max (closestToZero summary.y.min summary.y.max) height } 0 0 ]
            [ Svg.map never (Maybe.map viewLabel label |> Maybe.withDefault (text ""))
            , rect (attributes ++
              [ Attributes.width (toString (scaleValue summary.x width))
              , Attributes.height (toString (scaleValue summary.y (abs height)))
              ])
              []
            ]

        indexedHeights group =
          List.indexedMap (,) group.bars

        viewGroup index group =
          g [ class "elm-plot__bars__group" ]
            (List.map2 (viewBar (toFloat (index + 1))) styles (indexedHeights group))
    in
        Just <| g [ class "elm-plot__bars" ] (List.indexedMap viewGroup groups)



-- VIEW HORIZONTAL AXIS


viewHorizontalAxis : PlotSummary -> Axis -> List LabelCustomizations -> List TickCustomizations -> Maybe (Svg msg)
viewHorizontalAxis summary axis moreLabels moreTicks =
  case axis of
    Axis toCustomizations ->
      Just (Svg.map never (viewActualHorizontalAxis summary (toCustomizations summary.x) moreLabels moreTicks))

    SometimesYouDoNotHaveAnAxis ->
      Nothing


viewActualHorizontalAxis : PlotSummary -> AxisCustomizations -> List LabelCustomizations -> List TickCustomizations -> Svg Never
viewActualHorizontalAxis summary { position, axisLine, ticks, labels, flipAnchor } glitterLabels glitterTicks =
    let
      at x =
        { x = x, y = position summary.y.min summary.y.max }

      lengthOfTick length =
        if flipAnchor then -length else length

      positionOfLabel =
        if flipAnchor then -10 else 20

      viewTickLine { attributes, length, position } =
        g [ place summary (at position) 0 0 ] [ viewTickInner attributes 0 (lengthOfTick length) ]

      viewLabel { format, position, view } =
        g [ place summary (at position) 0 positionOfLabel, style "text-anchor: middle;" ]
          [ view (format position) ]
    in
      g [ class "elm-plot__horizontal-axis" ]
        [ viewAxisLine summary at axisLine
        , g [ class "elm-plot__ticks" ] (List.map viewTickLine (ticks ++ glitterTicks))
        , g [ class "elm-plot__labels" ] (List.map viewLabel (labels ++ glitterLabels))
        ]



-- VIEW VERTICAL AXIS


viewVerticalAxis : PlotSummary -> Axis -> List TickCustomizations -> Maybe (Svg msg)
viewVerticalAxis summary axis moreTicks =
  case axis of
    Axis toCustomizations ->
      Just (Svg.map never (viewActualVerticalAxis summary (toCustomizations summary.y) moreTicks))

    SometimesYouDoNotHaveAnAxis ->
      Nothing


viewActualVerticalAxis : PlotSummary -> AxisCustomizations -> List TickCustomizations -> Svg Never
viewActualVerticalAxis summary { position, axisLine, ticks, labels, flipAnchor } glitterTicks =
    let
      at y =
        { x = position summary.x.min summary.x.max, y = y }

      lengthOfTick length =
        if flipAnchor then length else -length

      positionOfLabel =
        if flipAnchor then 10 else -10

      anchorOfLabel =
        if flipAnchor then "text-anchor: start;" else "text-anchor: end;"

      viewTickLine { attributes, length, position } =
        g [ place summary (at position) 0 0 ]
          [ viewTickInner attributes (lengthOfTick length) 0 ]

      viewLabel { format, position, view } =
        g [ place summary (at position) positionOfLabel 5, style anchorOfLabel ]
          [ view (format position) ]
    in
      g [ class "elm-plot__vertical-axis" ]
        [ viewAxisLine summary at axisLine
        , g [ class "elm-plot__ticks" ] (List.map viewTickLine (ticks ++ glitterTicks))
        , g [ class "elm-plot__labels" ] (List.map viewLabel labels)
        ]



-- AXIS HELP


viewAxisLine : PlotSummary -> (Float -> Point) -> Maybe LineCustomizations -> Svg Never
viewAxisLine summary at axisLine =
  case axisLine of
    Just { attributes, start, end } ->
      draw attributes (linear summary [ at start, at end ])

    Nothing ->
      text ""


viewTickInner : List (Attribute msg) -> Float -> Float -> Svg msg
viewTickInner attributes width height =
  Svg.line (x2 (toString width) :: y2 (toString height) :: attributes) []


{-| -}
viewLabel : List (Svg.Attribute msg) -> String -> Svg msg
viewLabel attributes string =
  text_ attributes [ tspan [] [ text string ] ]



-- VIEW GLITTER


viewGlitterLines :
  PlotSummary ->
  { a
  | xLine : Maybe (AxisSummary -> LineCustomizations)
  , yLine : Maybe (AxisSummary -> LineCustomizations)
  , x : Float
  , y : Float
  }
  -> List (Svg Never)
viewGlitterLines summary { xLine, yLine, x, y } =
  [ viewAxisLine summary (\y -> { x = x, y = y }) (Maybe.map (\toLine -> toLine summary.y) xLine)
  , viewAxisLine summary (\x -> { x = x, y = y }) (Maybe.map (\toLine -> toLine summary.x) yLine)
  ]



-- TICK HELP


{-| For decently spaces positions. Useful in tick/label and grid configurations.
-}
decentPositions : AxisSummary -> List Float
decentPositions summary =
  if summary.length > 600 then
    interval 0 (niceInterval summary.min summary.max 10) summary
  else
    interval 0 (niceInterval summary.min summary.max 5) summary


{-| For ticks with a particular interval. The first value passed if the offset,
  and the second value is actual interval. The offset in useful when you want
   two sets of ticks with different views. For example if you want a long ticks
   at every 2 * x and a small ticks at every 2 * x + 1.
-}
interval : Float -> Float -> AxisSummary -> List Float
interval offset delta { min, max } =
  let
    range = abs (min - max)
    value = firstValue delta min + offset
    indexes = List.range 0 <| count delta min range value
  in
    List.map (tickPosition delta value) indexes


{-| If you regret a particular position. Typically used for removing the label
  at the origin. Use like this:

    normalAxis : Axis
    normalAxis =
      axis <| \summary ->
        { position = ClosestToZero
        , axisLine = Just (simpleLine summary)
        , ticks = List.map simpleTick (decentPositions summary |> remove 0)
        , labels = List.map simpleLabel (decentPositions summary |> remove 0)
        , whatever = []
        }

  See how in the normal axis we make a bunch of ticks, but then remove then one we don't
  want. You can do the same!
-}
remove : Float -> List Float -> List Float
remove banned values =
  List.filter (\v -> v /= banned) values


tickPosition : Float -> Float -> Int -> Float
tickPosition delta firstValue index =
  firstValue
    + (toFloat index)
    * delta
    |> Round.round (deltaPrecision delta)
    |> String.toFloat
    |> Result.withDefault 0


deltaPrecision : Float -> Int
deltaPrecision delta =
  delta
    |> toString
    |> Regex.find (Regex.AtMost 1) (Regex.regex "\\.[0-9]*")
    |> List.map .match
    |> List.head
    |> Maybe.withDefault ""
    |> String.length
    |> (-) 1
    |> min 0
    |> abs


firstValue : Float -> Float -> Float
firstValue delta lowest =
  ceilToNearest delta lowest


ceilToNearest : Float -> Float -> Float
ceilToNearest precision value =
  toFloat (ceiling (value / precision)) * precision


count : Float -> Float -> Float -> Float -> Int
count delta lowest range firstValue =
  floor ((range - (abs lowest - abs firstValue)) / delta)


niceInterval : Float -> Float -> Int -> Float
niceInterval min max total =
  let
    range = abs (max - min)
    -- calculate an initial guess at step size
    delta0 = range / (toFloat total)
    -- get the magnitude of the step size
    mag = floor (logBase 10 delta0)
    magPow = toFloat (10 ^ mag)
    -- calculate most significant digit of the new step size
    magMsd = round (delta0 / magPow)
    -- promote the MSD to either 1, 2, or 5
    magMsdFinal =
      if magMsd > 5 then 10
      else if magMsd > 2 then 5
      else if magMsd > 1 then 1
      else magMsd
  in
    toFloat magMsdFinal * magPow



-- DRAW HELP


points : List (DataPoint msg) -> List Point
points =
  List.map point


point : DataPoint msg -> Point
point { x, y } =
  Point x y
