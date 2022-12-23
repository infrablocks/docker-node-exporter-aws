# frozen_string_literal: true

require 'spec_helper'

describe 'commands' do
  image = 'node-exporter-aws:latest'
  extra = {
    'Entrypoint' => '/bin/sh'
  }

  before(:all) do
    set :backend, :docker
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  after(:all, &:reset_docker_backend)

  it 'includes the node_exporter command' do
    expect(command('/opt/node-exporter/bin/node_exporter --version').stdout)
      .to(match(/1.5.0/))
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end
end
