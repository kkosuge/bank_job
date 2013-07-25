require 'bank_job/core_ext/string'
require 'bank_job/core_ext/fixnum'
require 'bank_job/configuration'
require 'mechanize'
require 'pathname'

module BankJob
  module Strategy
    attr_accessor *BankJob::Configration::OPTION_KEYS, :agent, :page

    def initialize
      @agent = Mechanize.new
      @agent.user_agent  = Mechanize::AGENT_ALIASES['Windows IE 9']
      @agent.ca_file     = (BankJob.root_path + 'ca/cacert.pem').to_s
      @agent.ssl_version = 'SSLv3'
    end
  end
end
