module MCollective

    # Language EBNF
    #
    # compound = ["("] expression [")"] {["("] expression [")"]}
    # expression = [not]statement ["and"|"or"] [not] statement
    # char = A-Z | a-z | < | > | => | =< | _ | - |* { A-Z | a-z | < | > | => | =< | _ | - | *}
    # int = 0|1|2|3|4|5|6|7|8|9{|0|1|2|3|4|5|6|7|8|9|0}
    #

  class Scanner

    attr_accessor :arguments, :token_index

    def initialize(arguments)
      @token_index = 0
      @arguments = arguments.first
    end

    #Scans the input string and identifies single language tokens
    def get_token
        if @token_index >= @arguments.size
          return nil
        end

        begin
            case @arguments[@token_index].chr
              when "("
                return "(", "("

            when ")"
                return ")", ")"

            when "n"
                if (@arguments[@token_index + 1].chr == "o") && (@arguments[@token_index + 2].chr == "t") &&
                            ((@arguments[@token_index + 3].chr == " ") || (@arguments[@token_index + 3].chr == "("))
                    @token_index += 2
                    return "not", "not"
                else
                    gen_statement
                end

            when "!"
                return "not", "not"

            when "a"
                if (@arguments[@token_index + 1].chr == "n") && (@arguments[@token_index + 2].chr == "d") &&
                            ((@arguments[@token_index + 3].chr == " ") || (@arguments[@token_index + 3].chr == "("))
                    @token_index += 2
                    return "and", "and"
                else
                    gen_statement
                end

            when "o"
                if (@arguments[@token_index + 1].chr == "r") && ((@arguments[@token_index + 2].chr == " ") ||
                            (@arguments[@token_index + 2].chr == "("))
                    @token_index += 1
                    return "or", "or"
                else
                    gen_statement
                end
            when " "
                return " ", " "
            else
                gen_statement
            end
        end
    rescue Exception => e
        pp e
        puts "Cannot end statement with 'and', 'or', 'not'"
        exit!
    end

    private
    #Helper generates a statement token
    def gen_statement
        current_token_value = ""
        j = @token_index

        if (@arguments[j].chr == "/")
            while !@arguments[j].nil? && !(@arguments[j].chr =~ /\s|\)|\(/)
                current_token_value << @arguments[j].chr
                j += 1
            end
        else
            while !(@arguments[j].chr =~ /=|<|>/)
                current_token_value << @arguments[j].chr
                j += 1
            end

            while (j < @arguments.size) && ((@arguments[j].chr != " ") && (@arguments[j].chr != ")"))
                current_token_value << @arguments[j].chr
                j += 1
            end

            while (j < @arguments.size) && ((@arguments[j].chr != " ") && (@arguments[j].chr != ")"))
                current_token_value << @arguments[j].chr
                j += 1
            end
        end

        @token_index += current_token_value.size - 1
        return "statement", current_token_value
    end

  end

  class Parser

    attr_reader :scanner, :execution_stack

    def initialize(args)
      @scanner = Scanner.new(args)
      @execution_stack = []
      parse
    end

    #Parse the input string, one token at a time a contruct the call stack
    def parse
        c_token,c_token_value = @scanner.get_token
        parenth = 0

        while (c_token != nil)
            @scanner.token_index += 1
            n_token, n_token_value = @scanner.get_token

            unless  n_token == " "
                case c_token
                when "and"
                    unless (n_token =~ /not|statement|\(/) || (scanner.token_index == scanner.arguments.size)
                        raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement' or '('. Found '#{n_token_value}'"
                    end

                when "or"
                    unless n_token =~ /not|satement|\(/
                        raise "Error at column #{scanner.token_index}. \nExpected 'not', 'statement', '(' or ')'. Found '#{n_token_value}'"
                    end

                when "not"
                    unless n_token =~ /statement|\(|not/
                        raise "Error at column #{scanner.token_index}. \nExpected 'statement' or '('. Found '#{n_token_value}'"
                    end

                when "statement"
                    unless (n_token =~ /and|or|\)/) && (scanner.token_index != scanner.arguments.size)
                            unless(scanner.token_index == scanner.arguments.size)
                                raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', 'or' ). Found '#{n_token_value}'"
                            end
                    end

                when ")"
                    unless (n_token =~ /|and|or|not|\(/)
                            unless(scanner.token_index == scanner.arguments.size)
                                raise "Error at column #{scanner.token_index}. \nExpected 'and', 'or', 'not' or '('. Found '#{n_token_value}'"
                            end
                    end
                    parenth += 1

                when "("
                    unless n_token =~ /statement|not|\(/
                        raise "Error at column #{scanner.token_index}. \nExpected 'statement', '(',  not. Found '#{n_token_value}'"
                    end
                    parenth -= 1

                else
                    raise "Unexpected token found at column #{scanner.token_index}. '#{c_token_value}'"
                end
                unless n_token == " "
                    @execution_stack << {c_token => c_token_value}
                end
                c_token, c_token_value = n_token, n_token_value
            end
        end

        if parenth < 0
            raise "Error. Missing parentheses ')'."
        elsif parenth > 0
            raise "Error. Missing parentheses '('."
        end
        rescue Exception => e
            STDERR.puts e
            exit!
    end
  end
end
