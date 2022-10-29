use env_logger::fmt::Color;
use log::{Level, LevelFilter};
use std::io::Write;

pub fn init() {
    env_logger::builder()
        .filter_level(LevelFilter::Trace)
        .format(|buf, record| {
            let mut level_style = buf.style();
            level_style.set_bold(true).set_intense(true);
            match record.level() {
                Level::Error => level_style.set_color(Color::Red),
                Level::Warn => level_style.set_color(Color::Yellow),
                Level::Info => level_style.set_color(Color::Rgb(100, 220, 100)),
                Level::Debug => level_style.set_color(Color::Magenta),
                Level::Trace => level_style.set_color(Color::Blue),
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
