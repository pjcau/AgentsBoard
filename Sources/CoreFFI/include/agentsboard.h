// AgentsBoard C FFI — Public API Header
// This header is consumed by Qt/C++ on Linux and Windows.
// All types are opaque handles; no Swift internals leak to C.

#ifndef AGENTSBOARD_H
#define AGENTSBOARD_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// MARK: - Opaque Handles

typedef void* ABCore;
typedef void* ABSession;

// MARK: - Enum Constants

// ABProvider
#define AB_PROVIDER_CLAUDE  0
#define AB_PROVIDER_CODEX   1
#define AB_PROVIDER_AIDER   2
#define AB_PROVIDER_GEMINI  3
#define AB_PROVIDER_CUSTOM  4

// ABAgentState
#define AB_STATE_WORKING     0
#define AB_STATE_NEEDS_INPUT 1
#define AB_STATE_ERROR       2
#define AB_STATE_INACTIVE    3

// ABLayoutMode
#define AB_LAYOUT_SINGLE       0
#define AB_LAYOUT_LIST         1
#define AB_LAYOUT_TWO_COLUMN   2
#define AB_LAYOUT_THREE_COLUMN 3
#define AB_LAYOUT_FLEET        4

// ABFleetEventType
#define AB_FLEET_SESSION_ADDED   0
#define AB_FLEET_SESSION_REMOVED 1
#define AB_FLEET_SESSION_UPDATED 2
#define AB_FLEET_STATS_CHANGED   3

// ABSessionEventType
#define AB_SESSION_STATE_CHANGED 0
#define AB_SESSION_OUTPUT        1
#define AB_SESSION_COST_UPDATED  2

// MARK: - Callbacks

/// Fleet callback: receives event_type (AB_FLEET_*) and user context.
typedef void (*ABFleetCallback)(int32_t event_type, void* context);

/// Session callback: receives event_type (AB_SESSION_*) and user context.
typedef void (*ABSessionCallback)(int32_t event_type, void* context);

// MARK: - Core Lifecycle

/// Create a new Core instance. Returns NULL on failure.
/// Caller owns the returned handle; must call ab_core_destroy().
ABCore ab_core_create(void);

/// Destroy a Core instance and release all resources.
void ab_core_destroy(ABCore core);

// MARK: - Fleet Operations

/// Get fleet stats via out-parameters.
/// out_counts: array of 4 int32_t [total, active, needs_input, error]
/// out_cost: pointer to total fleet cost (double)
void ab_fleet_get_stats(ABCore core, int32_t* out_counts, double* out_cost);

/// Get the number of sessions in the fleet.
int32_t ab_fleet_session_count(ABCore core);

/// Get a session handle by fleet index (0-based).
/// Returns NULL if index is out of range.
/// The returned handle is borrowed — do NOT free it.
ABSession ab_fleet_get_session(ABCore core, int32_t index);

/// Get a session handle by ID. Returns NULL if not found.
ABSession ab_fleet_get_session_by_id(ABCore core, const char* session_id);

/// Register a callback for fleet events. Pass NULL to unregister.
void ab_fleet_set_callback(ABCore core, ABFleetCallback callback, void* context);

// MARK: - Session Operations

/// Create a new session. Returns a session handle, or NULL on failure.
ABSession ab_session_create(ABCore core,
                            const char* command,
                            const char* name,
                            const char* workdir);

/// Send input text to a session's terminal.
void ab_session_send_input(ABSession session, const char* input, int32_t len);

/// Get the current agent state (AB_STATE_*).
int32_t ab_session_get_state(ABSession session);

/// Get the agent provider (AB_PROVIDER_*).
int32_t ab_session_get_provider(ABSession session);

/// Get the session's unique identifier. Borrowed string.
const char* ab_session_get_id(ABSession session);

/// Get the session's display name. Borrowed string.
const char* ab_session_get_name(ABSession session);

/// Get the session's project path. May return NULL.
const char* ab_session_get_project_path(ABSession session);

/// Get accumulated cost for this session.
double ab_session_get_cost(ABSession session);

/// Get the session start time as Unix timestamp.
double ab_session_get_start_time(ABSession session);

/// Get terminal output text. Borrowed string.
const char* ab_session_get_output(ABSession session);

/// Get output length in bytes.
int32_t ab_session_get_output_length(ABSession session);

/// Register a callback for session-specific events.
void ab_session_set_callback(ABSession session, ABSessionCallback callback, void* context);

/// Archive a session (hide but preserve).
void ab_session_archive(ABCore core, const char* session_id);

/// Unarchive a session.
void ab_session_unarchive(ABCore core, const char* session_id);

/// Delete a session permanently.
void ab_session_delete(ABCore core, const char* session_id);

/// Destroy a session handle (only for handles returned by ab_session_create).
void ab_session_destroy(ABSession session);

// MARK: - Configuration

/// Load configuration from a YAML file path. Returns true on success.
bool ab_config_load(ABCore core, const char* path);

/// Get current theme name. Borrowed string.
const char* ab_config_get_theme(ABCore core);

/// Get current layout mode (AB_LAYOUT_*).
int32_t ab_config_get_layout(ABCore core);

/// Set layout mode.
void ab_config_set_layout(ABCore core, int32_t mode);

/// Get font size.
double ab_config_get_font_size(ABCore core);

/// Set font size.
void ab_config_set_font_size(ABCore core, double size);

// MARK: - Cost Tracking

/// Get fleet-wide total cost.
double ab_cost_get_fleet_total(ABCore core);

/// Get cost for a specific session.
double ab_cost_get_session_total(ABCore core, const char* session_id);

/// Get current burn rate (cost per hour).
double ab_cost_get_burn_rate(ABCore core);

// MARK: - Terminal Operations

/// Launch the session's terminal process.
/// command: shell command (e.g. "claude", "/bin/bash")
/// workdir: working directory (may be NULL)
/// Returns true if launch succeeded.
bool ab_terminal_launch(ABSession session, const char* command, const char* workdir);

/// Resize the terminal.
void ab_terminal_resize(ABSession session, int32_t columns, int32_t rows);

/// Check if the terminal process is running.
bool ab_terminal_is_running(ABSession session);

/// Terminate the terminal process.
void ab_terminal_terminate(ABSession session);

/// Terminal data callback: receives raw output bytes from PTY.
/// data is borrowed; copy it if needed beyond the callback scope.
typedef void (*ABTerminalDataCallback)(const char* session_id,
                                       const uint8_t* data, int32_t len,
                                       void* context);

/// Terminal exit callback: receives session_id and exit code.
typedef void (*ABTerminalExitCallback)(const char* session_id,
                                       int32_t exit_code,
                                       void* context);

/// Register terminal output/exit callbacks for a session.
void ab_terminal_set_callbacks(ABSession session,
                                ABTerminalDataCallback on_data,
                                ABTerminalExitCallback on_exit,
                                void* context);

// MARK: - Activity Log

/// Get the number of activity events for a session (or all if session_id is NULL).
int32_t ab_activity_count(ABCore core, const char* session_id);

/// Get activity event details by index. Returns false if out of range.
/// out_type: event type string (borrowed), out_details: details string (borrowed),
/// out_timestamp: Unix timestamp, out_cost: cost delta (0 if none).
bool ab_activity_get_event(ABCore core, const char* session_id, int32_t index,
                            const char** out_type, const char** out_details,
                            double* out_timestamp, double* out_cost);

// MARK: - Version

/// Get the library version string. Static string, never freed.
const char* ab_version(void);

#ifdef __cplusplus
}
#endif

#endif // AGENTSBOARD_H
