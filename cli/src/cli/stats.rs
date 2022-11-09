use crate::cli::{StatsCommand, StatsMode};
use std::io::Read;
use std::path::PathBuf;
use std::{fs, io};

pub fn stats_cmd(dirs: &[String], stats_cmd: StatsCommand) {
    log::info!("Starting stats calculation.");

    let files_stats = match process_files(dirs) {
        Ok(files) => files,
        Err(err) => {
            log::error!("Reading source files: {}.", err);
            return;
        }
    };

    files_stats.iter().for_each(|stats| {
        log::info!("{} stats:", stats.path);
        for mode in &stats_cmd.mode {
            match mode {
                StatsMode::Words => println!("\t- {} words", stats.words),
                StatsMode::Lines => println!("\t- {} lines", stats.lines),
                StatsMode::Bytes => println!("\t- {} bytes", stats.bytes),
            };
        }
    });
}

fn process_files(dirs: &[String]) -> Result<Vec<BookFileStats>, io::Error> {
    let mut files = Vec::with_capacity(10);
    for dir in dirs {
        process_files_stats(dir, &mut files)?;
    }
    Ok(files)
}

fn process_files_stats(dir: &str, files: &mut Vec<BookFileStats>) -> Result<(), io::Error> {
    let entries = fs::read_dir(dir)?;
    for entry in entries {
        let abs_path = fs::canonicalize(entry?.path())?;
        let abs_path_str = abs_path.to_string_lossy();
        let file_ext = abs_path.extension();
        if file_ext.map(|e| e == PathBuf::from("md")) != Some(true) {
            log::info!("Skipping '{}', unknown extension.", abs_path_str);
            continue;
        }

        log::info!("Processing stats for '{}'.", abs_path_str);
        let mut file = fs::OpenOptions::new()
            .read(true)
            .write(false)
            .create(false)
            .open(&abs_path)?;

        let mut file_contents = String::with_capacity(2000);
        let bytes = file.read_to_string(&mut file_contents)?;
        let lines = file_contents.lines().count();
        let words = file_contents.split_whitespace().count();

        log::debug!("Valid UTF-8 contents.");
        files.push(BookFileStats {
            path: abs_path_str.to_string(),
            lines,
            words,
            bytes,
        });
    }

    Ok(())
}

struct BookFileStats {
    path: String,
    lines: usize,
    words: usize,
    bytes: usize,
}
