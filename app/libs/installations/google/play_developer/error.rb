module Installations
  class Google::PlayDeveloper::Error
    using RefinedString

    ERRORS = [
      {
        status: "PERMISSION_DENIED",
        code: 403,
        message_matcher: /APK specifies a version code that has already been used/,
        decorated_exception: Installations::Errors::BuildExistsInBuildChannel
      },
      {
        status: "NOT_FOUND",
        code: 404,
        message_matcher: /Package not found:/,
        decorated_exception: Installations::Errors::BundleIdentifierNotFound
      },
      {
        status: "PERMISSION_DENIED",
        code: 403,
        message_matcher: /You cannot rollout this release because it does not allow any existing users to upgrade to the newly added APKs/,
        decorated_exception: Installations::Errors::BuildNotUpgradable
      }
    ]

    def self.handle(exception)
      new(exception).handle
    end

    def initialize(exception)
      @exception = exception
    end

    def handle
      return error if match.nil?
      match[:decorated_exception].new
    end

    private

    attr_reader :exception

    def match
      @match ||= matched_error
    end

    def matched_error
      ERRORS.find do |known_error|
        known_error[:status].eql?(status) && known_error[:code].eql?(code) && known_error[:message_matcher] =~ message
      end
    end

    def parsed_body
      @parsed_body ||= exception.body.safe_json_parse
    end

    def error
      return exception.body if parsed_body.blank?
      parsed_body["error"]
    end

    def message
      error["message"]
    end

    def code
      error["code"]
    end

    def status
      error["status"]
    end
  end
end