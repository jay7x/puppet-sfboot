# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/modules/ruby_task_helper/files/task_helper'
require_relative '../../tasks/init'

describe SfbootTask do
  let(:task) { described_class.new }
  let(:opts) { { cli_helper: sfboot_helper } }
  let(:sfboot_helper) do
    helper = instance_double(PuppetX::Sfboot::CliHelper)
    helper
  end

  describe '#task' do
    let(:opts) { super().merge(adapter: 'enp196s0f1np1', firmware_variant: 'full-feature', boot_image: 'optionrom', link_speed: '10g') }

    it 'runs successfully' do
      expect(sfboot_helper).to receive(:set_attrs).with(
        {
          firmware_variant: 'full-feature',
          boot_image: 'optionrom',
          link_speed: '10g',
        },
        'enp196s0f1np1',
      ).and_return({ foo: 'bar' })

      result = task.task(opts)
      expect(result).to eq({ sfboot: { foo: 'bar' } })
    end
  end
end
