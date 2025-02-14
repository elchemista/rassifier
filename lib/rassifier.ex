defmodule Rassifier do
  use Rustler, otp_app: :rassifier, crate: "rassifier"

  # If the NIF is not loaded, these function calls will raise :nif_not_loaded error.
  def load(_file_path, _level, _k, _algorithm_atom), do: :erlang.nif_error(:nif_not_loaded)
  def classify_query(_resource, _query), do: :erlang.nif_error(:nif_not_loaded)
end
