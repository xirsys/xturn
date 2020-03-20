defmodule Xirsys.XTurn.SockImpl do
  alias Xirsys.XTurn.Pipeline
  alias Xirsys.Sockets.{Conn, Response}
  alias XMediaLib.Stun
  require Logger

  @channel_msg 1
  @send_msg 0
  @software "xirsys-turnserver"
  # fixed, for now.
  @nonce "5543438859252a7c"

  @doc """
  With new data, see if we can process a message on the buffer
  """
  @spec process_buffer(binary()) :: {binary() | nil, binary()}
  def process_buffer(bin) when byte_size(bin) <= 4, do: {nil, bin}

  def process_buffer(<<type::2, _::14, body_bytes::16, _body::binary-size(body_bytes), _::binary>> = bin)
       when type == @send_msg or type == @channel_msg do
    msg_bytes = pad_body_bytes(type, body_bytes)
    process_data(bin, msg_bytes)
  end

  def process_buffer(<<type::2, _::14, _body_bytes::16, _::binary>> = bin)
       when type == @send_msg or type == @channel_msg,
       # message is not yet long enough 
       do: {nil, bin}

  def process_buffer(<<type::2, _::14, _::binary>> = bin) do
    Logger.error("Unknown message type : #{inspect(type)}")
    {nil, bin}
  end

  @doc """
  Dispatches the socket data to the application
  """
  @spec dispatch(%Conn{}) :: %Conn{}
  def dispatch(%Conn{message: <<type::2, _::30, _body::binary>>} = conn)
       when type == @send_msg or type == @channel_msg do
    Pipeline.process_message(%Conn{conn | listener: self()})
    conn
  end

  @doc """
  If a response message has been set, then we must notify the client according
  to the STUN and TURN specifications.
  """
  @spec send(%Conn{}) :: %Conn{}
  def send(%Conn{response: %Response{err_no: err, message: msg}} = conn) when is_integer(err) do
    conn
    |> build_response(err, msg)
    |> Conn.send()
  end

  def send(%Conn{response: %Response{class: cls, attrs: attrs}} = conn) when is_atom(cls) do
    conn
    |> build_response(cls, attrs)
    |> Conn.send()
  end

  def send(%Conn{} = conn) do
    Logger.info("SEND: #{inspect(conn)}")
    conn
  end

  def send(v) do
    Logger.info("SEND: #{inspect(v)}")
    v
  end

  # ----------------------------
  # Private functions
  # ----------------------------

  # With a packet header extracted from the buffer,  see  
  # if we can process it  
  # need more data  
  defp process_data(bin, required_size) when required_size > byte_size(bin), do: {nil, bin}

  defp process_data(bin, required_size) when required_size == byte_size(bin), do: {bin, <<>>}
  
  defp process_data(bin, required_size) do
    <<turn::binary-size(required_size), tail::binary>> = bin
    {turn, tail}
  end

  defp pad_body_bytes(@channel_msg, bytes),
    do: roundup_to_4(bytes)

  defp pad_body_bytes(@send_msg, bytes),
    do: bytes + 20

  # Pad message if needed 
  defp roundup_to_4(num) do
    pad = rem(num, 4)
    padded = num + (4 - pad)
    if rem(num, 4) == 0, do: padded, else: padded + 4
  end

  # Adjust Conn struct ready for response to end user.
  @spec build_response(%Conn{}, atom() | integer(), binary() | any()) :: %Conn{}
  defp build_response(%Conn{decoded_message: %Stun{} = turn} = conn, class, attrs)
       when is_atom(class) do
    new_attrs =
      cond do
        is_map(attrs) ->
          Map.put(attrs, :software, @software)

        true ->
          %{software: @software}
      end

    fingerprint = turn.integrity
    Logger.info("#{inspect(new_attrs)}")

    msg = %Stun{turn | class: class, fingerprint: fingerprint, attrs: new_attrs}

    %Conn{
      conn
      | decoded_message: msg, message: Stun.encode(msg)
    }
  end

  defp build_response(%Conn{decoded_message: %Stun{} = turn} = conn, err_no, err_msg)
       when is_integer(err_no) do
    new_attrs = %{
      error_code: {err_no, err_msg},
      nonce: @nonce,
      realm: realm(),
      software: @software
    }

    msg = %Stun{turn | class: :error, attrs: new_attrs}

    %Conn{conn | decoded_message: msg, message: Stun.encode(msg)}
  end

  defp realm() do
    case Application.get_env(:xturn, :realm) do
      v when is_binary(v) -> v
      _ -> "xirsys.com"
    end
  end
end
