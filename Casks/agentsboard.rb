# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.1.0"
  sha256 :no_check # Updated on release

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
