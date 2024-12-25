# frozen_string_literal: true

require 'spec_helper'
require 'puppet/type/sfboot_adapter'

describe 'the sfboot_adapter type' do
  it 'loads' do
    expect(Puppet::Type.type(:sfboot_adapter)).not_to be_nil
  end
end
