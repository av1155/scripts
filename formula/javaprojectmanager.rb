class Javaprojectmanager < Formula
  desc "Easily compile and run Java files, manage cleanup, and view syntax-highlighted errors through a user-friendly fuzzy-finding menu."
  homepage "https://github.com/av1155/scripts"
  url "https://raw.githubusercontent.com/av1155/scripts/main/scripts/JavaProjectManager/JavaProjectManager.zsh"
  version "2.0.0"
  sha256 "66d325dc9126487618eb8d97e06d297ee5e5f4b92eb278fe064d530f154d9e70"
  license "MIT"

  depends_on "fzf"
  depends_on "bat"
  depends_on "openjdk"

  def install
    bin.install "JavaProjectManager.zsh" => "jcr"
  end

  # This method provides additional information to the user post-installation
  def caveats
    <<~EOS
      To run JavaProjectManager, use the 'jcr' command in your terminal.

      Options:
        -h, --help: Display help information.
        -v, --version: Display the version of JavaProjectManager.
    EOS
  end

  test do
    system "#{bin}/jcr", "--version"
  end
end
