module godot.tools.generator.common;

/// 
struct Settings {
    /// (Experimental) Should use classes over structs?
    bool useClasses;
}


//
__gshared Settings _settings;

///
const(Settings) settings() { return _settings; }

///
void setSettings(Settings newSettings) { _settings = newSettings; }
