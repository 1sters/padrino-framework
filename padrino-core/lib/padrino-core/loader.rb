module Padrino
  class << self

    ##
    # Hooks to be called before a load/reload
    #
    # ==== Examples
    #
    #   before_load do
    #     pre_initialize_something
    #   end
    #
    #
    def before_load(&block)
      @_before_load ||= []
      @_before_load << block if block_given?
      @_before_load
    end

    ##
    # Hooks to be called after a load/reload
    #
    # ==== Examples
    #
    #   after_load do
    #     DataMapper.finalize
    #   end
    #
    #
    def after_load(&block)
      @_after_load ||= []
      @_after_load << block if block_given?
      @_after_load
    end

    ##
    # Returns the used $LOAD_PATHS from padrino
    #
    def load_paths
      @_load_paths_was = %w(lib models shared).map { |path| Padrino.root(path) }
      @_load_paths ||= @_load_paths_was
    end

    ##
    # Require all necessary core dependencies
    #
    def load_core!
      @_called_from = first_caller
      Padrino.set_encoding
      Padrino.set_load_paths(*load_paths) # We set the padrino load paths
      Padrino::Logger.setup! # Initialize our logger
      Padrino.require_dependencies("#{root}/config/database.rb", :nodeps => true) # Be sure to don't remove constants from dbs.
      Thread.current[:padrino_loaded] = true
    end

    ##
    # Requires necessary applications dependencies as well as application files from root lib and models
    #
    def load_application!
      # stdout_was = STDOUT.dup
      # STDOUT.reopen('/dev/null', 'a')
      # $stdout = STDOUT
      Padrino.before_load.each(&:call) # Run before hooks
      Padrino.dependency_paths.each { |path| Padrino.require_dependencies(path) }
      Padrino.after_load.each(&:call) # Run after hooks
    #   stdout_was
    # ensure
    #   STDOUT.reopen(stdout_was)
    #   $stdout = STDOUT
    end

    ##
    # Load all core and application dependencies
    #
    def load!
      return false if loaded?
      load_core!
      load_application!
      true
    end

    ##
    # This adds the ablity to instantiate Padrino.load! after Padrino::Application definition.
    #
    def called_from
      @_called_from || first_caller
    end

    ##
    # Return true if Padrino was loaded with Padrino.load!
    #
    def loaded?
      Thread.current[:padrino_loaded] || ENV["PADRINO_LOADED"]
    end

    ##
    # Attempts to require all dependency libs that we need.
    # If you use this method we can perform correctly a Padrino.reload!
    # Another good thing that this method are dependency check, for example:
    #
    #   models
    #    \-- a.rb => require something of b.rb
    #    \-- b.rb
    #
    # In the example above if we do:
    #
    #   Dir["/models/*.rb"].each { |r| require r }
    #
    # we get an error, because we try to require first a.rb that need +something+ of b.rb.
    #
    # With +require_dependencies+ we don't have this problem.
    #
    # ==== Examples
    #
    #   # For require all our app libs we need to do:
    #   require_dependencies("#{Padrino.root}/lib/**/*.rb")
    #
    def require_dependencies(*paths)
      options = paths.extract_options!

      # Extract all files to load
      files = paths.flatten.map { |path| Dir[path] }.flatten.uniq.sort

      while files.present?
        # List of errors and failed files
        errors, failed = [], []

        # We need a size to make sure things are loading
        size_at_start = files.size

        # Now we try to require our dependencies, we dup files
        # so we don't perform delete on the original array during
        # iteration, this prevent problems with rubinus
        files.dup.each do |file|
          begin
            require file
            files.delete(file)
          rescue LoadError => e
            errors << e
            failed << file
          rescue NameError => e
            errors << e
            failed << file
          rescue Exception => e
            raise e
          end
        end

        # Stop processing if nothing loads or if everything has loaded
        raise errors.last if files.size == size_at_start && files.present?
        break if files.empty?
      end
    end

    ##
    # Returns default list of path globs to load as dependencies
    # Appends custom dependency patterns to the be loaded for Padrino
    #
    # ==== Examples
    #    Padrino.dependency_paths << "#{Padrino.root}/uploaders/*.rb"
    #
    def dependency_paths
      @_dependency_paths_was = [
        "#{root}/config/database.rb", "#{root}/lib/**/*.rb", "#{root}/shared/lib/**/*.rb",
        "#{root}/models/**/*.rb", "#{root}/shared/models/**/*.rb", "#{root}/config/apps.rb"
      ]
      @_dependency_paths ||= @_dependency_paths_was
    end

    ##
    # Concat to $LOAD_PATH the given paths
    #
    def set_load_paths(*paths)
      $:.concat(paths); load_paths.concat(paths)
      $:.uniq!; load_paths.uniq!
    end
  end # self
end # Padrino