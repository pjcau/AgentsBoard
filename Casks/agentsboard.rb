# MARK: - Homebrew Cask Formula (Step 20.1)

cask "agentsboard" do
  version "0.2.0"
  sha256 "3037919937432e29e477991e0e05824ed7626d57234c5c65ee881407376b3fe7"

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
