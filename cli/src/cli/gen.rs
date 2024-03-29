use crate::cli::GenCommand;
use std::fmt::{Display, Formatter};
use std::io::{ErrorKind, Read, Write};
use std::path::PathBuf;
use std::{fs, io};

pub fn gen_cmd(dirs: &[String], gen_cmd: GenCommand) {
    log::info!("Starting document generation.");

    let files_contents = match read_files(&dirs) {
        Ok(files) => files,
        Err(err) => {
            log::error!("Reading source files: {}.", err);
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
            write_to_file(&gen_cmd, &files_contents)
        }
    };

    match result {
        Ok(_) => log::info!("Operation successful."),
        Err(err) if err.kind() == ErrorKind::AlreadyExists => log::error!(
            "File '{}' already exists (use --force to overwrite)",
            &gen_cmd.file.unwrap()
        ),
        Err(err) => log::error!("{}.", err),
    };
}

fn read_files(dirs: &[String]) -> Result<Vec<BookFile>, io::Error> {
    let mut files = Vec::with_capacity(10);

    for dir in dirs {
        log::debug!("Start reading directory '{}'.", dir);
        let dir_files = read_files_in_dir(dir)?;
        files.extend(dir_files);
    }

    Ok(files)
}

fn read_files_in_dir(dir: &str) -> Result<Vec<BookFile>, io::Error> {
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
        log::debug!("Read {} bytes.", n);
        log::debug!("Valid UTF-8 contents.");
        files.push(BookFile {
            contents: file_contents.to_owned(),
            path: abs_path,
        });
    }

    files.sort_by(|i, j| i.path.cmp(&j.path));
    Ok(files)
}

fn write_to_file(gen_cmd: &GenCommand, files: &[BookFile]) -> Result<(), io::Error> {
    let dest_file_path = gen_cmd.file.as_ref().unwrap();
    let mut file_opt = fs::OpenOptions::new();
    file_opt.read(false).write(true);
    let mut file = if gen_cmd.force {
        file_opt.create(true).truncate(true)
    } else {
        file_opt.create_new(true)
    }
    .open(dest_file_path)?;

    for file_content in files {
        let path_as_str = file_content.path.to_string_lossy();
        log::debug!("Writing '{}' to {}", path_as_str, dest_file_path);

        let mut file_contents: String = (&gen_cmd.replace).iter().fold(
            file_content.contents.clone(),
            |contents, (from, to)| {
                log::debug!("Replacing '{}' with '{}'", from, to);
                return contents.replace(from, to);
            },
        );

        file_contents.push('\n');
        let bytes = file_contents.as_bytes();
        match file.write_all(bytes) {
            Err(err) => return Err(err),
            Ok(_) => log::info!(
                "Written {} successfully ({} bytes).",
                path_as_str,
                bytes.len()
            ),
        }
    }

    Ok(())
}

struct BookFile {
    path: PathBuf,
    contents: String,
}

impl Display for BookFile {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        writeln!(f, "==========================================================================================")?;
        writeln!(f, "Start of '{}'", self.path.to_string_lossy())?;
        writeln!(f,"==========================================================================================")?;
        writeln!(f, "{}", self.contents)
    }
}
