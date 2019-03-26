port module Main exposing (..)

import Browser
import Html exposing (text, div, button,h2)
import Html.Events exposing (onClick)
import Html.Attributes exposing (id,style)
import Bootstrap.CDN as CDN

import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar      -- [2-1] Navbar(1)
import Bootstrap.Grid as Grid          -- [2-2] Grid(1)
import Bootstrap.Grid.Col as Col       -- [2-2] Grid(2)
import Bootstrap.Card as Card          -- [2-3] Card(1)
import Bootstrap.Card.Block as Block   -- [2-3] Card(2)
import Bootstrap.Button as Button
import Bootstrap.ListGroup as Listgroup

import List.Extra exposing (find)

type alias Member = {name : String, place : String, order : Float}

port updateBackend : Member -> Cmd msg

port updateMember : (Member -> msg) -> Sub msg
port feedMembers : (List Member -> msg) -> Sub msg

main = Browser.document {init = init, update = update, view = view, subscriptions = subscriptions}

type alias Model = {members : List Member, places : List Place, showModal : Modal.Visibility, currentName : String, 
    thisRoom : String, pageTitle : String}

-- subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [updateMember Receive, feedMembers FeedMembers]


type alias Flags = {members : List Member, places : List Place}
init : Flags -> (Model, Cmd msg)
init {members, places} = ({members = members, places = places, showModal = Modal.hidden, currentName = "",
    thisRoom = "", pageTitle = "場所の更新"}, Cmd.none)

type Msg = Change String String | ChangeAndClose Member String | AnimateModal Modal.Visibility | CloseModal
    | DialogFor String
    | Receive Member
    | FeedMembers (List Member)
    | NoOp

type alias Place = {name : String, color : String}

getMember : String -> Model -> Maybe Member
getMember name model =
    find (\m -> m.name == name) model.members

mkEnterBtn model place = 
    button [
        style "background" place.color,
        style "margin" "5px",
        style "border-radius" "4px",
        style "font-size" "14px",
        style "height" "50px",
        style "color" "#fff",
        style "white-space" "nowrap", 
        style "width" (if place.name == "帰宅" || place.name == model.thisRoom then "212px" else "100px"),
        onClick (
            case getMember model.currentName model of
                Nothing -> NoOp
                Just m -> ChangeAndClose m place.name
            )
        ] [text place.name]



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
                ]
            ]
        |> Modal.view model.showModal


updatePlace n p model =
    let f e =
            if n == e.name then {e | place = p} else e
    in
        {model | members = List.map f model.members}

updateMemberData : List Member -> Member -> List Member
updateMemberData members new_data =
    case find (\m -> m.name == new_data.name) members of
        Just mm -> List.map (\m -> if m.name == new_data.name then new_data else m) members
        Nothing -> List.append members [new_data]

update msg model =
    case msg of
        NoOp -> (model, Cmd.none)
        ChangeAndClose member p ->
            let m = updatePlace member.name p model
            in ({m | showModal = Modal.hidden}, updateBackend {member | place = p})
        Change n p ->
            (updatePlace n p model, Cmd.none)
        AnimateModal v -> ({model | showModal = v},Cmd.none)
        CloseModal -> ({model | showModal = Modal.hidden},Cmd.none)
        DialogFor n -> ({model | showModal = Modal.shown, currentName = n},Cmd.none)
        Receive m -> ({model | members = updateMemberData model.members m},Cmd.none)
        FeedMembers ms -> ({model | members = List.map (\m -> {name = m.name, place = m.place, order = m.order}) ms}, Cmd.none)


getColor : Model -> String -> String
getColor {places} place_name =
    case find (\p -> p.name == place_name) places of
        Just p -> p.color
        Nothing -> "#bababa"

view model = 
    {title = "在席表",
    body = [Grid.container []
        [Grid.row []
            [ Grid.col []
                [
                    h2 [] [text model.pageTitle],
                    div [] [div [id "buttons"]
                        <| List.map (\e -> button [
                            style "width" "23%", style "margin" "5px"
                            , style "border-radius" "6px"
                            , style "border" "1px solid #666"
                            , style "background" (getColor model e.place)
                            -- onClick (Change e.name (if e.place == "居室" then "帰宅" else "居室"))
                            , onClick (DialogFor e.name)
                            ] [
                            div [style "font-size" "32px", style "color" "#fff"                            , style "white-space" "nowrap"] [text e.name],
                            div [style "font-size" "14px", style "color" "#fff"
                                , style "white-space" "nowrap"] [text e.place]]
                            ) model.members
                                ]
                ]
            ]
        , modal model
        ]]}

