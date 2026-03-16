// Tauri IPC commands exposed to the web frontend.

use crate::server::ServerHandle;
use tauri::State;

#[tauri::command]
pub fn get_server_status(server: State<'_, ServerHandle>) -> bool {
    server.is_running()
}

#[tauri::command]
pub fn restart_server(server: State<'_, ServerHandle>) -> bool {
    server.restart();
    server.is_running()
}
