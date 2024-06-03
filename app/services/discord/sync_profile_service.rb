module Discord
  class SyncProfileService
    attr_reader :error_msg
    def initialize(user, additional_discord_role_ids:)
      @user = user
      @additional_discord_role_ids =
        if additional_discord_role_ids.is_a?(Array)
          additional_discord_role_ids
        else
          [additional_discord_role_ids].compact
        end
      @error_msg = ""
    end

    def execute
      return false unless sync_ready?

      rest_client =
        Discordrb::API::Server.update_member(
          "Bot #{configuration.bot_token}",
          configuration.server_id,
          user.discord_user_id,
          roles: all_discord_role_ids,
          nick: nick_name
        )

      if rest_client.code == 200
        sync_and_cache_roles(rest_client)
        true
      else
        false
      end
    rescue Discordrb::Errors::UnknownMember
      @error_msg = "Unknown member #{user.discord_user_id}"
      Rails.logger.error(@error_msg)
      @user.update!(discord_user_id: nil)

      false
    rescue Discordrb::Errors::NoPermission
      @error_msg =
        "Bot does not have permission to update member #{user.discord_user_id}"
      Rails.logger.error(@error_msg)
      false
    rescue RestClient::BadRequest => e
      @error_msg =
        "Bad request with discord_user_id: #{user.discord_user_id}; #{e.response.body}"
      Rails.logger.error(@error_msg)
      false
    end

    def sync_ready?
      user.discord_user_id.present? && configuration.configured?
    end

    private

    attr_reader :user, :additional_discord_role_ids

    def sync_and_cache_roles(rest_client)
      response_role_ids = JSON.parse(rest_client.body).dig("roles")

      additional_synced_role_ids = additional_role_ids & response_role_ids

      school
        .discord_roles
        .where(discord_id: additional_synced_role_ids)
        .each do |role|
          AdditionalUserDiscordRole.where(
            user_id: user.id,
            discord_role_id: role.id
          ).first_or_create!
        end

      deleted_discord_role_ids =
        user
          .discord_roles
          .where.not(discord_id: additional_synced_role_ids)
          .pluck(:id)

      AdditionalUserDiscordRole
        .where(discord_role_id: deleted_discord_role_ids)
        .where(user_id: user.id)
        .delete_all
    end

    def all_discord_role_ids
      @all_discord_role_ids ||=
        begin
          cohort_assigned_ids = [
            user.cohorts.pluck(:discord_role_ids),
            configuration.default_role_ids
          ].flatten.compact.uniq

          (additional_role_ids + cohort_assigned_ids).uniq
        end
    end

    def additional_role_ids
      @additional_role_ids ||=
        begin
          school_discord_roles
            .filter { |role| role.id.to_s.in?(additional_discord_role_ids) }
            .pluck(:discord_id)
        end
    end

    def configuration
      @configuration ||= Schools::Configuration::Discord.new(school)
    end

    def nick_name
      return @user.name if @user.name.length <= 32
      @user.name[0..28] + "..."
    end

    def school_discord_roles
      @school_discord_roles ||= school.discord_roles.to_a
    end

    def school
      @school ||= @user.school
    end
  end
end
