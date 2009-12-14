require 'active_dotfile'

module Historian
  class Configuration
    include ActiveDotfile::Configurable
    load_dotfiles_on_initialize

    attr_accessor_with_default :map => {}
  end
end
