#! /usr/bin/env ruby

require 'parser.rb'
require 'rubygems'
require 'rspec'
require 'rspec/mocks'
require 'mocha'

RSpec.configure do |config|
    config.mock_with :mocha
end

describe 'parser' do

    describe '#parse' do
        it "should parse statements seperated by '='" do
            parser = ::MCollective::Parser.new("foo=bar")
            parser.execution_stack.should == [{"statement" => "foo=bar"}]
        end

        it "should parse statements seperated by '<'" do
            parser = ::MCollective::Parser.new("foo<bar")
            parser.execution_stack.should == [{"statement" => "foo<bar"}]
        end

        it "should parse statements seperated by '>'" do
            parser = ::MCollective::Parser.new("foo>bar")
            parser.execution_stack.should == [{"statement" => "foo>bar"}]
        end

        it "should parse statements seperated by '<='" do
            parser = ::MCollective::Parser.new("foo<=bar")
            parser.execution_stack.should == [{"statement" => "foo<=bar"}]
        end

        it "should parse statements seperated by '>='" do
            parser = ::MCollective::Parser.new("foo>=bar")
            parser.execution_stack.should == [{"statement" => "foo>=bar"}]
        end

        it "should parse class regex statements" do
            parser = ::MCollective::Parser.new("/foo/")
            parser.execution_stack.should == [{"statement" => "/foo/"}]
        end

        it "should parse fact regex statements" do
            parser = ::MCollective::Parser.new("foo=/bar/")
            parser.execution_stack.should == [{"statement" => "foo=/bar/"}]
        end

        it "should raise and exception on an invalid statemt" do
            MCollective::Scanner.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Invalid token found - 'foo'")
            parser = ::MCollective::Parser.new("foo")
        end

        it "should parse a correct 'and' token" do
            parser = ::MCollective::Parser.new("foo=bar and bar=foo")
            parser.execution_stack.should == [{"statement" => "foo=bar"}, {"and" => "and"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect and token" do
            MCollective::Parser.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Error at column 10. \n Expression cannot start with 'and'")
            parser = ::MCollective::Parser.new("and foo=bar")
        end

        it "should parse a correct 'or' token" do
            parser = ::MCollective::Parser.new("foo=bar or bar=foo")
            parser.execution_stack.should == [{"statement" => "foo=bar"}, {"or" => "or"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect and token" do
            MCollective::Parser.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Error at column 9. \n Expression cannot start with 'or'")
            parser = ::MCollective::Parser.new("or foo=bar")
        end

        it "should parse a correct 'not' token" do
            parser = ::MCollective::Parser.new("! bar=foo")
            parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar=foo"}]
            parser = ::MCollective::Parser.new("not bar=foo")
            parser.execution_stack.should == [{"not" => "not"}, {"statement" => "bar=foo"}]
        end

        it "should not parse an incorrect 'not' token" do
            MCollective::Parser.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Error at column 8. \nExpected 'and', 'or', 'or' ). Found 'not'")
            parser = ::MCollective::Parser.new("foo=bar !")
        end

        it "should parse correct parentheses" do
            parser = ::MCollective::Parser.new("(foo=bar)")
            parser.execution_stack.should == [{"(" => "("}, {"statement" => "foo=bar"}, {")" => ")"}]
        end

        it "should fail on incorrect parentheses" do
            MCollective::Parser.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Error. Missing parentheses '('.")
            parser = ::MCollective::Parser.new(")foo=bar(")
        end

        it "should fail on missing parentheses" do
            MCollective::Parser.any_instance.expects(:exit!)
            STDERR.expects(:puts).with("Error. Missing parentheses ')'.")
            parser = ::MCollective::Parser.new("(foo=bar")
        end

        it "should parse correctly formatted compound statements" do
            parser = ::MCollective::Parser.new("(foo=bar or foo=rab) and (bar=foo)")
            parser.execution_stack.should == [{"(" => "("}, {"statement"=>"foo=bar"}, {"or"=>"or"}, {"statement"=>"foo=rab"},
                                             {")"=>")"}, {"and"=>"and"}, {"("=>"("}, {"statement"=>"bar=foo"},
                                             {")"=>")"}]
        end

    end
end

#describe 'scanner'
#
#end
