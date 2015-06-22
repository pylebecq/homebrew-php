require File.expand_path("../../Abstract/abstract-php", __FILE__)

class Php70 < AbstractPhp
  init
  include AbstractPhpVersion::Php70Defs

  url     PHP_SRC_TARBALL
  sha256  PHP_CHECKSUM[:sha256]
  version PHP_VERSION

  head    PHP_GITHUB_URL, :branch => PHP_BRANCH

  def install_args
    args = super

    # dtrace is not compatible with phpdbg: https://github.com/krakjoe/phpdbg/issues/38
    if build.without? "phpdbg"
      args << "--enable-dtrace"
      args << "--disable-phpdbg"
    else
      args << "--enable-phpdbg"

      if build.with? "debug"
        args << "--enable-phpdbg-debug"
      end
    end

    args << "--enable-zend-signals"
  end

  def php_version
    "7.0"
  end

  def php_version_path
    "70"
  end

  def _install
      system "./buildconf" if build.head?
      system "./configure", *install_args()

      unless build.without? 'apache'
        # Use Homebrew prefix for the Apache libexec folder
        inreplace "Makefile",
          /^INSTALL_IT = \$\(mkinstalldirs\) '([^']+)' (.+) LIBEXECDIR=([^\s]+) (.+)$/,
          "INSTALL_IT = $(mkinstalldirs) '#{libexec}/apache2' \\2 LIBEXECDIR='#{libexec}/apache2' \\4"
      end

      inreplace 'Makefile' do |s|
        s.change_make_var! "EXTRA_LIBS", "\\1 -lstdc++"
      end

      system "make"
      ENV.deparallelize # parallel install fails on some systems
      system "make install"

      # Prefer relative symlink instead of absolute for relocatable bottles
      ln_s "phar.phar", bin+"phar", :force => true if File.exist? bin+"phar.phar"

      # Install new php.ini unless one exists
      config_path.install default_config => "php.ini" unless File.exist? config_path+"php.ini"

      chmod_R 0775, lib+"php"

      system bin+"pear", "config-set", "php_ini", config_path+"php.ini", "system" unless skip_pear_config_set?

      if build_fpm?
        if File.exist?('sapi/fpm/init.d.php-fpm')
          chmod 0755, 'sapi/fpm/init.d.php-fpm'
          sbin.install 'sapi/fpm/init.d.php-fpm' => "php#{php_version_path}-fpm"
        end

        if File.exist?('sapi/cgi/fpm/php-fpm')
          chmod 0755, 'sapi/cgi/fpm/php-fpm'
          sbin.install 'sapi/cgi/fpm/php-fpm' => "php#{php_version_path}-fpm"
        end

        if !File.exist?(config_path+"php-fpm.conf")
          if File.exist?('sapi/fpm/php-fpm.conf')
            config_path.install 'sapi/fpm/php-fpm.conf'
          end

          if File.exist?('sapi/cgi/fpm/php-fpm.conf')
            config_path.install 'sapi/cgi/fpm/php-fpm.conf'
          end

          inreplace config_path+"php-fpm.conf" do |s|
            s.sub!(/^;?daemonize\s*=.+$/,'daemonize = no')
            s.sub!(/^;include\s*=.+$/,";include=#{config_path}/fpm.d/*.conf")
          end

          inreplace config_path+"fpm.d/www.conf" do |s|
            s.sub!(/^;?listen\.mode\s*=.+$/,'listen.mode = 0666')
            s.sub!(/^;?pm\.max_children\s*=.+$/,'pm.max_children = 10')
            s.sub!(/^;?pm\.start_servers\s*=.+$/,'pm.start_servers = 3')
            s.sub!(/^;?pm\.min_spare_servers\s*=.+$/,'pm.min_spare_servers = 2')
            s.sub!(/^;?pm\.max_spare_servers\s*=.+$/,'pm.max_spare_servers = 5')
          end
        end
      end
    end
end
