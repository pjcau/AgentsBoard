# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.4.0"
  sha256 "e60556a9b852f2c222f8bfcecca1163088f1da45ebce510b45941bdf2bef82a1"

  url "https://github.com/pjcau/AgentsBoard/releases/download/v#{version}/AgentsBoard-#{version}.dmg"
  name "AgentsBoard"
  desc "Fleet management dashboard for AI coding agents"
  homepage "https://github.com/pjcau/AgentsBoard"

  depends_on macos: ">= :sonoma"

  app "AgentsBoard.app"

  zap trash: [
    "~/Library/Application Support/AgentsBoard",
    "~/.config/agentsboard",
  ]
end
