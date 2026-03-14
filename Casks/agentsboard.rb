# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.5.0"
  sha256 "cc4f429aa05f7e1097d6efd0056e28ff499f5e6d12b19cf0124964f45c33e012"

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
