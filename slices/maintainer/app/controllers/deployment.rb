class Maintainer::Deployment < Maintainer::Application

  include Merb::Maintainer::TasksHelper
  before :initialize_repo

  def index
    @branches = @git.branches.local.map(&:full)
    @current_branch = @git.current_branch
    render :layout => false
  end

  def deploy
    @branches = @git.branches.local.map(&:full)
    @current_branch = @git.current_branch

    if @current_branch == params[:branch]
      @git.pull('origin', @current_branch)            # NOTE: the git gem's pull actually does a fetch. That's why we have to do a merge below.
      msg = @git.remote('origin').merge('master')
      unless msg == "Already up-to-date."
        DataMapper.repository(:maintainer) {
          Maintainer::DeploymentItem.create(
            :sha     => @git.log.first.sha,
            :message => @git.log.first.message,
            :time    => Time.now
          )
        }
        log({
          :action => 'deployed',
          :ip     => request.remote_ip,
          :name   => @git.log.first.sha
        })
        # TODO: perform optional database upgrade
        # TODO: restart instance
      end
    else
      # TODO: implement branch change
    end

    refresh_rake_tasks_file

    redirect('/maintain#deployment')
  end

  def rollback
    @git.reset_hard(@git.gcommit(params[:sha]))
    # TODO: remove DeploymentItems from db
    return "true"
  end

  def check
    s = `git remote show origin`.split("\n")
    status = s.slice(s.index(s.grep(/Local refs? configured for 'git push':/).first)+1..-1).grep(/#{params[:branch]}/).first[/\(.*\)/]
    if status == "(local out of date)"
      "yes"
    elsif status == "(up to date)"
      "no"
    end
  end

  private
  def initialize_repo
    @git = Git.open('/home/vicky/Documents/Mostfit/repo2')
  end

end
