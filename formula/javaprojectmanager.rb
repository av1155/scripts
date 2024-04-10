class Javaprojectmanager < Formula
  desc 'A versatile command-line utility for Java developers to compile and run Java files from the terminal.'
  homepage 'https://github.com/av1155/scripts'
  url 'https://raw.githubusercontent.com/av1155/scripts/main/scripts/JavaProjectManager/JavaProjectManager.zsh'
  sha256 'a1cd8f5f816ab3bb477a5c3d8461ecaec833e6a8869a1ee9f41a25422b9033c1'
  license 'MIT'

  depends_on 'fzf'
  depends_on 'bat'
  depends_on 'openjdk'

  def install
    bin.install 'JavaProjectManager.zsh' => 'jcr'
  end

  test do
    system "#{bin}/jcr", '--version'
  end
end
