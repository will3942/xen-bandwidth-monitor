require 'bundler/setup'
Bundler.require(:default)

ENV['RACK_ENV'] = "development"
Mongoid.logger.level = Logger::FATAL
Mongoid.load!('./mongoid.yml')

class VirtualMachine
  include Mongoid::Document
  include Mongoid::Timestamps
  
  has_many :bandwidth_measurements
  
  field :hostname, type: String
  field :bandwidth_limit_gigabytes, type: Integer 
  
  index({ hostname: 1 }, { unique: true })
  index "bandwidth_measurements.cumulative_gigabytes" => 1
end

class BandwidthMeasurement
  include Mongoid::Document
  
  belongs_to :virtual_machine
  
  field :cumulative_gigabytes, type: Integer
  field :current_gigabytes, type: Integer
  field :timestamp, type: Mongoid::Metastamp::Time
end
