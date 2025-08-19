# frozen_string_literal: true

require "yard"
require "json"
require "fileutils"
require "tmpdir"

module OpenGemdocs
  class YardJsonFormatter
    def self.format_gem_docs(gem_name, object_path = nil)
      # Ensure YARD server data is available
      yard_db_path = find_yard_db(gem_name)

      unless yard_db_path
        # Try to generate the .yardoc if it doesn't exist
        gem_path = find_gem_path(gem_name)
        return { error: "Gem '#{gem_name}' not found" } unless gem_path

        # Create a temporary .yardoc path
        yard_db_path = File.join(Dir.tmpdir, "yard_#{gem_name}_#{Process.pid}", ".yardoc")
        FileUtils.mkdir_p(File.dirname(yard_db_path))

        # Generate YARD documentation
        YARD::CLI::Yardoc.run("--no-output", "--db", yard_db_path, gem_path)
      end

      # Load the YARD registry
      YARD::Registry.load(yard_db_path)

      if object_path
        # Return specific object documentation
        obj = YARD::Registry.at(object_path)
        return { error: "Object '#{object_path}' not found in #{gem_name}" } unless obj

        begin
          format_object(obj)
        rescue StandardError => e
          { error: "Failed to format object: #{e.message}\n#{e.backtrace.first(3).join("\n")}" }
        end
      else
        # Return gem overview with main classes and modules
        {
          gem: gem_name,
          summary: get_gem_summary(gem_name),
          namespaces: format_namespaces,
          classes: format_classes,
          modules: format_modules
        }
      end
    ensure
      YARD::Registry.clear
    end

    private_class_method def self.find_yard_db(gem_name)
      # Check common locations for .yardoc databases
      possible_paths = [
        File.join(Dir.home, ".yard", "gems", "#{gem_name}-*", ".yardoc"),
        File.join(Gem.dir, "doc", "#{gem_name}-*", ".yardoc")
      ]

      possible_paths.each do |pattern|
        matches = Dir.glob(pattern)
        return matches.first if matches.any?
      end

      nil
    end

    private_class_method def self.find_gem_path(gem_name)
      spec = Gem::Specification.find_by_name(gem_name)
      spec.full_gem_path if spec
    rescue Gem::LoadError
      nil
    end

    private_class_method def self.get_gem_summary(gem_name)
      spec = Gem::Specification.find_by_name(gem_name)
      {
        version: spec.version.to_s,
        description: spec.description,
        summary: spec.summary,
        homepage: spec.homepage
      }
    rescue Gem::LoadError
      {}
    end

    private_class_method def self.format_namespaces
      YARD::Registry.all(:module, :class).select { |obj| obj.namespace.root? }.map do |obj|
        {
          name: obj.name.to_s,
          path: obj.path,
          type: obj.type.to_s
        }
      end
    end

    private_class_method def self.format_classes
      YARD::Registry.all(:class).map do |obj|
        {
          name: obj.name.to_s,
          path: obj.path,
          namespace: obj.namespace.path == "" ? nil : obj.namespace.path,
          superclass: obj.superclass ? obj.superclass.path : nil,
          docstring: obj.docstring.to_s.empty? ? nil : obj.docstring.to_s,
          methods_count: obj.meths.count
        }
      end
    end

    private_class_method def self.format_modules
      YARD::Registry.all(:module).map do |obj|
        {
          name: obj.name.to_s,
          path: obj.path,
          namespace: obj.namespace.path == "" ? nil : obj.namespace.path,
          docstring: obj.docstring.to_s.empty? ? nil : obj.docstring.to_s,
          methods_count: obj.meths.count
        }
      end
    end

    private_class_method def self.format_object(obj)
      return nil unless obj

      base_info = {
        name: obj.name.to_s,
        path: obj.path,
        type: obj.type.to_s,
        namespace: obj.namespace && obj.namespace.path != "" ? obj.namespace.path : nil,
        docstring: obj.docstring.to_s.empty? ? nil : obj.docstring.to_s,
        tags: format_tags(obj.tags),
        source: obj.file ? { file: obj.file, line: obj.line } : nil
      }

      case obj.type
      when :class
        base_info.merge!(
          superclass: obj.superclass ? obj.superclass.path : nil,
          includes: obj.mixins(:instance).map(&:path),
          extends: obj.mixins(:class).map(&:path),
          methods: format_methods(obj.meths),
          attributes: format_attributes(obj.attributes)
        )
      when :module
        base_info.merge!(
          includes: obj.mixins(:instance).map(&:path),
          extends: obj.mixins(:class).map(&:path),
          methods: format_methods(obj.meths),
          attributes: format_attributes(obj.attributes)
        )
      when :method
        base_info.merge!(
          signature: obj.signature,
          parameters: format_parameters(obj.parameters),
          visibility: obj.visibility.to_s,
          scope: obj.scope.to_s,
          aliases: obj.aliases.map(&:name).map(&:to_s)
        )
      end

      base_info
    end

    private_class_method def self.format_tags(tags)
      tags.map do |tag|
        result = {
          tag_name: tag.tag_name,
          text: tag.text
        }
        result[:types] = tag.types if tag.respond_to?(:types)
        result[:name] = tag.name if tag.respond_to?(:name)
        result
      end
    end

    private_class_method def self.format_methods(methods)
      methods.map do |meth|
        {
          name: meth.name.to_s,
          path: meth.path,
          signature: meth.signature,
          visibility: meth.visibility.to_s,
          scope: meth.scope.to_s,
          docstring: meth.docstring.to_s.empty? ? nil : meth.docstring.to_s,
          parameters: format_parameters(meth.parameters),
          return_type: extract_return_type(meth)
        }.compact
      end
    end

    private_class_method def self.format_parameters(params)
      return [] unless params

      params.map do |param|
        name, default = param
        {
          name: name,
          default: default
        }
      end
    end

    private_class_method def self.format_attributes(attrs)
      attrs.map do |_name, attr|
        # Handle case where both read and write might be nil (shouldn't happen but defensive)
        accessor = attr[:read] || attr[:write]
        next unless accessor

        {
          name: accessor.name.to_s.sub("=", ""),
          read: !attr[:read].nil?,
          write: !attr[:write].nil?,
          docstring: accessor.docstring.to_s
        }
      end.compact
    end

    private_class_method def self.extract_return_type(method)
      return_tag = method.tags.find { |t| t.tag_name == "return" }
      return_tag ? return_tag.types : nil
    end
  end
end

