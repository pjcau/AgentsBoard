import Foundation

/// Type-safe access to all localizable strings in AgentsBoard.
///
/// Every key in `en.lproj/Localizable.strings` is exposed as a static property
/// or static function (for format strings). Views must use these accessors
/// instead of raw string literals — this satisfies the ISP rule that UI
/// components depend only on the narrow interface they need (a plain `String`).
enum L10n {

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

    static var cancel: String { tr("cancel") }
    static var save: String { tr("save") }
    static var delete: String { tr("delete") }
    static var dismiss: String { tr("dismiss") }
    static var create: String { tr("create") }
    static var send: String { tr("send") }
    static var remove: String { tr("remove") }
    static var refresh: String { tr("refresh") }
    static var approve: String { tr("approve") }
    static var reject: String { tr("reject") }
    static var copy: String { tr("copy") }

    // MARK: - App

    enum App {
        static var name: String { tr("app.name") }
        static var subtitle: String { tr("app.subtitle") }
        static var noActiveSessions: String { tr("app.no_active_sessions") }
        static var launchSession: String { tr("app.launch_session") }
        static var newSession: String { tr("app.new_session") }
        static var openApp: String { tr("app.open_app") }
        static var quit: String { tr("app.quit") }
        static var checkForUpdates: String { tr("app.check_for_updates") }
        static var updateTitle: String { tr("app.update_title") }
        static var currentVersion: String { tr("app.current_version") }
        static var checkingForUpdates: String { tr("app.checking_for_updates") }
        static var upToDate: String { tr("app.up_to_date") }
        static var updateAvailable: String { tr("app.update_available") }
        static var installingUpdate: String { tr("app.installing_update") }
        static var doNotClose: String { tr("app.do_not_close") }
        static var restarting: String { tr("app.restarting") }
        static var updateError: String { tr("app.update_error") }
        static var updateNow: String { tr("app.update_now") }
        static var recheckUpdates: String { tr("app.recheck_updates") }
        static var close: String { tr("app.close") }
    }

    // MARK: - Sidebar

    enum Sidebar {
        static var searchPlaceholder: String { tr("sidebar.search_placeholder") }
        static var showArchived: String { tr("sidebar.show_archived") }
        static var hideArchived: String { tr("sidebar.hide_archived") }
        static var newSessionHint: String { tr("sidebar.new_session_hint") }
        static var all: String { tr("sidebar.all") }
        static var projects: String { tr("sidebar.projects") }
        static var noProject: String { tr("sidebar.no_project") }
        static var noProjectHint: String { tr("sidebar.no_project_hint") }
        static var archived: String { tr("sidebar.archived") }
    }

    // MARK: - Session

    enum Session {
        static var edit: String { tr("session.edit") }
        static var editTitle: String { tr("session.edit_title") }
        static var editInfoHint: String { tr("session.edit_info_hint") }
        static var moveUp: String { tr("session.move_up") }
        static var moveDown: String { tr("session.move_down") }
        static var archive: String { tr("session.archive") }
        static var unarchive: String { tr("session.unarchive") }
        static var delete: String { tr("session.delete") }
        /// "Delete \"<name>\"?"
        static func deleteTitle(_ name: String) -> String {
            String(format: tr("session.delete_title"), name)
        }
        static var deleteMessage: String { tr("session.delete_message") }
        static var copyID: String { tr("session.copy_id") }
        static var rename: String { tr("session.rename") }
        static var kill: String { tr("session.kill") }
        static var restart: String { tr("session.restart") }
        static var remix: String { tr("session.remix") }
        static var startRecording: String { tr("session.start_recording") }
        static var stopRecording: String { tr("session.stop_recording") }
        static var sectionSession: String { tr("session.section.session") }
        static var sectionExecution: String { tr("session.section.execution") }
        static var sectionGit: String { tr("session.section.git") }
        static var namePlaceholder: String { tr("session.name_placeholder") }
        static var commandPlaceholder: String { tr("session.command_placeholder") }
        static var workdirPlaceholder: String { tr("session.workdir_placeholder") }
        static var selectWorkdir: String { tr("session.select_workdir") }
    }

