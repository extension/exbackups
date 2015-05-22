# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'open3'

module Exbackups

  class Backup

    attr_accessor :results, :host, :fqdn, :backupcommand, :local_backup_directory

    def self.host_list
      if(Exbackups.settings.backuphosts)
        Exbackups.settings.backuphosts.to_hash.keys.map{|hostname| hostname.to_s}
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
        @fqdn = Exbackups.settings.backuphosts.to_hash[@host.to_sym]
      else
        @fqdn = "#{@host}.test.extension.org"
      end


      # build the command
      build_backup = []
      # program
      build_backup << Exbackups.settings.backups.program
      # options
      build_backup << Exbackups.settings.backups.options
      # include files
      build_backup <<  "--include-globbing-filelist #{Exbackups.settings.backups.configdir}/backup-includelist-default}"
      # exclude files
      build_backup << "--exclude '**'"
      # run rdiff-backup remotely with sudo
      build_backup << "--remote-schema 'ssh -C %s \"sudo /usr/bin/rdiff-backup --server\"'"
      # host::remotedir
      build_backup << "#{@fqdn}::#{Exbackups.settings.backups.remotedir}"
      # localdir

      @local_backup_directory =  "#{Exbackups.settings.backups.parentdestination}/#{@host}"
      build_backup << @local_backup_directory

      @backupcommand = build_backup.join(' ')
      @results = {}

    end


    def go_forth_and_backup

      if(!@testmode)
        if not File.exists?(@local_backup_directory) then
          Dir.mkdir(@local_backup_directory)
        end

        @results['server_name'] = @host
        @results['server_fqdn'] = @fqdn
        @results['backupcommand'] = @backupcommand
        @results['start'] = Time.now.utc
        stdin, stdout, stderr = Open3.popen3(@backupcommand)
        stdin.close
        @results['stdout'] = stdout.readlines
        @results['stderr'] = stderr.readlines
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

      backuplog = Exbackups::BackupLog.new("#{@host}-backup",@results)
      postresults = backuplog.post
      postresults
    end

  end # class
end # module
