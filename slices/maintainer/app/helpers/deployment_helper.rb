module Merb::Maintainer::DeploymentHelper

  # helper to deploy code as per the options passed
  def deploy_code(params)

    @branches = @git.branches.local.map(&:full)
    @current_branch = @git.current_branch

    database_backup

    branch = params[:branch]
    unless @current_branch == branch
      # branch change
      @git.checkout(branch)
    end

    # perform the actual code fetch and merge
    # NOTE: the git gem's pull erroneously does a fetch. That's why we have to do a merge below.
    @git.pull('origin', branch)
    msg = @git.remote('origin').merge(branch)

    unless msg == "Already up-to-date."
      # record deployment in deployment and action histories
      DM_REPO.scope { Maintainer::DeploymentItem.create_from_last_commit }
      log(
        :action => (params[:upgrade_db] == "yes") ? ('deployed_and_upgraded') : ('deployed'),
        :ip     => request.remote_ip,
        :name   => @git.log.first.sha
      )

      if params[:upgrade_db] == "yes"
        instance_take_offline
        database_upgrade
        instance_start
      else
        instance_restart
      end

      refresh_rake_tasks_file
    end

  end

  # helper to rollback code to a particular DeploymentItem
  def rollback_code(params)
    deployment = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => params[:sha]) }

    # checkout to the rollback commit's branch and reset to that commit
    @git.checkout(deployment.branch) unless deployment.branch == @git.current_branch
    @git.reset_hard(@git.gcommit(params[:sha]))

    # remove appropriate DeploymentItems from db
    rollback_to = DM_REPO.scope { Maintainer::DeploymentItem.first(:sha => params[:sha]) }
    commits_to_trash = DM_REPO.scope { Maintainer::DeploymentItem.all(:time.gt => rollback_to.time) }
    commits_to_trash.destroy

    # log rollback in action history
    log(
      :action => 'rollback',
      :ip     => request.remote_ip,
      :name   => @git.log.first.sha
    )
  end

  def deployable?
    Dir.chdir(GIT_REPO)
    `git remote update`
    status = (`git rev-list --max-count=1 refs/heads/#{@git.current_branch}` != `git rev-list --max-count=1 refs/remotes/origin/#{@git.current_branch}`)
    Dir.chdir(Merb.root)
    return status.to_s
  end

end
