require "erb"
require "rack"
require "sinatra/base"
require "json"
require "open-uri"
require "yaml"
require "chronic"
require "chronic_duration"
require "optparse"

require "pencil/version"
require "pencil/config"
require "pencil/helpers"
require "pencil/models"
require "pencil/rubyfixes"

module Pencil
  class App < Sinatra::Base
    include Pencil::Models
    helpers Pencil::Helpers
    config = Pencil::Config.new
    set :config, config
    set :port, config.global_config[:port]
    set :run, true
    use Rack::Session::Cookie, :expire_after => 126227700 # 4 years
    use Rack::Logger
    set :root, File.expand_path('../pencil', __FILE__)
    set :static, true
    set :logging, true
    set :erb, :trim => '-'
    set :numthreads, 0

    def initialize(settings={})
      super
    end

    before do
      settings.config.lock.lock
      if settings.numthreads == 0 &&
          settings.config.reload_available &&
          !settings.config.reload_pending
        logger.info 'new config available, reloading...'
        settings.config.reload! #fast operation
        logger.info "config version #{settings.config.version} loaded"
        settings.config.reload_available = false
        settings.config.reload_pending = false
      end
      settings.numthreads += 1
      settings.config.lock.unlock

      session[:not] #fixme kludge is back
      @request_time = Time.now
      @dashboards = Dashboard.all
      @no_graphs = false
      # time stuff
      start = param_lookup("start")
      duration = param_lookup("duration")

      @stime = Chronic.parse(start)
      if @stime
        @stime -= @stime.sec unless @params["noq"]
      elsif start =~ /^\d+$/ #epoch
        @stime = Time.at start.to_i
      end

      if duration
        @duration = ChronicDuration.parse(duration) || 0
      else
        @duration = @request_time.to_i - @stime.to_i
      end

      unless @params["noq"]
        @duration -= (@duration % settings.config.global_config[:quantum]||1)
      end

      if @stime
        @etime = Time.at(@stime + @duration)
        @etime = @request_time if @etime > @request_time
      else
        @etime = @request_time
      end

      session[:stime] = @stime.to_i.to_s
      session[:etime] = @etime.to_i.to_s
      # fixme reload hosts after some expiry
    end

    after do
      settings.config.lock.lock
      settings.numthreads -= 1
      settings.config.lock.unlock
    end

    get %r[^/(dash/?)?$] do
      @no_graphs = true
      if settings.config.clusters.size == 1
        redirect append_query_string("/dash/#{settings.config.clusters.first}")
      else
        redirect append_query_string('/dash/global')
      end
    end

    get '/dash/:cluster/:dashboard/:zoom/?' do
      @cluster = params[:cluster]
      @dash = Dashboard.find(params[:dashboard])
      raise "Unknown dashboard: #{params[:dashboard].inspect}" unless @dash

      @zoom = nil
      @dash.graphs.each do |graph|
        @zoom = graph if graph.name == params[:zoom]
      end
      raise "Unknown zoom parameter: #{params[:zoom]}" unless @zoom

      @title = "dashboard :: #{@cluster} :: #{@dash['title']} :: #{params[:zoom]}"

      if @cluster == "global"
        erb :'dash-global-zoom'
      else
        erb :'dash-cluster-zoom'
      end
    end

    get '/dash/:cluster/:dashboard/?' do
      @cluster = params[:cluster]
      @dash = Dashboard.find(params[:dashboard])
      raise "Unknown dashboard: #{params[:dashboard].inspect}" unless @dash

      @title = "dashboard :: #{@cluster} :: #{@dash['title']}"

      if @cluster == "global"
        erb :'dash-global'
      else
        erb :'dash-cluster'
      end
    end

    get '/dash/:cluster/?' do
      @no_graphs = true
      @cluster = params[:cluster]
      if @cluster == "global"
        @title = "Overview"
        erb :global
      else
        @title = "cluster :: #{params[:cluster]}"
        erb :cluster
      end
    end

    get '/host/:cluster/:host/?' do
      @host = Host.find_by_name_and_cluster(params[:host], params[:cluster])
      @cluster = @host.cluster
      raise "Unknown host: #{params[:host]} in #{params[:cluster]}" unless @host

      @title = "#{@host.cluster} :: host :: #{@host.name}"

      erb :host
    end

    get '/process' do
      case params["action"]
      when "Save"
        # fixme make sure not to save shitty values for :start
        logger.info 'saving prefs'
        params.each do |k ,v|
          next if [:etime, :stime, :duration].member?(k.to_sym)
          session[k] = v unless v.empty?
        end
        redirect URI.parse(request.referrer).path
      when "Clear"
        logger.info URI.parse(request.referrer).path
        redirect URI.parse(request.referrer).path
      when "Reset"
        logger.info "clearing prefs"
        session.clear
        redirect URI.parse(request.referrer).path
      when "Submit"
        # fixme offensive to sensibility
        redirect URI.parse(request.referrer).path + "?" + \
        request.query_string.sub("&action=Submit", "").sub("?action=Submit", "")
      end
    end

    get '/reload' do
      logger.info "manual reload triggered"
      settings.config.trigger_restart
      "manual reload triggered"
    end

  end # Pencil::App
end # Pencil
