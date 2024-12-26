#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/puppet_x/jay7x/sfboot/cli_helper'
require_relative '../../ruby_task_helper/files/task_helper' unless Object.const_defined?('TaskHelper')

# Run sfboot
class SfbootTask < TaskHelper
  def task(opts = {})
    @sfboot_helper ||= opts.delete(:cli_helper) || PuppetX::Sfboot::CliHelper.new
    adapter = opts.delete(:adapter)

    begin
      { sfboot: @sfboot_helper.set_attrs(opts, adapter) }
    rescue PuppetX::Sfboot::Error => e
      raise TaskHelper::Error.new(e.message, 'sfboot/task-error')
    end
  end
end

SfbootTask.run if $PROGRAM_NAME == __FILE__
