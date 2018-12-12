# frozen_string_literal: true

class Admin::GroupsController < Admin::ApplicationController
  include MembersPresentation

  before_action :group, only: [:edit, :update, :destroy, :project_update, :members_update]

  def index
    @groups = Group.with_statistics.with_route
    @groups = @groups.sort_by_attribute(@sort = params[:sort])
    @groups = @groups.search(params[:name]) if params[:name].present?
    @groups = @groups.page(params[:page])
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def show
    @group = Group.with_statistics.joins(:route).group('routes.path').find_by_full_path(params[:id])
    @members = present_members(
      @group.members.order("access_level DESC").page(params[:members_page]))
    @requesters = present_members(
      AccessRequestsFinder.new(@group).execute(current_user))
    @projects = @group.projects.with_statistics.page(params[:projects_page])
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def new
    @group = Group.new
  end

  def edit
  end

  def create
    @group = Group.new(group_params)
    @group.name = @group.path.dup unless @group.name

    if @group.save
      @group.add_owner(current_user)
      redirect_to [:admin, @group], notice: "群组 '#{@group.name}' 创建成功。"
    else
      render "new"
    end
  end

  def update
    if @group.update(group_params)
      redirect_to [:admin, @group], notice: '群组更新成功。'
    else
      render "edit"
    end
  end

  def members_update
    member_params = params.permit(:user_ids, :access_level, :expires_at)
    result = Members::CreateService.new(current_user, member_params.merge(limit: -1)).execute(@group)

    if result[:status] == :success
      redirect_to [:admin, @group], notice: '用户增加成功。'
    else
      redirect_to [:admin, @group], alert: result[:message]
    end
  end

  def destroy
    Groups::DestroyService.new(@group, current_user).async_execute

    redirect_to admin_groups_path,
                status: 302,
                alert: "群组 '#{@group.name}' 已列入删除计划表。"
  end

  private

  def group
    @group ||= Group.find_by_full_path(params[:id])
  end

  def group_params
    params.require(:group).permit(allowed_group_params)
  end

  def allowed_group_params
    [
      :avatar,
      :description,
      :lfs_enabled,
      :name,
      :path,
      :request_access_enabled,
      :visibility_level,
      :require_two_factor_authentication,
      :two_factor_grace_period
    ]
  end
end
