import Foundation

/// Type-safe access to all localizable strings in AgentsBoard.
///
/// Every key in `en.lproj/Localizable.strings` is exposed as a static property
/// or static function (for format strings). Views must use these accessors
/// instead of raw string literals — this satisfies the ISP rule that UI
/// components depend only on the narrow interface they need (a plain `String`).
public enum L10n {

    // MARK: - Bundle Resolution

    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        // SPM embeds resources in a synthesised Bundle.module
        return Bundle.module
        #else
        return Bundle.main
        #endif
    }()

    private static func tr(_ key: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: "")
    }

    // MARK: - General

    public static var cancel: String { tr("cancel") }
    public static var save: String { tr("save") }
    public static var delete: String { tr("delete") }
    public static var dismiss: String { tr("dismiss") }
    public static var create: String { tr("create") }
    public static var send: String { tr("send") }
    public static var remove: String { tr("remove") }
    public static var refresh: String { tr("refresh") }
    public static var approve: String { tr("approve") }
    public static var reject: String { tr("reject") }
    public static var copy: String { tr("copy") }

    // MARK: - App

    public enum App {
        public static var name: String { tr("app.name") }
        public static var subtitle: String { tr("app.subtitle") }
        public static var noActiveSessions: String { tr("app.no_active_sessions") }
        public static var launchSession: String { tr("app.launch_session") }
        public static var newSession: String { tr("app.new_session") }
        public static var openApp: String { tr("app.open_app") }
        public static var quit: String { tr("app.quit") }
    }

    // MARK: - Sidebar

    public enum Sidebar {
        public static var searchPlaceholder: String { tr("sidebar.search_placeholder") }
        public static var showArchived: String { tr("sidebar.show_archived") }
        public static var hideArchived: String { tr("sidebar.hide_archived") }
        public static var newSessionHint: String { tr("sidebar.new_session_hint") }
        public static var all: String { tr("sidebar.all") }
        public static var projects: String { tr("sidebar.projects") }
        public static var noProject: String { tr("sidebar.no_project") }
        public static var noProjectHint: String { tr("sidebar.no_project_hint") }
        public static var archived: String { tr("sidebar.archived") }
    }

    // MARK: - Session

    public enum Session {
        public static var edit: String { tr("session.edit") }
        public static var editTitle: String { tr("session.edit_title") }
        public static var editInfoHint: String { tr("session.edit_info_hint") }
        public static var moveUp: String { tr("session.move_up") }
        public static var moveDown: String { tr("session.move_down") }
        public static var archive: String { tr("session.archive") }
        public static var unarchive: String { tr("session.unarchive") }
        public static var delete: String { tr("session.delete") }
        /// "Delete \"<name>\"?"
        public static func deleteTitle(_ name: String) -> String {
            String(format: tr("session.delete_title"), name)
        }
        public static var deleteMessage: String { tr("session.delete_message") }
        public static var copyID: String { tr("session.copy_id") }
        public static var rename: String { tr("session.rename") }
        public static var kill: String { tr("session.kill") }
        public static var restart: String { tr("session.restart") }
        public static var remix: String { tr("session.remix") }
        public static var startRecording: String { tr("session.start_recording") }
        public static var stopRecording: String { tr("session.stop_recording") }
        public static var sectionSession: String { tr("session.section.session") }
        public static var sectionExecution: String { tr("session.section.execution") }
        public static var sectionGit: String { tr("session.section.git") }
        public static var namePlaceholder: String { tr("session.name_placeholder") }
        public static var commandPlaceholder: String { tr("session.command_placeholder") }
        public static var workdirPlaceholder: String { tr("session.workdir_placeholder") }
        public static var selectWorkdir: String { tr("session.select_workdir") }
    }

    // MARK: - Tabs

    public enum Tab {
        public static var terminal: String { tr("tab.terminal") }
        public static var activity: String { tr("tab.activity") }
        public static var info: String { tr("tab.info") }
        public static var files: String { tr("tab.files") }
        public static var diff: String { tr("tab.diff") }
        public static var restartTerminal: String { tr("tab.restart_terminal") }
    }

    // MARK: - Activity

    public enum Activity {
        public static var noActivity: String { tr("activity.no_activity") }
        public static var recent: String { tr("activity.recent") }
    }

    // MARK: - Info

    public enum Info {
        public static var provider: String { tr("info.provider") }
        public static var model: String { tr("info.model") }
        public static var state: String { tr("info.state") }
        public static var name: String { tr("info.name") }
        public static var sessionID: String { tr("info.session_id") }
        public static var command: String { tr("info.command") }
        public static var duration: String { tr("info.duration") }
        public static var cost: String { tr("info.cost") }
        public static var directory: String { tr("info.directory") }
        public static var branch: String { tr("info.branch") }
        public static var links: String { tr("info.links") }
    }

    // MARK: - Resources

    public enum Resources {
        public static var title: String { tr("resources.title") }
    }

    // MARK: - Terminal

    public enum Terminal {
        public static var waiting: String { tr("terminal.waiting") }
        public static var noOutput: String { tr("terminal.no_output") }
        public static var selectToActivate: String { tr("terminal.select_to_activate") }
        public static var noWorkdir: String { tr("terminal.no_workdir") }
        public static var increaseFont: String { tr("terminal.increase_font") }
        public static var decreaseFont: String { tr("terminal.decrease_font") }
        public static var resetFont: String { tr("terminal.reset_font") }
        public static var toggleHint: String { tr("terminal.toggle_hint") }
    }

    // MARK: - Fleet

    public enum Fleet {
        public static var title: String { tr("fleet.title") }
        public static var total: String { tr("fleet.total") }
        public static var active: String { tr("fleet.active") }
        public static var needsInput: String { tr("fleet.needs_input") }
        public static var errors: String { tr("fleet.errors") }
        public static var totalCost: String { tr("fleet.total_cost") }
        public static var provider: String { tr("fleet.provider") }
        public static var state: String { tr("fleet.state") }
    }

    // MARK: - Activity Log

    public enum ActivityLog {
        public static var title: String { tr("activity_log.title") }
        public static var lastHour: String { tr("activity_log.last_hour") }
        public static var today: String { tr("activity_log.today") }
        public static var all: String { tr("activity_log.all") }
        public static var files: String { tr("activity_log.files") }
        public static var commands: String { tr("activity_log.commands") }
        public static var errors: String { tr("activity_log.errors") }
        public static var costs: String { tr("activity_log.costs") }
    }

    // MARK: - Command Palette

    public enum Palette {
        public static var placeholder: String { tr("palette.placeholder") }
        public static var all: String { tr("palette.all") }
        public static var navigate: String { tr("palette.navigate") }
        public static var execute: String { tr("palette.execute") }
        public static var dismiss: String { tr("palette.dismiss") }
        public static var commands: String { tr("palette.commands") }
    }

    // MARK: - Diff

    public enum Diff {
        public static var unified: String { tr("diff.unified") }
        public static var sideBySide: String { tr("diff.side_by_side") }
        public static var loading: String { tr("diff.loading") }
        public static var noChanges: String { tr("diff.no_changes") }
        public static var rejectTitle: String { tr("diff.reject_title") }
        /// "This will discard all unstaged changes in <path>. This cannot be undone."
        public static func rejectMessage(_ path: String) -> String {
            String(format: tr("diff.reject_message"), path)
        }
        public static var changesStaged: String { tr("diff.changes_staged") }
        public static var changesDiscarded: String { tr("diff.changes_discarded") }
        public static var discardChanges: String { tr("diff.discard_changes") }
    }

    // MARK: - Recordings

    public enum Recording {
        public static var recordings: String { tr("recording.recordings") }
        public static var none: String { tr("recording.none") }
    }

    // MARK: - Search

    public enum Search {
        public static var placeholder: String { tr("search.placeholder") }
        public static var all: String { tr("search.all") }
        public static var output: String { tr("search.output") }
        public static var files: String { tr("search.files") }
        public static var activity: String { tr("search.activity") }
        public static var noResults: String { tr("search.no_results") }
        public static var results: String { tr("search.results") }
    }

    // MARK: - Plan

    public enum Plan {
        public static var title: String { tr("plan.title") }
        public static var tasks: String { tr("plan.tasks") }
    }

    // MARK: - Diagram

    public enum Diagram {
        public static var title: String { tr("diagram.title") }
        public static var `default`: String { tr("diagram.default") }
        public static var dark: String { tr("diagram.dark") }
        public static var forest: String { tr("diagram.forest") }
        public static var neutral: String { tr("diagram.neutral") }
        public static var export: String { tr("diagram.export") }
        public static var noDiagram: String { tr("diagram.no_diagram") }
    }

    // MARK: - Drag & Drop

    public enum Drop {
        public static var filesAttached: String { tr("drop.files_attached") }
        public static var dropHere: String { tr("drop.drop_here") }
        public static var unsupported: String { tr("drop.unsupported") }
    }

    // MARK: - Launcher

    public enum Launcher {
        public static var title: String { tr("launcher.title") }
        public static var addSession: String { tr("launcher.add_session") }
        public static var cloneTitle: String { tr("launcher.clone_title") }
        public static var cloneButton: String { tr("launcher.clone_button") }
        public static var cloneDestination: String { tr("launcher.clone_destination") }
        public static var enterCommand: String { tr("launcher.enter_command") }
        /// "Launch <name>"
        public static func launch(_ name: String) -> String {
            String(format: tr("launcher.launch"), name)
        }
    }

    // MARK: - Smart Mode

    public enum Smart {
        public static var title: String { tr("smart.title") }
        public static var description: String { tr("smart.description") }
        public static var placeholder: String { tr("smart.placeholder") }
        public static var workdir: String { tr("smart.workdir") }
        public static var plan: String { tr("smart.plan") }
        public static var recommended: String { tr("smart.recommended") }
        /// "<percent> match"
        public static func match(_ percent: String) -> String {
            String(format: tr("smart.match"), percent)
        }
    }

    // MARK: - Remix

    public enum Remix {
        public static var title: String { tr("remix.title") }
        /// "Fork \"<name>\" into an isolated branch"
        public static func forkMessage(_ name: String) -> String {
            String(format: tr("remix.fork_message"), name)
        }
        public static var sectionBranch: String { tr("remix.section.branch") }
        public static var sectionNewSession: String { tr("remix.section.new_session") }
        public static var sectionContext: String { tr("remix.section.context") }
        public static var button: String { tr("remix.button") }
    }

    // MARK: - Worktree

    public enum Worktree {
        public static var title: String { tr("worktree.title") }
        public static var createHint: String { tr("worktree.create_hint") }
        public static var refreshHint: String { tr("worktree.refresh_hint") }
        public static var none: String { tr("worktree.none") }
        public static var openSession: String { tr("worktree.open_session") }
        public static var revealFinder: String { tr("worktree.reveal_finder") }
        public static var delete: String { tr("worktree.delete") }
    }

    // MARK: - Menu Bar

    public enum MenuBar {
        public static var costByProvider: String { tr("menubar.cost_by_provider") }
        public static var noSessions: String { tr("menubar.no_sessions") }
        public static var newSession: String { tr("menubar.new_session") }
    }

    // MARK: - File Explorer

    public enum FileExplorer {
        public static var workspace: String { tr("file_explorer.workspace") }
    }

    // MARK: - Editor

    public enum Editor {
        public static var selectFile: String { tr("editor.select_file") }
    }

    // MARK: - Navigation

    public enum Nav {
        public static var launchSessionHint: String { tr("nav.launch_session_hint") }
    }

    // MARK: - Appearance

    public enum Appearance {
        public static var light: String { tr("appearance.light") }
        public static var dark: String { tr("appearance.dark") }
        public static var auto: String { tr("appearance.auto") }
    }
}
