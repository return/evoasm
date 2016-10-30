require 'evoasm/test'
require 'evoasm/population'
require 'evoasm/x64'
require 'evoasm'

require 'population_helper'

module Evoasm
  class PopulationTest < Minitest::Test
    include PopulationHelper

    def setup
      set_population_parameters_ivars
    end

    def test_unseeded
      error = assert_raises Evoasm::Error do
        deme = new_population
        deme.evaluate { |_, _|}
      end

      assert_match /seed/, error.message
    end

    def test_no_error
      start
    end

    def test_no_instructions
      @instruction_names = []
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /instructions/, error.message
    end

    def test_no_parameters
      @parameters = []
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /parameters/, error.message
    end

    def test_no_examples
      @examples = {}
      error = assert_raises Evoasm::Error do
        start
      end

      assert_match /input|output/, error.message
    end

    def test_invalid_deme_size
      @deme_size = 0
      error = assert_raises Evoasm::Error do
        start
      end
      assert_match /deme size/i, error.message
    end

    def test_invalid_program_size
      [0, (0..0)].each do |program_size|
        @program_size = program_size
        error = assert_raises Evoasm::Error do
          start
        end
        assert_match /program size/i, error.message
      end
    end

    def test_invalid_kernel_size
      [0, (0..0)].each do |kernel_size|
        @kernel_size = kernel_size
        error = assert_raises Evoasm::Error do
          start
        end
        assert_match /kernel size/i, error.message
      end
    end
  end
end