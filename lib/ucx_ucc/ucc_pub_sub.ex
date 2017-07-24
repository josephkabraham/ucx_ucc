defmodule UcxUcc.UccPubSub do

  use GenServer

  require Logger

  @name __MODULE__

  defstruct subscriptions: %{}

  defmacro __using__(_) do
    quote do
      use unquote(__MODULE__).Api
      alias unquote(__MODULE__), warn: false
    end
  end

  ################
  # Public API

  def start_link do
    GenServer.start_link __MODULE__, [], name: @name
  end


  def subscribe(topic) do
    subscribe self(), topic
  end

  def subscribe(pid, topic) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, "*", nil}
  end

  def subscribe(topic, event) do
    subscribe self(), topic, event
  end

  def subscribe(pid, topic, event) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, event, nil}
  end

  def subscribe(topic, event, meta) do
    subscribe self(), topic, event, meta
  end

  def subscribe(pid, topic, event, meta) when is_pid(pid) do
    GenServer.cast @name, {:subscribe, pid, topic, event, meta}
  end

  def unsubscribe(topic) do
    unsubscribe self(), topic
  end

  def unsubscribe(pid, topic) when is_pid(pid) do
    GenServer.call @name, {:unsubscribe, pid, topic}
  end

  def unsubscribe(topic, event) do
    unsubscribe self(), topic, event
  end

  def unsubscribe(pid, topic, event) when is_pid(pid) do
    GenServer.call @name, {:unsubscribe, pid, topic, event}
  end

  def broadcast(topic, event, payload) do
    GenServer.cast @name, {:broadcast, topic, event, payload}
  end

  def state do
    GenServer.call @name, :state
  end

  ################
  # Callbacks

  def init(_) do
    {:ok, initial_state()}
  end

  def initial_state do
    __MODULE__.__struct__
  end

  def handle_cast({:subscribe, pid, topic, event, meta}, state) do
    subs =
      update_in state.subscriptions, [{topic, event}], fn
        nil -> [{pid, meta}]
        list -> [{pid, meta} | list]
      end
    Process.monitor pid
    {:noreply, struct(state, [subscriptions: subs])}
  end

  def handle_cast({:broadcast, topic, event, payload}, state) do
    Logger.warn "broadcast, topic: #{topic}, event: #{event}"
    state.subscriptions
    |> Map.get({topic, "*"}, [])
    |> broadcast_to_list(topic, event, payload)

    state.subscriptions
    |> Map.get({topic, event}, [])
    |> broadcast_to_list(topic, event, payload)

    {:noreply, state}
  end

  def handle_call({:unsubscribe, pid, topic}, _, state) do
    subs =
      Enum.reject state.subscriptions, fn
        {^topic, _} -> true
        _           -> false
      end
    {:reply, :ok, struct(state, subscriptions: subs)}
  end

  def handle_call({:unsubscribe, pid, topic, event}, _, state) do
    subs =
      Enum.reject state.subscriptions, fn
        {^topic, ^event} -> true
        _           -> false
      end
    {:reply, :ok, struct(state, subscriptions: subs)}
  end

  def handle_call(:state, _, state) do
    {:reply, state, state}
  end

  ################
  # Private

  defp broadcast_to_list(list, topic, event, payload) do
    Enum.each(list, fn
      {pid, nil} ->
        spawn fn -> send pid, {topic, event, payload} end
      {pid, meta} ->
        spawn fn -> send pid, {topic, event, payload, meta} end
    end)
  end

end