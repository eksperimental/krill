defmodule Krill.Supervisor do
  use Supervisor

  def start_link(module, dict) do
    result = {:ok, sup } = Supervisor.start_link(__MODULE__, [dict])
    start_workers(sup, module, dict)
    result
  end
  
  def start_workers(sup, module, dict) do
    {:ok, _pid} = apply(module, :start_link, [dict])
    :ok = apply(module, :counter, [dict, 1])
    apply(module, :start, [dict])
    apply(module, :messages_default, [dict])

    # Start the stash worker
    {:ok, stash} = 
       Supervisor.start_child(sup, worker(Krill.Htmlproof, [dict]))
    # and then the subsupervisor for the actual sequence server
    #Supervisor.start_child(sup, supervisor(Sequence.SubSupervisor, [stash]))
  end

  def init(_) do

    children = [
      # Execute

      # Parse
      worker()
    ]
    supervise children, strategy: :one_for_one
  end
end
