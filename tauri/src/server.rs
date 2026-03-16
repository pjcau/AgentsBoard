// Manages the AgentsBoardServer Swift sidecar process.

use std::process::{Child, Command};
use std::sync::Mutex;
use tauri::AppHandle;

pub struct ServerHandle {
    process: Mutex<Option<Child>>,
}

impl ServerHandle {
    pub fn is_running(&self) -> bool {
        self.process
            .lock()
            .map(|mut p| {
                p.as_mut()
                    .map(|c| c.try_wait().ok().flatten().is_none())
                    .unwrap_or(false)
            })
            .unwrap_or(false)
    }

    pub fn stop(&self) {
        if let Ok(mut guard) = self.process.lock() {
            if let Some(ref mut child) = *guard {
                let _ = child.kill();
                let _ = child.wait();
            }
            *guard = None;
        }
    }

    pub fn restart(&self) {
        self.stop();
        if let Ok(mut guard) = self.process.lock() {
            *guard = spawn_server();
        }
    }
}

impl Drop for ServerHandle {
    fn drop(&mut self) {
        self.stop();
    }
}

pub fn start_server(_app: AppHandle) -> ServerHandle {
    let process = spawn_server();
    ServerHandle {
        process: Mutex::new(process),
    }
}

fn spawn_server() -> Option<Child> {
    // Look for AgentsBoardServer binary in common locations
    let candidates = [
        "AgentsBoardServer",
        "./AgentsBoardServer",
        "/usr/local/bin/agentsboard-server",
    ];

    for path in &candidates {
        match Command::new(path)
            .env("AGENTSBOARD_HOST", "127.0.0.1")
            .env("AGENTSBOARD_PORT", "19850")
            .spawn()
        {
            Ok(child) => {
                println!("[Tauri] Started AgentsBoardServer (PID {})", child.id());
                return Some(child);
            }
            Err(_) => continue,
        }
    }

    eprintln!("[Tauri] Warning: Could not find AgentsBoardServer binary");
    None
}
