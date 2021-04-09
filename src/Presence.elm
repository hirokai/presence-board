port module Presence exposing (..)

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Browser
import Html exposing (Html, button, div, h2, text)
import Html.Attributes exposing (id, style)
import Html.Events exposing (onClick)
import List.Extra exposing (find)


type alias Member =
    { name : String, place : String, order : Float, last_updated : Int }


type alias Place =
    { name : String, color : String, order : Int, span : Int }


port updateBackend : { member : Member, noLog : Bool } -> Cmd msg


port updateMember : (Member -> msg) -> Sub msg


port updatePlace : (Place -> msg) -> Sub msg


port feedMembers : (List Member -> msg) -> Sub msg


main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


type alias Model =
    { members : List Member
    , places : List Place
    , showModal : Modal.Visibility
    , currentName : String
    , thisRoom : String
    , pageTitle : String
    , checkNoLog : Bool
    }



-- subscriptions : Model -> Sub Msg


subscriptions model =
    Sub.batch [ updateMember Receive, updatePlace ReceivePlace, feedMembers FeedMembers ]


type alias Flags =
    { members : List Member, places : List Place }


init : Flags -> ( Model, Cmd msg )
init { members, places } =
    ( { members = members
      , places = places
      , showModal = Modal.hidden
      , currentName = ""
      , thisRoom = ""
      , pageTitle = "場所の更新"
      , checkNoLog = False
      }
    , Cmd.none
    )


type Msg
    = Change String String
    | ChangeAndClose Member String
    | AnimateModal Modal.Visibility
    | CloseModal
    | DialogFor String
    | Receive Member
    | ReceivePlace Place
    | FeedMembers (List Member)
    | CheckNoLog Bool
    | NoOp

getMember : String -> Model -> Maybe Member
getMember name model =
    find (\m -> m.name == name) model.members


mkEnterBtn : Model -> Place -> Html Msg
mkEnterBtn model place =
    button
        [ style "background" place.color
        , style "margin" "5px"
        , style "border-radius" "4px"
        , style "font-size" "14px"
        , style "height" "50px"
        , style "color" "#fff"
        , style "white-space" "nowrap"
        , style "width"
            (if place.span == 2 then
                "210px"

             else if place.span == 3 then
                "320px"

             else if place.span == 4 then
                "430px"

             else
                "100px"
            )
        , onClick
            (case getMember model.currentName model of
                Nothing ->
                    NoOp

                Just m ->
                    ChangeAndClose m place.name
            )
        ]
        [ text place.name ]


modal model =
    Modal.config CloseModal
        |> Modal.withAnimation AnimateModal
        -- |> Modal.hideOnBackdropClick True
        |> Modal.h4 [] [ text <| model.currentName ++ "さん" ]
        |> Modal.body []
            [ Grid.containerFluid []
                [ Grid.row []
                    [ Grid.col
                        [ Col.xs12 ]
                        (List.map (mkEnterBtn model) model.places)
                    ]
                , Grid.row []
                    [ Grid.col [ Col.xs12 ]
                        [ div []
                            [ Checkbox.checkbox [ Checkbox.id "cb-no-log", Checkbox.onCheck CheckNoLog, Checkbox.checked model.checkNoLog ]
                                "ログを残さない"
                            ]
                        ]
                    ]
                ]
            ]
        |> Modal.view model.showModal


updatePersonPlaceData n p model =
    let
        f e =
            if n == e.name then
                { e | place = p }

            else
                e
    in
    { model | members = List.map f model.members }


updateMemberData : List Member -> Member -> List Member
updateMemberData members new_data =
    case find (\m -> m.name == new_data.name) members of
        Just mm ->
            List.map
                (\m ->
                    if m.name == new_data.name then
                        new_data

                    else
                        m
                )
                members

        Nothing ->
            List.append members [ new_data ]


updatePlaceData : List Place -> Place -> List Place
updatePlaceData vs new_data =
    case find (\m -> m.name == new_data.name) vs of
        Just mm ->
            List.map
                (\m ->
                    if m.name == new_data.name then
                        new_data

                    else
                        m
                )
                vs

        Nothing ->
            List.append vs [ new_data ]


update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChangeAndClose member p ->
            let
                m =
                    updatePersonPlaceData member.name p model
            in
            ( { m | showModal = Modal.hidden }, updateBackend { member = { member | place = p }, noLog = model.checkNoLog } )

        Change n p ->
            ( updatePersonPlaceData n p model, Cmd.none )

        AnimateModal v ->
            ( { model | showModal = v }, Cmd.none )

        CloseModal ->
            ( { model | showModal = Modal.hidden }, Cmd.none )

        DialogFor n ->
            ( { model | showModal = Modal.shown, currentName = n, checkNoLog = False }, Cmd.none )

        Receive m ->
            ( { model | members = updateMemberData model.members m }, Cmd.none )

        ReceivePlace p ->
            ( { model | places = updatePlaceData model.places p }, Cmd.none )

        FeedMembers ms ->
            ( { model | members = List.map (\m -> { name = m.name, place = m.place, order = m.order, last_updated = m.last_updated }) ms }, Cmd.none )

        CheckNoLog b ->
            ( { model | checkNoLog = b }, Cmd.none )


getColor : Model -> String -> String
getColor { places } place_name =
    case find (\p -> p.name == place_name) places of
        Just p ->
            p.color

        Nothing ->
            "#bababa"


view model =
    { title = "在席表"
    , body =
        [ Grid.container []
            [ Grid.row []
                [ Grid.col []
                    [ h2 [] [ text model.pageTitle ]
                    , div []
                        [ div [ id "buttons" ] <|
                            List.map
                                (\e ->
                                    button
                                        [ style "width" "23%"
                                        , style "margin" "5px"
                                        , style "border-radius" "6px"
                                        , style "border" "1px solid #666"
                                        , style "background" (getColor model e.place)

                                        -- onClick (Change e.name (if e.place == "居室" then "帰宅" else "居室"))
                                        , onClick (DialogFor e.name)
                                        ]
                                        [ div [ style "font-size" "32px", style "color" "#fff", style "white-space" "nowrap" ] [ text e.name ]
                                        , div
                                            [ style "font-size" "14px"
                                            , style "color" "#fff"
                                            , style "white-space" "nowrap"
                                            ]
                                            [ text e.place ]
                                        ]
                                )
                                model.members
                        ]
                    ]
                ]
            , modal model
            ]
        ]
    }