    // MARK: - Tabs

    enum Tab {
        static var terminal: String { tr("tab.terminal") }
        static var activity: String { tr("tab.activity") }
        static var info: String { tr("tab.info") }
        static var files: String { tr("tab.files") }
        static var diff: String { tr("tab.diff") }
        static var restartTerminal: String { tr("tab.restart_terminal") }
    }

    // MARK: - Activity

    enum Activity {
        static var noActivity: String { tr("activity.no_activity") }
        static var recent: String { tr("activity.recent") }
    }

    // MARK: - Info

    enum Info {
        static var provider: String { tr("info.provider") }
        static var model: String { tr("info.model") }
        static var state: String { tr("info.state") }
        static var name: String { tr("info.name") }
        static var sessionID: String { tr("info.session_id") }
        static var command: String { tr("info.command") }
        static var duration: String { tr("info.duration") }
        static var cost: String { tr("info.cost") }
        static var directory: String { tr("info.directory") }
        static var branch: String { tr("info.branch") }
        static var links: String { tr("info.links") }
    }

    // MARK: - Resources

    enum Resources {
        static var title: String { tr("resources.title") }
    }

    // MARK: - Terminal

    enum Terminal {
        static var waiting: String { tr("terminal.waiting") }
        static var noOutput: String { tr("terminal.no_output") }
        static var selectToActivate: String { tr("terminal.select_to_activate") }
        static var noWorkdir: String { tr("terminal.no_workdir") }
        static var increaseFont: String { tr("terminal.increase_font") }
        static var decreaseFont: String { tr("terminal.decrease_font") }
        static var resetFont: String { tr("terminal.reset_font") }
        static var toggleHint: String { tr("terminal.toggle_hint") }
    }

    // MARK: - Fleet

    enum Fleet {
        static var title: String { tr("fleet.title") }
        static var total: String { tr("fleet.total") }
        static var active: String { tr("fleet.active") }
        static var needsInput: String { tr("fleet.needs_input") }
        static var errors: String { tr("fleet.errors") }
        static var totalCost: String { tr("fleet.total_cost") }
        static var provider: String { tr("fleet.provider") }
        static var state: String { tr("fleet.state") }
    }

    // MARK: - Activity Log

    enum ActivityLog {
        static var title: String { tr("activity_log.title") }
        static var lastHour: String { tr("activity_log.last_hour") }
        static var today: String { tr("activity_log.today") }
        static var all: String { tr("activity_log.all") }
        static var files: String { tr("activity_log.files") }
        static var commands: String { tr("activity_log.commands") }
        static var errors: String { tr("activity_log.errors") }
        static var costs: String { tr("activity_log.costs") }
    }

    // MARK: - Command Palette

    enum Palette {
        static var placeholder: String { tr("palette.placeholder") }
        static var all: String { tr("palette.all") }
        static var navigate: String { tr("palette.navigate") }
        static var execute: String { tr("palette.execute") }
        static var dismiss: String { tr("palette.dismiss") }
        static var commands: String { tr("palette.commands") }
    }

    // MARK: - Diff

    enum Diff {
        static var unified: String { tr("diff.unified") }
        static var sideBySide: String { tr("diff.side_by_side") }
        static var loading: String { tr("diff.loading") }
        static var noChanges: String { tr("diff.no_changes") }
        static var rejectTitle: String { tr("diff.reject_title") }
        /// "This will discard all unstaged changes in <path>. This cannot be undone."
        static func rejectMessage(_ path: String) -> String {
            String(format: tr("diff.reject_message"), path)
        }
        static var changesStaged: String { tr("diff.changes_staged") }
        static var changesDiscarded: String { tr("diff.changes_discarded") }
        static var discardChanges: String { tr("diff.discard_changes") }
    }

