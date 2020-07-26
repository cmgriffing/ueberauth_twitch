# Überauth Twitch

> Twitch strategy for Überauth.

_Note_: Sessions are required for this strategy.

## Installation

1. Setup your application at [Twitch Developers](https://dev.twitch.com/).

1. Add `:ueberauth_twitch` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_twitch, "~> 0.2"},
       {:oauth, github: "tim/erlang-oauth"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_twitch]]
    end
    ```

1. Add Twitch to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        twitch: {Ueberauth.Strategy.Twitch, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Twitch.OAuth,
      consumer_key: System.get_env("TWITCH_CONSUMER_KEY"),
      consumer_secret: System.get_env("TWITCH_CONSUMER_SECRET")
    ```

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. Your controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://github.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initiate the request through:

    /auth/twitch

## Development mode

As noted when registering your application on the Twitch Developer site, you need to explicitly specify the `oauth_callback` url.  While in development, this is an example url you need to enter.

    Website - http://127.0.0.1
    Callback URL - http://127.0.0.1:4000/auth/twitch/callback

## License

Please see [LICENSE](https://github.com/ueberauth/ueberauth_twitch/blob/master/LICENSE) for licensing details.
