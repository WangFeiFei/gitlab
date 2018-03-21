class PushoverService < Service
  BASE_URI = 'https://api.pushover.net/1'.freeze

  prop_accessor :api_key, :user_key, :device, :priority, :sound
  validates :api_key, :user_key, :priority, presence: true, if: :activated?

  def title
    'Pushover'
  end

  def description
    'Pushover 可以轻松在Android设备，iPhone，iPad和桌面操作系统上获取实时通知。'
  end

  def self.to_param
    'pushover'
  end

  def fields
    [
      { type: 'text', name: 'api_key', placeholder: 'Your application key', required: true },
      { type: 'text', name: 'user_key', placeholder: 'Your user key', required: true },
      { type: 'text', name: 'device', placeholder: 'Leave blank for all active devices' },
      { type: 'select', name: 'priority', required: true, choices:
        [
          ['Lowest Priority', -2],
          ['Low Priority', -1],
          ['Normal Priority', 0],
          ['High Priority', 1]
        ],
        default_choice: 0 },
      { type: 'select', name: 'sound', choices:
        [
          ['Device default sound', nil],
          ['Pushover (default)', 'pushover'],
          %w(Bike bike),
          %w(Bugle bugle),
          ['Cash Register', 'cashregister'],
          %w(Classical classical),
          %w(Cosmic cosmic),
          %w(Falling falling),
          %w(Gamelan gamelan),
          %w(Incoming incoming),
          %w(Intermission intermission),
          %w(Magic magic),
          %w(Mechanical mechanical),
          ['Piano Bar', 'pianobar'],
          %w(Siren siren),
          ['Space Alarm', 'spacealarm'],
          ['Tug Boat', 'tugboat'],
          ['Alien Alarm (long)', 'alien'],
          ['Climb (long)', 'climb'],
          ['Persistent (long)', 'persistent'],
          ['Pushover Echo (long)', 'echo'],
          ['Up Down (long)', 'updown'],
          ['None (silent)', 'none']
        ] }
    ]
  end

  def self.supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    ref = Gitlab::Git.ref_name(data[:ref])
    before = data[:before]
    after = data[:after]

    message =
      if Gitlab::Git.blank_ref?(before)
        "#{data[:user_name]} 推送了新的分支 \"#{ref}\"."
      elsif Gitlab::Git.blank_ref?(after)
        "#{data[:user_name]} 删除了分支 \"#{ref}\"."
      else
        "#{data[:user_name]} 推送了分支 \"#{ref}\"."
      end

    if data[:total_commits_count] > 0
      message << "\n合计提交数量： #{data[:total_commits_count]}"
    end

    pushover_data = {
      token: api_key,
      user: user_key,
      device: device,
      priority: priority,
      title: "#{project.name_with_namespace}",
      message: message,
      url: data[:project][:web_url],
      url_title: "查看项目 #{project.name_with_namespace}"
    }

    # Sound parameter MUST NOT be sent to API if not selected
    if sound
      pushover_data[:sound] = sound
    end

    Gitlab::HTTP.post('/messages.json', base_uri: BASE_URI, body: pushover_data)
  end
end
