# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.9.6"
  sha256 "4604412b4876f5040485cab4406880f990a3113cb43806afbe72562aed850e0f"

  url "https://github.com/pjcau/AgentsBoard/releases/download/v#{version}/AgentsBoard-#{version}-macos.zip"
  name "AgentsBoard"
  desc "Fleet management dashboard for AI coding agents"
  homepage "https://github.com/pjcau/AgentsBoard"

  depends_on macos: ">= :sonoma"

  app "AgentsBoard.app"

  # Gracefully quit the running app before upgrade replaces the binary
  uninstall quit: "com.agentsboard.app"

  postflight do
    # Remove quarantine flag so macOS doesn't block the unsigned app
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/AgentsBoard.app"],
                   sudo: false
    # Relaunch the app after upgrade
    system_command "/usr/bin/open",
                   args: ["#{appdir}/AgentsBoard.app"],
                   sudo: false
  end

  caveats <<~EOS
    AgentsBoard is not signed with a Developer ID certificate.
    If macOS blocks the app on first launch:
      1. Go to System Settings > Privacy & Security
      2. Click "Open Anyway" next to the AgentsBoard message
    Or run: xattr -cr /Applications/AgentsBoard.app
  EOS

  zap trash: [
    "~/Library/Application Support/AgentsBoard",
    "~/.config/agentsboard",
  ]
end
