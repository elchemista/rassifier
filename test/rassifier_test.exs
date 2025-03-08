defmodule RassifierTest do
  use ExUnit.Case
  alias Rassifier

  # Resolve the CSV file path relative to the test directory.
  @csv_path Path.expand("job_action.csv", __DIR__)

  describe "Rassifier NIF" do
    test "loads CSV and classifies a query" do
      # Load the classifier resource from the CSV file.
      resource = Rassifier.load(@csv_path, 1, 3, "zstd")

      # Run classification on a sample query.
      result = Rassifier.classify_query(resource, "job")

      # Assert that the result is a binary string.
      assert is_binary(result)
    end
  end
end
