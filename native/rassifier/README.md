## Under the Hood: Rust Implementation

Rassifier’s performance is driven by a Rust NIF using the [Rustler](https://github.com/rusterlium/rustler) framework. Below is an annotated explanation of the Rust code powering Rassifier.

### Rust Code Overview

```rust
use std::fs::File;
use std::sync::RwLock;

use csv::Reader;
use lrtc::{classify, CompressionAlgorithm};
use rustler::{NifResult, ResourceArc};
use rustler::{Term, Env};

// -------------------------------
// Data we want to store in Rust
// -------------------------------
struct ClassifierData {
    training: Vec<String>,
    labels: Vec<String>,
    level: i32,
    algorithm: CompressionAlgorithm,
    k: usize,
}

/// Our resource that holds ClassifierData.
struct ClassifierResource {
    data: RwLock<ClassifierData>,
}

// -------------------------------
// Helper function: parse a string into CompressionAlgorithm
// -------------------------------
fn parse_algorithm(alg_str: &str) -> CompressionAlgorithm {
    match alg_str.to_lowercase().as_str() {
        "zstd" => CompressionAlgorithm::Zstd,
        "gzip" => CompressionAlgorithm::Gzip,
        "zlib" => CompressionAlgorithm::Zlib,
        "deflate" => CompressionAlgorithm::Deflate,
         _ => CompressionAlgorithm::Zstd,
    }
}

// -------------------------------
// Helper function: replicate the algorithm
// (because lrtc's enum doesn't derive Clone)
// -------------------------------
fn copy_algorithm(alg: &CompressionAlgorithm) -> CompressionAlgorithm {
    match alg {
        CompressionAlgorithm::Zstd => CompressionAlgorithm::Zstd,
        CompressionAlgorithm::Gzip => CompressionAlgorithm::Gzip,
        CompressionAlgorithm::Zlib => CompressionAlgorithm::Zlib,
        CompressionAlgorithm::Deflate => CompressionAlgorithm::Deflate,
    }
}

// -------------------------------
// NIF #1: load training data
// -------------------------------
#[rustler::nif]
fn load(
    file_path: String,
    level: i64,
    k: i64,
    alg_string: String,
) -> NifResult<ResourceArc<ClassifierResource>> {
    // Open CSV file with training data.
    let file = File::open(&file_path)
        .map_err(|_e| rustler::Error::BadArg)?;

    let mut reader = Reader::from_reader(file);
    let mut training = Vec::new();
    let mut labels = Vec::new();

    // Naively assume CSV has two columns: text in column 0, label in column 1.
    for record in reader.records() {
        let record = record.map_err(|_e| rustler::Error::BadArg)?;
        let text = record.get(0).unwrap_or("").to_string();
        let label = record.get(1).unwrap_or("").to_string();
        training.push(text);
        labels.push(label);
    }

    // Build our classifier data.
    let data = ClassifierData {
        training,
        labels,
        level: level as i32,
        algorithm: parse_algorithm(&alg_string),
        k: k as usize,
    };

    // Wrap the data in a thread-safe resource.
    let resource = ClassifierResource {
        data: RwLock::new(data),
    };
    Ok(ResourceArc::new(resource))
}

// -------------------------------
// NIF #2: classify a single query
// -------------------------------
#[rustler::nif]
fn classify_query(resource: ResourceArc<ClassifierResource>, query: String) -> String {
    // Lock the resource data for read access.
    let guard = resource.data.read().unwrap();
    let data = &*guard;

    // Replicate the algorithm (needed since the enum isn't Clone).
    let algo = copy_algorithm(&data.algorithm);

    // Call the lrtc classify function.
    let result = classify(
        &data.training,
        &data.labels,
        &[query],
        data.level,
        algo,         // Passed by value
        data.k,
    );

    // Return the first label found, or "unknown" if nothing matches.
    result.into_iter().next().unwrap_or_else(|| "unknown".to_string())
}

// -------------------------------
// on_load: register the resource
// -------------------------------
#[allow(non_local_definitions)]
fn on_load(env: Env, _info: Term) -> bool {
    let _ = rustler::resource!(ClassifierResource, env);
    true
}

// -------------------------------
// Rustler init
// -------------------------------
rustler::init!(
    "Elixir.Rassifier",
    load = on_load
);
```

- **Data Structures:**  
  - `ClassifierData` holds:
    - **training**: A vector of training texts.
    - **labels**: Corresponding classification labels.
    - **level**: The compression level to use.
    - **algorithm**: The chosen compression algorithm.
    - **k**: The number of nearest neighbors (k-NN) to consider.
  - `ClassifierResource` wraps the `ClassifierData` in a `RwLock` to allow safe concurrent reads.

- **Helper Functions:**
  - `parse_algorithm` converts a string (e.g. `"zstd"`) into the corresponding `CompressionAlgorithm` enum.
  - `copy_algorithm` replicates the algorithm value since the lrtc enum does not implement `Clone`.

- **NIF Functions:**
  - **`load`**:  
    Reads the CSV file, populates the training data and labels, and returns a resource handle wrapped in a `ResourceArc`. This resource is stored and used by the GenServer.
  - **`classify_query`**:  
    Accepts the resource and a query string. It then uses the lrtc `classify` function, which computes the compression distance between the query and training examples. The function returns the label of the nearest neighbor, or `"unknown"` if none match.

- **Initialization:**
  - The `on_load` function registers the resource with Rustler.
  - The `rustler::init!` macro sets up the NIF under the module name `Elixir.Rassifier`.

This implementation ensures that Rassifier can load a small CSV dataset and classify incoming queries efficiently using compression-based methods—all while being accessible from Elixir.

---