    // MARK: - Recordings

    enum Recording {
        static var recordings: String { tr("recording.recordings") }
        static var none: String { tr("recording.none") }
    }

    // MARK: - Search

    enum Search {
        static var placeholder: String { tr("search.placeholder") }
        static var all: String { tr("search.all") }
        static var output: String { tr("search.output") }
        static var files: String { tr("search.files") }
        static var activity: String { tr("search.activity") }
        static var noResults: String { tr("search.no_results") }
        static var results: String { tr("search.results") }
    }

    // MARK: - Plan

    enum Plan {
        static var title: String { tr("plan.title") }
        static var tasks: String { tr("plan.tasks") }
    }

    // MARK: - Diagram

    enum Diagram {
        static var title: String { tr("diagram.title") }
        static var `default`: String { tr("diagram.default") }
        static var dark: String { tr("diagram.dark") }
        static var forest: String { tr("diagram.forest") }
        static var neutral: String { tr("diagram.neutral") }
        static var export: String { tr("diagram.export") }
        static var noDiagram: String { tr("diagram.no_diagram") }
    }

    // MARK: - Drag & Drop

    enum Drop {
        static var filesAttached: String { tr("drop.files_attached") }
        static var dropHere: String { tr("drop.drop_here") }
        static var unsupported: String { tr("drop.unsupported") }
    }

    // MARK: - Launcher

    enum Launcher {
        static var title: String { tr("launcher.title") }
        static var addSession: String { tr("launcher.add_session") }
        static var enterCommand: String { tr("launcher.enter_command") }
        /// "Launch <name>"
        static func launch(_ name: String) -> String {
            String(format: tr("launcher.launch"), name)
        }
    }

    // MARK: - Smart Mode

    enum Smart {
        static var title: String { tr("smart.title") }
        static var description: String { tr("smart.description") }
        static var placeholder: String { tr("smart.placeholder") }
        static var workdir: String { tr("smart.workdir") }
        static var plan: String { tr("smart.plan") }
        static var recommended: String { tr("smart.recommended") }
        /// "<percent> match"
        static func match(_ percent: String) -> String {
            String(format: tr("smart.match"), percent)
        }
    }

    // MARK: - Remix

    enum Remix {
        static var title: String { tr("remix.title") }
        /// "Fork \"<name>\" into an isolated branch"
        static func forkMessage(_ name: String) -> String {
            String(format: tr("remix.fork_message"), name)
        }
        static var sectionBranch: String { tr("remix.section.branch") }
        static var sectionNewSession: String { tr("remix.section.new_session") }
        static var sectionContext: String { tr("remix.section.context") }
        static var button: String { tr("remix.button") }
    }

    // MARK: - Worktree

    enum Worktree {
        static var title: String { tr("worktree.title") }
        static var createHint: String { tr("worktree.create_hint") }
        static var refreshHint: String { tr("worktree.refresh_hint") }
        static var none: String { tr("worktree.none") }
        static var openSession: String { tr("worktree.open_session") }
        static var revealFinder: String { tr("worktree.reveal_finder") }
        static var delete: String { tr("worktree.delete") }
    }

    // MARK: - Menu Bar

    enum MenuBar {
        static var costByProvider: String { tr("menubar.cost_by_provider") }
        static var noSessions: String { tr("menubar.no_sessions") }
        static var newSession: String { tr("menubar.new_session") }
    }

    // MARK: - File Explorer

    enum FileExplorer {
        static var workspace: String { tr("file_explorer.workspace") }
    }

    // MARK: - Editor

    enum Editor {
        static var selectFile: String { tr("editor.select_file") }
    }

    // MARK: - Navigation

    enum Nav {
        static var launchSessionHint: String { tr("nav.launch_session_hint") }
    }

    // MARK: - Appearance

    enum Appearance {
        static var light: String { tr("appearance.light") }
        static var dark: String { tr("appearance.dark") }
        static var auto: String { tr("appearance.auto") }
    }
}
