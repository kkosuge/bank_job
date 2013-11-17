require 'hashie/mash'

module BankJob
  module Configration

    OPTION_KEYS = [
      :strategy,
      :key,
      :number,
      :pin,
      :questions,
    ].freeze

    attr_accessor *OPTION_KEYS, :agents

    def register
      yield self
      contract
      self
    end

    def contract
      @agents ||= []
      OPTION_KEYS.each do |key|
        next if key == :strategy
        @strategy.instance_variable_set(:"@#{key}", self.send(key))
      end
      @agents << @strategy
    end
  end
end
