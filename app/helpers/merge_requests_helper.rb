module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.default_merge_request_target
    project_new_merge_request_path(
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    {
      merge_request: {
        source_project_id: event.project.id,
        target_project_id: target_project.id,
        source_branch: event.branch_name,
        target_branch: target_project.repository.root_ref
      }
    }
  end

  def mr_css_classes(mr)
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path(merge_request)
    build_url = merge_request.source_project.ci_service.build_page(merge_request.diff_head_sha, merge_request.source_branch)
    return nil unless build_url

    parsed_url = URI.parse(build_url)

    unless parsed_url.userinfo.blank?
      parsed_url.userinfo = ''
    end

    parsed_url.to_s
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "项目:分支: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.full_path}:#{@merge_request.target_branch}"
    else
      "分支: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  def mr_change_branches_path(merge_request)
    project_new_merge_request_path(
      @project,
      merge_request: {
        source_project_id: merge_request.source_project_id,
        target_project_id: merge_request.target_project_id,
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch
      },
      change_branches: true
    )
  end

  def format_mr_branch_names(merge_request)
    source_path = merge_request.source_project_path
    target_path = merge_request.target_project_path
    source_branch = merge_request.source_branch
    target_branch = merge_request.target_branch

    if source_path == target_path
      [source_branch, target_branch]
    else
      ["#{source_path}:#{source_branch}", "#{target_path}:#{target_branch}"]
    end
  end

  def target_projects(project)
    MergeRequestTargetProjectFinder.new(current_user: current_user, source_project: project)
      .execute
  end

  def merge_request_button_visibility(merge_request, closed)
    return 'hidden' if merge_request.closed? == closed || (merge_request.merged? == closed && !merge_request.closed?) || merge_request.closed_without_fork?
  end

  def merge_request_version_path(project, merge_request, merge_request_diff, start_sha = nil)
    diffs_project_merge_request_path(project, merge_request, diff_id: merge_request_diff.id, start_sha: start_sha)
  end

  def version_index(merge_request_diff)
    @merge_request_diffs.size - @merge_request_diffs.index(merge_request_diff)
  end

  def different_base?(version1, version2)
    version1 && version2 && version1.base_commit_sha != version2.base_commit_sha
  end

  def merge_params(merge_request)
    {
      merge_when_pipeline_succeeds: true,
      should_remove_source_branch: true,
      sha: merge_request.diff_head_sha
    }.merge(merge_params_ee(merge_request))
  end

  def tab_link_for(merge_request, tab, options = {}, &block)
    data_attrs = {
      action: tab.to_s,
      target: "##{tab}",
      toggle: options.fetch(:force_link, false) ? '' : 'tab'
    }

    url = case tab
          when :show
            data_attrs[:target] = '#notes'
            method(:project_merge_request_path)
          when :commits
            method(:commits_project_merge_request_path)
          when :pipelines
            method(:pipelines_project_merge_request_path)
          when :diffs
            method(:diffs_project_merge_request_path)
          else
            raise "Cannot create tab #{tab}."
          end

    link_to(url[merge_request.project, merge_request], data: data_attrs, &block)
  end

  def merge_params_ee(merge_request)
    {}
  end
end
