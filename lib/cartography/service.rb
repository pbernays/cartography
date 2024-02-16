# frozen_string_literal: true

require "forwardable"

module Cartography
  class Service
    class << self
      extend Forwardable

      def delegate_to_instance(*methods)
        class << self; self; end.def_delegators :new, *methods
      end

      def attribute(name, as: nil, array: false, assert: nil)
        method_name = as || name

        define_method(method_name) do |arg|
          assert_unlocked!

          if assert and not instance_exec(arg, &assert)
            fail ArgumentError, "#{Cartography.inflector.humanize(name)} not supported by #{adapter_name}: #{arg}"
          end

          if array
            arg = Array(arg)
            arg.map! { |obj| Cartography::Location.from(obj) } if array == :locations
          end

          attributes[name] = arg

          self
        end

        define_method(name) { attributes[name] }
        delegate_to_instance method_name
      end
    end

    attr_accessor :adapter, :api_key, :async

    def initialize(adapter: nil, api_key: nil, async: false)
      @adapter = adapter || Cartography.adapter
      @api_key = api_key || Cartography.config[@adapter]&.api_key
      @async   = !!async
    end

    def data
      @data ||= adapter_instance.call(**attributes).tap { lock! }
    end

    def lock!
      attributes.freeze
    end

    def locked?
      attributes.frozen?
    end

    def unlock!
      @attributes = attributes.dup
      @data = nil
    end

    def service_name
      @service_name ||= Cartography.inflector.demodulize(self.class)
    end

    def adapter_name
      @adapter_name ||= Cartography.inflector.classify(adapter)
    end

    def adapter_module
      @adapter_module ||= Adapters.const_get(adapter_name)
    rescue NameError
      raise AdapterMissing, "No such adapter: #{adapter_name}"
    end

    def adapter_class
      @adapter_class ||= adapter_module.const_get(service_name)
    rescue NameError
      raise ServiceMissing, "No such service for #{adapter_name}: #{service_name}"
    end

    def adapter_instance
      @adapter_instance ||= adapter_class.new(api_key: api_key, async: async)
    end

    private

    def attributes
      @attributes ||= {}
    end

    def assert_unlocked!
      fail ServiceLocked, "can't modify attributes after making a request" if locked?
    end
  end
end
