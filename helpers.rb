require 'shellwords'

module Helpers
  FIELD_MAPPING = {
    percentage: 7..12,
    eta: 24..33,
    status: 57..69,
    name: 70..-1
  }

  def four_oh_four
    res.status = 404
    res.write 'not found'

    halt(res.finish)
  end

  def config
    @config ||= YAML::load(File.open(File.join('config', 'secrets.yml')))
  end

  def active_torrents
    sys = `transmission-remote --auth #{config['transmission_rpc_user']}:#{config['transmission_rpc_password']} -l`

    list = sys.split "\n"

    return nil if list.size == 2

    # remove the header & footer
    list.pop && list.shift

    list.each_with_object([]) do |item, arr|
      mapped = {}
      FIELD_MAPPING.each do |f, range|
        mapped[f] = item.slice(range).strip
      end
      arr << mapped
    end
  end

  def currently_downloading
    active_torrents&.reject { |tor| tor[:eta] ==  'Done' || tor[:percentage] == '100%'}
  end

  def download_and_start(link)
    http = HTTP['User-Agent' => config[:user_agent], 'Cookie' => config['cookie']]

    res = http.get(link)

    raise 'err' unless res.status == 200

    if res['Content-Disposition']
      cd = res['Content-Disposition']
      cd.match(/filename="(.+)"$/)
      filename = $1
    else
      filename = link.gsub(/^.*&/, '')
    end

    torrent_file = File.join('tmp', filename)
    File.open(torrent_file, 'wb' ) {|f| f.write res.body }


    `transmission-remote --auth #{config['transmission_rpc_user']}:#{config['transmission_rpc_password']} -a #{Shellwords.escape(torrent_file)}`
  end
end
