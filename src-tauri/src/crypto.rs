use rand::Rng;
use serde::{Deserialize, Serialize};

const WORD_LIST: &[&str] = &[
    "correct", "horse", "battery", "staple", "monkey", "dragon", "castle", "sunset",
    "ocean", "mountain", "forest", "river", "thunder", "lightning", "rainbow", "crystal",
    "phoenix", "wizard", "knight", "sword", "shield", "armor", "treasure", "adventure",
    "journey", "quest", "magic", "wonder", "dream", "star", "moon", "sun", "cloud",
    "wind", "fire", "water", "earth", "stone", "metal", "wood", "flower", "garden",
    "butterfly", "eagle", "lion", "tiger", "wolf", "bear", "dolphin", "whale", "shark",
];

#[derive(Serialize, Deserialize)]
pub struct PassphraseOptions {
    pub word_count: usize,
    pub separator: String,
}

/// Generate a random passphrase using the XKCD-style word list
///
/// This creates memorable but secure passphrases like "correct-horse-battery-staple"
#[tauri::command]
pub fn generate_passphrase(options: PassphraseOptions) -> Result<String, String> {
    if options.word_count < 3 || options.word_count > 10 {
        return Err("Word count must be between 3 and 10".to_string());
    }

    let mut rng = rand::thread_rng();
    let words: Vec<&str> = (0..options.word_count)
        .map(|_| WORD_LIST[rng.gen_range(0..WORD_LIST.len())])
        .collect();

    Ok(words.join(&options.separator))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_passphrase() {
        let options = PassphraseOptions {
            word_count: 4,
            separator: "-".to_string(),
        };

        let result = generate_passphrase(options);
        assert!(result.is_ok());

        let passphrase = result.unwrap();
        let words: Vec<&str> = passphrase.split('-').collect();
        assert_eq!(words.len(), 4);
    }

    #[test]
    fn test_invalid_word_count() {
        let options = PassphraseOptions {
            word_count: 2,
            separator: "-".to_string(),
        };

        let result = generate_passphrase(options);
        assert!(result.is_err());
    }
}
