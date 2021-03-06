require 'pencil/models/base'
require 'pencil/models/graph'

module Pencil
  module Models
    class Host < Base
      class << self
        ATTRS = [:sort_method]
        attr_accessor(*ATTRS)
        # fixme modulify
        def save
          ATTRS.each do |a|
            val = instance_variable_get("@#{a}")
            instance_variable_set("@_#{a}", val)
          end
        end
        def restore
          ATTRS.each do |a|
            val = instance_variable_get("@_#{a}")
            instance_variable_set("@#{a}", val)
          end
        end
      end

      attr_accessor :graphs, :noassoc # set by Config after initialization
      attr_reader :shortname, :cluster

      def self.get_name (name, cluster)
        cluster ? "#{name}.#{cluster}" : name
      end

      def initialize(name, cluster)
        @name = self.class.get_name(name, cluster)
        @shortname = name
        super(@name)
        @cluster = cluster
        @graphs = []
        @noassoc = false
      end

      def <=>(other)
        self.class.sort_method ||= 'sensible'
        if self.class.sort_method == 'builtin'
          return key <=> other.key
        elsif self.class.sort_method == 'numeric'
          regex = /\d+/
          match = @name.match(regex)
          match2 = other.name.match(regex)
          if match.pre_match != match2.pre_match
            return match.pre_match <=> match2.pre_match
          else
            return match[0].to_i <=> match2[0].to_i
          end
        else
          # http://www.bofh.org.uk/2007/12/16/comprehensible-sorting-in-ruby
          sensible = lambda do |k|
            k.to_s.split(
                         /((?:(?:^|\s)[-+])?(?:\.\d+|\d+(?:\.\d+?(?:[eE]\d+)?(?:$|(?![eE\.])))?))/ms
                         ).map { |v| Float(v) rescue v.downcase }
          end
          return sensible.call(self) <=> sensible.call(other)
        end
      end

      def path
        @cluster ? "#{@cluster}/#{shortname}" : "/global/#{shortname}"
      end

      def match(glob)
        return true if glob == '*'
        # convert glob to a regular expression
        glob_re = /^#{Regexp.escape(glob).gsub('\*', '.*').gsub('\#', '\d+')}$/
        return @shortname.match(glob_re)
      end
    end # Pencil::Models::Host
  end # Pencil::Models
end
