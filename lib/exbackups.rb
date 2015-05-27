# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file

require 'logger'
require 'rest-client'
require 'ostruct'
require 'pathname'

require "exbackups/version"
require 'exbackups/deep_merge' unless defined?(DeepMerge)
require "exbackups/options"
require "exbackups/errors"
require "exbackups/backup"
require "exbackups/backup_log"
require "exbackups/ping"

module Exbackups

  SETTINGS_CONFIG_FILE = '/etc/exbackups/settings.toml'
  TEST_HOST = 'testhost'
  TEST_ERROR_HOST = 'testerrorhost'

  def self.settings
    if(@settings.nil?)
      @settings = Exbackups::Options.new
      @settings.load!
    end

    @settings
  end

  def self.logger
    options = self.settings
    if(@logger.nil?)
      if(!File.exists?(options.logsdir))
        FileUtils.mkdir_p(options.logsdir)
      end
      @logger = Logger.new("#{options.logsdir}/exbackups.log")
    end
    @logger
  end

end
