# requires tilt if available; falls back on bundled version.
begin
  require 'tilt'
rescue LoadError
  require 'sinatra/tilt'
end
require 'padrino-core/support_lite' unless defined?(SupportLite)

module Padrino
  ##
  # This component uses the +mail+ library to create a powerful but simple mailer within Padrino (and Sinatra).
  # There is full support for using plain or html content-types as well as for file attachments.
  #
  # Using the mailer in Padrino has two forms. The 'quick' method requires only use
  # of the +email+ method directly in the controller:
  #
  #  # app/controllers/session.rb
  #  post :create do
  #    email do
  #      from "tony@reyes.com"
  #      to "john@smith.com"
  #      subject "Welcome!"
  #      body render('email/registered')
  #    end
  #  end
  #
  # For a more detailed guide, please read the {Padrino Mailer}[http://www.padrinorb.com/guides/padrino-mailer] guide.
  #
  module Mailer
    class << self
      ##
      # Registers the Padrino::Mailer helpers with the application.
      #
      # @param [Sinatra::Application] app The application that needs mailers.
      #
      # @example
      #   require 'padrino-mailer'
      #   class Demo < Padrino::Application
      #     register Padrino::Mailer::Helpers
      #   end
      #
      # @api public
      def registered(app)
        require 'padrino-mailer/base'
        require 'padrino-mailer/helpers'
        require 'padrino-mailer/mime'
        # This lazily loads the mail gem, due to its long require time.
        app.set :_padrino_mailer, proc {
          begin
            app._padrino_mailer = Mail
          rescue NameError
            require 'mail'
            require 'padrino-mailer/ext'
            app._padrino_mailer = Mail
          end
        }
        app.helpers Padrino::Mailer::Helpers
      end
      alias :included :registered
    end
  end # Mailer
end # Padrino
