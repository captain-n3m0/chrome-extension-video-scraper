require 'sinatra/base'

class VideoDownloader < Sinatra::Base
  get '/' do
    erb :index
  end

  post '/download' do
    videos = params[:videos]
    videos.each do |src|
      uri = URI(src)
      filename = File.basename(uri.path)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)
        File.open(filename, 'wb') do |file|
          file.write(response.body)
        end
      end
      chrome_downloads_download(filename, save_as: filename)
    end
  end
end

def chrome_downloads_download(url, options = {})
  options[:url] = url
  chrome_downloads_create options
end

def chrome_downloads_create(options = {})
  message = {method: 'chrome.downloads.create', args: [options]}
  send_message_to_content_script message
end

def send_message_to_content_script(message)
  current_tab_id = nil
  chrome_tabs_query active: true do |tabs|
    current_tab_id = tabs.first['id']
  end
  chrome_tabs_execute_script current_tab_id, code: "window.postMessage(#{JSON.generate(message)}, '*')"
end

def chrome_tabs_query(query, &block)
  chrome_tabs_query_internal query do |tabs|
    chrome_tabs_execute_script tabs.first['id'], code: 'null', &block
  end
end

def chrome_tabs_query_internal(query, &block)
  chrome_tabs_query_raw query do |tabs|
    tabs.each do |tab|
      chrome_tabs_execute_script tab['id'], code: 'null'
    end
    chrome_tabs_query_raw query, &block
  end
end

def chrome_tabs_query_raw
