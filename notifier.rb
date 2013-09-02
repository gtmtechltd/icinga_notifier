require 'open-uri'
require 'JSON'
require 'net/http'
require 'digest/hmac'

params = {}
params[:icinga_server]   = "localhost"
params[:icinga_port]     = 80
params[:icinga_login]    = "admin"
params[:icinga_password] = "password"
params[:duration]        = 3600                         # duration of downtime
params[:service]         = "SSH"                        # servicename you wish to take down
params[:hosts]           = [ "localhost" ]              # hosts for which you want to schedule downtime
params[:comment]         = "automated by notifier.rb"   # downtime comment



def login( http_client, params )
  path = "/icinga-web/modules/appkit/login/json"
  headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }
  post_data = "dologin=1&username=#{params[ :icinga_login ]}&password=#{params[ :icinga_password ]}"
  resp, data = http_client.post(path, post_data, headers)
  cookie = resp.response['set-cookie']
  raise StandardError, "Could not get login cookie" if cookie.nil?
  cookie_token = ""
  if cookie =~ /icinga-web=(\w+)/
    cookie_token = $1
  end
  raise StandardError, "Could not get login token from login cookie" if cookie_token.empty?
  params[:cookie_token] = cookie_token
end

def get_authorization_code( http_client, params )
  timestamp_seconds = Time.now.to_i.to_s
  headers = { 'Cookie' => "icinga-web=#{params[ :cookie_token ]}; icinga-web-loginname=#{params[ :icinga_login ]};"}
  path = "/icinga-web/modules/cronks/commandproc/SCHEDULE_SVC_DOWNTIME/json/inf?_dc=#{timestamp_seconds}000"
  resp, data = http_client.get(path, headers)
  raise StandardError, "Could not get authorization code for SCHEDULE_SVC_DOWNTIME" unless resp.response.message == "OK"
  json_object = JSON.parse resp.response.body
  tktoken = json_object["tk"]
  raise StandardError, "Could not get tk encrypted time token" if tktoken.nil?
  auth = Digest::HMAC.hexdigest("SCHEDULE_SVC_DOWNTIME", tktoken, Digest::RMD160)
  params[:auth_token] = auth
end


def request_service_downtime( http_client, params )
  start_time = Time.now.to_s.split(" ").slice(0,2).join(" ")
  end_time = (Time.now + params[:duration]).to_s.split(" ").slice(0,2).join(" ")
  headers = { 'Cookie' => "icinga-web=#{params[ :cookie_token ]}; icinga-web-loginname=#{params[ :icinga_login ]};",
              'Content-Type' => 'application/x-www-form-urlencoded' }
  path = "/icinga-web/modules/cronks/commandproc/SCHEDULE_SVC_DOWNTIME/json/send"
  selection = []
  params[:hosts].each do |host|
    selection << { "host" => host,
                   "service" => params[ :service ],
                   "instance" => "default" }
  end
  json_selection = JSON.generate selection 

  data = { "starttime" => start_time,
           "endtime" => end_time,
           "fixed" => "1",
           "data" => "0",
           "duration" => params[:duration],
           "author" => params[ :icinga_login ],
           "comment" => params[ :comment ] }

  json_data = JSON.generate data

  post_string = "auth=#{params[ :auth_token ]}&selection=#{URI::encode json_selection}&data=#{URI::encode json_data}"
  resp, data = http_client.post(path, post_string, headers)
  raise StandardError, "Could not schedule downtime" unless resp.response.message == "OK"
  result = JSON.parse resp.response.body
  raise StandardError, "Scheduling downtime was not successful" if result["success"].nil?
  raise StandardError, "Scheduling downtime was not successful" unless result["success"] == true
  true
end

# BEGIN

http_client = Net::HTTP.new( params[:icinga_server], params[:icinga_port] )

if params[:icinga_port] == 443 
  http_client.use_ssl = true
  http_client.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

login( http_client, params )
get_authorization_code( http_client, params )
request_service_downtime( http_client, params)

puts "Successfully scheduled downtime"

