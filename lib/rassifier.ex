defmodule Rassifier do
  @moduledoc """
  A classifier module that leverages a Rust-based NIF to classify text queries.

  This module provides an interface to load a CSV file containing training data
  and labels, and then classify queries based on that data. The underlying
  functionality is implemented in Rust using Rustler.
  """

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :rassifier,
    crate: "rassifier",
    base_url: "https://github.com/elchemista/rassifier/releases/download/v#{version}",
    force_build: System.get_env("RUSTLER_PRECOMPILATION_EXAMPLE_BUILD") in ["1", "true"],
    version: version

  @doc """
  Loads the classifier resource from a CSV file.

  The CSV file should have two columns:
    1. The text data.
    2. The label associated with the text.

  ## Parameters

    - `file_path` - The path to the CSV file containing training data.
    - `level` - The compression level used during classification.
    - `k` - The number of neighbors to consider.
    - `algorithm` - The compression algorithm to use (e.g., `"zstd"`, `"gzip"`, `"zlib"`, or `"deflate"`).

  ## Returns

    - A resource handle (opaque reference) to the classifier data.

  If the NIF is not loaded, this function will raise a `:nif_not_loaded` error.
  """
  @spec load(String.t(), integer, integer, String.t()) :: reference()
  def load(_file_path, _level, _k, _algorithm), do: :erlang.nif_error(:nif_not_loaded)

  @doc """
  Classifies a given query using the loaded classifier resource.

  ## Parameters

    - `resource` - The classifier resource returned by `load/4`.
    - `query` - A string representing the query to classify.

  ## Returns

    - A string representing the label assigned to the query.
    - Returns `"unknown"` if classification fails.

  If the NIF is not loaded, this function will raise a `:nif_not_loaded` error.
  """
  @spec classify_query(reference(), String.t()) :: String.t()
  def classify_query(_resource, _query), do: :erlang.nif_error(:nif_not_loaded)
end
