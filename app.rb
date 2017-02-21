require 'base64'
require 'cuba'
require 'cuba/render'
require 'erb'
require 'http'
require './helpers'

MEDIA_DIR = 'media'.freeze

Cuba.plugin Cuba::Render

Cuba.use Rack::Static,
  urls: ["/media"]

Cuba.plugin Helpers

Cuba.define do
  on get do
    on root do
      @files = Video.list
      @downloads = req['all'].nil? ? currently_downloading : active_torrents
      res.write view('index')
    end

    on "watch/:filekey" do |filekey|
      @file_path =
        begin
          Base64.urlsafe_decode64(filekey)
        rescue ArgumentError
          four_oh_four
        end

      unless @file = Video.list[@file_path]
        four_oh_four
      end

      res.write view('watch')
    end

    on 'upload' do
      res.write view('upload')
    end
  end

  on post do
    on 'upload' do
      on param('linky') do |linky|
        download_and_start(linky)
        res.redirect '/'
      end
    end
  end
end

module Video
  module_function

  def list
    file_list.each_with_object({}) do |file, hash|
      hash[file] = {
        param: Base64.urlsafe_encode64(file),
        display_name: display_name(file),
      }
    end
  end

  def file_list
    Dir.glob("#{MEDIA_DIR}/**/*").reject do |entry|
      entry.match?(/^\./) || File.directory?(entry)
    end
  end

  def display_name(file)
    name = file.gsub(/^#{MEDIA_DIR}\//, '')
    name.split('/').join ': '
  end
end
