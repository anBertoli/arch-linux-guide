use env_logger::fmt::Color;
use log::{Level, LevelFilter};
use std::io::Write;

pub fn init() {
    env_logger::builder()
        .filter_level(LevelFilter::Trace)
        .format(|buf, record| {
            let mut level_style = buf.style();
            match record.level() {
                Level::Error => level_style.set_color(Color::Red).set_bold(true),
                Level::Warn => level_style.set_color(Color::Yellow).set_bold(true),
                Level::Info => level_style.set_color(Color::Green).set_bold(true),
                Level::Debug => level_style.set_color(Color::Magenta).set_bold(true),
                Level::Trace => level_style.set_color(Color::Blue).set_bold(true),
            };
            writeln!(
                buf,
                "{:<5} {}",
                level_style.value(record.level()),
                record.args(),
            )
        })
        .init();
}

pub fn set_max_level(lvl: Level) {
    log::set_max_level(lvl.to_level_filter())
}
