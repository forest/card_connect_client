defmodule CardConnectClient.Error do
  @moduledoc false

  @type meta :: map() | keyword()

  @typedoc "The exception type"
  @type t :: %__MODULE__{
          :reason => atom(),
          :message => String.t(),
          :meta => meta()
        }

  defexception [:reason, :message, :meta]

  @spec new(atom(), String.t(), meta()) :: t()
  def new(reason, message, meta \\ %{}) when is_binary(message) do
    %__MODULE__{reason: reason, message: message, meta: Map.new(meta)}
  end

  @spec timeout(binary(), meta()) :: t()
  def timeout(message, meta \\ %{}) do
    new(:timeout, message, meta)
  end

  @spec internal(binary(), meta()) :: t()
  def internal(message, meta \\ %{}) do
    new(:internal, message, meta)
  end

  @spec http_status(integer(), meta()) :: t()
  def http_status(status, meta \\ %{}) when is_integer(status) do
    reason = Plug.Conn.Status.reason_atom(status)
    message = Plug.Conn.Status.reason_phrase(status)

    new(reason, message, meta)
  end

  @impl true
  def message(exception) do
    exception.message
  end
end
