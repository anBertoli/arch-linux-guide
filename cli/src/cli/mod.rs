mod gen;
mod stats;

use crate::logs;
use clap::{ArgAction, Args, Parser, Subcommand, ValueEnum};
use log::Level;

pub fn run_cli() {
    logs::init();
    let cli: Cli = Cli::parse();
    if !cli.verbose {
        logs::set_max_level(Level::Info);
    }
    log::debug!("{:?}", cli);
    match cli.command {
        SubCommand::Gen(cmd) => gen::gen_cmd(&cli.source_dir, cmd),
        SubCommand::Stats(cmd) => stats::stats_cmd(&cli.source_dir, cmd),
    }
}

#[derive(Parser, Debug)]
#[command(name = "arch-cli", author, version, about)]
#[command(propagate_version = true)]
pub struct Cli {
    /// The directories containing the desired chapters.
    #[arg(long, short, required = true)]
    #[arg(action = ArgAction::Append, value_delimiter = ',')]
    source_dir: Vec<String>,

    /// Enable/disable verbose logs.
    #[arg(short, long, global = true)]
    verbose: bool,

    /// Force operation (do it at your own risk).
    #[arg(long, global = true)]
    force: bool,

    #[command(subcommand)]
    command: SubCommand,
}

#[derive(Debug, Subcommand)]
pub enum SubCommand {
    /// Generate the book from the chapter files.
    Gen(GenCommand),
    /// Calculate statistics about the book.
    Stats(StatsCommand),
}

#[derive(Debug, Args)]
pub struct GenCommand {
    /// Write to file instead of standard output.
    #[arg(short, long, required = false)]
    file: Option<String>,

    #[arg(from_global)]
    force: bool,
    #[arg(from_global)]
    verbose: bool,
}

#[derive(Debug, Args)]
pub struct StatsCommand {
    #[arg(short, long, value_enum, required = true)]
    #[arg(action = ArgAction::Append, value_delimiter = ',')]
    mode: Vec<StatsMode>,

    #[arg(from_global)]
    force: bool,
    #[arg(from_global)]
    verbose: bool,
}

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord, ValueEnum)]
pub enum StatsMode {
    Words,
    Lines,
    Bytes,
}
