![version badge](https://img.shields.io/hexpm/v/clover.svg?style=for-the-badge)
![ci badge](https://img.shields.io/circleci/project/github/wasnotrice/clover/master.svg?style=for-the-badge)
![code coverage badge](https://img.shields.io/coveralls/github/wasnotrice/clover/master.svg?style=for-the-badge)
![license badge](https://img.shields.io/github/license/wasnotrice/clover.svg?style=for-the-badge)

# Clover

Clover is a framework for building chat bots in Elixir. It takes inspiration from [Hubot](https://hubot.github.com/) and [Hedwig](https://github.com/hedwig-im/hedwig). Like Hubot and Hedwig, Clover:

- uses adapters so you can connect your bot to various platforms
- allows you to specify multiple handlers for incoming messages
- associates a regular expression for matching messages with a function that transforms the message into a response

Like Hedwig, Clover:

- supervises processes for fault tolerance

Clover adds some features:

- matches each incoming message with at most one handler (e.g., no double responses)
- allows you to start your robot under Clover's supervision tree, or under your own
- configuration happens at runtime, not through application config

Planned features for Clover:

- only ever responds to messages addressed to your robot (e.g., no "hear" handlers)
- maintains "room state", so your robot can carry on conversations
- handles messages in their own worker processes

## Creating your robot

_Coming soon. See the [Test Robot](test/support/test_robot.ex) for an example._

## Starting your robot

Clover bots always run under a `Clover.Robot.Supervisor` process. The supervisor handles crashes in your robot or in its adapter, and restarts processes as needed. However, you have some choice as to who supervises the supervisor.

Let's say you have a Clover bot called `Mybot`. To start a robot under Clover's supervision tree, provide a name, your bot's module, and an adapter:

```elixir
Clover.start_supervised_robot("mybot", Mybot, {Clover.Adapter.Slack, token: "my-slack-bot-token"})
```

Clover will start your robot under its own supervision tree, and manage it for you.

_(The name you provide here will be used to register your robot with Clover. It's not your robot's chat nick.)_

To handle supervision yourself:

```elixir
Clover.start_robot("mybot", Mybot, {Clover.Adapter.Slack, token: "my-slack-bot-token"})
```

The individual robot and adapter processes will still be supervised by a `Clover.Robot.Supervisor`, but you can place this process into your own supervision tree, for greater control over its lifecycle.

## Adapters

Clover is designed to support multiple chat platforms through adapters. Currently, there is a test adapter bundled with Clover, and a Slack adapter (which is also bundled with Clover, but will be pulled out in the future).

## Installation

The package can be installed by adding `clover` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:clover, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/clover](https://hexdocs.pm/clover).
