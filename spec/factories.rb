FactoryGirl.define do
  factory :user_group do |f|
    name 'Test Group'
  end

  factory :user do |f|
    sequence(:login) {|n| "test#{n}"}
    first_name 'Test'
    last_name 'Test'
    password 'Test1234!'
    password_confirmation 'Test1234!'
    sequence(:email) {|n| "test#{n}n@test.com"}
    app_id 1
    user_groups {[FactoryGirl.create(:user_group)]}
    
    factory :super_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Super User')]}
    end
    
    factory :routing_admin do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Routing Admin')]}
    end
    
    factory :routing_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Routing User')]}
    end
    
    factory :read_only_routing_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Read Only Routing User')]}
    end
    
    factory :routing_recording_admin do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Routing Recording Admin')]}
    end
    
    factory :routing_recording_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Routing Recording User')]}
    end
    
    factory :read_only_routing_recording_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Read Only Routing Recording User')]}
    end
    
    factory :prompt_set_admin do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Prompt Set Admin')]}
    end
    
    factory :prompt_set_user do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Prompt Set User')]}
    end
    
    factory :quick_allocator do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Quick Allocator')]}
    end
    
    factory :pre_route_editor do
      user_groups {[FactoryGirl.create(:user_group, :name => 'Pre Route Editor')]}
    end
  end

  factory :audit do |f|
    f.user_type 'User'
    f.user_id 1
    f.username 'test'
  end

  factory :destination do
    app_id 1
    sequence(:destination) {|n| '1235551212+%d' % (123001 + n)}
    destination_title 'EL1235551212+1230001'
    destination_property_name 'L3_ON_NET'
    modified_time Time.now
    after(:build) { |dest| FactoryGirl.create(:destination_property) unless DestinationProperty.find_by_destination_property_name('L3_ON_NET') }
  end

  factory :location do
    app_id 1
    sequence(:destination) {|n| 'Chicago CC %d' % (12345 + n)}
    destination_title 'Chicago Call Center'
    destination_property_name 'LOCATION_PROP'
    modified_time Time.now
    after(:build) { |dest| FactoryGirl.create(:destination_property, :validation_format => 'ALL', :destination_property_name => 'LOCATION_PROP', :dtype => 'M') unless DestinationProperty.find_by_destination_property_name('LOCATION_PROP') }
  end

  factory :destination_property do
    app_id 1
    cdr_auth 'T'
    destination_form 'network_app'
    destination_property_name 'L3_ON_NET'
    dial_or_block 'D'
    max_speed_digits 0
    modified_time { Time.now }
    music_on_hold 'Musak'
    outcome_timeout 1
    outdial_format 1
    pass_parentcallID 'T'
    recording_percentage 0
    retry_count 0
    super_user_only false
    terminate '1'
    transfer_lookup 'A'
    transfer_method 'B'
    transfer_pattern 'S'
    transfer_type 'S'
    validation_format '10_DIGIT'
  end

  factory :destination_validation_format do |f|
    f.name '10_DIGIT'
    f.regex '^[0-9]{10}$'
    f.error_message 'The destination must be a 10-digit number.  Example: 1234567890'
    f.description 'This only accepts a 10-digit number'
  end

  sequence :phone_number_value do |n|
    "123555%04d" % n
  end

  factory :phone_number do
    value { generate(:phone_number_value) }
    category "b"
    app_id 1
  end

  factory :package do |f|
    f.app_id 1
    f.name 'Package Name'
    f.description 'Test Desc'
    f.active false
    f.created_by 'Tester1'
    f.updated_by 'Tester2'
    f.association :vlabel_map, :factory => :vlabel_map
  end

  factory :profile do |f|
    f.name 'Profile'
    f.description 'Test Desc'
    f.app_id 1
    f.association :package, :factory => :package
  end

  factory :time_segment do |f|
    f.start_min 0
    f.end_min 1439
    f.app_id 1
  end

  factory :routing do |f|
    f.percentage 100
    f.app_id 1
  end

  factory :session do |f|
  end

  factory :company_config do |f|
    f.app_id 1
    f.alternate_command_character 'G'
  end

  factory :company do
    app_id 1
    app_name 'test app'
    cache_url_xrefs { |c| [c.association(:cache_url_xref)] }
    company_config { |c| c.association(:company_config, :app_id => c.app_id) }
    environment 'test'
    full_call_recording_enabled 'F'
    full_call_recording_percentage 0
    job_id 1111
    job_name 'test_job'
    max_destinations_for_time_segment 50
    max_dynamic_ivr_actions 0
    max_packages_for_route 50
    multi_channel_recording 'F'
    name 'test_name'
    process_family 'test'
    recording_type 'P'
    split_full_recording 'F'
    subdomain 'test_subdomain'
  end

  factory :destination_type do |f|
    f.destination_type 'TEST'
    f.regex ""
    f.gui_value 0
    f.app_id 1 
    f.error_messages "TEST error"
  end

  factory :recorded_dnis do |f|
    f.parm_key '123456'
    f.parm_name 'test_parm_name'
    f.s1 "*"
    f.s2 '*'
    f.app_id 1
    f.i5 1
  end

  factory :dli do |f|
    f.app_id 1
    f.value 'test_value'
    f.description "test_description"
  end

  factory :li do
    app_id 1
    value 'test_value'
    description "test_description"
    dpct 100
  end

  factory :operation do |f|
    f.app_id 1
    f.sequence(:vlabel_group) {|n| ("test_group_#{n}")}
    f.description 'testing_desc'
    f.operation 1
    f.route_name 'unused'
    f.post_call 'F'
    f.hangup_message 'hanging_up.wav'
    f.newop_rec 'test_newop_rec'
    f.default_property 'L3_ON_NET'
    f.exception_route 'F'
    f.dst_name 'eastern'
    f.cti_name 'test_cti'
    f.nvp_modified_time_unix 0
  end

  factory :racc_cti do |f|
    f.app_id 1
    f.cti_id 1
    f.cti_name 'test_cti'
    f.cti_order 1
    f.cti_enabled 'T'
    f.vendor_type 'C'
    f.modified_by 'test_user'
    f.modified_time Time.now
  end
  
  factory :racc_cti_host do |f|
    f.app_id 1
    f.cti_name 'test_cti'
    f.vail_site 'chicago'
    f.itype 'R'
    f.host1 'sipdev1'
    f.status1 'U'
    f.host2 'sipdev2'
    f.status2 'D'
    f.port 2374
    f.modified_time Time.now
  end

  factory :racc_dst do |f|
    f.dst_name 'test_dst'
    f.start_type 'S'
    f.local_start_month 3
    f.local_start_sunday 1
    f.local_start_minute 120
    f.end_type 'S'
    f.local_end_month 11
    f.local_end_sunday 0
    f.local_end_minute 120
    f.gmt_offset -500
    f.dst_adjust 0
    f.modified_by 'test_user'
  end

  factory :racc_genesys_cti do |f|
    f.app_id 1
    f.cti_name 'test_cti_genesys'
    f.vail_site 'test site'
    f.modified_by 'test_user'
  end

  factory :racc_post_call do |f|
    f.app_id 1
    f.vlabel_group 'test_group'
    f.route_name 'test_name'
    f.post_call_prompt 'hello'
    f.accept_digit 'T'
    f.modified_by 'test_user'
  end

  factory :racc_route do |f|
    f.app_id 1
    f.sequence(:route_name) {|n| "test_route_name#{n}"}
    f.day_of_week 254
    f.begin_time 0
    f.end_time 1439
    f.destid 12345
    f.distribution_percentage 100
    f.modified_time Time.now
    f.modified_by 'test_user'
  end

  factory :racc_route_destination_xref do
    app_id 1
    modified_by 'test_user'
    modified_time Time.now
    route_id 1
    route_order 1
    transfer_lookup 'O'
    
    association :exit, factory: :destination
  end

  factory :setting do |f|
    f.app_id 1
    f.name 'test_name'
    f.value 'test'
    f.modified_by 'test_user'
  end

  factory :transfer_map do |f|
    f.app_id 1
    f.sequence(:transfer_string) {|n| (1000 + n).to_s }
    f.vlabel {|tm| FactoryGirl.create(:racc_route, :app_id => tm.app_id).route_name}
    f.modified_by 'test_user'
    f.modified_time Time.now
  end

  factory :vlabel_map do
    app_id 1
    sequence(:vlabel) { |n| "vlabel_map_#{n}" }
    full_call_recording_enabled 'F'
    full_call_recording_percentage 0
    multi_channel_recording 'F'
    vlabel_group { |v| FactoryGirl.create(:group, :app_id => v.app_id).name}
    modified_by 'test_user'
    modified_time Time.now
    after(:build) { |vlm| FactoryGirl.create(:company, :app_id => vlm.app_id) unless Company.find_by_app_id(vlm.app_id) }
  end

  factory :cti_routine do |f|
    f.app_id 1
    f.sequence(:value) {|n| n}
    f.description 'testing desc'
    f.target 'op'
  end

  factory :group_cti_routine_xref do |f|
    f.group_id 1
    f.sequence(:cti_routine_id) {|n| n}
    f.default_cti_for_group 0
    f.modified_by 'tester_one'
  end

  factory :group do |f|
    f.category 'b'
    f.description 'test description'
    f.group_default false
    f.app_id 1
    f.sequence(:name) {|n| ("test_group_#{n}")}
    f.operation { |grp| grp.association(:operation, :app_id => grp.app_id, :vlabel_group => grp.name)}
    f.cti_routines {|grp| [grp.association(:cti_routine)]}

    factory :frontend_group do |f|
      f.category 'f'
      f.sequence(:display_name) {|n| ("display_name_#{n}")}
      f.show_display_name true
      f.operation { |grp| grp.association(:operation,:app_id => grp.app_id, :vlabel_group => grp.name, :preroute_enabled => 1)}
    end

    factory :with_preroute do |f|
      f.show_display_name true
      f.sequence(:display_name) {|n| ("display_name_#{n}")}
      f.operation { |grp| grp.association(:operation, :app_id => grp.app_id, :vlabel_group => grp.name, :preroute_enabled => 1)}
    end
  end

  factory :business_unit do |f|
    f.name "Test_Category"
    f.app_id 8245
  end

  factory :prompt_set do |f|
    f.app_id 1
    f.name "Test_Sub_Category"
  end

  factory :slot do |f|
    f.prompt_order 1
    f.enabled true
    f.prompt_set_id 1
    f.app_id 1
  end

  factory :preroute_group do
    app_id 1
    group_name 'Test'
    route_name 'Route Test'
    preroute_enabled 'F'
  end

  factory :survey_group do |f|
    f.app_id 1
    f.name 'Test Survey'
    f.description 'Survey Desc'
    f.survey_vlabel { |sg| FactoryGirl.create(:transfer_map, :app_id => sg.app_id).transfer_string }
    f.percent_to_survey 10
    f.dsat_score 25
    f.announcement_file 'test.wav'
    f.modified_by 'racc_admin'
  end

  factory :company_job_id do |f|
    f.company_id 1
    f.job_id 1111
  end

  factory :operation_type do |f|
    f.sequence(:number) {|num| num}
    f.sequence(:name) {|n| "test_op_type_name#{n}"}
    f.sequence(:description) {|d| "test_op_type_desc#{d}"}
  end

  factory :ani_map do |f|
    f.app_id 1
    f.ani '773'
    f.association :ani_group
  end

  factory :ani_group do |f|
    f.app_id 1
    f.sequence(:name) {|n| "Test ANI Group #{n}"}
    f.description 'Test ANI Group Desc'
  end

  factory :geo_route_group do |f|
    f.app_id 1
    f.name 'Test Geo-Route Group'
    f.description 'Test Geo-Route Group Desc'
  end

  factory :geo_route_ani_xref do |f|
    f.app_id 1
    f.route_name 'geoRouteTest'
    f.association :geo_route_group
    f.association :ani_group
  end

  factory :loadmonitor_dnis_detail do |f|
    f.normalized_timestamp Time.parse("01/01/2010 12:00:00 UTC")
  end

  factory :loadmonitor_dnis_aggregate do |f|
    f.normalized_timestamp Time.parse("01/01/2010 12:00:00 UTC")
    f.sequence(:dnis) {|d| "#{8005563412 + d}" }
    f.appid 1
    f.direction 1 #inbound
    f.num_active 1
    f.num_complete 0
    f.total_time 50
    f.num_internal 50
  end

  factory :dynamic_ivr do |f|
    f.app_id 1
    f.sequence(:name) {|n| "test ivr #{n}"} 
    f.json_string '{"data":"test ivr", "metadata":{"tree_state":"In Progress"}}'
    f.state 'In Progress'
  end

  factory :dynamic_ivr_destination do |f|
    f.association :dynamic_ivr, :factory => :dynamic_ivr
    f.association :destination, :factory => :destination
  end

  factory :page do |f|
    f.name 'Test Pages'
    f.url '/test_pages'
    f.controller_action 'test_pages/index'
    f.placeholder 0
  end

  factory :preroute_selection do |f|
    f.app_id 1
    f.modified_by 'test_admin'
  end

  factory :preroute_grouping do |f|
    f.app_id 1
    f.name 'test pre-route grouping'
    f.modified_by 'test_admin'
    f.temp_preroute_group_ids [1]
  end

  factory :cache_url_xref do |f|
    f.app_id 1
    f.cache_url_id 1
    #f.association :company, :factory => :company
  
    f.association :cache_url, :factory => :cache_url
  end

  factory :cache_url do |f|
    f.sequence(:id) { |n| n+1 }
    f.address 'url.vail'
    f.cache_table_group_id 'racc_v2b'
    f.port '9200'
  end
  
  factory :queue_configuration do |f|
    f.app_id 8245
    f.name "Test_Queue_Configuration"
    f.updated_by "test_user"
    f.association :queue_hold_treatment
  end
  
  factory :queue_hold_treatment do |f|
    
  end
  
  factory :group_default_route do |f|
    f.sequence(:vlabel_map_id) {|n| n+1}
    f.sequence(:group_id) {|n| n+1}
  end
  
  factory :destination_attribute_bit do |f|
    f.sequence(:decimal_value) {|n| n}
    f.description "test bit desc"
    f.display false
  end
  
  factory :label_destination_map do |f|
    f.app_id 1
    f.association :vlabel_map, :factory => :vlabel_map
    f.association :mapped_destination, :factory => :destination
    f.association :exit, :factory => :destination 
    f.exit_type "Destination"
  end

  factory :routing_exit do |f|
    f.app_id 1
    f.call_priority 1

    factory :destination_exit do |f|
      f.exit_id 1
      f.exit_type "Destination"
    end
    factory :media_exit do |f|
      f.exit_id 1
      f.exit_type "MediaFile"
    end
    factory :route_exit do |f|
      f.exit_id 1
      f.exit_type "VlabelMap"
    end
  end

  factory :media_file do |f|
    f.keyword "recording abc"
    f.start_time Time.now
    f.duration 1000
    f.owner_id 1
    f.app_id 1
    f.job_id 1
  end

  factory :admin_report do |f|
    f.app_id 1
    f.name 'test_report'
    f.username 'test_username'
    f.password 'test_password'
    f.password_confirmation "test_password"
    f.url 'http://test_url'
  end
end
