require 'spec_helper'

describe Apache::Master, "should provide basic helpers for configuration" do
  let(:apache) { Apache::Config }

  before { apache.reset! }

  it "should build the modules with the provided block" do
    apache.modules(:this, :that) do
      my "is here"
    end.should == [
      '',
      'LoadModule "this_module" "modules/mod_this.so"',
      'LoadModule "that_module" "modules/mod_that.so"',
      'LoadModule "my_module" "is here"',
      ''
    ]
  end

  it "should set up the runner" do
    apache.runner('test', 'test2')
    apache.to_a.should == [ 'User test', 'Group test2' ]
  end


  it "should handle miscellaneous Apache directives" do
    [
      [ [ :apache_include, 'test' ], [ 'Include test' ] ],
      [ [ :apache_alias, 'test', 'test2' ], [ 'Alias "test" "test2"' ] ],
      [ [ :timeout, 300 ], [ 'Timeout 300' ] ]
    ].each do |call, config|
      apache.reset!
      apache.send(*call)
      apache.to_a.should == config
    end
  end

  it "should handle rotate logs" do
    apache.rotate_logs_path = "/my/path"
    apache.rotatelogs('/log/path', 12345).should == "|/my/path /log/path 12345"
  end

  it "should create Passenger directives" do
    apache.passenger '/opt/local/ruby', '1.8', '2.2.11'
    apache.to_a.should == [
      'LoadModule "passenger_module" "/opt/local/ruby/lib/ruby/gems/1.8/gems/passenger-2.2.11/ext/apache2/mod_passenger.so"',
      'PassengerRoot "/opt/local/ruby/lib/ruby/gems/1.8/gems/passenger-2.2.11"',
      'PassengerRuby "/opt/local/ruby/bin/ruby"'
    ]
  end

  # not testing this big blob for output correctness...
  it "should enable gzip server-wide" do
    apache.enable_gzip!
  end

  it "should create Apache comments" do
    apache.comment("This is a comment")
    apache.to_a.should == [ '#', '# This is a comment', '#' ]

    apache.reset!

    apache.comment(["This is", "a comment"])
    apache.to_a.should == [ '#', '# This is', '# a comment', '#' ]
  end

  it "should create & check a script alias" do
    dir = File.dirname(__FILE__)

    apache.script_alias '/script/', dir
    apache.to_a.should == [ %{ScriptAlias "/script/" "#{dir}"} ]
  end

  it "should add a type with some other options" do
    apache.add_type! 'text/html', '.html', :handler => 'html-handler'
    apache.to_a.should == [ 'AddType text/html .html', 'AddHandler html-handler .html' ]
  end

  it "should create headers" do
    apache.set_header :test => :test2
    apache.set_header 'test3' => [ 'test4', "test5=test6" ]
    apache.to_a.should == [ 'Header set test test2', 'Header set "test3" "test4" test5=test6' ]
  end

  describe '#listen' do
    it 'should not allow one to listen twice on the same interface' do
      apache.listen "one"
      apache.listen "two"
      apache.listen "one"

      apache.to_a.should == [ 'Listen "one"', 'Listen "two"' ]

      Apache::Master.listening_on.should == %w{"one" "two"}
    end
  end
end
