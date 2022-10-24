use log::Level;
use simple_logger::SimpleLogger;

pub fn init() {
    SimpleLogger::new()
        .with_level(Level::Debug.to_level_filter())
        .without_timestamps()
        .init()
        .unwrap()
}

pub fn set_max_level(lvl: Level) {
    log::set_max_level(lvl.to_level_filter())
}
