class Exit
  attr_reader :type, :value, :app_id, :dequeue_value, :after_prompt, :id
  
  def initialize(init_obj = {}, app_id = nil)
    case init_obj
    when Hash
      from_hash(init_obj, app_id)
    when RoutingExit, RaccRouteDestinationXref, LabelDestinationMap, Location
      from_xref(init_obj)
    end
  end

  def source
    @source ||= find
  end
 
  def description
    return '' if source.nil?

    case source
    when Destination; "Destination: #{source.destination_title}"
    when VlabelMap; "Number/Label: #{source.description}"
    when MediaFile; "Prompt"
    end
  end

  def dtype
    return '' if source.nil?

    case source
    when Destination
      return 'M' if source.mappable?
      return 'D'
    when VlabelMap
      return 'O'
    when MediaFile
      return '5' if after_prompt == 'continue'
      return 'P'
    end
  end

  def transfer_lookup
    return 'O' if requires_dequeue?
    return ''
  end

  def requires_dequeue?
    if source.present? && source.is_a?(Destination)
      source.is_queue?
    else
      false
    end
  end

  def ==(o)
    o.class == self.class && o.state == self.state
  end
  alias_method :eql?, :==

  def hash
    state.hash
  end

  def validate(parent_obj)
    case parent_obj
    when Package, PrerouteGroup, RoutingExit, VlabelMap
      attrs = {:exit => :route_to, :dest => :destination, :dequeue => :dequeue_route}
    when Location
      attrs = {:exit => :default_exit, :dest => :destination, :dequeue => :base}
    end
    
    if source.nil?
      parent_obj.errors.add(attrs[:exit], 'must be a valid destination, number, label, or prompt')
    end

    if 'Destination' == @type
      unless Destination.destination_verified_for_package(@app_id, @value)
        msg = "must exist. #{Destination::DIVR_MESSAGE}"
        parent_obj.errors.add(attrs[:dest], msg)
      end
    end

    if requires_dequeue?
      company = Company.find(@app_id)
      parent_obj.errors.add(:base, I18n.t('errors.messages.queuing_deactivated')) unless company.queuing_active?

      vlabel = VlabelMap.find_by_vlabel_and_app_id(@dequeue_value, @app_id)
      parent_obj.errors.add(attrs[:dequeue], 'must exist') unless vlabel
    end
  end

  protected

  def from_hash(attributes, app_id)
    attrs = attributes.stringify_keys
    @id = attrs['id']
    @type = attrs['type']
    @value = attrs['value']
    @dequeue_value = attrs['dequeue_value']
    @after_prompt = attrs['after_prompt']
    @app_id = app_id
  end

  def from_xref(xref)
    @id = xref.id
    @type = xref.exit_type
    @dequeue_value = xref.dequeue_label unless xref.class == LabelDestinationMap
    @app_id = xref.app_id

    @value = case xref.exit
    when Destination; xref.exit.destination
    when VlabelMap; xref.exit.vlabel
    when MediaFile; xref.exit.keyword
    end

    if xref.exit.is_a?(MediaFile) && xref.respond_to?(:dtype)
      @after_prompt = 'continue' if xref.dtype == '5'
      @after_prompt = 'stop' if xref.dtype == 'P'
    else
      @after_prompt = ''
    end
  end

  def find
    case @type
    when 'Destination'
      Destination.find_by_destination_and_app_id(@value, @app_id)
    when 'VlabelMap'
      VlabelMap.find_by_vlabel_and_app_id(@value, @app_id)
    when 'MediaFile'
      MediaFile.find_by_keyword_and_app_id(@value, @app_id)
    end
  end
 
  def state
    [@type, @value, @dequeue_value, @app_id]
  end
end
