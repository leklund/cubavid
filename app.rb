require 'base64'
require 'cuba'
require 'cuba/render'
require 'erb'

MEDIA_DIR = 'media'.freeze

Cuba.plugin Cuba::Render

Cuba.use Rack::Static,
  urls: ["/media"]

Cuba.define do
  on get do
    on root do
      @files = Video.list
      res.write view('index')
    end

    on "watch/:filekey" do |filekey|
      @file_path = Base64.urlsafe_decode64(filekey)
      unless @file = Video.list[@file_path]
        res.status = 404
        res.write 'not found'

        halt(res.finish)
      end

      res.write view('watch')
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
