use crate::cli::GenCommand;
use std::fmt::{Display, Formatter};
use std::io::{ErrorKind, Read, Write};
use std::path::PathBuf;
use std::{fs, io};

pub fn gen_cmd(dir: &str, gen_cmd: GenCommand) {
    log::info!("Generating final document.");

    let files_contents = match read_files(&dir) {
        Ok(files) => files,
        Err(err) => {
            log::error!("Error: reading source files: '{}'.", err);
            return;
        }
    };

    let result = match &gen_cmd.file {
        None => {
            log::info!("Start writing to standard output.");
            files_contents.into_iter().for_each(|f| print!("{}", f));
            Ok(())
        }
        Some(out_path) => {
            log::info!("Start writing to file '{}'.", out_path);
            write_to_file(out_path, gen_cmd.force, &files_contents)
        }
    };

    match result {
        Ok(_) => log::info!("Operation successful."),
        Err(err) => log::error!("{}.", err),
    };
}

fn read_files(dir: &str) -> Result<Vec<BookFile>, io::Error> {
    let mut files = Vec::with_capacity(10);

    let entries = fs::read_dir(dir)?;
    for entry in entries {
        let abs_path = fs::canonicalize(entry?.path())?;
        let abs_path_str = abs_path.to_string_lossy();
        let file_ext = abs_path.extension();
        if file_ext.map(|e| e == PathBuf::from("md")) != Some(true) {
            log::info!("Skipping '{}', unknown extension.", abs_path_str);
            continue;
        }

        log::info!("Processing '{}' doc.", abs_path_str);
        let mut file = fs::OpenOptions::new()
            .read(true)
            .write(false)
            .create(false)
            .open(&abs_path)?;

        let mut file_contents = String::with_capacity(2000);
        let n = file.read_to_string(&mut file_contents)?;
        log::debug!("\tRead {} bytes.", n);
        log::debug!("\tValid UTF-8 contents.");
        files.push(BookFile {
            contents: file_contents.to_owned(),
            path: abs_path,
            n_bytes: n,
        });
    }

    Ok(files)
}

fn write_to_file(out_path: &str, force: bool, files_contents: &[BookFile]) -> Result<(), String> {
    let mut file_opt = fs::OpenOptions::new();
    file_opt.read(false).write(true);
    let mut file = if force {
        file_opt.create(true).truncate(true)
    } else {
        file_opt.create_new(true)
    }
    .open(&out_path);

    let mut file = match file {
        Err(err) if err.kind() == ErrorKind::AlreadyExists => {
            return Err(format!(
                "file '{}' already exists (use --force to overwrite)",
                out_path
            ))
        }
        Err(err) => return Err(err.to_string()),
        Ok(f) => f,
    };

    for file_content in files_contents {
        let path_as_str = file_content.path.to_string_lossy();
        log::debug!("Writing '{}' to {}", path_as_str, out_path);
        match file.write_all(file_content.contents.as_bytes()) {
            Ok(_) => log::info!("Written {} successfully.", path_as_str),
            Err(err) => return Err(err.to_string()),
        }
    }

    Ok(())
}

struct BookFile {
    path: PathBuf,
    contents: String,
    n_bytes: usize,
}

impl Display for BookFile {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "==========================================================================================")?;
        writeln!(f, "Start of '{}'", self.path.to_string_lossy())?;
        writeln!(f,"==========================================================================================")?;
        writeln!(f, "{}", self.contents)
    }
}
