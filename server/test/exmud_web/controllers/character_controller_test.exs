defmodule ExmudWeb.CharacterControllerTest do
  use ExmudWeb.ConnCase

  alias Exmud.Engine
  alias Exmud.Engine.Character

  @create_attrs %{
    name: "some name"
  }
  @update_attrs %{
    name: "some updated name"
  }
  @invalid_attrs %{name: nil}

  def character_fixture(attrs \\ @create_attrs) do
    player = player_fixture()
    attrs = Map.put(attrs, :player_id, player.id)
    {:ok, character} = Engine.create_character(attrs)
    Map.put(character, :player, player)
  end

  alias Exmud.Account

  @valid_player_attrs %{status: Account.Constants.PlayerStatus.created(), tos_accepted: false}

  def player_fixture(attrs \\ @valid_player_attrs) do
    {:ok, player} = Account.create_player(attrs)

    player
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "listing characters" do
    setup [:create_character]

    test "listing player characters fails when requested/authed player are not the same", %{
      conn: conn,
      character: character
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: player_fixture()})
        |> post(Routes.character_path(conn, :list_player_characters),
          playerId: character.player.id
        )

      assert json_response(conn, 401)["data"] == nil
    end

    test "listing player characters fails when not authenticated", %{
      conn: conn,
      character: character
    } do
      conn =
        post(conn, Routes.character_path(conn, :list_player_characters),
          playerId: character.player.id
        )

      assert json_response(conn, 401)["data"] == nil
    end

    test "listing player characters succeeds when requested/authed player are the same", %{
      conn: conn,
      character: character
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: character.player})
        |> post(Routes.character_path(conn, :list_player_characters),
          playerId: character.player.id
        )

      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create character" do
    test "renders character when data is valid", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: player_fixture()})
        |> post(Routes.character_path(conn, :create), character: @create_attrs)

      assert %{"id" => id, "slug" => slug} = json_response(conn, 201)["data"]

      conn = post(conn, Routes.character_path(conn, :get), slug: slug)

      assert %{
               "id" => id,
               "name" => "some name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: player_fixture()})
        |> post(Routes.character_path(conn, :create), character: @invalid_attrs)

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update character" do
    setup [:create_character]

    test "renders character when data is valid", %{
      conn: conn,
      character: %Character{id: id} = character
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: character.player})
        |> post(Routes.character_path(conn, :update), id: id, character: @update_attrs)

      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = post(conn, Routes.character_path(conn, :get), id: id)

      assert %{
               "id" => id,
               "name" => "some updated name",
               "slug" => "some-updated-name"
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, character: character} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: character.player})
        |> post(Routes.character_path(conn, :update),
          id: character.id,
          character: @invalid_attrs
        )

      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete character" do
    setup [:create_character]

    test "deletes chosen character", %{conn: conn, character: character} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{player: character.player})
        |> post(Routes.character_path(conn, :delete), id: character.id)

      assert response(conn, 204)

      conn = post(conn, Routes.character_path(conn, :get), id: character.id)
      assert response(conn, 404)
    end
  end

  defp create_character(_) do
    character = character_fixture()
    {:ok, character: character}
  end
end
