class ExitSearch
  class << self
    def all(app_id, term, for_mapped=nil)
      company = Company.find(app_id)
      results = for_mapped ? Location.for_mapped_dest_autocomplete(app_id, term) : Destination.for_autocomplete(app_id, term)
      results += VlabelMap.search_for(app_id, term) if company.allows_route_to_vlabels?
      results += MediaFile.search_for(app_id, term) if company.allows_route_to_media?

      format_as_autocomplete(results)
    end

    def find(app_id, term, for_mapped=nil)
      company = Company.find(app_id)
      results = for_mapped ? Location.for_mapped_dest_autocomplete(app_id, term, true) : Destination.send(:find_valid, app_id, term, true)
      results += VlabelMap.search_for_exact(app_id, term) if company.allows_route_to_vlabels?
      results += MediaFile.search_for_exact(app_id, term) if company.allows_route_to_media?

      format_as_autocomplete(results).first
    end

    def format_as_autocomplete(results)
      return [{'label' => 'No results found', 'value' => ''}] if results.empty?

      results.map do |e|
        case e
        when Destination; format_destination_as_autocomplete(e)
        when VlabelMap; format_vlabel_as_autocomplete(e)
        when MediaFile; format_media_file_as_autocomplete(e)
        end
      end
    end

    def format_destination_as_autocomplete(e)
      {
        'label' => "Destination: #{e.destination}",
        'value' => e.destination,
        'description' => "Destination: #{e.destination_title}",
        'type' => e.class.name,
        'id' => e.destination_id,
        'requires_dequeue' => e.is_queue?
      }
    end
    
    def format_vlabel_as_autocomplete(e)
      {
        'label' => "Number/Label: #{e.vlabel}",
        'value' => e.vlabel,
        'description' => "Number/Label: #{e.description}",
        'type' => e.class.name,
        'id' => e.vlabel_map_id,
        'requires_dequeue' => false
      }
    end

    def format_media_file_as_autocomplete(e)
      {
        'label' => "Prompt: #{e.keyword}",
        'value' => e.keyword,
        'description' => 'Prompt',
        'type' => e.class.name,
        'id' => e.recording_id,
        'requires_dequeue' => false
      }
    end
  end
end
