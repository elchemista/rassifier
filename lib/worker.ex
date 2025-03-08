defmodule Rassifier.Worker do
  use GenServer

  @doc """
  Start the classifier worker. Options can include:
    - :file_path (string)  -- path to your CSV
    - :level (integer)     -- compression level
    - :k (integer)         -- number of nearest neighbors
    - :algorithm (string)    -- e.g. "zstd", "gzip", "zlib", "deflate"
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    file_path = Keyword.fetch!(opts, :file_path)
    level = Keyword.get(opts, :level, 3)
    k = Keyword.get(opts, :k, 1)
    algorithm = Keyword.get(opts, :algorithm, "zstd")

    # This calls the Rust NIF, returning an opaque resource handle.
    resource = Rassifier.load(file_path, level, k, algorithm)

    # We store that resource in our GenServer state for later classification calls:
    {:ok, resource}
  end

  @doc "Public API to classify a string. The GenServer must already be started."
  def classify(query) do
    GenServer.call(__MODULE__, {:classify, query})
  end

  @impl true
  def handle_call({:classify, query}, _from, resource) do
    # We call the Rust side with our resource to get the classification.
    label = Rassifier.classify_query(resource, query)
    {:reply, label, resource}
  end

  @impl true
  def handle_cast({:classify, query, from}, resource) do
    # We call the Rust side with our resource to get the classification.
    label = Rassifier.classify_query(resource, query)
    send(from, {:classified, label})

    {:noreply, resource}
  end
end
