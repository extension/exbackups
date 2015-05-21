# === COPYRIGHT:
# Copyright (c) 2013 North Carolina State University
# === LICENSE:
# see LICENSE file

module Exbackups
  class Ping

    def post
      post_options = {'backup_key' => Exbackups.settings.backup_key, 'results' => {'message' => 'ping'}}

      begin
        response = RestClient.post("#{Exbackups.settings.albatross_uri}/backups/ping",
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
      @posted = true
      Exbackups.logger.info("LOGGING: Posted ping to #{Exbackups.settings.albatross_uri}")
      OpenStruct.new(success: true, message: "Posted ping to #{Exbackups.settings.albatross_uri}")
    end

    def post_failed(message)
      Exbackups.logger.error("LOGGING: #{message}")
      OpenStruct.new(success: false, message: message)
    end

  end
end
