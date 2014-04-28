# encoding: UTF-8
# coding: UTF-8
# -*- coding: UTF-8 -*-

require_relative 'spec_helper'

describe 'gotcms::default' do
  include_context 'gotcms_stubs'

  describe 'Normal execution on Redhat' do
    let(:chef_run) { ChefSpec::Runner.new(REDHAT_OPTS).converge(described_recipe) }

    it 'includes recipes' do
      expect(chef_run).to include_recipe('php')
      expect(chef_run).to include_recipe('apache2')
      expect(chef_run).to include_recipe('apache2::mod_php5')
      expect(chef_run).to include_recipe('gotcms::database')
    end

    it 'create directory' do
      expect(chef_run).to create_directory('/var/www/html/gotcms').with(
        owner: 'apache',
        group: 'apache'
      )
    end

    it 'download archive' do
      expect(chef_run).to create_remote_file('/var/chef/cache/gotcms.tar.gz').with(
        source: 'https://github.com/GotCms/GotCms/archive/master.tar.gz'
      )
    end

    it 'extract archive' do
      expect(chef_run).to run_execute('extract-gotcms').with(
        command: 'tar xf /var/chef/cache/gotcms.tar.gz --strip-components 1 -C /var/www/html/gotcms',
        creates: '/var/www/html/gotcms/public/index.php'
      )
    end

    ['config/autoload', 'public/frontend', 'public/media', 'data/cache'].each do |path|
      it "prepare #{path} directory" do
        expect(chef_run).to create_directory("/var/www/html/gotcms/#{path}").with(
          recursive: true,
          mode: '775',
          owner: 'apache',
          group: 'apache'
        )
      end
    end
  end

  describe 'Override attributes on Redhat' do
    let(:chef_run) do
      ChefSpec::Runner.new(REDHAT_OPTS) do |node|
        node.set['gotcms']['parent_dir'] = '/home/got'
        node.set['apache']['group'] = 'got'
        node.set['apache']['user'] = 'got'
      end.converge(described_recipe)
    end

    it 'includes recipes' do
      expect(chef_run).to include_recipe('php')
      expect(chef_run).to include_recipe('apache2')
      expect(chef_run).to include_recipe('apache2::mod_php5')
      expect(chef_run).to include_recipe('gotcms::database')
    end

    it 'create directory' do
      expect(chef_run).to create_directory('/home/got/gotcms').with(
        owner: 'got',
        group: 'got'
      )
    end

    it 'download archive' do
      expect(chef_run).to create_remote_file('/var/chef/cache/gotcms.tar.gz').with(
        source: 'https://github.com/GotCms/GotCms/archive/master.tar.gz'
      )
    end

    it 'extract archive' do
      expect(chef_run).to run_execute('extract-gotcms').with(
        command: 'tar xf /var/chef/cache/gotcms.tar.gz --strip-components 1 -C /home/got/gotcms',
        creates: '/home/got/gotcms/public/index.php'
      )
    end

    ['config/autoload', 'public/frontend', 'public/media', 'data/cache'].each do |path|
      it "prepare #{path} directory" do
        expect(chef_run).to create_directory("/home/got/gotcms/#{path}").with(
          recursive: true,
          mode: '775',
          owner: 'got',
          group: 'got'
        )
      end
    end
  end

  # Actually can't test definitions
  # it 'create web app' do
  #   expect(chef_run).to enable_web_app('gotcms').with(
  #     template: 'gotcms.conf.erb',
  #     docroot: '/var/www/html/gotcms/public',
  #     server_name: 'gotcms',
  #     server_aliases: 'gotcms',
  #     server_port: '80',
  #     enable: true
  #   )
  # end
end