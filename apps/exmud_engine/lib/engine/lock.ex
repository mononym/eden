defmodule Exmud.Engine.Lock do
  @moduledoc """
  Locks perform a double duty of defining the actions that can be taken on an Object, and what Objects can perform said actions.

  A Lock is made up of three parts. An access type which is a simple string that identifies the action to be enabled, the data which configures the Lock, and the callback module which uses the configuration data along with both the accessing and accessed Objects to determine if the lock check passes. These last two bits of information are provided to the callback module at runtime, and must produce a boolean value.

  For example, a locked garden gate might only be able to be opened by the local gardener. So a Lock might be added with the access type of 'open' with a callback module name of of 'owner' and config of '%{id: 42}'. Of course for this to have any affect, the code which controls opening the gate must check the lock. Such a check might look like:

  '''
  if Lock.check!(24, "open", 42) do
    ...
  else
    ...
  end
  '''

  In the background the Object which should have the Lock on it, 24, is checked to see if anything exists for the "open" access type. Then the associated callback module for the "owner" check is retrieved and passed the two ids along with data associted with the Lock. Assuming the check passes the above code would execute the 'if' block.

  Almost everything in Exmud interacts with Locks in one way or another. The Engine applies default Locks to several different types of Objects on creation otherwise the provided default logic simply wouldn't work. For example, at Character creation a 'puppet' Lock is created on the Character Object which points to the Player Object which owns it. Without this Lock, a Player would be unable to puppet their newly created Character.
  """

  #
  # Behavior definition and default callback setup
  #

  @doc false
  defmacro __using__( _ ) do
    quote location: :keep do
      @behaviour Exmud.Engine.Lock

      @doc false
      def check( _target_object, _accessing_object, _lock_config ), do: false

      defoverridable check: 3
    end
  end

  @doc """
  Called when a Lock is being checked to determine if an Object has permission.
  """
  @callback check( target_object, accessing_object, lock_config ) :: boolean

  @typedoc "An error message."
  @type error :: term

  @typedoc "An in game Object."
  @type object_id :: integer

  @typedoc "The type of access being checked for on an Object."
  @type access_type :: String.t()

  @typedoc "The Object attempting to perform an action."
  @type accessing_object :: object_id

  @typedoc "The Object the action is to be taken on."
  @type target_object :: object_id

  @typedoc "The map which defines the values used to configure the individual Lock."
  @type lock_config :: %{}

  @typedoc "The name of a callback module which implements the Lock behaviour."
  @type callback_module :: atom

  @typedoc "The name that a callback module is registered under with the Engine."
  @type lock_name :: String.t()

  alias Exmud.Engine.Repo
  alias Exmud.Engine.Schema.Lock
  import Ecto.Query
  import Exmud.Common.Utils
  import Exmud.Engine.Utils
  require Logger

  #
  # Manipulation of Locks on an Object.
  #

  @doc """
  Attach a Lock to an Object.
  """
  @spec attach( object_id, access_type, callback_module, lock_config ) ::
    :ok | { :error, :no_such_object } | { :error, :already_attached }
  def attach( object_id, access_type, callback_module, lock_config \\ %{} ) do
    Lock.new( %{
      object_id: object_id,
      access_type: access_type,
      callback_module: pack_term( callback_module ),
      config: pack_term( lock_config )
    } )
    |> Repo.insert()
    |> normalize_repo_result()
    |> case do
      { :error, [ object_id: _error ] } ->
        Logger.error(
          "Attempt to add Lock with access type `#{ access_type }` onto non existing object `#{ object_id }`"
        )

        { :error, :no_such_object }

      { :error, [ access_type: _error ] } ->
        Logger.error(
          "Attempt to add Lock with access type `#{ access_type }` onto Object `#{ object_id }` when it already exists."
        )

        { :error, :already_attached }

      :ok ->
        :ok
    end
  end

  @doc """
  Check to see if there is a lock for a specific access type on an Object.
  """
  @spec attached?( object_id, access_type ) :: boolean
  def attached?( object_id, access_type ) do
    query = from( lock in lock_query( object_id, access_type ), select: count( "*" ))

    Repo.one( query ) == 1
  end

  @doc """
  Perform a Lock check.

  Given an Object id and an access type, the Lock is first retrieved and then the matching callback module is retrieved
  before the callbacks 'check' method is called to perform the actual check.
  """
  @spec check( object_id, access_type, accessing_object ) :: { :ok, boolean } | { :error, :no_such_lock }
  def check( object_id, access_type, accessing_object ) do
    query = from( lock in lock_query( object_id, access_type ), select: { lock.callback_module, lock.config } )

    case Repo.one( query ) do
      nil ->
        { :error, :no_such_lock }

      { callback_module, config } ->
        { :ok,
          apply( unpack_term( callback_module ), :check, [
            object_id,
            accessing_object,
            unpack_term( config )
          ] )
        }
    end
  end

  @doc """
  Perform a Lock check.

  Given an Object id and an access type, the Lock is first retrieved and then the matching callback module is retrieved
  before the callbacks 'check' method is called to perform the actual check.

  Raises an ArgumentError if the Lock does not exist on the provided Object.
  """
  @spec check!( object_id, access_type, accessing_object ) :: boolean
  def check!( object_id, access_type, accessing_object ) do
    try do
      { :ok, result } = check( object_id, access_type, accessing_object )
      result
    rescue
      _ ->
        raise ArgumentError, message: "no such lock"
    end
  end

  @doc """
  Detach a Lock from an Object.

  Does not check for presence of specified lock, simply deletes any that match the given parameters.
  """
  @spec detach(object_id, access_type) :: :ok
  def detach(object_id, access_type) do
    lock_query(object_id, access_type)
    |> Repo.delete_all()

    :ok
  end

  #
  # Internal Functions
  #

  @spec lock_query(object_id, access_type) :: term
  defp lock_query(object_id, access_type) do
    from(lock in Lock, where: lock.object_id == ^object_id and lock.access_type == ^access_type)
  end
end
