# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'open3'

module Exbackups

  class Syncto

    attr_accessor :results, :host, :fqdn, :backupcommand

    def self.host_list
      if(Exbackups.settings.synctohosts)
        Exbackups.settings.synctohosts.to_hash.keys.map{|hostname| hostname.to_s}
      else
        []
      end
    end

    def initialize(host)
      if(self.class.host_list.include?(host))
        @testmode = false
        @host = host
      elsif(host == Exbackups::TEST_HOST)
        @testmode = true
        @host = host
        @errortest = false
      elsif(host == Exbackups::TEST_ERROR_HOST)
        @testmode = true
        @host = host
        @errortest = true
      else
        raise Exbackups::ConfigurationError, "invalid host specified: #{host}"
      end

      if(!@testmode)
        @fqdn = Exbackups.settings.synctohosts.to_hash[@host.to_sym]
      else
        @fqdn = "#{@host}.test.extension.org"
      end


      # build the sync command
      build_syncto = []
      # program
      build_syncto << Exbackups.settings.syncto.program
      # options
      build_syncto << Exbackups.settings.syncto.options
      # localdir
      build_syncto << Exbackups.settings.syncto.localdir
      # remote syncto and dir
      build_syncto << "#{@fqdn}:#{Exbackups.settings.syncto.remotedir}"
      @backupcommand = build_syncto.join(' ')
      @results = {}

    end


    def go_forth_and_syncto

      if(!@testmode)
        @results['server_name'] = @host
        @results['server_fqdn'] = @fqdn
        @results['backupcommand'] = @backupcommand
        @results['start'] = Time.now.utc
        stdin, stdout, stderr = Open3.popen3(@backupcommand)
        stdin.close
        @results['stdout'] = stdout.read
        @results['stderr'] = stderr.read

        @results['finish'] = Time.now.utc
        @results['runtime'] = (@results['finish'] - @results['start'])
        @results['success'] = @results['stderr'].empty?
      else
        @results['server_name'] = @host
        @results['server_fqdn'] = @fqdn
        @results['backupcommand'] = @backup_command
        @results['start'] = Time.now.utc
        @results['finish'] = @results['start'] + 42
        @results['runtime'] = (@results['finish'] - @results['start'])
        @results['stdout'] = 'Simulating a backup log and post'
        if(@errortest)
          @results['stderr'] = 'Simulating a backup error'
        else
          @results['stderr'] = ''
        end
        @results['success'] = @results['stderr'].empty?
      end

      backuplog = Exbackups::BackupLog.new("#{@host}-syncto",@results)
      postresults = backuplog.post
      postresults
    end

  end # class
end # module
