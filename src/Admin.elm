port module Admin exposing (Member, Model, Msg(..), Place, feedMembers, init, main, sendChangeMembers, sendChangePlaces, subscriptions, update, updateMember, updateMemberData, updatePlace, view)

import Bootstrap.Button as Button
import Bootstrap.CDN as CDN
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.ListGroup as Listgroup
import Bootstrap.Modal as Modal
import Bootstrap.Navbar as Navbar
import Browser
import Html exposing (a, button, div, h2, h3, h4, h5, input, li, span, text, ul)
import Html.Attributes exposing (cols, id, name, property, rows, style, type_, value)
import Html.Events exposing (onClick)
import Json.Encode
import List.Extra exposing (find)



type alias Member =
    { name : String, place : String, order : Float, last_updated : Int }


type alias Place =
    { name : String, color : String, order : Int, span : Int }



port sendChangeMembers : String -> Cmd msg


port sendChangePlaces : String -> Cmd msg


port downloadLogs : () -> Cmd msg


port clearLogs : () -> Cmd msg


port updateMember : (Member -> msg) -> Sub msg


port feedMembers : (List Member -> msg) -> Sub msg


port addLog : (LogEntry -> msg) -> Sub msg


main =
    Browser.document { init = init, update = update, view = view, subscriptions = subscriptions }


type alias Model =
    { initialData : { members : String, places : List Place, placesString : String }
    , data : { members : String, places : List Place, placesString : String, logs : List LogEntry }
    }


type alias LogEntry =
    { name : String, place : String, time : String, timestamp : Int }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ addLog ReceiveLog ]


type alias Flags =
    { members : List Member, places : List Place, logs : List LogEntry }


init : Flags -> ( Model, Cmd msg )
init { members, places, logs } =
    let
        m_str =
            String.concat <| List.map (\m -> m.name ++ "\n") members

        p_str =
            String.concat <| List.map (\p -> p.name ++ "," ++ p.color ++ "," ++ String.fromInt p.span ++ "\n") places
    in
    ( { initialData = { members = m_str, places = places, placesString = p_str }
      , data = { members = m_str, places = places, placesString = p_str, logs = logs }
      }
    , Cmd.none
    )


type Msg
    = NoOp
    | SaveChangeMembers
    | SaveChangePlaces
    | CancelChangeMembers
    | CancelChangePlaces
    | UpdateMembers String
    | UpdatePlaces String
    | DownloadLogs
    | ClearLogs
    | ReceiveLog LogEntry


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


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        SaveChangeMembers ->
            ( model, sendChangeMembers model.data.members )

        CancelChangeMembers ->
            let
                md0 =
                    model.initialData

                md =
                    model.data
            in
            ( { model | data = { md | members = md0.members } }, Cmd.none )

        SaveChangePlaces ->
            ( model, sendChangePlaces model.data.placesString )

        CancelChangePlaces ->
            let
                md0 =
                    model.initialData

                md =
                    model.data
            in
            ( { model | data = { md | places = md0.places, placesString = md0.placesString } }, Cmd.none )

        UpdateMembers newContent ->
            let
                md =
                    model.data
            in
            ( { model | data = { md | members = newContent } }, Cmd.none )

        UpdatePlaces newContent ->
            let
                md =
                    model.data
            in
            ( { model | data = { md | placesString = newContent } }, Cmd.none )

        ClearLogs ->
            let
                md =
                    model.data
            in
            ( { model | data = { md | logs = [] } }, clearLogs () )

        DownloadLogs ->
            ( model, downloadLogs () )

        ReceiveLog l ->
            let
                new_logs =
                    l :: model.data.logs

                data =
                    model.data
            in
            ( { model | data = { data | logs = new_logs } }, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "管理画面"
    , body =
        [ Grid.container []
            [ Grid.row []
                [ Grid.col [ Col.md6 ] [ h2 [] [ text "管理画面" ] ]
                ]
            , Grid.row []
                [ Grid.col [ Col.md6, Col.xs12 ]
                    [ div [ style "font-size" "20px" ]
                        [ h3 [] [ text "メンバー" ]
                        , div [ style "font-size" "16px" ] [ text "名前（一行ずつ）" ]
                        , Textarea.textarea
                            [ Textarea.id "myarea"
                            , Textarea.rows 25
                            , Textarea.attrs [ cols 6 ]
                            , Textarea.value model.data.members
                            , Textarea.onInput UpdateMembers
                            ]
                        , div [ style "clear" "both" ] []
                        , div [ style "float" "right", style "margin-top" "10px" ]
                            [ Button.button [ Button.primary, Button.attrs [ onClick SaveChangeMembers ] ] [ text "保存" ]
                            , Button.button [ Button.secondary, Button.onClick CancelChangeMembers ] [ text "元に戻す" ]
                            ]
                        ]
                    , div [ style "clear" "both" ] []
                    ]
                , Grid.col [ Col.md6, Col.xs12 ]
                    [ div [ style "font-size" "20px" ]
                        [ h3 [] [ text "場所" ]
                        , div [ style "font-size" "16px" ] [ text "名前，色，幅（1-4)" ]
                        , Textarea.textarea
                            [ Textarea.id "myarea"
                            , Textarea.rows 25
                            , Textarea.attrs [ cols 6 ]
                            , Textarea.value model.data.placesString
                            , Textarea.onInput UpdatePlaces
                            ]
                        , div [ style "clear" "both" ] []
                        , div [ style "float" "right", style "margin-top" "10px" ]
                            [ Button.button [ Button.primary, Button.attrs [ onClick SaveChangePlaces ] ] [ text "保存" ]
                            , Button.button [ Button.secondary, Button.onClick CancelChangePlaces ] [ text "元に戻す" ]
                            ]
                        ]
                    , div [ style "clear" "both" ] []
                    ]
                ]
            , Grid.row []
                [ Grid.col [ Col.md12, Col.xs12 ]
                    [ div [ style "font-size" "20px" ]
                        [ h3 [] [ text "ログ" ]
                        , div [ style "font-size" "16px" ] [ text "タイムスタンプ（Unix time），タイムスタンプ（文字列表示），名前，場所" ]
                        , Textarea.textarea
                            [ Textarea.id "myarea"
                            , Textarea.rows 15
                            , Textarea.attrs [ cols 6 ]
                            , Textarea.value (String.concat <| List.map (\l -> String.concat [ String.fromInt l.timestamp, ",", l.time, ",", l.name, ",", l.place, "\n" ]) model.data.logs)
                            , Textarea.onInput UpdateMembers
                            ]
                        , div [ style "clear" "both" ] []
                        ]
                    , div [ style "float" "right", style "margin-top" "10px" ]
                        [ Button.button [ Button.primary, Button.attrs [ onClick DownloadLogs ] ] [ text "ログのダウンロード" ]
                        , Button.button [ Button.danger, Button.attrs [ onClick ClearLogs ] ] [ text "ログの削除" ]
                        ]
                    , a [ id "downloadAnchorElem", style "display" "none" ] []
                    , div [ style "clear" "both" ] []
                    ]
                ]
            ]
        ]
    }
