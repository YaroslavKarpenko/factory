# frozen_string_literal: true

# * Here you must define your `Factory` class.
# * Each instance of Factory could be stored into variable. The name of this variable is the name of created Class
# * Arguments of creatable Factory instance are fields/attributes of created class
# * The ability to add some methods to this class must be provided while creating a Factory
# * We must have an ability to get/set the value of attribute like [0], ['attribute_name'], [:attribute_name]
#
# * Instance of creatable Factory class should correctly respond to main methods of Struct
# - each
# - each_pair
# - dig
# - size/length
# - members
# - select
# - to_a
# - values_at
# - ==, eql?

class Factory
  class << self
    def new(first_arg, *factory_args, &block)
      const_set(first_arg, class_creator(*factory_args)) if first_arg.is_a? String
      class_creator(*factory_args.unshift(first_arg), &block)
    end

    def class_creator(*factory_args, &block)
      Class.new do
        attr_accessor(*factory_args)

        define_method :initialize do |*arg_from_new_class|
          raise ArgumentError, 'Extra arguments passed' unless factory_args.count == arg_from_new_class.count

          factory_args.zip(arg_from_new_class).to_h.each do |variable, value|
            instance_variable_set("@#{variable}", value)
          end
        end

        define_method :each do |&container|
          values.each(&container)
        end

        define_method :each_pair do |&container|
          to_h.each(&container)
        end

        define_method :dig do |*args|
          args.inject(self) { |key, value| key[value] if key }
        end

        define_method :length do
          factory_args.size
        end

        alias_method :size, :length

        define_method :members do
          factory_args
        end

        define_method :select do |&container|
          values.select(&container)
        end

        define_method :to_a do
          instance_variables.collect { |factory_args| instance_variable_get(factory_args) }
        end

        alias_method :values, :to_a

        define_method :values_at do |*index|
          values.select { |value| index.include?(values.index(value)) }
        end

        define_method :eql? do |term|
          instance_of?(term.class) && values == term.values
        end

        alias_method :==, :eql?

        define_method :to_h do
          factory_args.zip(values).to_h
        end

        define_method :[] do |arg|
          arg.is_a?(Integer) ? values[arg] : instance_variable_get("@#{arg}")
        end

        define_method :[]= do |arg, value|
          variable_to_set = arg.is_a?(Integer) ? instance_variables[arg] : "@#{arg}"
          instance_variable_set(variable_to_set, value)
        end

        class_eval(&block) if block_given?
      end
    end
  end
end
