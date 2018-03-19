module Fastlane
  module Actions
    class SentryUploadProguardAction < Action
      def self.run(params)
        Helper::SentryHelper.check_sentry_cli!
        Helper::SentryConfig.parse_api_params(params)

        # Params - proguard
        proguard_path = params[:proguard_path]
        proguard_paths = params[:proguard_paths] || []

        # Verify files
        proguard_paths += [proguard_path] unless proguard_path.nil?
        proguard_paths = proguard_paths.map { |path| File.absolute_path(path) }
        proguard_paths.each do |path|
          UI.user_error!("file does not exist at path: #{path}") unless File.exist? path
        end

        command = ["sentry-cli", "upload-proguard"]
        command.push("--android-manifest") unless params[:android_manifest].nil?
        command.push(params[:android_manifest]) unless params[:android_manifest].nil?
        command += proguard_paths

        Helper::SentryHelper.call_sentry_cli(command)
        UI.success("Successfully uploaded proguard!")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload dSYM symbolication files to Sentry"
      end

      def self.details
        [
          "This action allows you to upload symbolication files to Sentry."
        ].join(" ")
      end

      def self.available_options
        Helper::SentryConfig.common_api_config_items + [
          FastlaneCore::ConfigItem.new(key: :proguard_path,
                                      env_name: "SENTRY_proguard_path",
                                      description: "Path to your symbols file.",
                                      default_value: Actions.lane_context[SharedValues::PROGUARD_OUTPUT_PATH],
                                      optional: true,
                                      verify_block: proc do |value|
                                        UI.user_error! "Could not find Path to your symbols file at path '#{value}'" unless File.exist?(value)
                                      end),
          FastlaneCore::ConfigItem.new(key: :proguard_paths,
                                       env_name: "SENTRY_proguard_paths",
                                       description: "Path to an array of your symbols file. For iOS and Mac provide path to app.dSYM.zip",
                                       default_value: Actions.lane_context[SharedValues::proguard_pathS],
                                       is_string: false,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :android_manifest,
                                      env_name: "SENTRY_android_manifest",
                                      description: "Path to Android manifest to add version information when uploading debug symbols",
                                      optional: true,
                                      verify_block: proc do |value|
                                        UI.user_error! "Could not find manifest at path '#{value}'" unless File.exist?(value)
                                      end)
        ]
      end

      def self.return_value
        nil
      end

      def self.authors
        ["brandons"]
      end

      def self.is_supported?(platform)
        platform == :android
      end
    end
  end
end
