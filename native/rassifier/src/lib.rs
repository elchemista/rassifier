use std::fs::File;
use std::sync::RwLock;

use csv::Reader;
use lrtc::{classify, CompressionAlgorithm};
use rustler::{NifResult, ResourceArc};
use rustler::{Term, Env};

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

fn parse_algorithm(alg_str: &str) -> CompressionAlgorithm {
    match alg_str.to_lowercase().as_str() {
        "zstd" => CompressionAlgorithm::Zstd,
        "gzip" => CompressionAlgorithm::Gzip,
        "zlib" => CompressionAlgorithm::Zlib,
        "deflate" => CompressionAlgorithm::Deflate,
         _ => CompressionAlgorithm::Zstd,
    }
}

fn copy_algorithm(alg: &CompressionAlgorithm) -> CompressionAlgorithm {
    match alg {
        CompressionAlgorithm::Zstd => CompressionAlgorithm::Zstd,
        CompressionAlgorithm::Gzip => CompressionAlgorithm::Gzip,
        CompressionAlgorithm::Zlib => CompressionAlgorithm::Zlib,
        CompressionAlgorithm::Deflate => CompressionAlgorithm::Deflate,
    }
}

#[rustler::nif]
fn load(
    file_path: String,
    level: i64,
    k: i64,
    alg_string: String,
) -> NifResult<ResourceArc<ClassifierResource>> {
    // Open CSV
    let file = File::open(&file_path)
        .map_err(|_e| rustler::Error::BadArg)?;

    let mut reader = Reader::from_reader(file);
    let mut training = Vec::new();
    let mut labels = Vec::new();

    // Naive: assume CSV has 2 columns: text in [0], label in [1].
    for record in reader.records() {
        let record = record.map_err(|_e| rustler::Error::BadArg)?;
        let text = record.get(0).unwrap_or("").to_string();
        let label = record.get(1).unwrap_or("").to_string();
        training.push(text);
        labels.push(label);
    }

    // Build data
    let data = ClassifierData {
        training,
        labels,
        level: level as i32,
        algorithm: parse_algorithm(&alg_string),
        k: k as usize,
    };

    // Wrap in ResourceArc
    let resource = ClassifierResource {
        data: RwLock::new(data),
    };
    Ok(ResourceArc::new(resource))
}

#[rustler::nif]
fn classify_query(resource: ResourceArc<ClassifierResource>, query: String) -> String {
    let guard = resource.data.read().unwrap();
    let data = &*guard;

    // replicate the enum to pass by value
    let algo = copy_algorithm(&data.algorithm);

    let result = classify(
        &data.training,
        &data.labels,
        &[query],
        data.level,
        algo,         // pass by value
        data.k,
    );

    // Return the first label or "unknown"
    result.into_iter().next().unwrap_or_else(|| "unknown".to_string())
}


#[allow(non_local_definitions)]
fn on_load(env: Env, _info: Term) -> bool {
    // saving in empty var to remove warning
    let _ = rustler::resource!(ClassifierResource, env);
    true
}

rustler::init!(
    "Elixir.Rassifier",
    load = on_load
);
