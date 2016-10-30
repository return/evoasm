require 'evoasm/prng'
require 'evoasm/program/io'
require 'evoasm/domain'

module Evoasm
  class Population
    class Parameters < FFI::AutoPointer

      def self.release(ptr)
        Libevoasm.pop_params_free ptr
      end

      attr_reader :input, :output

      def initialize(architecture, &block)
        ptr = Libevoasm.pop_params_alloc
        Libevoasm.pop_params_init ptr

        case architecture
        when :x64
          @inst_id_enum_type = Libevoasm.enum_type :x64_inst_id
          @param_id_enum_type = Libevoasm.enum_type :x64_param_id
        else
          raise "unknown architecture #{architecture}"
        end

        super(ptr)

        self.seed = PRNG::DEFAULT_SEED

        if block
          block[self]
        end
      end

      def mutation_rate
        Libevoasm.pop_params_get_mut_rate(self)
      end

      def mutation_rate=(mutation_rate)
        Libevoasm.pop_params_set_mut_rate self, mutation_rate
      end

      def deme_size
        Libevoasm.pop_params_get_deme_size self
      end

      def deme_size=(deme_size)
        Libevoasm.pop_params_set_deme_size self, deme_size
      end

      def deme_count
        Libevoasm.pop_params_get_n_demes self
      end

      def deme_count=(deme_count)
        Libevoasm.pop_params_set_n_demes self, deme_count
      end

      def parameters=(parameter_names)
        parameter_names.each_with_index do |parameter_name, index|
          Libevoasm.pop_params_set_param(self, index, parameters_enum_type[parameter_name])
        end
        Libevoasm.pop_params_set_n_params(self, parameter_names.size)
        puts "Setting n_params to #{parameter_names.size}"
        puts "n_params is #{Libevoasm.pop_params_get_n_params self}"
      end

      def parameters
        Array.new(Libevoasm.pop_params_get_n_params self) do |index|
          parameters_enum_type[Libevoasm.pop_params_get_param(self, index)]
        end
      end

      def domains=(domains_hash)
        domains = []
        domains_hash.each do |parameter_name, domain_value|
          domain = Domain.for domain_value
          success = Libevoasm.pop_params_set_domain(self, parameter_name, domain)
          if !success
            raise ArgumentError, "no such parameter #{parameter_name}"
          end
          domains << domain
        end

        # keep reference to prevent disposal by GC
        @domains = domains
      end

      def domains
        parameters.map do |parameter_name|
          domain_ptr = Libevoasm.pop_params_get_domain(self, parameter_name)
          domain = @domains.find { |domain| domain == domain_ptr }
          [parameter_name, domain]
        end.to_h
      end

      def seed=(seed)
        if seed.size != PRNG::SEED_SIZE
          raise ArgumentError, 'invalid seed size'
        end

        seed.each_with_index do |seed_value, index|
          Libevoasm.pop_params_set_seed(self, index, seed_value)
        end
      end

      def seed
        Array.new(PRNG::SEED_SIZE) do |index|
          Libevoasm.pop_params_get_seed(self, index)
        end
      end

      def validate!
        unless Libevoasm.pop_params_validate(self)
          raise Error.last
        end
      end

      def instructions=(instructions)
        instructions.each_with_index do |instruction, index|
          name =
            if instruction.is_a? Symbol
              instruction
            else
              instruction.name
            end
          Libevoasm.pop_params_set_inst(self, index, name)
        end
        Libevoasm.pop_params_set_n_insts(self, instructions.size)
      end

      def instructions
        Array.new(Libevoasm.pop_params_get_n_insts self) do |index|
          @inst_id_enum_type[Libevoasm.pop_params_get_inst(self, index)]
        end
      end

      %w(kernel_size program_size).each do |attr_name|
        define_method attr_name do
          min = Libevoasm.send "pop_params_get_min_#{attr_name}", self
          max = Libevoasm.send "pop_params_get_max_#{attr_name}", self

          if min == max
            return min
          else
            return (min..max)
          end
        end

        define_method "#{attr_name}=" do |value|
          case value
          when Range
            min = value.min
            max = value.max
          else
            min = value
            max = value
          end

          Libevoasm.send "pop_params_set_min_#{attr_name}", self, min
          Libevoasm.send "pop_params_set_max_#{attr_name}", self, max
        end
      end

      def recur_limit
        Libevoasm.pop_params_get_recur_limit self
      end

      def recur_limit=(recur_limit)
        Libevoasm.pop_params_set_recur_limit self, recur_limit
      end

      def examples=(examples)
        input_examples = examples.keys.map { |k| Array(k) }
        output_examples = examples.values.map { |k| Array(k) }

        self.input = Program::Input.new input_examples
        self.output = Program::Output.new output_examples
      end

      def input=(input)
        @input = input
        Libevoasm.pop_params_set_program_input self, input
      end

      def output=(output)
        @output = output
        Libevoasm.pop_params_set_program_output self, output
      end

      def examples
        input.zip(output).to_h
      end

      private
      def parameters_enum_type
        @param_id_enum_type
      end
    end
  end
end
