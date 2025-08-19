require "spec_helper"
require "open_gemdocs/yard_json_formatter"
require "tmpdir"
require "fileutils"

RSpec.describe OpenGemdocs::YardJsonFormatter do
  describe ".format_gem_docs" do
    context "when gem does not exist" do
      it "returns an error" do
        result = described_class.format_gem_docs("nonexistent_gem_12345")
        expect(result).to have_key(:error)
        expect(result[:error]).to include("not found")
      end
    end

    context "when formatting a real gem" do
      let(:gem_name) { "json" }

      it "returns gem overview when no object path is specified" do
        result = described_class.format_gem_docs(gem_name)
        
        expect(result).to have_key(:gem)
        expect(result[:gem]).to eq(gem_name)
        expect(result).to have_key(:summary)
        expect(result).to have_key(:namespaces)
        expect(result).to have_key(:classes)
        expect(result).to have_key(:modules)
      end

      it "includes gem metadata in summary" do
        result = described_class.format_gem_docs(gem_name)
        
        expect(result[:summary]).to have_key(:version)
        expect(result[:summary][:version]).to match(/\d+\.\d+/)
        expect(result[:summary]).to have_key(:description)
      end

      it "lists classes with their details" do
        result = described_class.format_gem_docs(gem_name)
        
        expect(result[:classes]).to be_an(Array)
        expect(result[:classes]).not_to be_empty
        
        first_class = result[:classes].first
        expect(first_class).to have_key(:name)
        expect(first_class).to have_key(:path)
        expect(first_class).to have_key(:methods_count)
      end

      it "lists modules with their details" do
        result = described_class.format_gem_docs(gem_name)
        
        expect(result[:modules]).to be_an(Array)
        expect(result[:modules]).not_to be_empty
        
        first_module = result[:modules].first
        expect(first_module).to have_key(:name)
        expect(first_module).to have_key(:path)
        expect(first_module).to have_key(:methods_count)
      end
    end

    context "when formatting a specific object" do
      let(:gem_name) { "json" }
      
      it "returns detailed object documentation for a class" do
        # First, get list of classes to find a valid one
        overview = described_class.format_gem_docs(gem_name)
        class_path = overview[:classes].first[:path] if overview[:classes].any?
        
        skip "No classes found in #{gem_name}" unless class_path
        
        result = described_class.format_gem_docs(gem_name, class_path)
        
        expect(result).to have_key(:name)
        expect(result).to have_key(:path)
        expect(result[:path]).to eq(class_path)
        expect(result).to have_key(:type)
        expect(result[:type]).to eq("class")
        expect(result).to have_key(:methods)
      end

      it "includes method details when formatting a class" do
        overview = described_class.format_gem_docs(gem_name)
        class_with_methods = overview[:classes].find { |c| c[:methods_count] > 0 }
        
        skip "No classes with methods found" unless class_with_methods
        
        result = described_class.format_gem_docs(gem_name, class_with_methods[:path])
        
        expect(result[:methods]).to be_an(Array)
        expect(result[:methods]).not_to be_empty
        
        first_method = result[:methods].first
        expect(first_method).to have_key(:name)
        expect(first_method).to have_key(:path)
        expect(first_method).to have_key(:signature)
        expect(first_method).to have_key(:visibility)
        expect(first_method).to have_key(:scope)
      end

      it "returns error for non-existent object path" do
        result = described_class.format_gem_docs(gem_name, "NonExistent::Class::Path")
        
        expect(result).to have_key(:error)
        expect(result[:error]).to include("not found")
      end
    end
  end

  describe "helper methods" do
    describe ".find_gem_path" do
      it "returns path for installed gem" do
        path = described_class.send(:find_gem_path, "json")
        expect(path).to be_a(String)
        expect(path).to include("json")
      end

      it "returns nil for non-existent gem" do
        path = described_class.send(:find_gem_path, "nonexistent_gem_12345")
        expect(path).to be_nil
      end
    end

    describe ".get_gem_summary" do
      it "returns gem metadata" do
        summary = described_class.send(:get_gem_summary, "json")
        
        expect(summary).to have_key(:version)
        expect(summary).to have_key(:description)
        expect(summary).to have_key(:summary)
      end

      it "returns empty hash for non-existent gem" do
        summary = described_class.send(:get_gem_summary, "nonexistent_gem_12345")
        expect(summary).to eq({})
      end
    end
  end

  describe "formatting methods" do
    # Create a minimal YARD registry for testing
    before do
      # This would need actual YARD objects in a real test environment
      # For now, we'll skip these tests as they require complex setup
    end

    describe ".format_tags" do
      it "formats YARD tags into hash structure" do
        # Would require YARD tag objects
        skip "Requires YARD tag setup"
      end
    end

    describe ".format_parameters" do
      it "formats method parameters" do
        params = [["arg1", nil], ["arg2", "default_value"]]
        result = described_class.send(:format_parameters, params)
        
        expect(result).to eq([
          { name: "arg1", default: nil },
          { name: "arg2", default: "default_value" }
        ])
      end

      it "returns empty array for nil parameters" do
        result = described_class.send(:format_parameters, nil)
        expect(result).to eq([])
      end
    end
  end
end