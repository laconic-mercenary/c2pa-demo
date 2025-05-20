use std::collections::HashMap;
use std::env;
use std::net::Ipv4Addr;
use warp::{http::Response, Filter};

#[tokio::main]
async fn main() {
    let sign_post = warp::post()
        .and(warp::path("api"))
        .and(warp::path("c2pa"))
        .and(warp::query::<HashMap<String, String>>())
        .map(|_| {
            warp::reply::html("ok")
        });

    let verify_get = warp::get()
        .and(warp::path("api"))
        .and(warp::path("c2pa"))
        .and(warp::query::<HashMap<String, String>>())
        .map(|_| {
            warp::reply::html("ok")
        });

    let port_key = "FUNCTIONS_CUSTOMHANDLER_PORT";
    let port: u16 = match env::var(port_key) {
        Ok(val) => val.parse().expect("Custom Handler port is not a number!"),
        Err(_) => 3000,
    };

    let routes = sign_post.or(verify_get);

    warp::serve(routes).run((Ipv4Addr::LOCALHOST, port)).await
}