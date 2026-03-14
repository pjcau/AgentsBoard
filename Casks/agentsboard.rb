# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.6.0"
  sha256 "45ff4022e668e5ace484c2fbe972fc3632085b83ad5f2010d849f4d3fc35cd3a"

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
