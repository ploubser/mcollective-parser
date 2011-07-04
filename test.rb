#! /usr/bin/ruby ruby

require 'yaml'
require 'pp'
require 'parser.rb'

module Util

    @facts = YAML.load(File.read("facts.yaml"))

    def self.has_cf_class?(klass)
        klass = Regexp.new(klass.gsub("\/", "")) if klass.match("^/")
        cfile = "classes.txt"

        begin
            File.readlines(cfile).each do |k|
                if klass.is_a?(Regexp)
                    return true if k.chomp.match(klass)
                else
                    return true if k.chomp == klass
                end
            end

            return false
        rescue Exception => e
            puts "Parsing classes file classes.txt failed: #{e.class}: #{e}"
        end
    end

    def self.has_fact?(fact, value, operator)
        fact = @facts[fact].to_s
        return false if fact.nil?

        fact = fact.clone
        if operator == '=~'
            if value =~ /^\/(.+)\/$/
                value = $1
            end

            return true if fact.match(Regexp.new(value))

        elsif operator == "=="
            return true if fact == value

        elsif ['<=', '>=', '<', '>', '!='].include?(operator)
            if value =~ /^[0-9]+$/ && fact =~ /^[0-9]+$/
                fact = Integer(fact)
                value = Integer(value)
            elsif value =~ /^[0-9]+.[0-9]+$/ && fact =~ /^[0-9]+.[0-9]+$/
                fact = Float(fact)
                value = Float(value)
            end

            return true if eval("fact #{operator} value")
        end

        false
    end
end

def run_statement(expression)
    name, value = ""

    if expression.values.first =~ /^\//
        return Util.has_cf_class?(expression.values.first)
    else
        if expression.values.first.match(/=\//)
            optype = "=~"
            name, value = expression.values.first.split("=/")
        else
            optype = expression.values.first.match(/>=|<=|=|<|>/)
            name, value = expression.values.first.split(optype[0])
            optype[0] == "=" ? optype = "==" : optype = optype[0]
        end

        return Util.has_fact?(name,value, optype).to_s
    end
end

a = ::MCollective::Parser.new(ARGV[0])
puts "Parsing input string - '#{ARGV[0]}'"
puts "----------------------------------"
stack = a.execution_stack
puts "Creating tokens"

stack.each do |token|
    puts "Type - #{token.keys.first}"
    if token.keys.first == "statement"
        puts "Value - #{token.values.first}"
    end
end

result = []

stack.each do |expression|
    case expression.keys.first
    when "statement"
        result << run_statement(expression).to_s
    when "and"
        result << "&&"
    when "or"
        result << "||"
    when "("
        result << "("
    when ")"
         result << ")"
    when "not"
        result << "!"
    end
end

puts "----------------------------------"
puts "Evaluating expression - #{result.join(" ")}"
result = eval(result.join(" "))
puts
if result
    puts "Expression matched fact/class combination"
else
    puts "Expression did not match fact/class combination"
end
