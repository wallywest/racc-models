require 'spec_helper'

describe RaccError do
  before do
    @profile_error = RaccError.create(:error_message => 'A profile error',
      :package_id => 1, :profile_id => -1, :time_segment_id => -1, :routing_id => -1)
    @time_segment_error = RaccError.create(:error_message => 'A time segment error',
      :package_id => 1, :profile_id => 1, :time_segment_id => -1, :routing_id => -1)
    @routing_error = RaccError.create(:error_message => 'A routing error',
      :package_id => 1, :profile_id => 1, :time_segment_id => 1, :routing_id => -1)
    @routing_exit_error = RaccError.create(:error_message => 'A routing exit error',
      :package_id => 1, :profile_id => 1, :time_segment_id => 1, :routing_id => 1)
  end
    
  it 'will retrieve profile errors' do
    errors = RaccError.on_profiles
    errors.length.should == 1
    errors.first.error_message.should == @profile_error.error_message
  end
  
  it 'will retrieve time segment errors' do
    errors = RaccError.on_time_segments
    errors.length.should == 1
    errors.first.error_message.should == @time_segment_error.error_message
  end

  it 'will retrieve routing errors' do
    errors = RaccError.on_routings
    errors.length.should == 1
    errors.first.error_message.should == @routing_error.error_message
  end

  it 'will retrieve routing exit errors' do
    errors = RaccError.on_routing_exits
    errors.length.should == 1
    errors.first.error_message.should == @routing_exit_error.error_message
  end
end
