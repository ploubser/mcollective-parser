#! /usr/bin/env ruby

require 'parser.rb'
require 'rubygems'
require 'rspec'
require 'rspec/mocks'
require 'mocha'

Rspec.configure do |config|
    config.mock_with :mocha
end

describe 'scanner' do
    it "should identify a '(' token" do
        scanner = MCollective::Scanner.new("(")
        token = scanner.get_token
        token.should == ["(", "("]
    end

    it "should identify a ')' token" do
        scanner = MCollective::Scanner.new(")")
        token = scanner.get_token
        token.should == [")", ")"]
    end

    it "should identify a 'and' token" do
        scanner = MCollective::Scanner.new("and ")
        token = scanner.get_token
        token.should == ["and", "and"]
    end

    it "should identify a 'or' token" do
        scanner = MCollective::Scanner.new("or ")
        token = scanner.get_token
        token.should == ["or", "or"]
    end

    it "should identify a 'not' token" do
        scanner = MCollective::Scanner.new("not ")
        token = scanner.get_token
        token.should == ["not", "not"]
    end

    it "should identify a '!' token" do
        scanner = MCollective::Scanner.new("!")
        token = scanner.get_token
        token.should == ["not", "not"]
    end

    it "should identify a fact statement token" do
        scanner = MCollective::Scanner.new("foo=bar")
        token = scanner.get_token
        token.should == ["statement", "foo=bar"]
    end

    it "should identify a fact statement token" do
        scanner = MCollective::Scanner.new("foo=bar")
        token = scanner.get_token
        token.should == ["statement", "foo=bar"]
    end

    it "should identify a class statement token" do
        scanner = MCollective::Scanner.new("/class/")
        token = scanner.get_token
        token.should == ["statement", "/class/"]
    end

    it "should fail if expression terminates with 'and'" do
        scanner = MCollective::Scanner.new("and")
        scanner.expects(:exit!)
        STDERR.expects(:puts).with("Cannot end statement with 'and', 'or', 'not'")
        token = scanner.get_token
    end

    it "should fail on an invalid token" do
        scanner = MCollective::Scanner.new("abc")
        scanner.expects(:exit!)
        STDERR.expects(:puts).with("Invalid token found - 'abc'")
        scanner.get_token
    end

end
