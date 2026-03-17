// AgentsBoard Tauri entry point
// Launches Swift server as sidecar, wraps web frontend in native window.

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::Manager;

mod server;
mod tray;
mod commands;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Launch AgentsBoardServer as a sidecar process
            let server_handle = server::start_server(app.handle().clone());
            app.manage(server_handle);

            // Setup system tray
            tray::setup_tray(app)?;

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_server_status,
            commands::restart_server,
        ])
        .run(tauri::generate_context!())
        .expect("error while running AgentsBoard");
}
