class Page < ActiveRecord::Base
  acts_as_tree
  
  validates_presence_of :name
  
  def replace_placeholders(params, objects)
    @params = params
    @objects = objects
    replace_url if self.url
    @parsed_name = self.name.split(',', 2)
    replace_name if @objects[@parsed_name.first.intern]
  end
  
  def create_ancestors(controller, action, default)
    case action
    when 'new', 'create', 'edit', 'update'
      self.parent_id = Page.find_by_controller_action("#{controller}/index#{default}").id
    when 'copy', 'create_copy'
      self.parent_id = Page.find_by_controller_action("#{controller}/show_item#{default}").id
    end
  end
  
  def parse_url
    if self.url
      @parsed_url = self.url.split('/')
    else
      @parsed_url = ['','']
    end
  end
  
  def replace_url
    parse_url
    url = ''
    @parsed_url.each do |url_fragment|
      if url_fragment =~ %r{id}
        unless @params[url_fragment.intern]
          fit_to_pattern
        end
        url_fragment = @params[url_fragment.intern]
      end
      url += "#{url_fragment}/"
    end
    self.url = url
  end
  
  def replace_name
    object_id = ''
    parse_url
    @parsed_url.each do |url_fragment|
      object_id = url_fragment unless url_fragment.to_i == 0
    end
    object_id = @params[:id] unless object_id.to_i != 0
    self.name = @objects[@parsed_name.first.intern].find(object_id)[@parsed_name.last.intern]
  end
  
  def fit_to_pattern
    if @params[:id] && @params[:controller] == "entry_groups"
      @params[:entry_group_id] = @params[:id]
    elsif @params[:frontend_group_id] && @params[:controller] == "frontend_numbers"
      @params[:id] = @params[:frontend_group_id]
    else
      if @params[:routing_id]
        package = Routing.find(@params[:routing_id]).time_segment.profile.package
      elsif @params[:time_segment_id]
        package = TimeSegment.find(@params[:time_segment_id]).profile.package
      elsif @params[:profile_id]
        package = Profile.find(@params[:profile_id]).package
      elsif @params[:package_id]
        package = Package.find(@params[:package_id])
      end
      if package
        @params[:backend_number_id] = package.vlabel_map.id
        @params[:id] = package.id
      end
    end
  end
end
