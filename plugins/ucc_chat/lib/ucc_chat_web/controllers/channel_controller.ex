defmodule UccChatWeb.ChannelController do
  use UccChatWeb, :controller
  use Rebel.Controller, channels: [
    # UccChatWeb.UiChannel,
    UccChatWeb.UserChannel,
    UccChatWeb.RoomChannel,
  ]

  import Ecto.Query

  require Logger

  alias UccChat.{ChatDat}
  alias UccChat.{Message, Channel, ChannelService}
  alias UcxUcc.Accounts.User
  alias UccChat.Schema.Channel, as: ChannelSchema
  alias UccChat.Schema.Direct, as: DirectSchema

  plug :put_user_id_session

  def put_user_id_session(conn, _) do
    current_user = Coherence.current_user conn
    put_session conn, :current_user_id, current_user.id
  end

  def index(conn, _params) do
    user = Coherence.current_user(conn)
    channel = if user.open_id do
      Logger.warn "index load open id"
      case Channel.get(user.open_id) do
        nil ->
          Channel.list() |> hd
        channel ->
          channel
      end
    else
      Logger.warn "index load no open id"
      channel =
        ChannelSchema
        |> Ecto.Query.first
        |> Repo.one

      user
      |> User.changeset(%{open_id: channel.id})
      |> Repo.update!
      channel
    end

    show(conn, channel)
  end

  def show(conn, %ChannelSchema{} = channel) do
    user =
      conn
      |> Coherence.current_user
      |> Repo.preload([:account])

    UccChat.PresenceAgent.load user.id

    messages = Message.get_room_messages(channel.id, user)
    # Logger.warn "message count #{length messages}"

    chatd =
      user
      |> ChatDat.new(channel, messages)
      |> ChatDat.get_messages_info

    # Logger.warn "controller messages_info: #{inspect chatd.messages_info}"
    conn
    |> put_view(UccChatWeb.MasterView)
    |> put_layout({UcxUccWeb.LayoutView, "app.html"})
    |> render("main.html", chatd: chatd)
  end

  def show(conn, %{"name" => name}) do
    # require IEx
    case Channel.get_by(name: name) do
      nil ->
        # IEx.pry
        conn
        |> put_flash(:error, "#{name} is an invalid channel name!")
        |> redirect(to: "/")
      channel ->
        # IEx.pry
        if channel.type in [0,1] do
          show(conn, channel)
        else
          redirect(conn, do: "/")
        end
    end
  end

  def direct(conn, %{"name" => name}) do
    with user when not is_nil(user) <-
         UccChat.ServiceHelpers.get_user_by_name(name),
         user_id <- Coherence.current_user(conn) |> Map.get(:id),
         false <- user.id == user_id do

      case get_direct(user_id, name) do
        nil ->
          # create the direct and redirect
          ChannelService.add_direct(name, user_id, nil)
          direct = get_direct(user_id, name)
          show(conn, direct.channel)
        direct ->
          show(conn, direct.channel)
      end
    else
      _ -> redirect conn, to: "/"
    end
  end
  # def direct(conn, %{"name" => name}) do
  #   case UccChat.ServiceHelpers.get_by User, :username, name do
  #     nil ->
  #       redirect conn, to: "/"
  #     user ->
  #       user_id = Coherence.current_user(conn) |> Map.get(:id)
  #       user_id
  #       |> get_direct(name)
  #       |> case do
  #         nil ->
  #           # create the direct and redirect
  #           ChannelService.add_direct(name, user_id, nil)
  #           direct = get_direct(user_id, name)
  #           show(conn, direct.channel)
  #         direct ->
  #           show(conn, direct.channel)
  #       end
  #   end
  # end

  defp get_direct(user_id, name) do
    (from d in DirectSchema,
      where: d.user_id == ^user_id and like(d.users, ^"%#{name}%"),
      preload: [:channel])
    |> Repo.one
  end

end