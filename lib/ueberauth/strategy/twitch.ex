defmodule Ueberauth.Strategy.Twitch do
  @moduledoc """
  Twitch Strategy for Üeberauth.
  """

  use Ueberauth.Strategy, uid_field: :id,
                          oauth2_module: Ueberauth.Strategy.Twitch.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles initial request for Twitch authentication.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    opts = [redirect_uri: callback_url(conn), scope: scopes]

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  def handle_callback!(conn, opts \\ [])
  @doc """
  Handles the callback from Twitch.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn, opts) do
    IO.inspect("callback url")
    IO.inspect(callback_url(conn))
    opts = opts ++ [redirect_uri: callback_url(conn)]
    IO.inspect("OAUTH: getting token")
    client = Ueberauth.Strategy.Twitch.OAuth.get_token!([code: code], opts)
    token = client.token

    if token.access_token == nil do
      IO.inspect("OAUTH: no access token")
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      IO.inspect("OAUTH: fetching user")
      # We need to reset the client in the token here because it has basic auth in the headers
      fetch_user(conn, Map.put(token, :client, Ueberauth.Strategy.Twitch.OAuth.client), opts)
    end
  end

  @doc false
  def handle_callback!(conn, _opts) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:twitch_user, nil)
    |> put_private(:twitch_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    Map.get(conn.private.twitch_token.other_params, "id")
  end

  @doc """
  Includes the credentials from response.
  """
  def credentials(conn) do
    token = conn.private.twitch_token

    %Credentials{
      expires: !!token.expires_at,
      token: token.access_token,
      other: %{ token_type: token.token_type }
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.twitch_user
    email =
      user
      |> Access.get("emails")
      |> Enum.find(&(&1["primary"] == true))
      |> Access.get("email")


    %Info{
      email: email,
      image: user["image"],
      name: user["first_name"] || email,
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.twitch_token,
        user: conn.private.twitch_user,
      }
    }
  end

  defp fetch_user(conn, token, opts) do
    conn = put_private(conn, :twitch_token, token)

    case Ueberauth.Strategy.Twitch.OAuth.get(token, "/helix/users", [
      "Client-ID": opts[:client_id]
    ]) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body } } ->
        set_errors!(conn, [error("token", "unauthorized")])

      { :ok, %OAuth2.Response{ status_code: status_code, body: res } } when status_code in 200..399 ->
        put_private(conn, :twitch_user, res)

      { :error, %OAuth2.Error{ reason: reason } } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
