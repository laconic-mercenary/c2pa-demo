#!/bin/bash

set -e -o pipefail

rustup target add x86_64-unknown-linux-musl

# cargo clean 
cargo build --release --target=x86_64-unknown-linux-musl

cp target/x86_64-unknown-linux-musl/release/handler .

chmod +x handler

rm -f c2pa-v2.zip

zip -r c2pa-v2.zip host.json handler c2pa

az functionapp deployment source config-zip --name mattc2pa-rust-test \
    --resource-group mattc2pa-rg01 \
    --src c2pa-v2.zip 