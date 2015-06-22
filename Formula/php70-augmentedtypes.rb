require File.expand_path("../../Abstract/abstract-php-extension", __FILE__)

class Php70Augmentedtypes < AbstractPhp70Extension
  init
  homepage 'https://github.com/box/augmented_types'
  url 'https://github.com/box/augmented_types/archive/v0.6.6.tar.gz'
  sha1 '0d6ef730b18ffbe551cbfd1d7273de6e6db746d5'
  head 'https://github.com/box/augmented_types.git'

  option 'without-default-enforcement', "Turn off Augmented Types enforcement by default"

  def extension_type; "zend_extension"; end

  def extension
    "augmented_types"
  end

  def install
    ENV.universal_binary if build.universal?

    safe_phpize
    system "./configure", "--prefix=#{prefix}", phpconfig, "--enable-augmented_types"
    system "make"
    prefix.install "modules/augmented_types.so"
    write_config_file if build.with? "config-file"
  end

  def config_file
    if active_spec.build.with? 'default-enforcement'
      super + <<-EOS.undent
        augmented_types.enforce_by_default = 1
      EOS
    else
      super
    end
  end
end
