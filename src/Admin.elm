port module Admin exposing (Member, Model, Msg(..), Place, feedMembers, init, main, subscriptions, update, sendChange, updateMember, updateMemberData, updatePlace, view)

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Browser
import Html exposing (button, div, h2, h3, h4, h5, input, li, span, text, ul)
import Html.Attributes exposing (id, property, style, value, type_, name, cols, rows)
import Html.Events exposing (onClick)
import Json.Encode
import List.Extra exposing (find)


type alias Member =
    { name : String, place : String, order : Float }


port sendChange : String -> Cmd msg


port updateMember : (Member -> msg) -> Sub msg


port feedMembers : (List Member -> msg) -> Sub msg


main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


type alias Model =
    {
        initialData : {members: String, places : List {name : String, color : String}}
        , data : {members: String, places : List {name : String, color : String}}
    }



-- subscriptions : Model -> Sub Msg


subscriptions model = Sub.none

type alias Flags = List Member

init : Flags -> (Model,Cmd msg)
init members =
    ( { initialData = {members = (String.concat <| List.map (\m -> m.name ++ "\n") members), places = []}
      , data = {members = (String.concat <| List.map (\m -> m.name ++ "\n") members), places = []}
      }
    , Cmd.none
    )


type Msg
    = NoOp | SaveChange | CancelChange | UpdateMembers String


type alias Place =
    String


updatePlace n p model =
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


update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        SaveChange -> (model, sendChange model.data.members)
        CancelChange -> ({model | data = model.initialData}, Cmd.none)
        UpdateMembers newContent ->
            let md = model.data in ({model | data = {md | members = newContent}}, Cmd.none)
            

view model =
    { title = "管理画面"
    , body =
        [ Grid.container []
            [ Grid.row [] [
                Grid.col [Col.md6] [h2 [] [ text "管理画面" ]]
            ],
            
              Grid.row []
                [ Grid.col [Col.md3, Col.xs12]
                    [div [ style "font-size" "20px" ]
                        [ h3 [] [ text "メンバー" ]
                        , Textarea.textarea
                            [ Textarea.id "myarea"
                            , Textarea.rows 15
                            , Textarea.attrs [cols 6]
                            , Textarea.value model.data.members
                            , Textarea.onInput UpdateMembers
                            ]
                        , div [ style "clear" "both" ] []
                        , div [style "float" "right", style "margin-top" "10px"] [
                           Button.button [ Button.primary, Button.attrs [onClick SaveChange] ] [ text "保存" ],
                           Button.button [ Button.secondary, Button.onClick CancelChange ] [ text "元に戻す" ]
                        ]],
                        div [ style "clear" "both" ] []
                    ]
                ]
            ]
        ]
    }
