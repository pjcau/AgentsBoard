# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.3.0"
  sha256 "5930f88b71eabe2644fa653e31d27419ca1fb025bd5e9469ba4cd51049c2f9ba"

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
