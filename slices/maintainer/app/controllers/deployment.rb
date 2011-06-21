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

    database_backup

    if @current_branch == params[:branch]
      branch = @current_branch
    else
      # branch change
      branch = params[:branch]
      @git.checkout(branch)
    end

    # perform the actual code fetch and merge
    # NOTE: the git gem's pull erroneously does a fetch. That's why we have to do a merge below.
    @git.pull('origin', branch)
    msg = @git.remote('origin').merge(branch)

    unless msg == "Already up-to-date."
      # record deployment in deployment and action histories
      DM_REPO.scope { Maintainer::DeploymentItem.create_from_last_commit }
      log({
        :action => (params[:upgrade_db] == "yes") ? ('deployed_and_upgraded') : ('deployed'),
        :ip     => request.remote_ip,
        :name   => @git.log.first.sha
      })

      if params[:upgrade_db] == "yes"
        # take the site offline
        `touch tmp/stop.txt`
        # perform database upgrade
        `rake db:autoupgrade > #{slice_path("log/db_upgrade.log")}`
        # start it up again
        `touch tmp/start.txt`
      else
        # restart instance
        `touch tmp/restart.txt`
      end

      refresh_rake_tasks_file
    end

    redirect('/maintain#deployment')
  end

  def rollback
    @git.reset_hard(@git.gcommit(params[:sha]))

    # remove appropriate DeploymentItems from db
    rollback_to = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => params[:sha]) }
    commits_to_trash = DM_REPO.scope { Maintainer::DeploymentItem.all(:time.gt => rollback_to.time) }
    commits_to_trash.destroy

    # log rollback in action history
    log({
      :action => 'rollback',
      :ip     => request.remote_ip,
      :name   => @git.log.first.sha
    })
    "true"
  end

  def create_initial_deployment_item
    DM_REPO.scope { create_deployment_item_from_last_commit if Maintainer::DeploymentItem.all.length == 0 }
  end

  def check_if_deployment_possible
    # s = `git remote show origin`.split("\n")
    # status = s.slice(s.index(s.grep(/Local refs? configured for 'git push':/).first)+1..-1).grep(/#{@git.current_branch}/).first[/\(.*\)/]
    Dir.chdir(GIT_REPO)
    `git remote update`
    status = (`git rev-list --max-count=1 refs/heads/#{@git.current_branch}` != `git rev-list --max-count=1 refs/remotes/origin/#{@git.current_branch}`)
    Dir.chdir(Merb.root)
    status.to_s
  end

  private
  def initialize_repo
    @git = Git.open(GIT_REPO)
  end

end
