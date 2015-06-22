require File.expand_path("../../Abstract/abstract-php-extension", __FILE__)

class Php70Sodium < AbstractPhp70Extension
  init
  homepage "https://github.com/alethia7/php-sodium"
  url "https://github.com/aletheia7/php-sodium/archive/1.0.7.tar.gz"
  sha256 "07d06b486ab5b687e63109d64bf9fd21c846a315b8c71088639dfa0a7272339e"
  head "https://github.com/alethia7/php-sodium.git"

  depends_on "libsodium"

  def install
    ENV.universal_binary if build.universal?

    safe_phpize
    system "./configure", "--prefix=#{prefix}", phpconfig
    system "make"
    prefix.install "modules/sodium.so"
    write_config_file if build.with? "config-file"
  end

  test do
    shell_output("php -m").split("\n").include?("sodium")
  end
end
