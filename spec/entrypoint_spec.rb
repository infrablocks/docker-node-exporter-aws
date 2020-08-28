require 'spec_helper'

describe 'entrypoint' do
  metadata_service_url = 'http://metadata:1338'
  s3_endpoint_url = 'http://s3:4566'
  s3_bucket_region = 'us-east-1'
  s3_bucket_path = 's3://bucket'
  s3_env_file_object_path = 's3://bucket/env-file.env'

  environment = {
      'AWS_METADATA_SERVICE_URL' => metadata_service_url,
      'AWS_ACCESS_KEY_ID' => "...",
      'AWS_SECRET_ACCESS_KEY' => "...",
      'AWS_S3_ENDPOINT_URL' => s3_endpoint_url,
      'AWS_S3_BUCKET_REGION' => s3_bucket_region,
      'AWS_S3_ENV_FILE_OBJECT_PATH' => s3_env_file_object_path
  }
  image = 'node-exporter-aws:latest'
  extra = {
      'Entrypoint' => '/bin/sh',
      'HostConfig' => {
          'NetworkMode' => 'docker_node_exporter_aws_test_default'
      }
  }

  before(:all) do
    set :backend, :docker
    set :env, environment
    set :docker_image, image
    set :docker_container_create_options, extra
  end

  describe 'by default' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path)

      execute_docker_entrypoint(
          started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'runs node exporter' do
      expect(process('/opt/node-exporter/bin/node_exporter')).to(be_running)
    end

    it 'logs using JSON' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--log.format=json/))
    end

    it 'uses a log level of info' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--log.level=info/))
    end

    it 'listens on port 9100' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--web\.listen-address=:9100/))
    end

    it 'uses a rootfs path of /host' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.rootfs=\/host/))
    end

    it 'uses a procfs path of /proc' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.procfs=\/proc/))
    end

    it 'uses a sysfs path of /sys' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.sysfs=\/sys/))
    end

    it 'ignores container filesystem' do
      option = "--collector.filesystem.ignored-mount-points"
      escaped_val = Regexp.escape("^/(dev|proc|run|sys|host|var/lib/docker/.+)($|/)")

      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/#{option}=#{escaped_val}/))
    end

    it 'runs with the nobody user' do
      expect(process('/opt/node-exporter/bin/node_exporter').user)
          .to(eq('nobody'))
    end

    it 'runs with the nobody group' do
      expect(process('/opt/node-exporter/bin/node_exporter').group)
          .to(eq('nobody'))
    end
  end

  describe 'with path overrides' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'NODE_EXPORTER_PATH_ROOTFS' => '/mnt/root',
              'NODE_EXPORTER_PATH_SYSFS' => '/mnt/sys',
              'NODE_EXPORTER_PATH_PROCFS' => '/mnt/proc'
          })

      execute_command('ln -s / /mnt/root')
      execute_command('ln -s /sys /mnt/sys')
      execute_command('ln -s /proc /mnt/proc')

      execute_docker_entrypoint(
          started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided rootfs path' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.rootfs=\/mnt\/root/))
    end

    it 'uses the provided procfs path' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.procfs=\/mnt\/proc/))
    end

    it 'uses the provided sysfs path' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--path.sysfs=\/mnt\/sys/))
    end
  end

  describe 'with log overrides' do
    before(:all) do
      create_env_file(
          endpoint_url: s3_endpoint_url,
          region: s3_bucket_region,
          bucket_path: s3_bucket_path,
          object_path: s3_env_file_object_path,
          env: {
              'NODE_EXPORTER_LOG_FORMAT' => 'logfmt',
              'NODE_EXPORTER_LOG_LEVEL' => 'debug'
          })

      execute_command('ln -s / /mnt/root')
      execute_command('ln -s /sys /mnt/sys')
      execute_command('ln -s /proc /mnt/proc')

      execute_docker_entrypoint(
          started_indicator: "Listening")
    end

    after(:all, &:reset_docker_backend)

    it 'uses the provided log format' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--log.format=logfmt/))
    end

    it 'uses a log level of info' do
      expect(process('/opt/node-exporter/bin/node_exporter').args)
          .to(match(/--log.level=debug/))
    end
  end

  def reset_docker_backend
    Specinfra::Backend::Docker.instance.send :cleanup_container
    Specinfra::Backend::Docker.clear
  end

  def create_env_file(opts)
    create_object(opts
        .merge(content: (opts[:env] || {})
            .to_a
            .collect { |item| " #{item[0]}=\"#{item[1]}\"" }
            .join("\n")))
  end

  def execute_command(command_string)
    command = command(command_string)
    exit_status = command.exit_status
    unless exit_status == 0
      raise RuntimeError,
          "\"#{command_string}\" failed with exit code: #{exit_status}"
    end
    command
  end

  def create_object(opts)
    execute_command('aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'mb ' +
        "#{opts[:bucket_path]} " +
        "--region \"#{opts[:region]}\"")
    execute_command("echo -n #{Shellwords.escape(opts[:content])} | " +
        'aws ' +
        "--endpoint-url #{opts[:endpoint_url]} " +
        's3 ' +
        'cp ' +
        '- ' +
        "#{opts[:object_path]} " +
        "--region \"#{opts[:region]}\" " +
        '--sse AES256')
  end

  def execute_docker_entrypoint(opts)
    logfile_path = '/tmp/docker-entrypoint.log'
    arguments = opts[:arguments] && !opts[:arguments].empty? ?
        " #{opts[:arguments].join(' ')}" : ''

    execute_command(
        "docker-entrypoint.sh#{arguments} " +
            "> #{logfile_path} 2>&1 &")

    begin
      Octopoller.poll(timeout: 15) do
        docker_entrypoint_log = command("cat #{logfile_path}").stdout
        docker_entrypoint_log =~ /#{opts[:started_indicator]}/ ?
            docker_entrypoint_log :
            :re_poll
      end
    rescue Octopoller::TimeoutError => e
      puts command("cat #{logfile_path}").stdout
      raise e
    end
  end
end