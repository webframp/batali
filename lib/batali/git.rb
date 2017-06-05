require 'git'
require 'batali'

# Batali namespace
module Batali
  # Helper module for git interactions
  module Git

    # @return [String] path to repository clone
    def base_path
      File.join(cache_path, Base64.urlsafe_encode64(url))
    end

    # Clone the repository to the local machine
    #
    # @return [TrueClass]
    def clone_repository
      if(File.directory?(base_path))
        repo = ::Git.open(base_path)
        Batali.ui.debug "#{__method__} repo: #{repo.remote.url}"
        Batali.ui.debug "#{__method__} called with base #{base_path}"
        repo.checkout('master')
        repo.checkout_index(:all => true, :force => true)
        if repo.status.changed.any?
          Batali.ui.debug "#{__method__}: override commit"
          repo.commit_all("Batali: commit from #{__method__}")
        end
        repo.pull
        repo.fetch
      else
        ::Git.clone(url, base_path)
      end
      true
    end

    # Duplicate reference and store
    #
    # @return [String] commit SHA
    # @note this will update ref to SHA
    def ref_dup
      git = ::Git.open(base_path)
      Batali.ui.debug "#{__method__} repo: #{git.remote.url}"
      Batali.ui.debug "#{__method__} called with base #{base_path}"
      git.checkout(ref)
      git.checkout_index(:all => true, :force => true)
      if git.status.changed.any?
        Batali.ui.debug "#{__method__}: override commit"
        git.commit_all("Batali: commit from #{__method__}")
      end
      git.pull('origin', ref)
      self.ref = git.log.first.sha
      self.path = File.join(cache_path, 'git', ref)
      unless(File.directory?(path))
        FileUtils.mkdir_p(path)
        FileUtils.cp_r(File.join(base_path, '.'), path)
        FileUtils.rm_rf(File.join(path, '.git'))
      end
      path
    end

    # Load attributes into class
    def self.included(klass)
      klass.class_eval do
        attribute :url, String, :required => true, :equivalent => true
        attribute :ref, String, :required => true, :equivalent => true
      end
    end

  end
end
