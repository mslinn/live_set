use std::env;
use std::fs;
use std::path::Path;
use std::process;

mod live_set;
mod als_delta;
mod common;

fn main() {
    let command = env::args().nth(1).unwrap_or_else(|| {
        eprintln!("Please provide a command (common, als_delta, or live_set).");
        process::exit(1);
    });

    match command.as_str() {
        "common" => common(),
        "als_delta" => als_delta(),
        "live_set" => live_set(),
        _ => {
            eprintln!("Invalid command. Please use 'common', 'als_delta', or 'live_set'.");
            process::exit(1);
        }
    }
}

fn common() {
    let options = common::parse_options();
    if env::args().len() == 1 {
        common::help_live_set("Ableton Live set name must be provided.");
    }
}

fn als_delta() {
    let options = als_delta::parse_options();
    if env::args().len() == 1 {
        als_delta::help_als_delta();
    }

    let set_name = env::args().skip(1).collect::<Vec<_>>().join(" ").expand_env();
    if !Path::new(&set_name).exists() {
        als_delta::help_als_delta(format!("{} does not exist", set_name));
    }
    if Path::new(&set_name).is_dir() {
        als_delta::help_als_delta(format!("{} is a directory", set_name));
    }

    let mut als_delta = als_delta::AlsDelta::new(&set_name, &options);
    match catch_ctrl_c!(als_delta.show()) {
        Ok(_) => als_delta.cleanup(),
        Err(e) => {
            als_delta.cleanup();
            eprintln!("Error: {}", e);
        }
    }
}

fn live_set() {
    let options = live_set::parse_options();
    if env::args().len() == 1 {
        live_set::help_live_set();
    }

    let set_name = env::args().skip(1).collect::<Vec<_>>().join(" ").expand_env();
    if !Path::new(&set_name).exists() {
        live_set::help_live_set(format!("{} does not exist", set_name));
    }
    if Path::new(&set_name).is_dir() {
        live_set::help_live_set(format!("{} is a directory", set_name));
    }

    let mut live_set = live_set::LiveSet::new(&set_name, &options);
    if options.convert11 {
        live_set.modify_als();
    } else {
        live_set.show();
    }
}

trait ExpandEnv {
    fn expand_env(self) -> String;
}

impl ExpandEnv for String {
    fn expand_env(self) -> String {
        let mut result = self;
        for (key, value) in env::vars() {
            result = result.replace(&format!("${}", key), &value);
        }
        result
    }
}

macro_rules! catch_ctrl_c {
    ($expr:expr) => {
        catch::catch(|| $expr)
    };
}
