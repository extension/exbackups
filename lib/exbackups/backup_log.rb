# === COPYRIGHT:
# Copyright (c) 2013 North Carolina State University
# === LICENSE:
# see LICENSE file

module Exbackups
  class BackupLog

    attr_reader :logfile, :results, :label, :logtime, :posted

    def initialize(label, results_or_timestamp)
      @posted = false
      @label = label
      @options = Exbackups.settings
      if(@options.logsdir.empty?)
        raise Exbackups::ConfigurationError, 'Missing configuration settings - logsdir'
      end

      if(results_or_timestamp.is_a?(Hash))
        @logtime = Time.now.utc
        @logfile = File.join(Exbackups.settings.logsdir, "#{@label}_#{@logtime.to_i}.json")
        @results = results_or_timestamp
        @metadata = {'label' => @label}
      elsif(results_or_timestamp.is_a?(Fixnum))
        @logtime = Time.at(results_or_timestamp).utc
        @logfile = File.join(Exbackups.settings.logsdir, "#{@label}_#{@logtime.to_i}.json")
        if(File.exists?(@logfile))
          logdata = JSON.parse(File.read(@logfile))
          @metadata = logdata['metadata'] || {}
          @results = logdata['results']
        else
          raise Exbackups::DataError, "Unable to find the backup log: #{@logfile}"
        end
      else
        raise Exbackups::ConfigurationError, 'Invalid BackupLog parameters'
      end
    end

    def dump
      logpath = Pathname.new(@logfile)
      log_parent_dir = logpath.dirname.to_s
      if(!File.exists?(log_parent_dir))
        FileUtils.mkdir_p(log_parent_dir)
      end
      logdata = {'metadata' => @metadata, 'results' => @results}
      File.open(@logfile, 'w') {|f| f.write(logdata.to_json) }
    end



    def post
      post_options = {'backup_key' =>  Exbackups.settings.backup_key, 'results' => @results}
      begin
        response = RestClient.post("#{Exbackups.settings.albatross_uri}/backups/log",
                                 post_options.to_json,
                                 :content_type => :json, :accept => :json)
        if(response)
          if(response.code == 200)
            return post_success
          elsif(response.code == 422)
            # possible this throws an exception if we don't get JSON, not catching for now
            response_data = JSON.parse(response.to_str)
             if(response_data['message'])
               return post_failed(response_data['message'])
             else
               return post_failed("Received an Unprocessable Entity error, but no error message.")
             end
          elsif(response.code == 401)
             return post_failed('Unauthorized request')
          else
             return post_failed("An unknown error occurred. Response code: #{response.code}")
          end
        else
          return post_failed('No response')
        end
      rescue StandardError => e
        return post_failed(e.message)
      end
    end

    def post_success
      if(File.exists?(@logfile))
        # in the event we posted an existing logfile
        File.unlink(@logfile)
      end
      @posted = true
      Exbackups.logger.info("LOGGING: Posted #{@label} output to #{@options.albatross_uri}")
      return true
    end

    def post_failed(message)
      @metadata['error'] = message
      @metadata['failcount'] ||= 0
      @metadata['failcount'] += 1
      self.dump
      Exbackups.logger.error("LOGGING: #{message}")
      return false
    end

    def error
      @metadata['error']
    end

    def posted?
      @posted
    end

    def self.logfile_to_label_timestamp(logfile)
      logpath = Pathname.new(logfile)
      regexp = %r{([[:alpha:]]+)_([[:digit:]]+)\.json}
      if(matched = regexp.match(logpath.basename.to_s))
        {'label' => matched[1], 'timestamp' => matched[2].to_i}
      else
        nil
      end
    end

    def self.check_for_logs(label)
      @options = Exbackups.settings
      Dir.glob(File.join(@options.logsdir,"#{label}_*.json")).sort
    end

    def self.post_logfile(logfile)
      if( data = logfile_to_label_timestamp(logfile) )
        begin
          backuplog = BackupLog.new(data['label'],data['timestamp'])
          BackupLog.post
          return backuplog
        rescue Exbackups::DataError
          return nil
        end
      end
    end

    def self.post_unposted(label)
      loglist = check_for_logs(label)
      if(!loglist.empty?)
        loglist.each do |logfile|
          self.post_logfile(logfile)
        end
      end
    end


  end
end
