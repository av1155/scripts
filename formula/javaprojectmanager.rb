class Javaprojectmanager < Formula
  desc "Easily compile and run Java files, manage cleanup, and view syntax-highlighted errors through a user-friendly fuzzy-finding menu."
  homepage "https://github.com/av1155/scripts"
  url "https://raw.githubusercontent.com/av1155/scripts/main/scripts/JavaProjectManager/JavaProjectManager.zsh"
  version "2.1.0"
  sha256 "1ca9457f2577f68e92a0854a19cb489c0fa7a29c042cedcca1893e78198b9573"
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
