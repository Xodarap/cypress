class AdminController < ApplicationController
  before_filter :authenticate_user!
  before_filter :validate_authorization!

  add_breadcrumb 'Dashboard',"/"
  add_breadcrumb 'Admin',"/admin/index"
  add_breadcrumb "Users", '', :only=>"users"

  def index

  end


  def users
    @users = User.all
  end

  def import_bundle
    begin
      bundle = params[:bundle]
      importer = HealthDataStandards::Import::Bundle::Importer
      @bundle_contents = importer.import(bundle, {:update_measures=>params[:update_measures],
                                                  :delete_existing => params[:delete_existing]})
      b = Bundle.find(@bundle_contents["_id"])
      b[:active] = params[:active]
      b.save
    rescue
      flash[:errors] = $!.message
    end

    redirect_to :action=>:index
  end

  def clear_database
    ["bundles", "measures", "products", "vendors", "test_executions", "product_tests", "records", "patient_cache", "query_cache", "health_data_standards_svs_value_sets", "fs.chunks", "fs.files"].each do|collection|
      Mongoid.default_session[collection].drop
    end
    ::Mongoid::Tasks::Database.create_indexes
    redirect_to :action=>:index
  end

  def delete_bundle
    bundle = Bundle.find(params[:bundle_id])
    bundle.delete
    redirect_to :action=>:index
  end

  def activate_bundle
    bundle = Bundle.find(params[:bundle_id])
    enable = params[:active]
    bundle[:active] = enable
    bundle.save!
    if (bundle.active)

        render :text => "Yes - <a href=\"#\" class=\"disable\" data-bundleid=\"#{bundle.id}\">disable</span>"
      else
        render :text => "No - <a href=\"#\" class=\"enable\" data-bundleid=\"#{bundle.id}\">enable</span>"
    end
  end

  def valueset
    @valueset = HealthDataStandards::SVS::ValueSet.find(params[:id])
  end

  def promote
    toggle_privilidges(params[:username], params[:role], :promote)
  end

  def demote
    toggle_privilidges(params[:username], params[:role], :demote)
  end

  def disable
    user = User.where(:email=>params[:username]).first
    disabled = params[:disabled].to_i == 1
    if user
      user.update_attribute(:disabled, disabled)
      if (disabled)
        render :text => "<a href=\"#\" class=\"disable\" data-username=\"#{h(user.email)}\">disabled</span>"
      else
        render :text => "<a href=\"#\" class=\"enable\" data-username=\"#{h(user.email)}\">enabled</span>"
      end
    else
      render :text => "User not found"
    end
  end

 def approve
     user = User.where(:email=>params[:username]).first
    if user
      user.update_attribute(:approved, true)
      render :text => "true"
    else
      render :text => "User not found"
    end
  end

private

  def toggle_privilidges(username, role, direction)
    user = User.where(:email=>username).first

    if user
      if direction == :promote
        user.update_attribute(role, true)
        render :text => "Yes - <a href=\"#\" class=\"demote\" data-role=\"#{role}\" data-username=\"#{username}\">revoke</a>"
      else
        user.update_attribute(role, false)
        render :text => "No - <a href=\"#\" class=\"promote\" data-role=\"#{role}\" data-username=\"#{username}\">grant</a>"
      end
    else
      render :text => "User not found"
    end
  end

  def validate_authorization!
    authorize! :admin, :users
  end

end
