defmodule Hugh.Adapter.Supervisor do
  @moduledoc """
  Supervises the processes of a single robot
  """
  use Supervisor

  alias Hugh.Adapter

  def start_adapter(adapter, adapter_opts, robot, opts) do
    # Naming adapter and supervisor is neat but unnecessary
    # robot_name = Keyword.fetch!(opts, :robot_name)
    # sup_name = String.to_atom("#{robot_name}.AdapterSupervisor")
    # adapter_name = String.to_atom("#{robot_name}.#{Adapter.process_suffix(adapter)}")
    # {:ok, pid} = Supervisor.start_link(__MODULE__, nil, Keyword.put(opts, :name, sup_name))
    # Supervisor.start_child(pid, adapter.child_spec({robot, adapter_opts}, name: adapter_name))
    {:ok, pid} = Supervisor.start_link(__MODULE__, nil, opts)
    Supervisor.start_child(pid, adapter.child_spec({robot, adapter_opts}, []))
  end

  @impl true
  def init(_arg) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
