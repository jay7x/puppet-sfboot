# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/sfboot_global'

describe 'the sfboot_global type' do
  it 'loads' do
    expect(Puppet::Type.type(:sfboot_global)).not_to be_nil
  end
end
