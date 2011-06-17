class Maintainer::Application < Merb::Controller
  require 'slices/maintainer/lib/utils'
  include Merb::Maintainer::Utils

  before :ensure_authenticated
  before :ensure_is_maintainer

  controller_for_slice

  def ensure_is_maintainer
    unless session.user and session.user.role == :maintainer
      raise NotPrivileged
    end
  end
end
