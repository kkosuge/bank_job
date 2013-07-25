require "bank_job/version"
require "bank_job/upper_process"

module BankJob
  class << self
    def new
      UpperProcess.new
    end

    def root_path
      @root_path ||= Pathname(__FILE__).dirname.realpath + '..'
    end
  end
end
