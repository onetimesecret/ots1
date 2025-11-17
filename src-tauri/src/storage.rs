use keyring::Entry;
use serde::{Deserialize, Serialize};
use thiserror::Error;

const SERVICE_NAME: &str = "dev.onetimesecret.desktop";

#[derive(Error, Debug)]
pub enum StorageError {
    #[error("Keyring error: {0}")]
    KeyringError(#[from] keyring::Error),
    #[error("Not found")]
    NotFound,
}

impl Serialize for StorageError {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

/// Store a value securely in the platform's credential store
///
/// Platform-specific backends:
/// - Windows: Windows Credential Manager (DPAPI)
/// - macOS: Keychain
/// - Linux: libsecret/kwallet
#[tauri::command]
pub fn store_secure(key: String, value: String) -> Result<(), StorageError> {
    let entry = Entry::new(SERVICE_NAME, &key)?;
    entry.set_password(&value)?;
    Ok(())
}

/// Retrieve a value from the platform's credential store
#[tauri::command]
pub fn retrieve_secure(key: String) -> Result<String, StorageError> {
    let entry = Entry::new(SERVICE_NAME, &key)?;
    match entry.get_password() {
        Ok(password) => Ok(password),
        Err(keyring::Error::NoEntry) => Err(StorageError::NotFound),
        Err(e) => Err(StorageError::KeyringError(e)),
    }
}

/// Delete a value from the platform's credential store
#[tauri::command]
pub fn delete_secure(key: String) -> Result<(), StorageError> {
    let entry = Entry::new(SERVICE_NAME, &key)?;
    entry.delete_password()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_store_and_retrieve() {
        let key = "test_key".to_string();
        let value = "test_value".to_string();

        // Store
        let store_result = store_secure(key.clone(), value.clone());
        assert!(store_result.is_ok());

        // Retrieve
        let retrieve_result = retrieve_secure(key.clone());
        assert!(retrieve_result.is_ok());
        assert_eq!(retrieve_result.unwrap(), value);

        // Cleanup
        let delete_result = delete_secure(key);
        assert!(delete_result.is_ok());
    }
}
