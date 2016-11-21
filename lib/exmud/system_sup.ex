defmodule Exmud.SystemSup do
  require Logger
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok,  name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Exmud.SystemRunner, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
