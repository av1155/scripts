class Javaprojectmanager < Formula
  desc "A versatile command-line utility for Java developers to compile and run Java files from the terminal."
  homepage "https://github.com/av1155/scripts"
  url "https://raw.githubusercontent.com/av1155/scripts/main/scripts/JavaProjectManager/JavaProjectManager.zsh"
  version "2.0.0" # Example version
  sha256 "66d325dc9126487618eb8d97e06d297ee5e5f4b92eb278fe064d530f154d9e70"
  license "MIT"

  depends_on "fzf"
  depends_on "bat"
  depends_on "openjdk"

  def install
    bin.install "JavaProjectManager.zsh" => "jcr"
  end

  test do
    system "#{bin}/jcr", "--version"
  end
end
