# Rassifier

**Rassifier** is an Elixir library that provides low-resource text classification powered by a Rust implementation using [lrtc](https://github.com/jerryjliu/lrtc) (Low-Resource Text Classification). It allows you to load a small training dataset from a CSV file and classify short text queries using compression-based similarity measures.

The library supports customization of the compression level, the number of nearest neighbors (k), and the compression algorithm (e.g. `"zstd"`, `"gzip"`, `"zlib"`, `"deflate"`). Rassifier is integrated into your Elixir application via a GenServer-based worker that wraps the Rust NIF.

---

## Installation

If available on Hex, add `rassifier` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:rassifier, "~> 0.1.0"}
  ]
end
```

Then, fetch the dependencies:

```bash
mix deps.get
```

---

## Usage

### CSV Training Data Format

Your CSV file should have two columns:
1. **user_input**: The training text (e.g., `"create job"`, `"Yes"`, `"No"`, etc.)
2. **label**: The corresponding label (e.g., `create`, `agree`, `cancel`, `edit`, or `exit`)

*Example CSV snippet:*

```csv
user_input,label
"Yes",agree
"create",create
"create job",create
"No",cancel
...
```

---

### Starting the Classifier Worker

The Rassifier worker is implemented as a GenServer. You start it with configuration options for your training CSV file, compression level, number of neighbors, and algorithm.

```elixir
defmodule MyApp do
  def start_classifier do
    {:ok, _pid} = Rassifier.Worker.start_link(
      file_path: "data/training_data.csv",
      level: 3,
      k: 1,
      algorithm: "zstd"
    )
  end
end
```

When started, the worker calls the Rust NIF to load the training data and stores an opaque resource handle in its state.

---

### Classifying a Query

#### Synchronous Classification

Once the worker is running, you can classify a query using a synchronous call:

```elixir
defmodule MyApp do
  def classify_query(query) do
    label = Rassifier.Worker.classify(query)
    IO.puts("The classification label is: #{label}")
    label
  end
end

# Example usage:
MyApp.start_classifier()
MyApp.classify_query("create job")
```

If your training data is set up appropriately, `"create job"` should return the label `"create"`.

#### Asynchronous Classification

You can also perform asynchronous classification using a cast. In this case, the worker sends the result back to the caller via a message.

```elixir
defmodule MyApp do
  def async_classify(query) do
    GenServer.cast(Rassifier.Worker, {:classify, query, self()})
    receive do
      {:classified, label} ->
        IO.puts("Asynchronously classified label: #{label}")
    after
      5000 ->
        IO.puts("No asynchronous result received")
    end
  end
end

# Example usage:
MyApp.start_classifier()
MyApp.async_classify("No")
```

---

### Full Example

Below is a full example combining both synchronous and asynchronous calls:

```elixir
defmodule Example do
  def run do
    # Start the classifier worker with the given training data.
    {:ok, _pid} = Rassifier.Worker.start_link(
      file_path: "data/training_data.csv",
      level: 3,
      k: 1,
      algorithm: "zstd"
    )

    # Synchronous classification
    label_sync = Rassifier.Worker.classify("create job")
    IO.puts("Synchronous result: #{label_sync}")

    # Asynchronous classification
    GenServer.cast(Rassifier.Worker, {:classify, "No", self()})
    receive do
      {:classified, label_async} ->
        IO.puts("Asynchronous result: #{label_async}")
    after
      5000 ->
        IO.puts("No asynchronous result received")
    end
  end
end

Example.run()
```

---

## Under the Hood

Rassifier uses a Rust NIF (via [Rustler](https://github.com/rusterlium/rustler)) to leverage a low-resource text classification method based on compression distances. The core functions provided by the Rust side are:

- **`load(file_path, level, k, algorithm)`**:  
  Reads training data from a CSV file and initializes the classifier with the specified compression level, number of nearest neighbors (k), and compression algorithm.

- **`classify_query(resource, query)`**:  
  Given a loaded resource and a query string, it returns the classification label by comparing the query against the training set using a compression-based distance metric.

The Elixir module `Rassifier` exposes these functions, while `Rassifier.Worker` wraps the resource in a GenServer for easier integration.

---

## Customization

- **Training Data:**  
  Ensure your CSV file has a balanced and unambiguous set of examples. For example, to distinguish `"create"` commands from simple `"agree"` responses, include short training examples such as `"create"`, `"create job"`, etc. in the **create** category.

- **Compression Settings:**  
  Experiment with different compression levels (e.g., from 1 to 9) and algorithms (`"zstd"`, `"gzip"`, `"zlib"`, `"deflate"`) to optimize classification accuracy based on your dataset.

- **Nearest Neighbors (k):**  
  Adjust the `k` parameter to determine how many nearest neighbors to consider. Increasing `k` may yield more robust results when your training data is noisy or sparse.

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests on [GitHub](https://github.com/elchemista/rassifier).

---

## License

This project is licensed under the MIT License.

---