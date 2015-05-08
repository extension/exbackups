# === COPYRIGHT:
# Copyright (c) 2015 North Carolina State University
# === LICENSE:
# see LICENSE file
require 'open3'

module Exbackups

  class ExbackupsError < StandardError; end


  class Backup

    attr_accessor :results, :host, :fqdn, :backup_command, :local_backup_directory

    def self.host_list
      Exbackups.settings.backuphosts.to_hash.keys.map{|hostname| hostname.to_s}
    end

    def initialize(host)
      if(self.class.host_list.include?(host))
        @host = host
      else
        raise ExbackupsError, "invalid host specified: #{host}"
      end

      @fqdn = Exbackups.settings.backuphosts.to_hash[@host]


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
      # host::remotedir
      build_backup << "#{@fqdn}::#{Exbackups.settings.backups.remotedir}"
      # localdir

      @local_backup_directory =  "#{Exbackups.settings.backups.parentdestination}/#{@host}"
      build_backup << @local_backup_directory

      @backup_command = build_backup.join(' ')

    end


    def go_forth_and_backup

      if not File.exists?(@local_backup_directory) then
        Dir.mkdir(@local_backup_directory)
      end

      @results['host'] = @host
      @results['fqdn'] = @fqdn
      @results['backupcommand'] = @backup_command
      @results['start'] = Time.now.utc
      stdin, stdout, stderr = Open3.popen3(@backup_command)
      stdin.close
      @results['stdout'] = stdout.readlines
      @results['stderr'] = stderr.readlines
      @results['finish'] = Time.now.utc
      @results['runtime'] = (@results['finish'] - @results['start'])
      @results['success'] = @results['stderr'].empty?

      # TODO log to albatross?
      # mythical boilerplate for now
      # backuplog = Exbackups::BackupLog.new(@results)
      # backuplog.post

      @results['success']
    end

  end # class
end # module
